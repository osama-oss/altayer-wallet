import 'package:banksync_app/core/auth/device_storage.dart';
import 'package:banksync_app/core/auth/merchant_session_store.dart';
import 'package:banksync_app/core/network/api_exception.dart';
import 'package:banksync_app/core/network/merchant_api_client.dart';

enum MerchantPosRole { owner, supervisor, cashier, unknown }

class MerchantLoginResult {
  const MerchantLoginResult({required this.role, this.simulationMode = false});

  final MerchantPosRole role;
  final bool simulationMode;
}

class MerchantAuthService {
  MerchantAuthService({
    MerchantApiClient? api,
    MerchantSessionStore? store,
    DeviceStorage? devices,
  })  : _api = api ?? MerchantApiClient(),
        _store = store ?? MerchantSessionStore(),
        _devices = devices ?? DeviceStorage();

  final MerchantApiClient _api;
  final MerchantSessionStore _store;
  final DeviceStorage _devices;

  Future<String?> readToken() => _store.readToken();

  Future<Map<String, dynamic>> readProfile() => _store.readProfile();

  Future<void> signOut() => _store.clear();

  Future<Map<String, dynamic>> refreshProfile() async {
    final token = await readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Not signed in');
    }
    final detail = await _api.userDetail(token);
    await _store.updateProfile(detail);
    return detail;
  }

  /// Merchant owner self-register (phone-first, merchant Keycloak realm).
  Future<Map<String, dynamic>> registerMerchantIdentity({
    required String mobile,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final data = await _api.registerIdentity(
      mobile: mobile,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    final username = data['username']?.toString().trim();
    if (username == null || username.isEmpty) {
      throw const KeycloakAuthException('Registration did not return a username');
    }
    return {
      ...data,
      'keycloakUsername': username,
    };
  }

  Future<MerchantLoginResult> completeInitialPasswordAndLogin({
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

  Future<MerchantLoginResult> loginWithPassword(String username, String password) async {
    final trimmedUser = username.trim();
    final keycloakUsername = await _api.resolveLoginUsername(trimmedUser);
    final tokens = await _api.loginKeycloak(keycloakUsername, password);
    final access = tokens['access_token'] as String?;
    if (access == null || access.isEmpty) {
      throw const KeycloakAuthException('No access token from Keycloak');
    }

    Map<String, dynamic> detail = const {};
    try {
      detail = await _api.userDetail(access);
    } catch (_) {}

    try {
      final deviceId = await _devices.getOrCreateDeviceId();
      await _api.registerDevice(access, deviceId);
    } catch (_) {}

    await _store.saveSession(
      token: access,
      username: trimmedUser,
      profile: detail,
      refreshToken: tokens['refresh_token'] as String?,
      accessTokenExpiry: _expiryFromExpiresIn(tokens['expires_in']),
    );

    return MerchantLoginResult(
      role: resolveRole(detail),
      simulationMode: detail['simulationMode'] == true,
    );
  }

  static MerchantPosRole resolveRole(Map<String, dynamic> detail) {
    final roles = detail['roles'];
    if (roles is List) {
      final set = roles.map((e) => e.toString().toUpperCase()).toSet();
      if (set.contains('MERCHANT_OWNER') || set.contains('MERCHANT_ADMIN')) {
        return MerchantPosRole.owner;
      }
      if (set.contains('MERCHANT_SUPERVISOR')) return MerchantPosRole.supervisor;
      if (set.contains('MERCHANT_CASHIER')) return MerchantPosRole.cashier;
    }
    final userRole = detail['userRole']?.toString().toUpperCase() ?? '';
    if (userRole == 'OWNER' || detail['admin'] == true) return MerchantPosRole.owner;
    if (userRole == 'SUPERVISOR') return MerchantPosRole.supervisor;
    if (userRole == 'CASHIER') return MerchantPosRole.cashier;
    return MerchantPosRole.unknown;
  }

  static DateTime? _expiryFromExpiresIn(Object? expiresIn) {
    if (expiresIn is int && expiresIn > 0) {
      return DateTime.now().add(Duration(seconds: expiresIn));
    }
    if (expiresIn is String) {
      final parsed = int.tryParse(expiresIn);
      if (parsed != null && parsed > 0) {
        return DateTime.now().add(Duration(seconds: parsed));
      }
    }
    return null;
  }
}
