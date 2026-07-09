import 'dart:convert';

import 'package:banksync_app/core/storage/secure_store.dart';

/// How the current session was authenticated. Determines the refresh path:
/// password sessions refresh directly against Keycloak, biometric sessions
/// refresh through mobile-service (`/devices/biometric/refresh`).
enum SessionAuthMethod { password, biometric }

/// Persists the authenticated session — JWT **access token**, **refresh
/// token**, access-token **expiry**, username and cached profile — exclusively
/// in the OS secure enclave via [SecureStore].
///
/// PERFORMANCE: every hot value (token, expiry, timeout, activity stamp) is
/// mirrored in memory after the first read. Secure-storage round-trips are
/// platform-channel hops (~tens of ms each on Android EncryptedSharedPreferences),
/// and the refresh interceptor consults these values on *every* API call — so
/// steady-state requests must never touch the platform channel.
///
/// SECURITY: nothing here ever touches SharedPreferences or any world-readable
/// store (OWASP MASVS MSTG-STORAGE-1/2). Tokens are additionally redacted from
/// logs by `ApiLoggingInterceptor`, and the transaction PIN is never persisted.
class SessionStore {
  SessionStore([SecureStore? secure]) : _secure = secure ?? SecureStore();

  final SecureStore _secure;

  // In-memory mirrors (null value + loaded=true means "known absent").
  String? _token;
  bool _tokenLoaded = false;
  String? _refreshToken;
  bool _refreshLoaded = false;
  DateTime? _expiry;
  bool _expiryLoaded = false;
  SessionAuthMethod? _authMethod;
  bool _authMethodLoaded = false;
  DateTime? _lastActivity;
  bool _lastActivityLoaded = false;

  /// Saves the session. [refreshToken] / [accessTokenExpiry] are written only
  /// when supplied, so a profile-only re-save (e.g. after `userDetail`) keeps
  /// the previously stored refresh token and expiry intact.
  ///
  /// The idle-timeout preference travels inside the access token as the
  /// `session_timeout_minutes` claim (Keycloak protocol mapper), so it is
  /// extracted and cached here on every save — no server round-trip needed.
  Future<void> saveSession({
    required String token,
    required String username,
    Map<String, dynamic>? profile,
    String? refreshToken,
    DateTime? accessTokenExpiry,
    SessionAuthMethod? authMethod,
  }) async {
    _token = token;
    _tokenLoaded = true;
    await _secure.write(SecureKeys.accessToken, token);
    await _secure.write(SecureKeys.username, username);
    if (profile != null) {
      await _secure.write(SecureKeys.userProfile, jsonEncode(profile));
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
      _refreshLoaded = true;
      await _secure.write(SecureKeys.refreshToken, refreshToken);
    }
    if (accessTokenExpiry != null) {
      _expiry = accessTokenExpiry;
      _expiryLoaded = true;
      await _secure.write(
        SecureKeys.accessTokenExpiry,
        accessTokenExpiry.millisecondsSinceEpoch.toString(),
      );
    }
    if (authMethod != null) {
      _authMethod = authMethod;
      _authMethodLoaded = true;
      await _secure.write(SecureKeys.authMethod, authMethod.name);
    }
  }

  Future<void> saveProfile(Map<String, dynamic> profile) =>
      _secure.write(SecureKeys.userProfile, jsonEncode(profile));

  Future<String?> readToken() async {
    if (!_tokenLoaded) {
      _token = await _secure.read(SecureKeys.accessToken);
      _tokenLoaded = true;
    }
    return _token;
  }

  Future<String?> readRefreshToken() async {
    if (!_refreshLoaded) {
      _refreshToken = await _secure.read(SecureKeys.refreshToken);
      _refreshLoaded = true;
    }
    return _refreshToken;
  }

  Future<String?> readUsername() => _secure.read(SecureKeys.username);

  Future<Map<String, dynamic>?> readProfile() async {
    final raw = await _secure.read(SecureKeys.userProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> accessTokenExpiry() async {
    if (!_expiryLoaded) {
      final millis =
          int.tryParse(await _secure.read(SecureKeys.accessTokenExpiry) ?? '');
      _expiry =
          millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
      _expiryLoaded = true;
    }
    return _expiry;
  }

  /// True when the access token is at/near expiry. When the expiry is unknown
  /// (e.g. a migrated legacy session) returns false and lets the API surface a
  /// 401, preserving the existing behaviour.
  Future<bool> isAccessTokenExpired({
    Duration skew = const Duration(seconds: 30),
  }) async {
    final expiry = await accessTokenExpiry();
    if (expiry == null) return false;
    return DateTime.now().add(skew).isAfter(expiry);
  }

  Future<SessionAuthMethod?> readAuthMethod() async {
    if (!_authMethodLoaded) {
      final raw = await _secure.read(SecureKeys.authMethod);
      _authMethod = null;
      for (final method in SessionAuthMethod.values) {
        if (method.name == raw) _authMethod = method;
      }
      _authMethodLoaded = true;
    }
    return _authMethod;
  }


  /// Stamps "the user was active now". Memory-only by default — called after
  /// every successful API response, so it must be free. Pass [persist] when
  /// the stamp must survive process death (app going to background).
  Future<void> touchLastActivity({bool persist = false}) async {
    _lastActivity = DateTime.now();
    _lastActivityLoaded = true;
    if (persist) {
      await _secure.write(
        SecureKeys.lastActivityAt,
        _lastActivity!.millisecondsSinceEpoch.toString(),
      );
    }
  }

  Future<DateTime?> lastActivityAt() async {
    if (!_lastActivityLoaded) {
      final millis =
          int.tryParse(await _secure.read(SecureKeys.lastActivityAt) ?? '');
      _lastActivity =
          millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
      _lastActivityLoaded = true;
    }
    return _lastActivity;
  }

  /// Soft sign-out: drops credentials (access + refresh + expiry) but keeps
  /// username/profile so the biometric-unlock screen can still greet the user.
  Future<void> clearSessionTokens() async {
    _token = null;
    _tokenLoaded = true;
    _refreshToken = null;
    _refreshLoaded = true;
    _expiry = null;
    _expiryLoaded = true;
    _authMethod = null;
    _authMethodLoaded = true;
    _lastActivity = null;
    _lastActivityLoaded = true;
    await _secure.delete(SecureKeys.accessToken);
    await _secure.delete(SecureKeys.refreshToken);
    await _secure.delete(SecureKeys.accessTokenExpiry);
    await _secure.delete(SecureKeys.authMethod);
    await _secure.delete(SecureKeys.lastActivityAt);
  }

  /// Hard sign-out: full wipe of the session record.
  Future<void> clear() async {
    await clearSessionTokens();
    await _secure.delete(SecureKeys.username);
    await _secure.delete(SecureKeys.userProfile);
  }
}
