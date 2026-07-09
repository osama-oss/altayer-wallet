import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:banksync_app/core/notifications/notification_channels.dart';
import 'package:banksync_app/core/notifications/notification_service.dart';

/// Top-level background message handler.
///
/// Must be a top-level function (not a class method) for Firebase.
/// Registered in main.dart via:
///   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM-BG] Received: ${message.data}');
  // Data-only messages in background are handled by the OS tray.
  // No additional processing needed for Phase 1.
}

/// Handles foreground display, tap routing, and cold-start deep links.
class NotificationHandler {
  NotificationHandler._();

  /// Setup foreground message listener and tap handlers.
  ///
  /// Call once after the app's router is ready (e.g. in the root widget).
  static void initialize({
    required void Function(String path) onNavigate,
  }) {
    // Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Background/terminated tap → navigate
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final path = _resolveRoute(message.data);
      onNavigate(path);
    });

    // Cold start — check if app was opened from a terminated notification
    _handleInitialMessage(onNavigate);
  }

  /// Check for a notification that launched the app from a killed state.
  static Future<void> _handleInitialMessage(
    void Function(String path) onNavigate,
  ) async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final path = _resolveRoute(initial.data);
      onNavigate(path);
    }
  }

  /// Displays a local notification when a data-only FCM message arrives
  /// while the app is in the foreground.
  ///
  /// Uses **generic** title/body from the FCM notification block (safe for
  /// lock screen). Full details are only shown in the in-app inbox.
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Use the FCM notification block if available (generic text from backend),
    // otherwise build a minimal fallback.
    final title = notification?.title ?? _fallbackTitle(data['type']);
    final body = notification?.body ?? 'Tap to view details.';

    final type = data['type'] as String?;
    final severity = data['severity'] as String?;
    final channelId = NotificationChannels.channelForMessage(type, severity);

    // Find the channel definition for importance/priority mapping.
    final channel = NotificationChannels.allChannels.firstWhere(
      (c) => c.id == channelId,
      orElse: () => NotificationChannels.generalChannel,
    );

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: _importanceToPriority(channel.importance),
      groupKey: data['threadId'] as String?,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use notificationId from data if available, otherwise hash.
    final id = int.tryParse(data['notificationId'] ?? '') ??
        message.messageId.hashCode;

    await NotificationService.localPlugin.show(id, title, body, details);
  }

  /// Maps notification type to a generic fallback title.
  static String _fallbackTitle(String? type) {
    switch (type) {
      case 'TRANSFER':
        return 'Transaction Update';
      case 'SECURITY':
        return 'Security Alert';
      case 'BILL':
        return 'Bill Reminder';
      case 'OFFER':
        return 'New Offer';
      default:
        return 'Notification';
    }
  }

  /// Resolves the GoRouter path from FCM data payload.
  ///
  /// Uses the notification_router for type-based routing.
  /// For Phase 1, all routes go to /home since detail screens aren't built yet.
  static String _resolveRoute(Map<String, dynamic> data) {
    // Phase 1: simple routing to home. When detail screens exist, use:
    // return NotificationRouter.resolve(data['type'], data);
    return '/home';
  }

  /// Converts Flutter Local Notifications Importance to Priority.
  static Priority _importanceToPriority(Importance importance) {
    switch (importance) {
      case Importance.max:
        return Priority.max;
      case Importance.high:
        return Priority.high;
      case Importance.low:
        return Priority.low;
      case Importance.min:
        return Priority.min;
      default:
        return Priority.defaultPriority;
    }
  }
}
