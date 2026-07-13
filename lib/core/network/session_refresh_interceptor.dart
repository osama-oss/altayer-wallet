import 'package:dio/dio.dart';

import 'package:banksync_app/core/auth/auth_service.dart';

/// TEMP — wallet phase ("prepare screens, backend wires later"): wallet users
/// are not yet linked to a core CIF, so their access token carries no
/// `customer_id` claim and every integration call comes back
/// "Customer id missing from token". While this flag is true, that specific
/// failure is treated as NON-fatal — the response is delivered to the calling
/// screen (which renders its own empty/error state) instead of ending the
/// session and bouncing the user to login ~2s after they sign in.
///
/// Flip to false once linkCore/KYC issues real `customer_id` claims, so a
/// genuine mid-session claim loss again triggers the in-place re-login sheet.
const bool kWalletUnlinkedClaimGrace = true;

/// Intercepts every outgoing request to silently refresh an expiring access
/// token, and handles 401 responses from the server.
///
/// Also enforces the fixed idle session timeout (`AppConfig.sessionIdleMinutes`):
/// activity is stamped on successful responses — no client-side timers — and a
/// request made after the idle window drops the session instead of refreshing.
///
/// Excluded paths (login, refresh, biometric challenge, etc.) are passed
/// through untouched so we never deadlock on a token-exchange call. The
/// Keycloak token endpoint itself MUST stay excluded: it is called through
/// this same Dio instance, and intercepting it would recurse into refresh
/// forever.
class SessionRefreshInterceptor extends Interceptor {
  SessionRefreshInterceptor({
    required AuthService auth,
    this.onSessionExpired,
    this.onReauthRequired,
    Dio? retryClient,
  })  : _auth = auth,
        _retryClient = retryClient;

  final AuthService _auth;

  /// Dio used to replay a request after a 401-triggered refresh. Must be the
  /// app's configured client (base options, TLS adapter) — a bare `Dio()`
  /// would fail against dev servers with self-signed certificates.
  final Dio? _retryClient;

  /// Invoked once the session is unrecoverable (idle timeout or a refresh the
  /// issuer rejected) so the app layer can bounce the router to login/unlock.
  final void Function()? onSessionExpired;

  /// Asks the app layer to re-authenticate the user *in place* (re-login
  /// sheet over the current screen). Returns true when the user signed in
  /// again — the failed request is then replayed with the fresh token so the
  /// screen continues as if nothing happened.
  ///
  /// POLICY — when the sheet appears vs. a full bounce to login/unlock:
  ///  • sheet: recoverable interruptions caught *mid-use* (idle check already
  ///    passed) — the token's customer-id claim is rejected, or the issuer
  ///    rejects a refresh (Keycloak SSO idle) while the user is active.
  ///  • full exit: the user's own idle timeout was exceeded, the user
  ///    cancels the sheet, or there is no UI to present the sheet on.
  final Future<bool> Function()? onReauthRequired;

  /// Single-flight re-login prompt: concurrent failing requests all await the
  /// one sheet instead of stacking prompts.
  Future<bool>? _reauthInFlight;

  /// Paths that must never be intercepted (they are the auth flow itself).
  static const _excluded = {
    '/protocol/openid-connect/', // Keycloak login/refresh — see class doc
    '/auth/token',
    '/auth/set-initial-password',
    '/auth/reset-password',
    '/auth/resolve-login',
    '/auth/register',
    '/devices/biometric/challenge',
    '/devices/biometric/login',
    '/devices/biometric/failure',
    '/devices/biometric/refresh',
    '/push-token',
  };

  bool _isExcluded(String path) =>
      _excluded.any((e) => path.contains(e));

  Future<void> _expire() async {
    await _auth.expireSession();
    onSessionExpired?.call();
  }

