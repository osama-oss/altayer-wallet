import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'kyc_document.dart';
import 'kyc_form_data.dart';
import 'kyc_reference_data.dart';
import 'kyc_status.dart';

/// Thrown when the verification backend is unreachable or not yet deployed
/// (connection failure, 404, or 5xx). The UI surfaces this as a soft
/// "service unavailable" message rather than a hard error, because the KYC
/// endpoints are the part still pending on the server side.
class KycUnavailableException implements Exception {
  const KycUnavailableException([this.message]);
  final String? message;
  @override
  String toString() => message ?? 'KYC service unavailable';
}

/// Single gateway between the KYC UI and the backend. Every network call goes
/// through here so the screens never touch [ApiClient] or tokens directly.
class KycRepository {
  KycRepository({required AuthService auth, required ApiClient api})
      : _auth = auth,
        _api = api;

  final AuthService _auth;
  final ApiClient _api;


  /// Fetches the authoritative KYC status. If the endpoint is not yet available
  /// it falls back to the value cached on the user profile (the real source once
  /// the backend adds `kycStatus` to `userDetail`), defaulting to unverified —
  /// it never fabricates a verified/pending state.
  Future<KycProfile> fetchStatus() async {
    final token = await _auth.readToken();
    if (token == null || token.isEmpty) {
      return KycProfile.unverified;
    }
    try {
      final data = await _api.getKycStatus(token);
      return KycProfile.fromMap(data);
    } on DioException {
      return _profileFallback();
    } on ApiException {
      // Endpoint missing / not-found envelope → derive from the cached profile.
      return _profileFallback();
    }
  }

  Future<KycProfile> _profileFallback() async {
    final profile = await _auth.readProfile();
    return KycProfile.fromUserProfile(profile);
  }

  /// Live country list (WALLET_COUNTRY via mobile-service). Falls back to the
  /// local [kycCountries] on any failure so the pickers always have options.
  Future<List<KycCountry>> fetchCountries() async {
    try {
      final token = await _auth.readToken();
      if (token == null || token.isEmpty) return kycCountries;
      final res = await _api.getKycReference(token, 'countries');
      final list = _rows(res)
          .map(KycCountry.fromWallet)
          .where((c) => c.code.isNotEmpty)
          .toList();
      return list.isEmpty ? kycCountries : list;
    } catch (_) {
      return kycCountries;
    }
  }

  /// Live sector list (WALLET_SECTOR via mobile-service). Falls back to
  /// [kycSectorsFallback] on any failure.
  Future<List<KycSector>> fetchSectors() async {
    try {
      final token = await _auth.readToken();
      if (token == null || token.isEmpty) return kycSectorsFallback;
      final res = await _api.getKycReference(token, 'sectors');
      final list = _rows(res)
          .map(KycSector.fromWallet)
          .where((s) => s.code.isNotEmpty)
          .toList();
      return list.isEmpty ? kycSectorsFallback : list;
    } catch (_) {
      return kycSectorsFallback;
    }
  }

