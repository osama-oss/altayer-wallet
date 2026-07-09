/// Deep-link routing from notification `type` + `payload` to GoRouter paths.
///
/// Central mapping keeps the "zero Flutter code changes per new type" goal —
/// add a new entry here and the handler routes automatically.
///
/// See: docs/NOTIFICATION_FRONTEND_PLAN_ADJUSTMENTS.md § 3
class NotificationRouter {
  NotificationRouter._();

  /// Maps a notification `type` to its GoRouter path template.
  ///
  /// Path segments starting with `:` are resolved from the `payload` map.
  /// Unknown types route to the notifications inbox as a fallback.
  static const _routes = <String, String>{
    'TRANSFER': '/home', // TODO: route to /transactions/:reference once screen exists
    'SECURITY': '/home', // TODO: route to /security-alerts once screen exists
    'BILL': '/home',     // Phase 2
    'OFFER': '/home',    // Phase 2
    'GENERAL': '/home',
  };

  /// Resolves the GoRouter path for the given notification type and payload.
  ///
  /// Falls back to `/home` for unknown types.
  static String resolve(String? type, Map<String, dynamic>? payload) {
    final template = _routes[type] ?? '/home';

    // If template has no dynamic segments, return as-is.
    if (!template.contains(':')) return template;

    // Replace :param segments with values from payload.
    var path = template;
    final params = payload ?? {};
    for (final entry in params.entries) {
      path = path.replaceAll(':${entry.key}', entry.value.toString());
    }

    // If any unresolved :param remains, fall back to notifications inbox.
    if (path.contains(':')) return '/home';

    return path;
  }
}
