import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/config/app_config.dart';

enum SupportSseEventType { caseUpdated, messageNew, messagesRead, unknown }

class SupportSseEvent {
  const SupportSseEvent({
    required this.type,
    this.data,
  });

  final SupportSseEventType type;
  final Map<String, dynamic>? data;
}

class SupportEventSubscription {
  SupportEventSubscription._(this._close);

  final void Function() _close;

  void close() => _close();
}

/// Parses SSE frames from a byte/text stream, keeping partial lines across chunks.
class _SseFrameParser {
  String _pendingLine = '';
  String _eventName = '';
  final StringBuffer _data = StringBuffer();

  List<SupportSseEvent> feed(String chunk) {
    final events = <SupportSseEvent>[];
    _pendingLine += chunk;

    while (true) {
      final newlineAt = _pendingLine.indexOf('\n');
      if (newlineAt < 0) break;

      var line = _pendingLine.substring(0, newlineAt);
      _pendingLine = _pendingLine.substring(newlineAt + 1);
      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }

      if (line.isEmpty) {
        final event = _flushEvent();
        if (event != null) events.add(event);
        continue;
      }
      if (line.startsWith(':')) {
        continue;
      }
      if (line.startsWith('event:')) {
        _eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        if (_data.isNotEmpty) _data.write('\n');
        _data.write(line.substring(5).trim());
      }
    }

    return events;
  }

  SupportSseEvent? _flushEvent() {
    if (_data.isEmpty) {
      _eventName = '';
      return null;
    }
    final event = _parseEvent(_eventName, _data.toString());
    _eventName = '';
    _data.clear();
    return event;
  }

  SupportSseEvent _parseEvent(String eventName, String data) {
    Map<String, dynamic>? parsed;
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        parsed = decoded;
      } else if (decoded is Map) {
        parsed = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    switch (eventName) {
      case 'case.updated':
        return SupportSseEvent(type: SupportSseEventType.caseUpdated, data: parsed);
      case 'message.new':
        return SupportSseEvent(type: SupportSseEventType.messageNew, data: parsed);
      case 'messages.read':
        return SupportSseEvent(type: SupportSseEventType.messagesRead, data: parsed);
      default:
        return SupportSseEvent(type: SupportSseEventType.unknown, data: parsed);
    }
  }
}

class SupportEventService {
  SupportEventSubscription subscribeAuthenticated({
    required String token,
    required int caseId,
    required void Function(SupportSseEvent event) onEvent,
    void Function(Object error)? onError,
    String currentLanguage = 'en',
  }) {
    final url = Uri.parse(
      '${AppConfig.instance.apiBaseUrl}/api/mobile/support/cases/$caseId/events',
    );
    return _subscribe(
      url: url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Current-Language': currentLanguage,
      },
      onEvent: onEvent,
      onError: onError,
    );
  }

  SupportEventSubscription subscribeGuest({
    required String caseNumber,
    required String mobile,
    required void Function(SupportSseEvent event) onEvent,
    void Function(Object error)? onError,
    String currentLanguage = 'en',
  }) {
    final url = Uri.parse(
      '${AppConfig.instance.apiBaseUrl}/api/mobile/support/guest/cases/$caseNumber/events',
    ).replace(queryParameters: {'mobile': mobile});
    return _subscribe(
      url: url,
      headers: {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Current-Language': currentLanguage,
      },
      onEvent: onEvent,
      onError: onError,
    );
  }

  SupportEventSubscription _subscribe({
    required Uri url,
    required Map<String, String> headers,
    required void Function(SupportSseEvent event) onEvent,
    void Function(Object error)? onError,
  }) {
    final client = _createHttpClient();
    var closed = false;

    Future<void> run() async {
      while (!closed) {
        try {
          final request = await client.getUrl(url);
          headers.forEach(request.headers.set);
          final response = await request.close();
          if (response.statusCode != 200) {
            throw HttpException('SSE failed: ${response.statusCode}', uri: url);
          }

          final parser = _SseFrameParser();
          await for (final chunk in response.transform(utf8.decoder)) {
            if (closed) break;
            for (final event in parser.feed(chunk)) {
              if (event.type != SupportSseEventType.unknown || event.data != null) {
                onEvent(event);
              }
            }
          }
        } catch (e) {
          if (closed) break;
          onError?.call(e);
          await Future<void>.delayed(const Duration(seconds: 5));
        }
      }
      client.close(force: true);
    }

    unawaited(run());

    return SupportEventSubscription._(() {
      closed = true;
      client.close(force: true);
    });
  }

  HttpClient _createHttpClient() {
    final client = HttpClient();
    client.autoUncompress = false;
    if (AppConfig.instance.keycloak.trustSelfSignedCerts) {
      client.badCertificateCallback = (_, __, ___) => true;
    }
    return client;
  }
}