  /// Extracts the row list from a reference response. `getKycReference` unwraps
  /// to `{ data: [ ...rows... ], totalCount }`.
  List<Map<String, dynamic>> _rows(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// Creates the wallet customer in the core from the collected form + captured
  /// documents via the single-call `POST /api/mobile/kyc/onboard` endpoint.
  ///
  /// The app sends the full payload in **one call**:
  /// ```json
  /// {
  ///   "idType": "NATIONAL_ID",
  ///   "profile": { ...nested identity fields... },
  ///   "images": [ "<front base64>", "<back base64>", "<selfie base64>" ]
  /// }
  /// ```
  ///
  /// The **backend** handles everything automatically:
  ///   WALLET_DOC_UPLOAD (per image) → WALLET_CUSTOMER_VALIDATE →
  ///   WALLET_CUSTOMER_CREATE → writes `customer_id` to Keycloak.
  ///
  /// The app never calls the WALLET_* integrations directly (they are INTERNAL).
  /// No `customerId` is sent — the core generates it and returns it; it is
  /// captured onto the cached profile.
  ///
  /// [orderedDocuments] must be in the exact order the core expects
  /// (national: front, back, selfie · passport: passport, selfie) — that
  /// order is preserved into the `images` list.
  Future<KycProfile> createCustomer({
    required KycIdType idType,
    required KycFormData formData,
    required List<KycDocument> orderedDocuments,
  }) async {
    final token = await _auth.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Not signed in');
    }
    try {
      // 1. Convert each captured photo to base64; keep the core's expected order.
      final images = <String>[];
      for (final doc in orderedDocuments) {
        final file = doc.file;
        if (file == null) {
          throw const ApiException('Missing document image');
        }
        images.add(base64Encode(await file.readAsBytes()));
      }

      // 2. Nested profile fields; merge registration-sourced givenName /
      //    familyName / mobile from the cached Keycloak profile.
      final profile = <String, dynamic>{...formData.toWire()};
      await _mergeRegistrationFields(profile);

      // 3. Single onboard call — backend does doc-upload → validate → create.
      final result = await _api.onboardKyc(token, {
        'idType': idType.wireCode, // NATIONAL_ID | PASSPORT
        'profile': profile,
        'images': images, // ordered base64 strings
      });

      final customerId = _deepFind(result, 'customerId') ??
          _deepFind(result, 'ID') ??
          _deepFind(result, 'customerCode');
      if (customerId != null) {
        await _persistCustomerId(customerId);
      }
      return const KycProfile(status: KycStatus.pending);
    } on DioException catch (e) {
      throw _asUnavailable(e);
    } on ApiException catch (e) {
      throw _translate(e);
    }
  }

  /// Merges the core-generated customer id onto the cached user profile so the
  /// rest of the app can read it. Best-effort — a storage failure never blocks
  /// the (already successful) customer creation.
  Future<void> _persistCustomerId(String customerId) async {
    try {
      final profile = await _auth.readProfile();
      await _auth.saveProfile(<String, dynamic>{
        ...?profile,
        'customerId': customerId,
      });
    } catch (_) {
      // Non-fatal: the id is also written to the Keycloak user server-side.
    }
  }

  /// Recursively finds the first non-empty value for [key] anywhere in a nested
  /// response (maps/lists). Used for `savedAs` (nested under `message` in the
  /// doc-upload response) and the customer `ID` (nested under `resposn`).
  static String? _deepFind(dynamic node, String key) {
    if (node is Map) {
      final direct = node[key];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }
      for (final value in node.values) {
        final found = _deepFind(value, key);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final value in node) {
        final found = _deepFind(value, key);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Folds the registration/profile-sourced fields the core also needs (name,
  /// mobile, privateCode) into [body]. These stay gaps until registration
  /// persists them (see KYC_BACKEND_PLAN §11.6); whatever is cached is
  /// best-effort and missing keys are simply omitted.
  Future<void> _mergeRegistrationFields(Map<String, dynamic> body) async {
    final profile = await _auth.readProfile();
    if (profile == null) return;
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = profile[k]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    final mobile = pick(['mobile', 'mobileNo', 'phone', 'phoneNumber']);
    if (mobile != null) {
      body['mobileNo'] = mobile;
      body['privateCode'] = mobile; // privateCode is always the phone number.
    }
    // NOTE: `customerId` is intentionally NOT sent. The core auto-generates it on
    // WALLET_CUSTOMER_CREATE and returns it; mobile-service writes it back onto
    // the Keycloak user so later tokens carry the customer_id claim.
    // `fullName` is NOT merged here — the form now collects it bilingually and
    // emits the flat `fullNameAr`/`fullNameEn` keys the core template expects.
    final given = pick(['firstName', 'givenName']);
    if (given != null) body['givenName'] = given;
    final family = pick(['lastName', 'surname', 'familyName']);
    if (family != null) body['familyName'] = family;
  }

  KycUnavailableException _asUnavailable(DioException e) {
    return KycUnavailableException(e.message);
  }

  /// A [BusinessException] from mobile-service always carries a `code`; a bare
  /// framework error (e.g. a 404 because the KYC controller isn't deployed yet)
  /// does not. Treat the latter as "service unavailable" and let real coded
  /// business errors (KYC_LOCKED, VALIDATION_ERROR, …) bubble up unchanged.
  Object _translate(ApiException e) {
    if (e.code == null || e.code!.isEmpty) {
      return KycUnavailableException(e.message);
    }
    return e;
  }
}
