import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs HTTP traffic to the debug console. Enabled only in debug builds.
class ApiLoggingInterceptor extends Interceptor {
  static const _sensitiveKeys = {
    'password',
    'currentpassword',
    'newpassword',
    'confirmpassword',
    'pin',
    'confirmpin',
    'currentpin',
    'newpin',
    'signature',
    'accesstoken',
    'refreshtoken',
    'authorization',
    'x-transaction-pin',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('→ ${options.method} ${_fullUri(options)}');
    _logHeaders('  headers', options.headers);
    if (options.data != null) {
      _log('  body: ${_formatData(options.data)}');
    }
    if (options.queryParameters.isNotEmpty) {
      _log('  query: ${jsonEncode(options.queryParameters)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log(
      '← ${response.statusCode} ${response.requestOptions.method} '
      '${_fullUri(response.requestOptions)}',
    );
    if (response.data != null) {
      _log('  response: ${_formatData(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    _log(
      '✕ ${err.response?.statusCode ?? 'ERR'} ${options.method} '
      '${_fullUri(options)}',
    );
    if (err.message != null) {
      _log('  error: ${err.message}');
    }
    if (err.response?.data != null) {
      _log('  response: ${_formatData(err.response!.data)}');
    }
    handler.next(err);
  }

  String _fullUri(RequestOptions options) {
    if (options.uri.isAbsolute) return options.uri.toString();
    return options.uri.resolve(options.path).toString();
  }

  void _logHeaders(String label, Map<String, dynamic> headers) {
    if (headers.isEmpty) return;
    final sanitized = headers.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, _redact(value?.toString()));
      }
      return MapEntry(key, value);
    });
    _log('$label: ${jsonEncode(sanitized)}');
  }

  /// Large payloads (e.g. a full accounts search) must not be logged whole:
  /// `debugPrint` is rate-throttled by Flutter, so multi-hundred-KB bodies
  /// stall the UI thread for seconds in debug builds.
  static const _maxLoggedChars = 2000;

  String _formatData(dynamic data) {
    if (data is Map || data is List) {
      return _truncate(jsonEncode(_sanitize(data)));
    }
    if (data is FormData) {
      final fields = data.fields
          .map((e) => MapEntry(e.key, _sanitizeValue(e.key, e.value)))
          .toList();
      return _truncate(jsonEncode(Map.fromEntries(fields)));
    }
    return _truncate(data.toString());
  }

  String _truncate(String text) {
    if (text.length <= _maxLoggedChars) return text;
    return '${text.substring(0, _maxLoggedChars)}… (+${text.length - _maxLoggedChars} chars truncated)';
  }

  dynamic _sanitize(dynamic value) {
    if (value is Map) {
      return value.map((key, val) {
        final keyText = key.toString();
        return MapEntry(keyText, _sanitizeValue(keyText, val));
      });
    }
    if (value is List) {
      return value.map(_sanitize).toList();
    }
    return value;
  }

  dynamic _sanitizeValue(String key, dynamic value) {
    if (_isSensitiveKey(key)) return _redact(value?.toString());
    return _sanitize(value);
  }

  bool _isSensitiveKey(String key) => _sensitiveKeys.contains(key.toLowerCase());

  String _redact(String? value) {
    if (value == null || value.isEmpty) return '***';
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}…***';
  }

  void _log(String message) {
    debugPrint('[API] $message');
  }
}

void attachApiLoggingIfDebug(Dio dio) {
  if (kDebugMode) {
    dio.interceptors.add(ApiLoggingInterceptor());
  }
}
