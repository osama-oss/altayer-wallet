import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Canonical keys for every value persisted in the OS secure enclave.
///
/// Centralised so [SessionStore], [DeviceStorage] and the one-time
/// [SecureMigration] can never drift out of sync on key names.
abstract class SecureKeys {
  // Session / credentials
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const accessTokenExpiry = 'access_token_expiry'; // epoch millis (String)
  static const username = 'username';
  static const userProfile = 'user_profile'; // JSON
  // Name + gender captured at sign-up, kept separate from [userProfile] so a
  // backend profile refresh (which replaces userProfile) never wipes it. Read
  // back read-only in the KYC form. JSON.
  static const registrationIdentity = 'registration_identity';
  static const authMethod = 'auth_method'; // 'password' | 'biometric'
  static const sessionTimeoutMinutes = 'session_timeout_minutes'; // int (String)
  static const lastActivityAt = 'last_activity_at'; // epoch millis (String)

  // Device identity & biometric preferences
  static const deviceId = 'device_id';
  static const biometricEnabled = 'biometric_login_enabled';
  static const preferPasswordLogin = 'prefer_password_login';

  // Internal
  static const migratedFlag = 'secure_migrated_v1';
}

/// Thin, hardened wrapper over [FlutterSecureStorage].
///
/// SECURITY (OWASP MASVS MSTG-STORAGE-1/2): all values live in the platform
/// secure enclave — never in SharedPreferences / NSUserDefaults / plaintext.
///   • Android → `EncryptedSharedPreferences` (AES-256-GCM); the master key is
///     held in the Android Keystore (hardware/StrongBox-backed when available).
///   • iOS     → Keychain, accessible only after first unlock, scoped to this
///     device and excluded from iCloud Keychain sync.
///
/// Reads are *fail-safe*: if a value can no longer be decrypted (e.g. the
/// backing key was invalidated by an OS/biometric change) we drop it and return
/// null rather than throwing — the caller then treats the user as logged-out.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage]) : _storage = storage ?? _default();

  final FlutterSecureStorage _storage;

  static FlutterSecureStorage _default() => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // Undecryptable / corrupted entry → drop it and behave as "no value".
      await delete(key);
      return null;
    }
  }

  /// Writes [value], or deletes the key when [value] is null/empty.
  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await delete(key);
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Best-effort: deletion failures must never propagate to the UI.
    }
  }

  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (_) {
      return false;
    }
  }
}
