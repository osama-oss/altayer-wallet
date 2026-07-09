import 'package:flutter/widgets.dart';

import 'package:banksync_app/core/auth/auth_service.dart';

/// Enforces the user's idle session timeout across background/foreground
/// transitions — without any running timers or touch tracking.
///
/// The moment the app leaves the foreground the "last activity" instant is
/// stamped; on resume, if the user was away longer than their
/// `session_timeout_minutes` preference the session is dropped (soft sign-out,
/// biometric enrollment survives) and [onSessionExpired] lets the router
/// bounce to biometric-unlock/login. In-foreground idleness is covered by the
/// refresh interceptor + Keycloak SSO idle.
class SessionIdleWatcher with WidgetsBindingObserver {
  SessionIdleWatcher({required AuthService auth, this.onSessionExpired})
      : _auth = auth;

  final AuthService _auth;
  final void Function()? onSessionExpired;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Persisted (not just in-memory) so the idle clock survives the OS
        // killing the process while backgrounded.
        _auth.persistActivityStamp();
      case AppLifecycleState.resumed:
        _checkIdleOnResume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _checkIdleOnResume() async {
    if (!await _auth.isIdleTimedOut()) return;
    await _auth.expireSession();
    onSessionExpired?.call();
  }
}
