import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:banksync_app/core/auth/biometric_challenge_result.dart';
import 'package:banksync_app/core/config/app_config.dart';
import 'package:banksync_app/core/network/api_error_message.dart';
import 'package:banksync_app/core/network/api_exception.dart';
import 'package:banksync_app/core/network/api_logging_interceptor.dart';
import 'package:banksync_app/core/network/banking_auth_exceptions.dart';

class ApiClient {
  ApiClient({Dio? dio, this.currentLanguageResolver}) : _dio = dio ?? createDio();

  final Dio _dio;
  final String Function()? currentLanguageResolver;

  /// Exposed so providers can attach interceptors (e.g. session refresh).
  Dio get dio => _dio;

  static final _validateOptions = Options(
    validateStatus: (status) => status != null && status < 500,
  );

  Future<Map<String, dynamic>> loginKeycloak(String username, String password) async {
    final kc = AppConfig.instance.keycloak;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        kc.tokenEndpoint,
        data: {
          'grant_type': 'password',
          'client_id': kc.clientId,
          'username': username,
          'password': password,
          'scope': kc.scopes.join(' '),
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return res.data ?? {};
    } on DioException catch (e) {
      throw KeycloakAuthException(_keycloakMessage(e));
    }
  }

  /// Keycloak refresh-token grant — exchanges a refresh token for a fresh
  /// access/refresh pair. Foundation for the (separate) silent-refresh task;
  /// secrets are sent form-encoded and redacted from logs.
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    final kc = AppConfig.instance.keycloak;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        kc.tokenEndpoint,
        data: {
          'grant_type': 'refresh_token',
          'client_id': kc.clientId,
          'refresh_token': refreshToken,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return res.data ?? {};
    } on DioException catch (e) {
      // No HTTP response → connectivity failure, not a rejection. Propagate
      // as-is so AuthService can keep the session instead of ending it.
      if (e.response == null) rethrow;
      throw KeycloakAuthException(_keycloakMessage(e));
    }
  }

  /// Maps core banking customer ID (or legacy login) to Keycloak username.
  Future<String> resolveLoginUsername(String login) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/auth/resolve-login',
      data: {'login': login.trim()},
      options: _validateOptions,
    );
    final body = res.data ?? {};
    if (body['success'] != true) {
      throw _apiFromBody(body, res.requestOptions);
    }
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final username = data['keycloakUsername']?.toString();
    if (username == null || username.isEmpty) {
      throw const ApiException('Unable to resolve customer ID');
    }
    return username;
  }

  Future<void> setInitialPassword({
    required String username,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _postPublic('/api/mobile/auth/set-initial-password', {
      'username': username,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  Future<void> resetPasswordByMobile(String mobileNo) async {
    await _postPublic('/api/mobile/auth/reset-password', {'mobileNo': mobileNo});
  }

  Future<Map<String, dynamic>> registerLookup(String customerId) async {
    return _postPublicData('/api/mobile/auth/register/lookup', {
      'customerId': customerId.trim(),
    });
  }

  Future<Map<String, dynamic>> registerCustomer({
    required String customerId,
    required String usernameMode,
    String? customUsername,
  }) async {
    return _postPublicData('/api/mobile/auth/register', {
      'customerId': customerId.trim(),
      'usernameMode': usernameMode,
      if (customUsername != null && customUsername.trim().isNotEmpty)
        'customUsername': customUsername.trim(),
    });
  }

  /// Wallet identity registration — no bank-core lookup. Creates a Keycloak
  /// user in the wallet realm keyed by the mobile number; the temporary
  /// password equals the normalized username (the mobile). Returns the
  /// response `data`, which includes `keycloakUsername`.
  ///
  /// This replaces [registerCustomer] for the wallet flow: the old
  /// `/api/mobile/auth/register` still resolves the customer against the bank
  /// core and requires a real `customerId`, which the wallet doesn't have at
  /// sign-up. The core CIF is linked later via [linkCore].
  Future<Map<String, dynamic>> registerIdentity({
    required String mobile,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    return _postPublicData('/api/mobile/auth/identity/register', {
      'mobile': mobile.trim(),
      if (firstName != null && firstName.trim().isNotEmpty)
        'firstName': firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty)
        'lastName': lastName.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    });
  }

  /// Links a freshly-created core CIF to the signed-in wallet identity. The
  /// server reads the mobile from the JWT `preferred_username`, so the caller
  /// only sends the core [customerId]. Requires a bearer token; after it
  /// succeeds the client must refresh/re-login so `customer_id` lands in the
  /// token.
  Future<Map<String, dynamic>> linkCore({
    required String token,
    required String customerId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/auth/identity/link-core',
      data: {'customerId': customerId.trim()},
      options: Options(
        headers: _bearer(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    final body = res.data ?? {};
    if (body['success'] == true) {
      final payload = body['data'];
      if (payload is Map) return Map<String, dynamic>.from(payload);
      return {};
    }
    throw _apiFromBody(body, res.requestOptions);
  }



  Future<Map<String, dynamic>> userDetail(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/user/detail',
      options: Options(headers: _bearer(token)),
    );
    return _unwrap(res);
  }

  Future<void> setPin(String token, String pin, String confirmPin) async {
    await _postAuth('/api/mobile/auth/pin/set', token, {'pin': pin, 'confirmPin': confirmPin});
  }

  Future<void> changePin(
    String token, {
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/auth/pin/change',
      data: {
        'currentPin': currentPin,
        'newPin': newPin,
        'confirmPin': confirmPin,
      },
      options: Options(
        headers: _bearer(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    _throwPinErrors(res);
    if (res.data?['success'] != true) {
      throw _apiFromBody(res.data ?? {}, res.requestOptions);
    }
  }

  Future<void> resetPin(
    String token, {
    required String password,
    required String newPin,
    required String confirmPin,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/auth/pin/reset',
      data: {
        'password': password,
        'newPin': newPin,
        'confirmPin': confirmPin,
      },
      options: Options(
        headers: _bearer(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    _throwPinErrors(res);
    if (res.data?['success'] != true) {
      throw _apiFromBody(res.data ?? {}, res.requestOptions);
    }
  }

  Future<void> registerDevice(String token, String deviceId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/devices/register',
      data: {'deviceId': deviceId},
      options: Options(headers: _bearer(token), validateStatus: _validateOptions.validateStatus),
    );
    _throwDeviceErrors(res);
    if (res.data?['success'] != true) {
      throw _apiFromBody(res.data ?? {}, res.requestOptions);
    }
  }

  Future<void> registerBiometricKey({
    required String token,
    required String deviceId,
    required String publicKey,
    required String publicKeyAlg,
    required String transactionPin,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/devices/biometric/register-key',
      data: {
        'deviceId': deviceId,
        'publicKey': publicKey,
        'publicKeyAlg': publicKeyAlg,
      },
      options: Options(
        headers: {
          ..._bearer(token),
          'X-Transaction-Pin': transactionPin,
        },
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    _throwPinErrors(res);
    _throwDeviceErrors(res);
    _throwBiometricErrors(res);
    if (res.data?['success'] != true) {
      throw _apiFromBody(res.data ?? {}, res.requestOptions);
    }
  }

  Future<void> revokeBiometricKey({
    required String token,
    required String deviceId,
    required String transactionPin,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/devices/biometric/revoke',
      data: {'deviceId': deviceId},
      options: Options(
        headers: {
          ..._bearer(token),
          'X-Transaction-Pin': transactionPin,
        },
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    _throwPinErrors(res);
    _throwDeviceErrors(res);
    if (res.data?['success'] != true) {
      throw _apiFromBody(res.data ?? {}, res.requestOptions);
    }
  }

  Future<BiometricChallengeResult> requestBiometricChallenge(String deviceId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/devices/biometric/challenge',
      data: {'deviceId': deviceId},
      options: _validateOptions,
    );
    _throwDeviceErrors(res);
    _throwBiometricErrors(res);
    final body = res.data ?? {};
    if (body['success'] != true) {
      throw _apiFromBody(body, res.requestOptions);
    }
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return BiometricChallengeResult.fromJson(data);
  }

  Future<int?> reportBiometricFailure({
    required String deviceId,
    required String challengeId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/devices/biometric/failure',
      data: {'deviceId': deviceId, 'challengeId': challengeId},
      options: _validateOptions,
    );
    _throwBiometricErrors(res);
    final body = res.data ?? {};
    if (body['success'] != true) return null;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    final remaining = data['failuresRemaining'];
    if (remaining is int) return remaining;
    return int.tryParse(remaining?.toString() ?? '');
  }

  Future<Map<String, dynamic>> completeBiometricLogin({
    required String deviceId,
    required String challengeId,
    required String signature,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/devices/biometric/login',
      data: {
        'deviceId': deviceId,
        'challengeId': challengeId,
        'signature': signature,
      },
      options: _validateOptions,
    );
    _throwDeviceErrors(res);
    _throwBiometricErrors(res);
    final body = res.data ?? {};
    if (body['success'] == true) {
      return body['data'] as Map<String, dynamic>? ?? body;
    }
    final data = body['data'] as Map<String, dynamic>?;
    if (data != null && data.containsKey('failuresRemaining')) {
      throw ApiException(
        'Invalid biometric. Attempts remaining: ${data['failuresRemaining']}',
        code: 'INVALID_SIGNATURE',
      );
    }
    throw _apiFromBody(body, res.requestOptions);
  }

  /// Rotates a biometric session's token pair via mobile-service. Biometric
  /// tokens are minted server-side by token-exchange, so the public Keycloak
  /// client cannot refresh them directly — this endpoint does it for us after
  /// re-checking the device binding.
  Future<Map<String, dynamic>> refreshBiometricSession({
    required String deviceId,
    required String refreshToken,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/devices/biometric/refresh',
      data: {'deviceId': deviceId, 'refreshToken': refreshToken},
      options: _validateOptions,
    );
    _throwDeviceErrors(res);
    _throwBiometricErrors(res);
    final body = res.data ?? {};
    if (body['success'] == true) {
      return body['data'] as Map<String, dynamic>? ?? body;
    }
    throw _apiFromBody(body, res.requestOptions);
  }

  Future<List<dynamic>> accounts(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/accounts',
      options: Options(headers: _bearer(token)),
    );
    final body = res.data ?? {};
    if (body['success'] != true) {
      throw _apiFromBody(body, res.requestOptions);
    }
    return body['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> getAccountPreferences(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/account-preferences',
      options: Options(headers: _bearer(token)),
    );
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> saveAccountPreferences(
    String token,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/mobile/account-preferences',
      data: body,
      options: Options(headers: _bearer(token)),
    );
    return _unwrap(res);
  }

  /// Generic integration gateway — POST /api/mobile/integrations/{code}
  Future<Map<String, dynamic>> invokeIntegration(
    String token,
    String code,
    Map<String, dynamic> body, {
    String? transactionPin,
    String? currentLanguage,
  }) async {
    final headers = _bearer(token);
    if (transactionPin != null && transactionPin.isNotEmpty) {
      headers['X-Transaction-Pin'] = transactionPin;
    }
    final language = currentLanguage ?? currentLanguageResolver?.call();
    if (language != null && language.isNotEmpty) {
      headers['Current-Language'] = language == 'ar' ? 'en' : language;
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/integrations/$code',
      data: body,
      options: Options(
        headers: headers,
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    return _unwrap(res);
  }

  Future<List<dynamic>> transactions(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/transactions',
      options: Options(headers: _bearer(token)),
    );
    final body = res.data ?? {};
    if (body['success'] != true) {
      throw _apiFromBody(body, res.requestOptions);
    }
    return body['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> validateTransfer(
    String token,
    Map<String, dynamic> body,
  ) async {
    return invokeIntegration(token, 'TRANSFER-TO-WALLET-VALIDATE', body);
  }

  Future<Map<String, dynamic>> confirmTransfer(
    String token,
    Map<String, dynamic> body,
    String pin,
  ) async {
    return invokeIntegration(
      token,
      'TRANSFER-TO-WALLET-VALIDATE-CONFIRM',
      body,
      transactionPin: pin,
    );
  }

  Future<Map<String, dynamic>> submitTransfer(
    String token,
    Map<String, dynamic> body,
    String pin,
  ) async {
    return confirmTransfer(token, body, pin);
  }

  // ─── Open new wallet account (validate → open) ──────────────────
  // Wallet exposes a SINGLE validate code and a SINGLE open code (no
  // current/saving split); the account type + ledger are baked into the Back
  // Office integration, so the app never sends a ledger and `saving` no longer
  // selects the code. validate returns a reference ID which the open (process)
  // call passes back. Opening saves AND auto-authorizes (Authorizers=0) and
  // requires the transaction PIN.

  /// Pre-checks the request and returns the account details to preview.
  Future<Map<String, dynamic>> validateAccountOpen(
    String token, {
    required String currency,
    required String customer,
    bool saving = false,
    String? purpose,
  }) async {
    return invokeIntegration(
      token,
      // Wallet single validate code. This string is the Mobile Channel Path
      // shown in Back Office for WALLET_ACCOUNT_VALIDATE (the URL segment).
      'VALIDATE_WALLET_ACCOUNT',
      {
        'currency': currency,
        'customer': customer,
        if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
      },
    );
  }

  /// Opens (saves + auto-authorizes) the account. [id] is the reference id
  /// returned by [validateAccountOpen]; [saving] picks current vs saving.
  Future<Map<String, dynamic>> openAccount(
    String token, {
    required String currency,
    required String customer,
    required String pin,
    bool saving = false,
    String? id,
    String? purpose,
  }) async {
    final payload = <String, dynamic>{
      'currency': currency,
      'customer': customer,
      if (id != null && id.isNotEmpty) 'ID': id,
      if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
    };
    return invokeIntegration(
      token,
      'WALLET_ACCOUNT_OPEN',
      payload,
      transactionPin: pin,
    );
  }

  // ─── Beneficiaries ───────────────────────────────────────
  Future<Map<String, dynamic>> getBeneficiaries(String token) async {
    return invokeIntegration(token, 'BENEFICIARY_LIST', {});
  }

  Future<Map<String, dynamic>> validateBeneficiaryAccount(
    String token,
    String accountNumber,
  ) async {
    // NOTE: backend specifics this lookup depends on — keep in sync with the
    // backoffice integration definition:
    //  - code spelling has a typo ("BEBEFICIARY", not "BENEFICIARY").
    //  - request body key must be snake_case `account_number`; the template
    //    maps it via {{body.account_number}} into the core's query param.
    return invokeIntegration(token, 'BEBEFICIARY_ACC_LOOKUP', {'account_number': accountNumber});
  }

  Future<Map<String, dynamic>> addBeneficiary(
    String token,
    Map<String, dynamic> data,
  ) async {
    return invokeIntegration(token, 'BENEFICIARY_ADD', data);
  }

  Future<Map<String, dynamic>> deleteBeneficiary(
    String token,
    int beneficiaryId,
  ) async {
    return invokeIntegration(
        token, 'BENEFICIARY_DELETE', {'beneficiaryId': beneficiaryId});
  }

  /// Update an existing beneficiary.
  ///
  /// Required: `beneficiaryId`, `customer_id`, `account_number`, `nameAr`.
  /// Optional: `iban`, `nickname`, `bankNameAr`, `currency` (defaults YER).
  Future<Map<String, dynamic>> updateBeneficiary(
    String token,
    Map<String, dynamic> data,
  ) async {
    return invokeIntegration(token, 'BENEFICIARY_UPDATE', data);
  }

  // ─── Favorite transfers (server-side, JWT-scoped) ────────
  Future<Map<String, dynamic>> getFavorites(String token) async {
    return invokeIntegration(token, 'FAVORITE_LIST', {});
  }

  /// Add a favorite transfer target. Idempotent on the server: re-adding the
  /// same `targetAccountNumber` returns the existing row instead of erroring.
  Future<Map<String, dynamic>> addFavorite(
    String token,
    Map<String, dynamic> data,
  ) async {
    return invokeIntegration(token, 'FAVORITE_ADD', data);
  }

  /// Delete by `favoriteId` or by `targetAccountNumber` (either works).
  Future<Map<String, dynamic>> deleteFavorite(
    String token,
    Map<String, dynamic> data,
  ) async {
    return invokeIntegration(token, 'FAVORITE_DELETE', data);
  }

  // ─── Digital wallets (server-side tag over real UFF sub-accounts) ─────────
  // A "wallet" is a real customer sub-account (opened via the account-open
  // flow) plus a JWT-scoped tag row — same shape as FAVORITE_*. The core stays
  // the source of truth (balances come from CUSTOMER_ACCOUNTS_SEARCH); this tag
  // only records which accounts the customer designated as wallets + a friendly
  // name and optional spend cap. Load/Unload reuse the own-account transfer
  // codes (validateTransfer / confirmTransfer), so no new financial code here.

  /// Lists the customer's wallet tags (accountNumber + name + cap). Balances are
  /// joined client-side from [accountsProvider].
  Future<Map<String, dynamic>> getWallets(String token) async {
    return invokeIntegration(token, 'WALLET_LIST', {});
  }

  /// Tags an already-opened sub-account as a wallet. Idempotent on the server:
  /// re-tagging the same `accountNumber` updates the existing row.
  /// Expected keys: `accountNumber`, `walletName`, `currency`, optional `cap`.
  Future<Map<String, dynamic>> tagWallet(
    String token,
    Map<String, dynamic> data,
  ) async {
    return invokeIntegration(token, 'WALLET_TAG', data);
  }

  /// Removes the wallet tag by `walletId` or `accountNumber` (does NOT close the
  /// underlying core account — the account must already be empty).
  Future<Map<String, dynamic>> untagWallet(
    String token,
    Map<String, dynamic> data,
  ) async {
    return invokeIntegration(token, 'WALLET_UNTAG', data);
  }

  // ─── Bill payments (Section 7) ───────────────────────────
  // All five codes are LOCAL in mobile-service: the orchestrator generates the
  // provider TransactionID, owns the PENDING lifecycle in mobile_transactions,
  // and fans out to the per-provider integration definitions (SADAD-* etc.).

  Future<Map<String, dynamic>> getBillerCatalog(String token) async {
    return invokeIntegration(token, 'BILLER_CATALOG', {});
  }

  Future<Map<String, dynamic>> inquireBill(
    String token, {
    required String billerCode,
    required String subscriberNo,
  }) async {
    return invokeIntegration(token, 'BILL_INQUIRY', {
      'billerCode': billerCode,
      'subscriberNo': subscriberNo,
    });
  }

  Future<Map<String, dynamic>> listBillOffers(
    String token, {
    required String billerCode,
    required String subscriberNo,
  }) async {
    return invokeIntegration(token, 'BILL_OFFERS', {
      'billerCode': billerCode,
      'subscriberNo': subscriberNo,
    });
  }

  /// Pays a bill (amount) or activates a package (offerCode) — exactly one of
  /// the two must be provided. PIN goes through X-Transaction-Pin as always.
  Future<Map<String, dynamic>> payBill(
    String token, {
    required String billerCode,
    required String subscriberNo,
    required String debitAccount,
    String? amount,
    String? offerCode,
    required String pin,
  }) async {
    return invokeIntegration(
      token,
      'BILL_PAY',
      {
        'billerCode': billerCode,
        'subscriberNo': subscriberNo,
        'debitAccount': debitAccount,
        if (amount != null && amount.isNotEmpty) 'amount': amount,
        if (offerCode != null && offerCode.isNotEmpty) 'offerCode': offerCode,
      },
      transactionPin: pin,
    );
  }

  /// Reconciles a PENDING bill payment against the provider
  /// (free-sadad GetOperationStatus) and returns the settled row.
  Future<Map<String, dynamic>> refreshBillStatus(String token, String reference) async {
    return invokeIntegration(token, 'BILL_STATUS', {'reference': reference});
  }

  /// UN Money receive: credits a looked-up remittance to the customer account.
  /// Direct integration code — the definition (incl. PERSIST_RECORD) lives in
  /// Back Office and is wired at bank onboarding.
  Future<Map<String, dynamic>> confirmUnMoneyReceive(
    String token,
    Map<String, dynamic> body,
    String pin,
  ) async {
    return invokeIntegration(token, 'UNMONEY-RECEIVE-CONFIRM', body, transactionPin: pin);
  }

  // ─── KYC / identity verification ─────────────────────────────────────────
  // The client calls mobile-service KYC endpoints only. mobile-service runs the
  // INTERNAL WALLET_* integrations (WALLET_DOC_UPLOAD → WALLET_CUSTOMER_VALIDATE
  // → WALLET_CUSTOMER_CREATE, and WALLET_COUNTRY / WALLET_SECTOR) with the
  // registry-realm service token — the app never calls those integrations
  // directly. Contract lives in `mobile-service-scaffold/`.

  /// Uploads ONE KYC document and returns its `savedAs` server-side filename.
  ///
  /// `POST /api/mobile/kyc/document` — mobile-service stores the file (running
  /// WALLET_DOC_UPLOAD) and returns the reference. This is the **separate upload
  /// step**: the file is sent once, here; the returned `savedAs` (together with
  /// [uploadType]) is what later `onboard`/validate calls send — never the file
  /// again.
  ///
  /// [uploadType] is the caller-defined document-type string (e.g. `ID_FRONT`);
  /// mobile-service persists it verbatim as a String alongside `savedAs`.
  ///
  /// The reference comes back as a plain String in `data`
  /// (e.g. `"uploads/temp/.../abc.jpg"`), or as `{ savedAs }` at `data` / top
  /// level, or nested deeper (e.g. under `message`) — all shapes are tolerated.
  Future<String?> uploadKycDocument(
    String token, {
    required String fileBase64,
    required String uploadType,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/kyc/document',
      data: {'file': fileBase64, 'uploadType': uploadType},
      options: Options(
        headers: _bearer(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    final body = res.data ?? {};
    if (body['success'] != true) {
      throw _apiFromBody(body, res.requestOptions);
    }
    String? asRef(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final data = body['data'];
    // savedAs arrives as a plain String in `data` (the endpoint's contract) …
    if (data is String) {
      final ref = asRef(data);
      if (ref != null) return ref;
    }
    // … or as `{ savedAs }` at data / top level …
    return asRef((data is Map ? data['savedAs'] : null)) ??
        asRef(body['savedAs']) ??
        // … or nested deeper anywhere in the response.
        _deepFindString(body, 'savedAs');
  }

  /// Recursively finds the first non-empty String value for [key] in a nested
  /// map/list response. Used to locate `savedAs` when the endpoint wraps it.
  static String? _deepFindString(dynamic node, String key) {
    if (node is Map) {
      final direct = node[key];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }
      for (final v in node.values) {
        final found = _deepFindString(v, key);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final v in node) {
        final found = _deepFindString(v, key);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Account-confirmation onboarding — POST /api/mobile/kyc/onboard (Bearer).
  /// Body: `{ idType, profile: {nested identity fields},
  ///          upload: [{ upload: "<savedAs>", uploadType: "<type>" }, ...] }`.
  /// Files are NOT sent here — they were uploaded first via [uploadKycDocument],
  /// and only their `savedAs` references + `uploadType` strings are passed. The
  /// backend runs WALLET_CUSTOMER_VALIDATE → WALLET_CUSTOMER_CREATE against those
  /// references → writes `customer_id` to Keycloak. Returns `{ customerId, status }`.
  Future<Map<String, dynamic>> onboardKyc(
    String token,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/kyc/onboard',
      data: body,
      options: Options(
        headers: _bearer(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    return _unwrap(res);
  }

  /// Reference lists for the KYC pickers, fetched from mobile-service (which
  /// proxies the INTERNAL WALLET_COUNTRY / WALLET_SECTOR integrations).
  /// `GET /api/mobile/kyc/reference/{countries|sectors}`.
  Future<Map<String, dynamic>> getKycReference(String token, String kind) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/kyc/reference/$kind',
      options: Options(
        headers: _bearer(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    return _unwrap(res);
  }

  /// Current KYC status + review metadata.
  /// `GET /api/mobile/kyc/status` → `{ status, rejectionReason?, submittedAt?, reviewedAt?, documents:[...] }`.
  /// Optional: [KycRepository.fetchStatus] falls back to the cached profile when
  /// this endpoint isn't available.
  Future<Map<String, dynamic>> getKycStatus(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/kyc/status',
      options: Options(
        headers: _bearer(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    return _unwrap(res);
  }

  Future<List<Map<String, dynamic>>> listSupportCases(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/support/cases',
      queryParameters: {'page': 0, 'size': 50},
      options: Options(headers: _bearer(token)),
    );
    final data = _unwrap(res);
    final content = data['content'];
    if (content is List) {
      return content
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createSupportCase(
    String token, {
    required String subject,
    required String message,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/support/cases',
      data: {'subject': subject, 'message': message},
      options: Options(headers: _bearer(token)),
    );
    return _unwrap(res);
  }

  Future<Map<String, dynamic>> getSupportCase(String token, int caseId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/support/cases/$caseId',
      options: Options(headers: _bearer(token)),
    );
    return _unwrap(res);
  }

  Future<List<Map<String, dynamic>>> listSupportMessages(String token, int caseId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/support/cases/$caseId/messages',
      options: Options(headers: _bearer(token)),
    );
    return _unwrapList(res);
  }

  Future<Map<String, dynamic>> sendSupportMessage(String token, int caseId, String message) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/support/cases/$caseId/messages',
      data: {'message': message},
      options: Options(headers: _bearer(token)),
    );
    return _unwrap(res);
  }

  Future<void> markSupportCaseRead(String token, int caseId) async {
    await _postAuth('/api/mobile/support/cases/$caseId/mark-read', token, {});
  }

  Future<Map<String, dynamic>> createGuestSupportCase({
    required String mobile,
    required String guestName,
    required String subject,
    required String message,
  }) async {
    return _postPublicData('/api/mobile/support/guest/cases', {
      'mobile': mobile,
      'guestName': guestName,
      'subject': subject,
      'message': message,
    });
  }

  Future<Map<String, dynamic>> getGuestSupportCase({
    required String caseNumber,
    required String mobile,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/support/guest/cases/$caseNumber',
      queryParameters: {'mobile': mobile},
      options: _validateOptions,
    );
    return _unwrap(res);
  }

  Future<List<Map<String, dynamic>>> listGuestSupportMessages({
    required String caseNumber,
    required String mobile,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/support/guest/cases/$caseNumber/messages',
      queryParameters: {'mobile': mobile},
      options: _validateOptions,
    );
    return _unwrapList(res);
  }

  Future<Map<String, dynamic>> sendGuestSupportMessage({
    required String caseNumber,
    required String mobile,
    required String message,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/support/guest/cases/$caseNumber/messages',
      data: {'mobile': mobile, 'message': message},
      options: _validateOptions,
    );
    return _unwrap(res);
  }

  Future<void> markGuestSupportCaseRead({
    required String caseNumber,
    required String mobile,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/support/guest/cases/$caseNumber/mark-read',
      queryParameters: {'mobile': mobile},
      options: _validateOptions,
    );
    _unwrap(res);
  }

  Future<void> _postPublic(String path, Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: _validateOptions,
    );
    _unwrap(res);
  }

  Future<Map<String, dynamic>> _postPublicData(String path, Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: _validateOptions,
    );
    final body = res.data ?? {};
    if (body['success'] == true) {
      final payload = body['data'];
      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) return Map<String, dynamic>.from(payload);
      return {};
    }
    throw _apiFromBody(body, res.requestOptions);
  }

  Future<void> _postAuth(String path, String token, Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: Options(headers: _bearer(token)),
    );
    _unwrap(res);
  }

  /// Builds headers with Bearer token and Current-Language for notification endpoints.
  Map<String, String> _bearerWithLang(String token) {
    final headers = _bearer(token);
    final language = currentLanguageResolver?.call();
    if (language != null && language.isNotEmpty) {
      headers['Current-Language'] = language == 'ar' ? 'en' : language;
    }
    return headers;
  }

  // ─── Notification API ─────────────────────────────────────────────────

  /// PUT /api/mobile/devices/{deviceId}/push-token
  Future<void> registerFcmToken(
    String token, {
    required String deviceId,
    required String fcmToken,
    required String platform,
    required String appVersion,
    required String locale,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/mobile/devices/$deviceId/push-token',
      data: {
        'fcmToken': fcmToken,
        'platform': platform,
        'appVersion': appVersion,
        'locale': locale,
      },
      options: Options(
        headers: _bearerWithLang(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    _throwDeviceErrors(res);
    _throwNotificationErrors(res);
    if (res.data?['success'] != true) {
      throw _apiFromBody(res.data ?? {}, res.requestOptions);
    }
  }

  /// DELETE /api/mobile/devices/{deviceId}/push-token
  Future<void> removeFcmToken(String token, {required String deviceId}) async {
    final res = await _dio.delete<Map<String, dynamic>>(
      '/api/mobile/devices/$deviceId/push-token',
      options: Options(
        headers: _bearerWithLang(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    if (res.data?['success'] != true && res.statusCode != 204) {
      // Tolerate 404 on logout (token may already be removed)
      if (res.statusCode == 404) return;
      throw _apiFromBody(res.data ?? {}, res.requestOptions);
    }
  }

  /// GET /api/mobile/notifications?page=&size=&type=
  Future<Map<String, dynamic>> getNotifications(
    String token, {
    int page = 0,
    int size = 20,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/notifications',
      queryParameters: queryParams,
      options: Options(headers: _bearerWithLang(token)),
    );
    return _unwrap(res);
  }

  /// GET /api/mobile/notifications/unread-count
  Future<Map<String, dynamic>> getUnreadCount(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/notifications/unread-count',
      options: Options(headers: _bearerWithLang(token)),
    );
    return _unwrap(res);
  }

  /// POST /api/mobile/notifications/{id}/read
  Future<void> markNotificationRead(String token, int notificationId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/notifications/$notificationId/read',
      options: Options(
        headers: _bearerWithLang(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    _throwNotificationErrors(res);
    if (res.data?['success'] != true) {
      throw _apiFromBody(res.data ?? {}, res.requestOptions);
    }
  }

  /// POST /api/mobile/notifications/read-all
  Future<void> markAllNotificationsRead(String token, {String? type}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/mobile/notifications/read-all',
      data: type != null ? {'type': type} : null,
      options: Options(
        headers: _bearerWithLang(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    if (res.data?['success'] != true) {
      throw _apiFromBody(res.data ?? {}, res.requestOptions);
    }
  }

  /// GET /api/mobile/notification-preferences
  Future<Map<String, dynamic>> getNotificationPreferences(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/notification-preferences',
      options: Options(headers: _bearerWithLang(token)),
    );
    return _unwrap(res);
  }

  /// PUT /api/mobile/notification-preferences
  Future<void> updateNotificationPreferences(
    String token,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/mobile/notification-preferences',
      data: body,
      options: Options(
        headers: _bearerWithLang(token),
        validateStatus: _validateOptions.validateStatus,
      ),
    );
    _throwNotificationErrors(res);
    if (res.data?['success'] != true) {
      throw _apiFromBody(res.data ?? {}, res.requestOptions);
    }
  }

  Map<String, String> _bearer(String token) => {'Authorization': 'Bearer $token'};

  List<Map<String, dynamic>> _unwrapList(Response<Map<String, dynamic>> res) {
    final body = res.data ?? {};
    if (body['success'] != true) {
      throw _apiFromBody(body, res.requestOptions);
    }
    final data = body['data'];
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Map<String, dynamic> _unwrap(Response<Map<String, dynamic>> res) {
    final body = res.data ?? {};
    if (body['success'] == true) {
      return _normalizeIntegrationPayload(body['data']);
    }
    throw _apiFromBody(body, res.requestOptions);
  }

  /// Integration gateway may return a map, a list (rows), or invalid template as `{ "raw": "..." }`.
  Map<String, dynamic> _normalizeIntegrationPayload(dynamic data) {
    if (data == null) return {};
    Map<String, dynamic> map;
    if (data is Map<String, dynamic>) {
      map = data;
    } else if (data is Map) {
      map = Map<String, dynamic>.from(data);
    } else if (data is List) {
      return {'data': data};
    } else {
      return {};
    }
    return _unwrapCoreBankingEnvelope(map);
  }

  /// Core returns `{ success, data: { data: [...], totalCount } }` — flatten to the inner block.
  static Map<String, dynamic> _unwrapCoreBankingEnvelope(Map<String, dynamic> map) {
    if (map['success'] == true) {
      final inner = map['data'];
      if (inner is Map<String, dynamic>) {
        return inner;
      }
      if (inner is Map) {
        return Map<String, dynamic>.from(inner);
      }
    }
    return map;
  }

  void _throwDeviceErrors(Response<Map<String, dynamic>> res) {
    final body = res.data ?? {};
    final code = body['code']?.toString();
    if (res.statusCode == 409 || code == 'DEVICE_ALREADY_BOUND') {
      throw DeviceAlreadyBoundException(body['message']?.toString());
    }
    if (code == 'DEVICE_NOT_REGISTERED') {
      throw DeviceNotRegisteredException(body['message']?.toString());
    }
  }

  void _throwBiometricErrors(Response<Map<String, dynamic>> res) {
    final body = res.data ?? {};
    final code = body['code']?.toString();
    if (res.statusCode == 403 && code == 'BIOMETRIC_LOCKED') {
      throw BiometricLockedException(body['message']?.toString());
    }
    if (code == 'BIOMETRIC_NOT_ENROLLED' || code == 'BIOMETRIC_DISABLED') {
      throw BiometricNotEnrolledException(body['message']?.toString());
    }
  }

  void _throwPinErrors(Response<Map<String, dynamic>> res) {
    final body = res.data ?? {};
    final code = body['code']?.toString();
    if (code == 'PIN_INVALID' || code == 'PIN_REQUIRED') {
      throw PinInvalidException(body['message']?.toString() ?? 'Invalid PIN');
    }
  }

  void _throwNotificationErrors(Response<Map<String, dynamic>> res) {
    final body = res.data ?? {};
    final code = body['code']?.toString();
    if (code == 'PUSH_TOKEN_INVALID') {
      throw PushTokenInvalidException(body['message']?.toString());
    }
    if (code == 'NOTIFICATION_NOT_FOUND') {
      throw NotificationNotFoundException(body['message']?.toString());
    }
    if (code == 'CATEGORY_NOT_TOGGLEABLE') {
      throw CategoryNotToggleableException(body['message']?.toString());
    }
  }

  ApiException _apiFromBody(Map<String, dynamic> body, RequestOptions options) {
    final message = formatApiErrorBody(body);
    final code = body['code']?.toString();
    return ApiException(
      message,
      code: code,
    );
  }

  String _keycloakMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final desc = data['error_description'] as String?;
      if (desc != null && desc.isNotEmpty) {
        final lower = desc.toLowerCase();
        if (lower.contains('not fully set up') ||
            lower.contains('account is not fully set up') ||
            lower.contains('update password') ||
            lower.contains('temporary password') ||
            lower.contains('required action')) {
          throw FirstLoginPasswordChangeRequired(message: desc);
        }
        return desc;
      }
      final err = data['error'] as String?;
      if (err == 'invalid_grant') {
        return 'Invalid username or password';
      }
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach server. Check network and API URL.';
    }
    return e.message ?? 'Keycloak login failed';
  }

}

Dio createDio() {
  final config = AppConfig.instance;
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ),
  );
  if (config.keycloak.trustSelfSignedCerts) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (_, __, ___) => true;
        return client;
      },
    );
  }
  attachApiLoggingIfDebug(dio);
  return dio;
}
