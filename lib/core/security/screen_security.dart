import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Toggles Android `FLAG_SECURE` (blocks screenshots / screen-recording and
/// blanks the recents thumbnail) **only while a sensitive screen is visible** —
/// balances, accounts, cards, transfers — instead of across the whole app.
///
/// Reference-counted so stacked/overlapping sensitive screens (e.g. account
/// detail pushed over the home tab) compose correctly: the flag stays on until
/// the last sensitive screen is gone.
///
/// A second [suspend]/[resume] counter lets a specific screen *opt out* of
/// protection while it is on top (e.g. the account-detail screen, whose receive
/// QR the owner wants to screenshot) even though a sensitive screen — the home
/// tab — is still mounted underneath. While any suspend is active the flag is
/// forced off; it is restored automatically when the screen is dismissed.
///
/// No-op on iOS/web: iOS provides no API to block screenshots; the app-switcher
/// privacy overlay there is global and handled natively in SceneDelegate.
class ScreenSecurity {
  ScreenSecurity._();
  static final ScreenSecurity instance = ScreenSecurity._();

  final MethodChannel _channel =
      const MethodChannel('com.banksync.banksync_app/device_signing');
  int _count = 0;
  int _suspend = 0;
  bool _secured = false;

  Future<void> acquire() async {
    _count++;
    await _reconcile();
  }

  Future<void> release() async {
    if (_count > 0) _count--;
    await _reconcile();
  }

  /// Force-allow screenshots while a screen that opts out is on top, overriding
  /// any sensitive screens mounted underneath.
  Future<void> suspend() async {
    _suspend++;
    await _reconcile();
  }

  Future<void> resume() async {
    if (_suspend > 0) _suspend--;
    await _reconcile();
  }

  Future<void> _reconcile() async {
    final shouldSecure = _suspend == 0 && _count > 0;
    if (shouldSecure == _secured) return;
    _secured = shouldSecure;
    await _apply(shouldSecure);
  }

  Future<void> _apply(bool secure) async {
    if (kDebugMode) return; // Disable screenshot protection during development/debug mode
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setSecureFlag', {'secure': secure});
    } catch (_) {
      // best-effort: never let screen-protection toggling crash the UI
    }
  }
}

/// Wrap a sensitive screen so screenshots are blocked (Android) while it is on
/// screen. Acquires protection on mount, releases on dispose.
///
/// ```dart
/// return SecureScreen(child: Scaffold(...));
/// ```
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    ScreenSecurity.instance.acquire();
  }

  @override
  void dispose() {
    ScreenSecurity.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Wrap a screen that should remain **screenshot-able** even when a sensitive
/// screen is mounted underneath it (e.g. account detail pushed over the home
/// tab). Suspends protection on mount, restores it on dispose.
class UnsecureScreen extends StatefulWidget {
  const UnsecureScreen({super.key, required this.child});

  final Widget child;

  @override
  State<UnsecureScreen> createState() => _UnsecureScreenState();
}

class _UnsecureScreenState extends State<UnsecureScreen> {
  @override
  void initState() {
    super.initState();
    ScreenSecurity.instance.suspend();
  }

  @override
  void dispose() {
    ScreenSecurity.instance.resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
