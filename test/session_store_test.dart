import 'package:banksync_app/core/auth/session_store.dart';
import 'package:banksync_app/core/storage/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [SecureStore] double — overrides the I/O methods so tests run
/// without the platform Keystore/Keychain channel.
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
  late SessionStore store;

  setUp(() {
    secure = _FakeSecureStore();
    store = SessionStore(secure);
  });

  test('persists and reads access + refresh token, username and profile', () async {
    final expiry = DateTime.now().add(const Duration(minutes: 5));
    await store.saveSession(
      token: 'access-1',
      username: 'cust-1',
      profile: {'pinStatus': 'SET'},
      refreshToken: 'refresh-1',
      accessTokenExpiry: expiry,
    );

    expect(await store.readToken(), 'access-1');
    expect(await store.readRefreshToken(), 'refresh-1');
    expect(await store.readUsername(), 'cust-1');
    expect((await store.readProfile())?['pinStatus'], 'SET');
    expect(await store.isAccessTokenExpired(), isFalse);
  });

  test('profile-only re-save preserves the refresh token', () async {
    await store.saveSession(token: 'a1', username: 'u', refreshToken: 'r1');
    await store.saveSession(token: 'a2', username: 'u'); // no refresh supplied
    expect(await store.readToken(), 'a2');
    expect(await store.readRefreshToken(), 'r1');
  });

  test('detects an expired access token (with skew)', () async {
    await store.saveSession(
      token: 'a',
      username: 'u',
      accessTokenExpiry: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    expect(await store.isAccessTokenExpired(), isTrue);
  });

  test('unknown expiry is treated as not-expired (legacy session)', () async {
    await store.saveSession(token: 'a', username: 'u');
    expect(await store.isAccessTokenExpired(), isFalse);
  });

  test('clearSessionTokens drops credentials but keeps username/profile', () async {
    await store.saveSession(
      token: 'a',
      username: 'u',
      profile: {'id': 1},
      refreshToken: 'r',
    );
    await store.clearSessionTokens();
    expect(await store.readToken(), isNull);
    expect(await store.readRefreshToken(), isNull);
    expect(await store.readUsername(), 'u');
    expect(await store.readProfile(), isNotNull);
  });

  test('clear wipes the full session record', () async {
    await store.saveSession(token: 'a', username: 'u', profile: {'id': 1});
    await store.clear();
    expect(await store.readToken(), isNull);
    expect(await store.readUsername(), isNull);
    expect(await store.readProfile(), isNull);
  });
}
