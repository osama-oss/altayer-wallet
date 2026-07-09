import 'dart:async';

import 'package:dio/dio.dart';

import 'package:banksync_app/core/auth/biometric_auth_service.dart';
import 'package:banksync_app/core/auth/biometric_challenge_result.dart';
import 'package:banksync_app/core/auth/device_signing_service.dart';
import 'package:banksync_app/core/auth/device_storage.dart';
import 'package:banksync_app/core/auth/session_store.dart';
import 'package:banksync_app/core/config/app_config.dart';
import 'package:banksync_app/core/network/api_client.dart';
import 'package:banksync_app/core/network/api_exception.dart';
import 'package:banksync_app/core/network/banking_auth_exceptions.dart';

enum PostLoginRoute { home, pinSetup, setInitialPassword, biometricEnroll }

/// Result of a silent token refresh. [offline] means the issuer was
/// unreachable — the session may still be valid, so callers must NOT sign the
/// user out; only [rejected] ends the session.
enum SessionRefreshOutcome { success, rejected, offline }

class LoginResult {
  const LoginResult({
    required this.route,
    this.username,
    this.keycloakUsername,
    this.tempPassword,
  });

  final PostLoginRoute route;
  /// Login identifier entered by the user (e.g. core customer id).
  final String? username;
  /// Resolved Keycloak username for password APIs.
  final String? keycloakUsername;
  final String? tempPassword;
}

class AuthService {
  AuthService({
    ApiClient? api,
    SessionStore? store,
    DeviceStorage? devices,
    BiometricAuthService? biometricAuth,
    DeviceSigningService? deviceSigning,
    Future<void> Function()? onSignOut,
    Future<void> Function()? onLoginSuccess,
  })  : _api = api ?? ApiClient(),
        _store = store ?? SessionStore(),
        _devices = devices ?? DeviceStorage(),
        _biometricAuth = biometricAuth ?? BiometricAuthService(),
        _deviceSigning = deviceSigning ?? DeviceSigningService(),
        _onSignOut = onSignOut,
        _onLoginSuccess = onLoginSuccess;

  final ApiClient _api;
  final SessionStore _store;
  final DeviceStorage _devices;
  final BiometricAuthService _biometricAuth;
  final DeviceSigningService _deviceSigning;
  final Future<void> Function()? _onSignOut;
  final Future<void> Function()? _onLoginSuccess;

  /// Re-entrancy guard: prevents recursive signOut when the push-token
  /// cleanup itself triggers another session expiry.
  bool _signingOut = false;

  Future<bool> canUnlockWithBiometric() async {
    if (!await _devices.isBiometricLoginEnabled()) return false;
    return _deviceSigning.hasEnrollmentKey();
  }

  Future<bool> isBiometricHardwareAvailable() =>
      _biometricAuth.isBiometricAvailable();

  Future<bool> isBiometricEnabled() async {
    if (!await _devices.isBiometricLoginEnabled()) return false;
    return _deviceSigning.hasEnrollmentKey();
  }

  Future<bool> prefersPasswordLogin() => _devices.prefersPasswordLogin();

  /// Soft sign-out for biometric unlock → password login (keeps enrollment).
  Future<void> switchToPasswordLogin() async {
    await _devices.setPreferPasswordLogin(true);
    await signOut();
  }

  Future<void> clearPreferPasswordLogin() => _devices.setPreferPasswordLogin(false);

  Future<LoginResult> loginWithPassword(String username, String password) async {
    final trimmedUser = username.trim();
    final keycloakUsername = await _api.resolveLoginUsername(trimmedUser);
    try {
      final tokens = await _api.loginKeycloak(keycloakUsername, password);
      final access = tokens['access_token'] as String?;
      if (access == null || access.isEmpty) {
        throw const KeycloakAuthException('No access token from Keycloak');
      }
      return _completePasswordSession(
        access,
        trimmedUser,
        refreshToken: tokens['refresh_token'] as String?,
        accessTokenExpiry: _expiryFromExpiresIn(tokens['expires_in']),
      );
    } on FirstLoginPasswordChangeRequired {
      return LoginResult(
        route: PostLoginRoute.setInitialPassword,
        username: trimmedUser,
        keycloakUsername: keycloakUsername,
        tempPassword: password,
      );
    }
  }

