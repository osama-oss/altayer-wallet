import 'package:flutter/widgets.dart';

import 'package:banksync_app/core/auth/auth_service.dart';

/// Soft-locks the session when the process is leaving (detached) and enforces
/// idle timeout on resume.
///
/// Deliberately does **not** clear tokens on every `paused`/`hidden` — that
/// races the OS biometric sheet and post-login navigation, which briefly
/// background the app and used to wipe the new session (empty wallet + false
/// "not verified" until pull-to-refresh).
///
/// Cold start still ends the session in [AuthService.bootstrapRoute]. Final
/// system back on the main shell soft-locks before [SystemNavigator.pop].
class SessionIdleWatcher with WidgetsBindingObserver {
  SessionIdleWatcher({
    required AuthService auth,
    this.onSessionExpired,
    this.onSessionLocked,
  }) : _auth = auth;

  final AuthService _auth;

  /// Idle timeout while away — may show a “session expired” notice.
  final void Function()? onSessionExpired;

  /// Soft lock when the process is dying — router refresh only, no snackbar.
  final void Function()? onSessionLocked;

  bool _notifiedLock = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        _lockOnProcessExit();
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _lockOnProcessExit() async {
    final token = await _auth.readToken();
    if (token == null || token.isEmpty) return;
    await _auth.lockSessionOnBackground();
    if (_notifiedLock) return;
    _notifiedLock = true;
    onSessionLocked?.call();
  }

  Future<void> _onResumed() async {
    _notifiedLock = false;
    final token = await _auth.readToken();
    if (token == null || token.isEmpty) {
      // Soft-lock already happened (back / detached / cold start). Sync router
      // so we never paint /home without a session.
      onSessionLocked?.call();
      return;
    }
    if (await _auth.isIdleTimedOut()) {
      await _auth.expireSession();
      onSessionExpired?.call();
    }
  }
}
