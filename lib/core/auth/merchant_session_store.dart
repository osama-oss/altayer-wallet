import 'dart:convert';

import 'package:banksync_app/core/storage/secure_store.dart';

/// Persists the merchant POS session separately from the customer tab session.
class MerchantSessionStore {
  MerchantSessionStore([SecureStore? secure]) : _secure = secure ?? SecureStore();

  final SecureStore _secure;

  String? _token;
  bool _tokenLoaded = false;
  Map<String, dynamic>? _profile;
  bool _profileLoaded = false;

  Future<void> saveSession({
    required String token,
    required String username,
    Map<String, dynamic>? profile,
    String? refreshToken,
    DateTime? accessTokenExpiry,
  }) async {
    _token = token;
    _tokenLoaded = true;
    await _secure.write(SecureKeys.merchantAccessToken, token);
    await _secure.write(SecureKeys.merchantUsername, username);
    if (profile != null) {
      _profile = profile;
      _profileLoaded = true;
      await _secure.write(SecureKeys.merchantUserProfile, jsonEncode(profile));
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secure.write(SecureKeys.merchantRefreshToken, refreshToken);
    }
    if (accessTokenExpiry != null) {
      await _secure.write(
        SecureKeys.merchantAccessTokenExpiry,
        accessTokenExpiry.millisecondsSinceEpoch.toString(),
      );
    }
  }

  Future<String?> readToken() async {
    if (_tokenLoaded) return _token;
    _token = await _secure.read(SecureKeys.merchantAccessToken);
    _tokenLoaded = true;
    return _token;
  }

  Future<Map<String, dynamic>> readProfile() async {
    if (_profileLoaded && _profile != null) return _profile!;
    final raw = await _secure.read(SecureKeys.merchantUserProfile);
    if (raw == null || raw.isEmpty) {
      _profile = const {};
      _profileLoaded = true;
      return _profile!;
    }
    _profile = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    _profileLoaded = true;
    return _profile!;
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    _profile = profile;
    _profileLoaded = true;
    await _secure.write(SecureKeys.merchantUserProfile, jsonEncode(profile));
  }

  Future<void> clear() async {
    _token = null;
    _tokenLoaded = true;
    _profile = null;
    _profileLoaded = true;
    await _secure.delete(SecureKeys.merchantAccessToken);
    await _secure.delete(SecureKeys.merchantRefreshToken);
    await _secure.delete(SecureKeys.merchantAccessTokenExpiry);
    await _secure.delete(SecureKeys.merchantUsername);
    await _secure.delete(SecureKeys.merchantUserProfile);
  }
}