  Future<LoginResult> _completePasswordSession(
    String token,
    String username, {
    String? refreshToken,
    DateTime? accessTokenExpiry,
  }) async {
    // Reset the idle clock BEFORE any API call — without this, the interceptor
    // sees a stale lastActivity stamp from a previous (expired) session and
    // rejects userDetail/registerDevice with 401 SESSION_IDLE_TIMEOUT.
    await _store.touchLastActivity(persist: true);

    final detail = await _api.userDetail(token);
    final deviceId = await _devices.getOrCreateDeviceId();
    try {
      await _api.registerDevice(token, deviceId);
    } on DeviceAlreadyBoundException {
      await _store.clear();
      rethrow;
    }
    await _store.saveSession(
      token: token,
      username: username,
      profile: detail,
      refreshToken: refreshToken,
      accessTokenExpiry: accessTokenExpiry,
      authMethod: SessionAuthMethod.password,
    );
    await clearPreferPasswordLogin();
    await _store.touchLastActivity(persist: true);
    _onLoginSuccess?.call();
    final pinStatus = detail['pinStatus']?.toString();
    if (pinStatus == 'NOT_SET') {
      return const LoginResult(route: PostLoginRoute.pinSetup);
    }
    if (await _biometricAuth.isBiometricAvailable() && !await isBiometricEnabled()) {
      return const LoginResult(route: PostLoginRoute.biometricEnroll);
    }
    return const LoginResult(route: PostLoginRoute.home);
  }