  DioException _sessionExpired(RequestOptions options) => DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        error: 'session_expired',
      );

  // ── Token-claim failure → in-place re-login ────────────────────────────

  /// True when the backend rejected the *token contents* (customer-id claim
  /// absent), e.g. `Customer id missing from token` from the integration
  /// layer or `Customer ID is required` (FORBIDDEN) from mobile-service.
  /// These arrive as `success:false` envelopes, not 401s, and only a fresh
  /// login can produce a token with the claim back.
  static bool _isCustomerClaimFailure(Response<dynamic>? response) {
    final body = response?.data;
    if (body is! Map) return false;
    if (body['success'] == true) return false;
    final inner = body['data'];
    final text = [
      body['message'],
      body['error'],
      body['errorMessage'],
      if (inner is Map) inner['message'],
    ].whereType<String>().join(' ').toLowerCase();
    return text.contains('missing from token') ||
        text.contains('customer id missing') ||
        text.contains('customer id is required');
  }

  bool _shouldOfferReauth(RequestOptions options) =>
      onReauthRequired != null &&
      !_isExcluded(options.path) &&
      options.extra['reauth_retry'] != true;

  Future<bool> _promptReauth() {
    final prompt = onReauthRequired;
    if (prompt == null) return Future.value(false);
    return _reauthInFlight ??= prompt().whenComplete(() {
      _reauthInFlight = null;
    });
  }

  /// Replays [options] with the freshly minted token. `reauth_retry` caps the
  /// flow at one prompt per request, so a still-broken token surfaces the
  /// original error instead of looping the sheet.
  Future<Response<dynamic>> _replayAfterReauth(RequestOptions options) async {
    final token = await _auth.readToken();
    options.headers['Authorization'] = 'Bearer $token';
    options.extra['reauth_retry'] = true;
    return (_retryClient ?? Dio()).fetch(options);
  }

  // ── onRequest ──────────────────────────────────────────────────────────

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isExcluded(options.path)) {
      return handler.next(options);
    }

    // Track whether the interceptor obtained a new token (via refresh or
    // re-login) so we know to overwrite the caller's header below.
    bool didObtainFreshToken = false;

    // Idle timeout beaten: the user has been away longer than the fixed
    // sessionIdleMinutes config — drop the session, do not refresh.
    if (await _auth.isIdleTimedOut()) {
      await _expire();
      return handler.reject(_sessionExpired(options));
    }

    // If the access token is near expiry, attempt a silent refresh.
    // refreshSession() is single-flight — parallel requests share one call.
    if (await _auth.isSessionExpired()) {
      switch (await _auth.refreshSession()) {
        case SessionRefreshOutcome.success:
          didObtainFreshToken = true;
          break;
        case SessionRefreshOutcome.rejected:
          // Issuer rejected the refresh (e.g. Keycloak SSO idle exceeded).
          // The user is mid-task (the idle check above already passed), so
          // offer the in-place re-login sheet first; only a decline — or no
          // way to show the sheet — ends the session and bounces to login.
          if (_shouldOfferReauth(options) && await _promptReauth()) {
            didObtainFreshToken = true;
            options.extra['reauth_retry'] = true;
            break; // fresh token is attached below
          }
          await _expire();
          return handler.reject(_sessionExpired(options));
        case SessionRefreshOutcome.offline:
          // Connectivity problem — keep the session, fail this request as a
          // network error so screens show their normal offline state.
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              error: 'refresh_unreachable',
            ),
          );
      }
    }

    // Attach the (possibly refreshed) token. When the interceptor just
    // refreshed or re-authenticated, always overwrite the header so the
    // request carries the new token. Otherwise respect any Authorization
    // header the caller explicitly provided — during the login flow,
    // _completePasswordSession passes a just-minted token that is NOT yet
    // persisted; blindly overwriting it with a stale stored token causes 401.
    final token = await _auth.readToken();
    if (token != null && token.isNotEmpty) {
      if (didObtainFreshToken || !options.headers.containsKey('Authorization')) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  // ── onResponse ─────────────────────────────────────────────────────────

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Successful API traffic counts as user activity for the idle clock.
    // Memory-only stamp — free.
    if (!_isExcluded(response.requestOptions.path)) {
      _auth.noteActivity();
    }

    // Claim-level rejection rides in on a 2xx/4xx `success:false` envelope
    // (integration errors pass validateStatus). Offer an in-place re-login
    // and, when the user signs back in, replay the request transparently.
    if (!kWalletUnlinkedClaimGrace &&
        _isCustomerClaimFailure(response) &&
        _shouldOfferReauth(response.requestOptions)) {
      if (await _promptReauth()) {
        try {
          return handler.resolve(await _replayAfterReauth(response.requestOptions));
        } on DioException catch (e) {
          return handler.reject(e);
        }
      }
      // User declined to re-login → the session is over; bounce to login.
      await _expire();
      return handler.reject(_sessionExpired(response.requestOptions));
    }

    handler.next(response);
  }

  // ── onError ────────────────────────────────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Same claim-level rejection as in onResponse, for endpoints where the
    // 4xx surfaces as a DioException instead of a validated response.
    if (!kWalletUnlinkedClaimGrace &&
        _isCustomerClaimFailure(err.response) &&
        _shouldOfferReauth(err.requestOptions)) {
      if (await _promptReauth()) {
        try {
          return handler.resolve(await _replayAfterReauth(err.requestOptions));
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
      await _expire();
      return handler.next(_sessionExpired(err.requestOptions));
    }

    if (err.response?.statusCode != 401 ||
        _isExcluded(err.requestOptions.path) ||
        // Never retry more than once — a 401 on the replayed request means
        // the problem is not token freshness.
        err.requestOptions.extra['session_retry'] == true) {
      return handler.next(err);
    }

    // 401 from the server — try one silent refresh.
    final outcome = await _auth.refreshSession();
    if (outcome != SessionRefreshOutcome.success) {
      if (outcome == SessionRefreshOutcome.rejected) {
        // Same policy as onRequest: the user is mid-task, so offer the
        // in-place re-login sheet before ending the session.
        if (_shouldOfferReauth(err.requestOptions) && await _promptReauth()) {
          try {
            return handler.resolve(await _replayAfterReauth(err.requestOptions));
          } on DioException catch (e) {
            return handler.next(e);
          }
        }
        await _expire();
      }
      return handler.next(err);
    }

    // Retry the original request with the fresh token.
    final token = await _auth.readToken();
    final opts = err.requestOptions;
    opts.headers['Authorization'] = 'Bearer $token';
    opts.extra['session_retry'] = true;

    try {
      final response = await (_retryClient ?? Dio()).fetch(opts);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
