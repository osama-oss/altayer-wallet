import 'package:shared_preferences/shared_preferences.dart';

import 'secure_store.dart';

/// One-time migration of any pre-existing session/device data from the legacy
/// **plaintext** SharedPreferences store into the [SecureStore] (Keystore /
/// Keychain).
///
/// Guarantees:
///  • Runs at most once — guarded by [SecureKeys.migratedFlag].
///  • **Idempotent & fail-safe** — wrapped in try/catch so a failure can never
///    block app startup; worst case the user simply re-authenticates.
///  • Preserves `device_id` exactly (moving, not regenerating) so server-side
///    device binding is not broken by the upgrade.
///
/// Must be invoked from `main()` *before* the router reads the access token.
class SecureMigration {
  SecureMigration({SecureStore? secure, SharedPreferences? prefs})
      : _secure = secure ?? SecureStore(),
        _prefsOverride = prefs;

  final SecureStore _secure;
  final SharedPreferences? _prefsOverride;

  static const _legacyStringKeys = <String>[
    SecureKeys.accessToken,
    SecureKeys.username,
    SecureKeys.userProfile,
    SecureKeys.deviceId,
  ];

  static const _legacyBoolKeys = <String>[
    SecureKeys.biometricEnabled,
    SecureKeys.preferPasswordLogin,
  ];

  Future<void> migrateIfNeeded() async {
    try {
      if (await _secure.containsKey(SecureKeys.migratedFlag)) return;

      final prefs = _prefsOverride ?? await SharedPreferences.getInstance();

      for (final key in _legacyStringKeys) {
        final value = prefs.getString(key);
        if (value != null && value.isNotEmpty) {
          await _secure.write(key, value);
        }
        await prefs.remove(key);
      }

      for (final key in _legacyBoolKeys) {
        if (prefs.containsKey(key)) {
          // Only the "true" state is meaningful; false == absent.
          if (prefs.getBool(key) == true) {
            await _secure.write(key, 'true');
          }
          await prefs.remove(key);
        }
      }

      await _secure.write(SecureKeys.migratedFlag, '1');
    } catch (_) {
      // Migration is best-effort: never crash startup over it.
    }
  }
}