  Future<LoginResult> completeInitialPasswordAndLogin({
    required String username,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.setInitialPassword(
      username: username,
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    return loginWithPassword(username, newPassword);
  }

  Future<void> resetPasswordByMobile(String mobileNo) async {
    await _api.resetPasswordByMobile(mobileNo.trim());
    await _clearBiometricLocal();
  }

  Future<Map<String, dynamic>> lookupRegistration(String customerId) =>
      _api.registerLookup(customerId);

  Future<Map<String, dynamic>> completeRegistration({
    required String customerId,
    required String usernameMode,
    String? customUsername,
  }) =>
      _api.registerCustomer(
        customerId: customerId,
        usernameMode: usernameMode,
        customUsername: customUsername,
      );

  Future<void> setupPinAndDevice(String pin, String confirmPin) async {
    final token = await _store.readToken();
    if (token == null) throw const ApiException('Not signed in');
    await _api.setPin(token, pin, confirmPin);
    final deviceId = await _devices.getOrCreateDeviceId();
    await _api.registerDevice(token, deviceId);
    await _refreshProfile();
  }

  Future<void> changeTransactionPin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    final token = await _store.readToken();
    if (token == null) throw const ApiException('Not signed in');
    await _api.changePin(
      token,
      currentPin: currentPin,
      newPin: newPin,
      confirmPin: confirmPin,
    );
    await _refreshProfile();
  }

  Future<void> resetTransactionPin({
    required String password,
    required String newPin,
    required String confirmPin,
  }) async {
    final token = await _store.readToken();
    if (token == null) throw const ApiException('Not signed in');
    await _api.resetPin(
      token,
      password: password,
      newPin: newPin,
      confirmPin: confirmPin,
    );
    await _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    final token = await _store.readToken();
    if (token == null) return;
    final detail = await _api.userDetail(token);
    final username = await _store.readUsername() ?? '';
    await _store.saveSession(token: token, username: username, profile: detail);
  }

  Future<bool> enableBiometricLogin(String transactionPin) async {
    if (!await _biometricAuth.isBiometricAvailable()) return false;
    final ok = await _biometricAuth.authenticate(
      reason: 'تفعيل تسجيل الدخول بالبصمة في محفظة عَ الطاير',
    );
    if (!ok) return false;

    final token = await _store.readToken();
    if (token == null) throw const ApiException('Not signed in');
    final deviceId = await _devices.getOrCreateDeviceId();

    try {
      final publicKey = await _deviceSigning.createEnrollmentKey();
      await _api.registerBiometricKey(
        token: token,
        deviceId: deviceId,
        publicKey: publicKey,
        publicKeyAlg: DeviceSigningService.publicKeyAlg,
        transactionPin: transactionPin,
      );
    } catch (e) {
      await _deviceSigning.deleteEnrollmentKey();
      rethrow;
    }

    await _devices.setBiometricLoginEnabled(true);
    await _store.clearSessionTokens();
    return true;
  }

  Future<bool> disableBiometricLogin(String transactionPin) async {
    final token = await _store.readToken();
    if (token == null) throw const ApiException('Not signed in');
    final deviceId = await _devices.getOrCreateDeviceId();
    await _api.revokeBiometricKey(
      token: token,
      deviceId: deviceId,
      transactionPin: transactionPin,
    );
    await _clearBiometricLocal();
    return true;
  }

  Future<BiometricChallengeResult> requestBiometricChallenge() async {
    if (!await canUnlockWithBiometric()) {
      throw const BiometricNotEnrolledException();
    }
    final deviceId = await _devices.getOrCreateDeviceId();
    return _api.requestBiometricChallenge(deviceId);
  }

  Future<int?> reportBiometricFailure(BiometricChallengeResult challenge) async {
    final deviceId = await _devices.getOrCreateDeviceId();
    return _api.reportBiometricFailure(
      deviceId: deviceId,
      challengeId: challenge.challengeId,
    );
  }

  Future<LoginResult> completeBiometricLogin(BiometricChallengeResult challenge) async {
    final deviceId = await _devices.getOrCreateDeviceId();
    Object? failureSideEffect;
    final signature = await _deviceSigning.signNonce(
      challenge.nonce,
      onBiometricAttemptFailed: () async {
        try {
          await reportBiometricFailure(challenge);
        } catch (e) {
          failureSideEffect ??= e;
        }
      },
    );
    if (failureSideEffect is BiometricLockedException) {
      throw failureSideEffect!;
    }

    final data = await _api.completeBiometricLogin(
      deviceId: deviceId,
      challengeId: challenge.challengeId,
      signature: signature,
    );

    final accessToken = data['accessToken']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('Biometric login missing access token');
    }

    final username = data['preferredUsername']?.toString() ??
        await _store.readUsername() ??
        '';
    final profile = {
      'id': data['id'],
      'mobile': data['mobile'],
      'fullName': data['fullName'],
      'preferredUsername': data['preferredUsername'],
      'pinStatus': data['pinStatus'],
    };

    await _store.saveSession(
      token: accessToken,
      username: username,
      profile: profile,
      refreshToken: data['refreshToken']?.toString(),
      accessTokenExpiry: _expiryFromExpiresIn(data['expiresIn']),
      authMethod: SessionAuthMethod.biometric,
    );
    await clearPreferPasswordLogin();
    await _store.touchLastActivity(persist: true);
    _onLoginSuccess?.call();

    if (profile['pinStatus']?.toString() == 'NOT_SET') {
      return const LoginResult(route: PostLoginRoute.pinSetup);
    }
    return const LoginResult(route: PostLoginRoute.home);
  }

