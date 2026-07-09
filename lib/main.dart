import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/notifications/notification_handler.dart';
import 'core/notifications/notification_service.dart';
import 'core/security/rasp_service.dart';
import 'core/security/threat_policy.dart';
import 'core/storage/secure_migration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional at startup: if it is not configured yet (no generated
  // firebase_options.dart / google-services.json), fail-open so the app still
  // runs. Wire it fully by running `flutterfire configure`.
  await _initFirebase();

  // Create Android notification channels + init local notifications plugin
  await NotificationService.initializeLocal();

  await AppConfig.load();
  // One-time migration of any pre-existing plaintext session into the secure
  // enclave (Keystore/Keychain). Runs before the router reads the token so a
  // logged-in user is not bounced to login after the upgrade.
  await SecureMigration().migrateIfNeeded();
  // Start runtime self-protection (root/jailbreak/tamper/hook/debugger…) in the
  // configured graded mode (default: monitor — observe + report, never block).
  // Fail-open: RASP init never blocks startup.
  await _startRaspMonitoring();
  runApp(const ProviderScope(child: BankSyncApp()));
}

/// Initialises Firebase (Crashlytics + FCM) if it is configured. Any failure —
/// most importantly the not-yet-configured placeholder options — is swallowed so
/// startup never blocks; the app simply runs without Firebase.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Pass uncaught fatal framework errors to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass uncaught async errors to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
      return true;
    };

    // Register FCM background handler (must be a top-level function).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase not initialised (running without it): $e');
  }
}

Future<void> _startRaspMonitoring() async {
  final security = AppConfig.instance.security;
  await RaspService.instance.start(
    policy: ThreatPolicy.fromName(security.threatPolicy),
    watcherMail: security.watcherMail,
    androidPackageName: 'com.uff.altayer',
    androidSigningCertHashes: security.androidSigningCertHashes,
    iosBundleIds: security.iosBundleIds,
    iosTeamId: security.iosTeamId,
  );
}
