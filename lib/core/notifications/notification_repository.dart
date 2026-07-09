import 'package:banksync_app/core/network/api_client.dart';
import 'package:banksync_app/core/notifications/notification_model.dart';

/// Repository for all notification REST API calls.
///
/// Uses [ApiClient] for HTTP. Endpoints are aligned with the shared contract
/// in docs/NOTIFICATION_API.md.
class NotificationRepository {
  NotificationRepository({
    required ApiClient api,
    required Future<String?> Function() tokenReader,
    required Future<String> Function() deviceIdReader,
  })  : _api = api,
        _readToken = tokenReader,
        _readDeviceId = deviceIdReader;

  final ApiClient _api;
  final Future<String?> Function() _readToken;
  final Future<String> Function() _readDeviceId;

  // ─── Push token lifecycle ─────────────────────────────────────────────

  /// PUT /api/mobile/devices/{deviceId}/push-token
  Future<void> registerPushToken({
    required String fcmToken,
    required String platform,
    required String appVersion,
    required String locale,
  }) async {
    final token = await _readToken();
    if (token == null) return;
    final deviceId = await _readDeviceId();
    await _api.registerFcmToken(
      token,
      deviceId: deviceId,
      fcmToken: fcmToken,
      platform: platform,
      appVersion: appVersion,
      locale: locale,
    );
  }

  /// DELETE /api/mobile/devices/{deviceId}/push-token
  Future<void> removePushToken() async {
    final token = await _readToken();
    if (token == null) return;
    final deviceId = await _readDeviceId();
    await _api.removeFcmToken(token, deviceId: deviceId);
  }

  // ─── Notification inbox ───────────────────────────────────────────────

  /// GET /api/mobile/notifications?page=&size=&type=
  Future<NotificationPage> getNotifications({
    int page = 0,
    int size = 20,
    String? type,
  }) async {
    final token = await _readToken();
    if (token == null) return const NotificationPage(content: [], page: 0, size: 20, totalElements: 0, totalPages: 0);
    final data = await _api.getNotifications(
      token,
      page: page,
      size: size,
      type: type,
    );
    return NotificationPage.fromJson(data);
  }

  /// GET /api/mobile/notifications/unread-count
  Future<int> getUnreadCount() async {
    final token = await _readToken();
    if (token == null) return 0;
    final data = await _api.getUnreadCount(token);
    return data['count'] as int? ?? 0;
  }

  /// POST /api/mobile/notifications/{id}/read
  Future<void> markRead(int notificationId) async {
    final token = await _readToken();
    if (token == null) return;
    await _api.markNotificationRead(token, notificationId);
  }

  /// POST /api/mobile/notifications/read-all
  Future<void> markAllRead({String? type}) async {
    final token = await _readToken();
    if (token == null) return;
    await _api.markAllNotificationsRead(token, type: type);
  }

  // ─── Preferences ──────────────────────────────────────────────────────

  /// GET /api/mobile/notification-preferences
  Future<NotificationPreferences> getPreferences() async {
    final token = await _readToken();
    if (token == null) return const NotificationPreferences();
    final data = await _api.getNotificationPreferences(token);
    return NotificationPreferences.fromJson(data);
  }

  /// PUT /api/mobile/notification-preferences
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    final token = await _readToken();
    if (token == null) return;
    await _api.updateNotificationPreferences(token, prefs.toJson());
  }
}