  /// In-place re-authentication for the session-continuation sheet: swaps in
  /// a fresh Keycloak token pair for the *already signed-in* user without
  /// touching device registration, the cached profile, or biometric
  /// enrollment. Used when the server rejects the current token (e.g. the
  /// customer-id claim is missing) and the user re-enters their password to
  /// keep working where they are.
  Future<void> reauthenticate(String password) async {
    final username = await _store.readUsername();
    if (username == null || username.isEmpty) {
      throw const ApiException('Not signed in');
    }
    final keycloakUsername = await _api.resolveLoginUsername(username);
    final tokens = await _api.loginKeycloak(keycloakUsername, password);
    final access = tokens['access_token'] as String?;
    if (access == null || access.isEmpty) {
      throw const KeycloakAuthException('No access token from Keycloak');
    }
    await _store.saveSession(
      token: access,
      username: username,
      refreshToken: tokens['refresh_token'] as String?,
      accessTokenExpiry: _expiryFromExpiresIn(tokens['expires_in']),
      authMethod: SessionAuthMethod.password,
    );
    await _store.touchLastActivity(persist: true);
  }

  Future<String?> bootstrapRoute() async {
    // Idle timeout applies across process death too: if the app was killed and
    // reopened after the user's timeout, drop the session before restoring it.
    if (await isIdleTimedOut()) {
      await _store.clearSessionTokens();
    }
    if (await canUnlockWithBiometric()) {
      final token = await _store.readToken();
      if (token == null || token.isEmpty) {
        if (await prefersPasswordLogin()) return '/login';
        return '/biometric-unlock';
      }
    }
    final restored = await tryRestoreSession();
    if (!restored) return '/login';
    return postRestoreRoute();
  }

  Future<bool> tryRestoreSession() async {
    final token = await _store.readToken();
    if (token == null) return false;
    try {
      final detail = await _api.userDetail(token);
      final username = await _store.readUsername() ?? '';
      await _store.saveSession(token: token, username: username, profile: detail);
      return true;
    } catch (_) {
      await _store.clearSessionTokens();
      return false;
    }
  }

  Future<String?> postRestoreRoute() async {
    final profile = await _store.readProfile();
    if (profile == null) return '/login';
    if (profile['pinStatus']?.toString() == 'NOT_SET') return '/pin-setup';
    return '/home';
  }

  /// Soft sign-out clears the session token but keeps biometric enrollment
  /// so the user can unlock with biometrics next time.
  /// [full: true] wipes all local session data and biometric enrollment.
  Future<void> signOut({bool full = false}) async {
    if (_signingOut) return; // prevent recursive sign-out loop
    _signingOut = true;
    try {
      try {
        await _onSignOut?.call();
      } catch (_) {
        // Push-token removal is best-effort; don't block sign-out.
      }
      if (full) {
        await clearPreferPasswordLogin();
        await _clearBiometricLocal();
        await _store.clear();
        return;
      }

      if (await canUnlockWithBiometric()) {
        await _store.clearSessionTokens();
        return;
      }

      await _store.clear();
    } finally {
      _signingOut = false;
    }
  }

  Future<void> _clearBiometricLocal() async {
    await _deviceSigning.deleteEnrollmentKey();
    await _devices.clearBiometricLoginEnabled();
  }

  Future<String?> readToken() => _store.readToken();

  Future<String?> readUsername() => _store.readUsername();

  Future<void> saveProfile(Map<String, dynamic> profile) => _store.saveProfile(profile);

  Future<Map<String, dynamic>?> readProfile() => _store.readProfile();

  // ─── Session lifecycle ────────────────────────────────────────────────
  /// True when the stored access token is missing/near expiry. Foundation for
  /// the (separate) silent-refresh interceptor and idle-lock tasks.
  Future<bool> isSessionExpired() => _store.isAccessTokenExpired();

  /// In-flight silent refresh, shared by all concurrent callers.
  ///
  /// CONCURRENCY: Keycloak runs with "Revoke Refresh Token" ON — the first
  /// refresh rotates (and revokes) the refresh token, so a second parallel
  /// refresh with the same token would be rejected and kill the session. All
  /// simultaneous callers must therefore await one single-flight future.
  Future<SessionRefreshOutcome>? _refreshInFlight;

