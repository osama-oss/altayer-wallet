import 'package:banksync_app/core/auth/device_storage.dart';
import 'package:banksync_app/core/storage/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSecureStore extends SecureStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);
}

void main() {
  late _FakeSecureStore secure;

  setUp(() => secure = _FakeSecureStore());

  test('fresh install uses the stable (Android) id and caches it', () async {
    final store = DeviceStorage(
      secure: secure,
      stableIdResolver: () async => 'android-id-abc',
    );
    final id = await store.getOrCreateDeviceId();
    expect(id, 'android-id-abc');
    // Cached for next time.
    expect(await secure.read(SecureKeys.deviceId), 'android-id-abc');
  });

  test('falls back to a UUID when no stable id is available', () async {
    final store = DeviceStorage(
      secure: secure,
      stableIdResolver: () async => null,
    );
    final id = await store.getOrCreateDeviceId();
    expect(id, isNotEmpty);
    expect(id, await secure.read(SecureKeys.deviceId));
  });

  test('reuses an existing stored id and ignores the resolver', () async {
    await secure.write(SecureKeys.deviceId, 'legacy-uuid-123');
    var resolverCalled = false;
    final store = DeviceStorage(
      secure: secure,
      stableIdResolver: () async {
        resolverCalled = true;
        return 'android-id-abc';
      },
    );
    final id = await store.getOrCreateDeviceId();
    expect(id, 'legacy-uuid-123'); // existing binding preserved
    expect(resolverCalled, isFalse);
  });

  test('id is stable across repeated calls', () async {
    final store = DeviceStorage(
      secure: secure,
      stableIdResolver: () async => null,
    );
    final first = await store.getOrCreateDeviceId();
    final second = await store.getOrCreateDeviceId();
    expect(first, second);
  });

  test('clearDeviceId drops the cached id so the next call re-resolves', () async {
    await secure.write(SecureKeys.deviceId, 'legacy-uuid-123');
    final store = DeviceStorage(
      secure: secure,
      stableIdResolver: () async => 'android-id-abc',
    );
    await store.clearDeviceId();
    final id = await store.getOrCreateDeviceId();
    expect(id, 'android-id-abc');
  });

  test('biometric + password-preference flags round-trip', () async {
    final store = DeviceStorage(secure: secure, stableIdResolver: () async => null);
    expect(await store.isBiometricLoginEnabled(), isFalse);
    await store.setBiometricLoginEnabled(true);
    expect(await store.isBiometricLoginEnabled(), isTrue);
    await store.setBiometricLoginEnabled(false);
    expect(await store.isBiometricLoginEnabled(), isFalse);

    await store.setPreferPasswordLogin(true);
    expect(await store.prefersPasswordLogin(), isTrue);
    await store.setPreferPasswordLogin(false);
    expect(await store.prefersPasswordLogin(), isFalse);
  });
}
