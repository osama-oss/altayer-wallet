import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'package:banksync_app/core/config/app_config.dart';
import 'package:banksync_app/core/network/api_client.dart';
import 'package:banksync_app/core/network/api_error_message.dart';
import 'package:banksync_app/core/network/api_exception.dart';
import 'package:banksync_app/core/network/api_logging_interceptor.dart';

/// HTTP client for `/api/merchant/*` (POS tab, merchant Keycloak realm).
class MerchantApiClient {
  MerchantApiClient({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  Dio get dio => _dio;

  static final _validateOptions = Options(
    validateStatus: (status) => status != null && status < 500,
  );

  Future<Map<String, dynamic>> loginKeycloak(String username, String password) async {
    final kc = _merchantKeycloak();
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

  Future<String> resolveLoginUsername(String login) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/merchant/auth/resolve-login',
      data: {'login': login.trim()},
      options: _validateOptions,
    );
    final body = res.data ?? {};
    if (body['success'] != true) {
      throw ApiException(formatApiErrorBody(body));
    }
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final username = data['keycloakUsername']?.toString();
    if (username == null || username.isEmpty) {
      throw const ApiException('Unable to resolve merchant login');
    }
    return username;
  }

  Future<Map<String, dynamic>> userDetail(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/merchant/user/detail',
      options: Options(headers: _bearer(token)),
    );
    return _unwrap(res);
  }

  Future<void> registerDevice(String token, String deviceId) async {
    await _postAuth('/api/merchant/devices/register', token, {'deviceId': deviceId});
  }

  Future<List<dynamic>> catalogServices(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/merchant/catalog/services',
      options: Options(headers: _bearer(token)),
    );
    return _unwrapList(res);
  }

  Future<Map<String, dynamic>> onboardingStatus(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/merchant/onboarding/status',
      options: Options(headers: _bearer(token)),
    );
    return _unwrap(res);
  }

  Future<List<dynamic>> transactions(String token) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/merchant/transactions',
      options: Options(headers: _bearer(token)),
    );
    return _unwrapList(res);
  }

  Future<Map<String, dynamic>> invokeIntegration(
    String token,
    String code, [
    Map<String, dynamic>? body,
  ]) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/merchant/integrations/$code',
      data: body ?? const {},
      options: Options(headers: _bearer(token)),
    );
    return _unwrap(res);
  }

  Future<List<int>> pointQrPng(String token) async {
    final res = await _dio.get<List<int>>(
      '/api/merchant/points/me/qr',
      options: Options(
        headers: _bearer(token),
        responseType: ResponseType.bytes,
      ),
    );
    return res.data ?? const [];
  }

  Map<String, String> _bearer(String token) => {'Authorization': 'Bearer $token'};

  Future<void> _postAuth(String path, String token, Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: Options(headers: _bearer(token), validateStatus: _validateOptions.validateStatus),
    );
    final body = res.data ?? {};
    if (body['success'] != true) {
      throw ApiException(formatApiErrorBody(body));
    }
  }

  Map<String, dynamic> _unwrap(Response<Map<String, dynamic>> res) {
    final body = res.data ?? {};
    if (body['success'] == true) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    }
    throw ApiException(formatApiErrorBody(body));
  }

  List<dynamic> _unwrapList(Response<Map<String, dynamic>> res) {
    final body = res.data ?? {};
    if (body['success'] == true) {
      final data = body['data'];
      if (data is List) return data;
      return const [];
    }
    throw ApiException(formatApiErrorBody(body));
  }

  static KeycloakConfig _merchantKeycloak() {
    final kc = AppConfig.instance.merchantKeycloak;
    if (kc == null) {
      throw const ApiException('Merchant Keycloak is not configured');
    }
    return kc;
  }

  static String _keycloakMessage(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach server. Check network and API URL.';
    }
    return e.message ?? 'Keycloak login failed';
  }

  static Dio _createDio() {
    final config = AppConfig.instance;
    final kc = config.merchantKeycloak ?? config.keycloak;
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );
    if (kc.trustSelfSignedCerts) {
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
}
