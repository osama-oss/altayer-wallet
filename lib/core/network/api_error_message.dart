import 'package:dio/dio.dart';

import 'api_exception.dart';

/// True for transport-level failures (timeouts, refused connections, DNS…):
/// the server never produced a response, so the user should see a friendly
/// "check your connection" message instead of the raw DioException text.
bool isNetworkError(Object error) {
  if (error is! DioException) return false;
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    default:
      return error.response == null && error.type != DioExceptionType.cancel;
  }
}

/// Normalizes API failures whether the backend returns a plain [message]
/// or a field-level [errors] / [message] array.
String formatThrowableMessage(Object error) {
  if (error is ApiException) return error.message;
  return formatApiErrorMessage(error);
}

String formatApiErrorMessage(dynamic value) {
  if (value == null) return 'Request failed';
  if (value is ApiException) return value.message;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Request failed' : trimmed;
  }
  if (value is Map) {
    return formatApiErrorBody(Map<String, dynamic>.from(value));
  }
  if (value is List) {
    final lines = _formatFieldErrorList(value);
    if (lines.isNotEmpty) return lines.join('\n');
    return value
        .map(formatApiErrorMessage)
        .where((line) => line.isNotEmpty && line != 'Request failed')
        .join('\n');
  }
  return value.toString();
}

String formatApiErrorBody(Map<String, dynamic> body) {
  final fieldLines = <String>[];
  final summaries = <String>[];

  for (final map in _errorSourceMaps(body)) {
    fieldLines.addAll(_collectFieldErrors(map['errors']));
    fieldLines.addAll(_collectFieldErrors(map['validationErrors']));
    fieldLines.addAll(_collectFieldErrors(map['fieldErrors']));

    final message = map['message'];
    if (message is List || message is Map) {
      fieldLines.addAll(_collectFieldErrors(message));
    } else {
      final text = _stringOrNull(message);
      if (text != null) summaries.add(text);
    }

    for (final key in ['error', 'errorMessage', 'description', 'detail']) {
      final text = _stringOrNull(map[key]);
      if (text != null) summaries.add(text);
    }
  }

  if (fieldLines.isNotEmpty) {
    return fieldLines.join('\n');
  }
  for (final summary in summaries) {
    if (summary.isNotEmpty) return summary;
  }
  return 'Request failed';
}

List<Map<String, dynamic>> _errorSourceMaps(Map<String, dynamic> body) {
  final maps = <Map<String, dynamic>>[body];
  final data = body['data'];
  if (data is Map<String, dynamic>) {
    maps.add(data);
  } else if (data is Map) {
    maps.add(Map<String, dynamic>.from(data));
  }
  return maps;
}

List<String> _collectFieldErrors(dynamic value) {
  if (value is List) return _formatFieldErrorList(value);
  if (value is Map) {
    final line = _formatFieldErrorItem(Map<String, dynamic>.from(value));
    return line == null ? const [] : [line];
  }
  return const [];
}

List<String> _formatFieldErrorList(List list) {
  final parts = <String>[];
  for (final item in list) {
    if (item is Map) {
      final line = _formatFieldErrorItem(Map<String, dynamic>.from(item));
      if (line != null) parts.add(line);
    } else {
      final text = item?.toString().trim();
      if (text != null && text.isNotEmpty) parts.add(text);
    }
  }
  return parts;
}

String? _formatFieldErrorItem(Map<String, dynamic> item) {
  final field = _stringOrNull(item['field']) ??
      _stringOrNull(item['fieldName']) ??
      _stringOrNull(item['property']);
  final message = _stringOrNull(item['message']) ??
      _stringOrNull(item['error']) ??
      _stringOrNull(item['defaultMessage']);
  if (message == null) return null;
  if (field != null) return '${_humanizeField(field)}: $message';
  return message;
}

String? _stringOrNull(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _humanizeField(String field) {
  return field
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}