  /// Exchanges the stored refresh token for a fresh access/refresh pair and
  /// persists the rotated tokens. Password sessions refresh straight against
  /// Keycloak; biometric sessions were minted by token-exchange, so they must
  /// go through mobile-service (`/devices/biometric/refresh`).
  Future<SessionRefreshOutcome> refreshSession() {
    return _refreshInFlight ??= _refreshSessionOnce().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<SessionRefreshOutcome> _refreshSessionOnce() async {
    final refresh = await _store.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return SessionRefreshOutcome.rejected;
    try {
      final String? access;
      final String? rotatedRefresh;
      final DateTime? expiry;
      if (await _store.readAuthMethod() == SessionAuthMethod.biometric) {
        final deviceId = await _devices.getOrCreateDeviceId();
        final data = await _api.refreshBiometricSession(
          deviceId: deviceId,
          refreshToken: refresh,
        );
        access = data['accessToken']?.toString();
        rotatedRefresh = data['refreshToken']?.toString();
        expiry = _expiryFromExpiresIn(data['expiresIn']);
      } else {
        final tokens = await _api.refreshAccessToken(refresh);
        access = tokens['access_token'] as String?;
        rotatedRefresh = tokens['refresh_token'] as String?;
        expiry = _expiryFromExpiresIn(tokens['expires_in']);
      }
      if (access == null || access.isEmpty) return SessionRefreshOutcome.rejected;
      final username = await _store.readUsername() ?? '';
      await _store.saveSession(
        token: access,
        username: username,
        refreshToken: rotatedRefresh ?? refresh,
        accessTokenExpiry: expiry,
      );
      return SessionRefreshOutcome.success;
    } on DioException catch (e) {
      // No HTTP response = connectivity problem, not a rejection: keep the
      // session so a momentarily-offline user is not signed out.
      if (e.response == null) return SessionRefreshOutcome.offline;
      return SessionRefreshOutcome.rejected;
    } catch (_) {
      return SessionRefreshOutcome.rejected;
    }
  }

  // ─── Idle session timeout ─────────────────────────────────────────────
  /// Fixed idle timeout (minutes) from [AppConfig]. Keycloak SSO Session Idle
  /// is the authoritative enforcer; this value drives the client-side UX
  /// fallback (show “session expired” and navigate to login).
  int sessionTimeoutMinutes() => AppConfig.instance.sessionIdleMinutes;



  /// Marks the user as active now (called after successful API traffic).
  /// Memory-only — it runs on every response, so it must never hit the
  /// platform channel.
  Future<void> noteActivity() => _store.touchLastActivity();

  /// Persists the activity stamp so the idle clock survives process death.
  /// Called when the app leaves the foreground.
  Future<void> persistActivityStamp() => _store.touchLastActivity(persist: true);

  /// True when the time since the last recorded activity exceeds the user's
  /// idle timeout. With no session/activity record it returns false and lets
  /// token expiry rule.
  Future<bool> isIdleTimedOut() async {
    final token = await _store.readToken();
    if (token == null || token.isEmpty) return false;
    final last = await _store.lastActivityAt();
    if (last == null) return false;
    final timeout = Duration(minutes: sessionTimeoutMinutes());
    return DateTime.now().difference(last) > timeout;
  }

  /// Drops the expired session (soft — biometric enrollment survives) so the
  /// router lands on biometric-unlock/login. Used by the idle watcher and the
  /// refresh interceptor when the session can no longer be renewed.
  Future<void> expireSession() => signOut();

  /// Converts a Keycloak `expires_in` value (seconds) into an absolute instant.
  DateTime? _expiryFromExpiresIn(dynamic expiresIn) {
    final seconds =
        expiresIn is int ? expiresIn : int.tryParse('${expiresIn ?? ''}');
    if (seconds == null || seconds <= 0) return null;
    return DateTime.now().add(Duration(seconds: seconds));
  }
}
