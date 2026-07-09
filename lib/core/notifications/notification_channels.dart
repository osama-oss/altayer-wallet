import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification channel definitions.
///
/// Maps FCM `type` and `severity` to the appropriate system channel so
/// the OS can apply the correct priority, sound, and vibration pattern.
///
/// See: docs/NOTIFICATION_API.md — Android Notification Channels
class NotificationChannels {
  NotificationChannels._();

  // ─── Channel IDs ──────────────────────────────────────────────────────

  static const securityId = 'security';
  static const transactionsId = 'transactions';
  static const billsId = 'bills';
  static const offersId = 'offers';
  static const generalId = 'general';

  // ─── Channel definitions ──────────────────────────────────────────────

  static const securityChannel = AndroidNotificationChannel(
    securityId,
    'Security Alerts',
    description: 'Critical security notifications — login alerts, password changes, suspicious activity.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const transactionsChannel = AndroidNotificationChannel(
    transactionsId,
    'Transactions',
    description: 'Transfer notifications — incoming and outgoing.',
    importance: Importance.high,
    playSound: true,
  );

  static const billsChannel = AndroidNotificationChannel(
    billsId,
    'Bills & Payments',
    description: 'Bill reminders and payment confirmations.',
    importance: Importance.defaultImportance,
  );

  static const offersChannel = AndroidNotificationChannel(
    offersId,
    'Offers & Promotions',
    description: 'Special offers and promotional notifications.',
    importance: Importance.low,
  );

  static const generalChannel = AndroidNotificationChannel(
    generalId,
    'General',
    description: 'General app notifications.',
    importance: Importance.defaultImportance,
  );

  /// All channels to register on Android.
  static const allChannels = [
    securityChannel,
    transactionsChannel,
    billsChannel,
    offersChannel,
    generalChannel,
  ];

  /// Creates all Android notification channels.
  ///
  /// Must be called once during app startup (before first push).
  /// No-op on iOS.
  static Future<void> createAll(FlutterLocalNotificationsPlugin plugin) async {
    if (!Platform.isAndroid) return;
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    for (final channel in allChannels) {
      await android.createNotificationChannel(channel);
    }
  }

  /// Selects the correct channel based on FCM `type` and `severity`.
  ///
  /// Rules (from contract):
  /// - `type == SECURITY` or `severity == CRITICAL` → security channel (MAX)
  /// - `type == TRANSFER` → transactions channel (HIGH)
  /// - `type == BILL` → bills channel (DEFAULT)
  /// - `type == OFFER` → offers channel (LOW)
  /// - everything else → general channel (DEFAULT)
  static String channelForMessage(String? type, String? severity) {
    if (type == 'SECURITY' || severity == 'CRITICAL') return securityId;
    switch (type) {
      case 'TRANSFER':
        return transactionsId;
      case 'BILL':
        return billsId;
      case 'OFFER':
        return offersId;
      default:
        return generalId;
    }
  }
}
