import 'package:dio/dio.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'kyc_document.dart';
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

  Future<String> _requireToken() async {
    final token = await _auth.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Not signed in');
    }
    return token;
  }

  /// Fetches the authoritative KYC status. If the endpoint is not yet available
  /// it falls back to the value cached on the user profile (the real source once
  /// the backend adds `kycStatus` to `userDetail`), defaulting to unverified —
  /// it never fabricates a verified/pending state.
  Future<KycProfile> fetchStatus() async {
    final token = await _requireToken();
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

  /// Uploads a single captured document. Translates connectivity / missing-
  /// endpoint failures into [KycUnavailableException]; genuine validation
  /// errors (e.g. blurry image rejected by the server) bubble up as [ApiException].
  Future<String?> uploadDocument(KycDocument document) async {
    final file = document.file;
    if (file == null) {
      throw const ApiException('No file to upload');
    }
    final token = await _requireToken();
    try {
      final data = await _api.uploadKycDocument(
        token,
        type: document.type.wireCode,
        filePath: file.path,
        fileName: file.name,
      );
      return data['documentId']?.toString();
    } on DioException catch (e) {
      throw _asUnavailable(e);
    } on ApiException catch (e) {
      throw _translate(e);
    }
  }

  /// Submits the uploaded set for review and returns the new status snapshot.
  /// [idType] is the wire value (NATIONAL_ID / PASSPORT) of the chosen document.
  /// [profile] carries the identity + residence details confirmed on the data
  /// form (see [KycFormData.toWire]); omitted keys are simply not sent.
  Future<KycProfile> submit({
    String? idType,
    Map<String, dynamic>? profile,
  }) async {
    final token = await _requireToken();
    try {
      final data = await _api.submitKyc(token, idType: idType, profile: profile);
      // Backend may return the full snapshot, or just a status — default to
      // pending on a bare success since submit always enqueues a review.
      final map = data.isEmpty ? {'status': KycStatus.pending.wireValue} : data;
      return KycProfile.fromMap(Map<String, dynamic>.from(map));
    } on DioException catch (e) {
      throw _asUnavailable(e);
    } on ApiException catch (e) {
      throw _translate(e);
    }
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
