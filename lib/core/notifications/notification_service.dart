import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:banksync_app/core/notifications/notification_channels.dart';
import 'package:banksync_app/core/notifications/notification_repository.dart';

/// Manages FCM token lifecycle, permission requests, and local notification init.
///
/// Token registration follows the permission-gating rule:
/// FCM token is only sent to the backend when ALL three conditions are true:
/// 1. User is authenticated (valid JWT)
/// 2. Device is registered via POST /devices/register
/// 3. Notification permission is granted
///
/// See: docs/NOTIFICATION_FRONTEND_PLAN_ADJUSTMENTS.md § 3
class NotificationService {
  NotificationService({
    required NotificationRepository repository,
    FirebaseMessaging? messaging,
  })  : _repository = repository,
        _injectedMessaging = messaging;

  final NotificationRepository _repository;
  final FirebaseMessaging? _injectedMessaging;

  /// FCM handle, or `null` when Firebase is not configured/initialised. Reading
  /// `FirebaseMessaging.instance` before `Firebase.initializeApp` throws, so we
  /// gate on `Firebase.apps` and let every method fail-open. Wire a real
  /// Firebase project (`flutterfire configure` + google-services.json) to
  /// activate push automatically.
  FirebaseMessaging? get _messaging {
    if (_injectedMessaging != null) return _injectedMessaging;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseMessaging.instance;
  }

  static final FlutterLocalNotificationsPlugin localPlugin =
      FlutterLocalNotificationsPlugin();

  /// One-time initialization. Call in main() after Firebase.initializeApp().
  ///
  /// Creates Android notification channels and initializes the local
  /// notifications plugin for foreground display.
  static Future<void> initializeLocal() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await localPlugin.initialize(initSettings);
    await NotificationChannels.createAll(localPlugin);
  }

  /// Requests notification permission (iOS always, Android 13+).
  ///
  /// Returns true if the user has granted permission.
  Future<bool> requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return false;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Checks if notification permission is currently granted.
  Future<bool> isPermissionGranted() async {
    final messaging = _messaging;
    if (messaging == null) return false;
    final settings = await messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Call after successful login + device registration.
  ///
  /// Requests permission (if not yet granted), then registers the FCM
  /// token with the backend. Also sets up onTokenRefresh listener.
  ///
  /// Because `firebase_messaging_auto_init_enabled` is `false` in the
  /// manifest, we must explicitly re-enable auto-init here so the SDK
  /// generates a token and fires `onTokenRefresh` on future rotations.
  Future<void> registerTokenIfPermitted() async {
    final messaging = _messaging;
    if (messaging == null) {
      debugPrint('[NotificationService] Firebase not configured, skipping push registration.');
      return;
    }
    final granted = await requestPermission();
    if (!granted) {
      debugPrint('[NotificationService] Permission not granted, skipping token registration.');
      return;
    }
    // Re-enable auto-init now that the user has granted permission.
    // This is required because the AndroidManifest disables it to prevent
    // unauthenticated token generation on cold start.
    await messaging.setAutoInitEnabled(true);
    await _registerCurrentToken();
    _listenForTokenRefresh();
  }

  /// Registers the current FCM token with the backend.
  Future<void> _registerCurrentToken() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('[NotificationService] No FCM token available.');
        return;
      }
      await _repository.registerPushToken(
        fcmToken: fcmToken,
        platform: Platform.isIOS ? 'IOS' : 'ANDROID',
        appVersion: '1.0.0', // TODO: read from package_info_plus
        locale: 'en', // TODO: read from locale provider
      );
      debugPrint('[NotificationService] FCM token registered.');
    } catch (e) {
      debugPrint('[NotificationService] Failed to register FCM token: $e');
    }
  }

  /// Listens for token refresh events and re-registers with backend.
  void _listenForTokenRefresh() {
    final messaging = _messaging;
    if (messaging == null) return;
    messaging.onTokenRefresh.listen((newToken) async {
      try {
        await _repository.registerPushToken(
          fcmToken: newToken,
          platform: Platform.isIOS ? 'IOS' : 'ANDROID',
          appVersion: '1.0.0',
          locale: 'en',
        );
        debugPrint('[NotificationService] Refreshed FCM token registered.');
      } catch (e) {
        debugPrint('[NotificationService] Failed to register refreshed token: $e');
      }
    });
  }

  /// Call on logout. Removes the push token from backend and Firebase,
  /// then disables auto-init to prevent silent token regeneration while
  /// the user is signed out.
  Future<void> cleanupOnLogout() async {
    try {
      await _repository.removePushToken();
    } catch (e) {
      debugPrint('[NotificationService] Failed to remove push token from backend: $e');
    }
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      await messaging.deleteToken();
    } catch (e) {
      debugPrint('[NotificationService] Failed to delete Firebase token: $e');
    }
    // Disable auto-init so the SDK does not silently regenerate a token
    // while the user is signed out (mirrors the manifest default).
    try {
      await messaging.setAutoInitEnabled(false);
    } catch (_) {}
  }
}
