import 'package:banksync_app/core/auth/platform_device_id.dart';
import 'package:banksync_app/core/storage/secure_store.dart';
import 'package:uuid/uuid.dart';

/// Resolver for an OS-stable device id (see [PlatformDeviceId]). Injectable so
/// [DeviceStorage] stays unit-testable without the platform channel.
typedef StableDeviceIdResolver = Future<String?> Function();

/// Device-scoped identity and biometric preference flags, stored in the secure
/// enclave (the `device_id` participates in server-side device binding).
class DeviceStorage {
  DeviceStorage({SecureStore? secure, StableDeviceIdResolver? stableIdResolver})
      : _secure = secure ?? SecureStore(),
        _resolveStableId = stableIdResolver ?? const PlatformDeviceId().stableId;

  final SecureStore _secure;
  final StableDeviceIdResolver _resolveStableId;

  /// Returns the device id used for server-side device binding.
  ///
  /// Resolution order (see also the design notes on the stable id):
  ///  1. **Reuse** any already-stored id — we never silently re-bind an
  ///     existing install to a different id (that would trip
  ///     `DEVICE_ALREADY_BOUND`).
  ///  2. On a fresh install / right after "clear data", prefer the OS-stable id
  ///     (Android `ANDROID_ID`) so the binding **survives future data/cache
  ///     wipes**.
  ///  3. Fall back to a random UUID when no stable id is available (iOS — where
  ///     the value persists in the Keychain regardless — or a null/bogus SSAID).
  Future<String> getOrCreateDeviceId() async {
    final cached = await _secure.read(SecureKeys.deviceId);
    if (cached != null && cached.isNotEmpty) return cached;

    final stable = await _resolveStableId();
    final id =
        (stable != null && stable.isNotEmpty) ? stable : const Uuid().v4();
    await _secure.write(SecureKeys.deviceId, id);
    return id;
  }

  /// Drops the locally cached device id so the next [getOrCreateDeviceId] can
  /// re-resolve (e.g. after a full sign-out or a server-side rebind).
  Future<void> clearDeviceId() => _secure.delete(SecureKeys.deviceId);

  Future<bool> isBiometricLoginEnabled() async =>
      (await _secure.read(SecureKeys.biometricEnabled)) == 'true';

  Future<void> setBiometricLoginEnabled(bool enabled) => enabled
      ? _secure.write(SecureKeys.biometricEnabled, 'true')
      : _secure.delete(SecureKeys.biometricEnabled);

  Future<void> clearBiometricLoginEnabled() =>
      _secure.delete(SecureKeys.biometricEnabled);

  /// User chose password on the biometric-unlock screen; skip auto-redirect to
  /// the biometric screen next time.
  Future<bool> prefersPasswordLogin() async =>
      (await _secure.read(SecureKeys.preferPasswordLogin)) == 'true';

  Future<void> setPreferPasswordLogin(bool value) => value
      ? _secure.write(SecureKeys.preferPasswordLogin, 'true')
      : _secure.delete(SecureKeys.preferPasswordLogin);
}
