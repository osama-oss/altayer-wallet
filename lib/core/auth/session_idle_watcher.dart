import 'package:flutter/widgets.dart';

import 'package:banksync_app/core/auth/auth_service.dart';

/// Enforces session lock across background / close without running timers.
///
/// When the app leaves the foreground (paused / hidden / detached — includes
/// swipe-away and final back), session tokens are cleared so reopen always
/// requires login again. Biometric enrollment survives; the login screen keeps
/// a simple fingerprint control (no dedicated biometric unlock page).
///
/// [onSessionLocked] is a quiet router refresh (no “session expired” banner).
/// [onSessionExpired] is reserved for the configured idle-timeout path.
///
/// In-foreground idleness remains covered by the refresh interceptor + Keycloak.
class SessionIdleWatcher with WidgetsBindingObserver {
  SessionIdleWatcher({
    required AuthService auth,
    this.onSessionExpired,
    this.onSessionLocked,
  }) : _auth = auth;

  final AuthService _auth;

  /// Idle timeout while away — may show a “session expired” notice.
  final void Function()? onSessionExpired;

  /// Soft lock on leave-foreground — router refresh only, no snackbar.
  final void Function()? onSessionLocked;

  bool _notifiedLock = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _lockOnLeaveForeground();
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _lockOnLeaveForeground() async {
    final token = await _auth.readToken();
    if (token == null || token.isEmpty) return;
    await _auth.lockSessionOnBackground();
    if (_notifiedLock) return;
    _notifiedLock = true;
    onSessionLocked?.call();
  }

  Future<void> _onResumed() async {
    _notifiedLock = false;
    // Warm resume after a background lock — token may already be gone; bounce
    // off protected screens so the UI cannot stay on /home without a session.
    final token = await _auth.readToken();
    if (token == null || token.isEmpty) {
      await _auth.expireSession();
      onSessionLocked?.call();
      return;
    }
    // Safety net if tokens somehow survived a kill without lifecycle callbacks.
    if (await _auth.isIdleTimedOut()) {
      await _auth.expireSession();
      onSessionExpired?.call();
    }
  }
}
