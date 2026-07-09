import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:banksync_app/core/auth/auth_service.dart';
import 'package:banksync_app/core/auth/device_storage.dart';
import 'package:banksync_app/core/auth/session_store.dart';
import 'package:banksync_app/core/auth/session_idle_watcher.dart';
import 'package:banksync_app/core/data/accounts_repository.dart';
import 'package:banksync_app/core/models/account_preferences.dart';
import 'package:banksync_app/core/models/banking_account.dart';
import 'package:banksync_app/core/models/favorite_transfer.dart';
import 'package:banksync_app/core/network/api_client.dart';
import 'package:banksync_app/core/notifications/notification_repository.dart';
import 'package:banksync_app/core/notifications/notification_service.dart';
import 'package:banksync_app/core/network/session_refresh_interceptor.dart';
import 'package:banksync_app/core/providers/locale_provider.dart';
import 'package:banksync_app/core/providers/router_refresh_notifier.dart';
import 'package:banksync_app/core/widgets/relogin_sheet.dart';
import 'package:banksync_app/router/navigation_keys.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    currentLanguageResolver: () => ref.read(localeProvider).languageCode,
  );
});

final Provider<AuthService> authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    api: ref.watch(apiClientProvider),
    onLoginSuccess: () => ref.read(notificationServiceProvider).registerTokenIfPermitted(),
    onSignOut: () => ref.read(notificationServiceProvider).cleanupOnLogout(),
  );
});

/// True when the user was bounced to login/unlock because the session ended
/// (idle timeout or the issuer rejected a refresh) — NOT on manual sign-out.
/// The login/biometric-unlock screens read this once to show a "session
/// expired" notice, then reset it.
final sessionExpiredNoticeProvider = StateProvider<bool>((ref) => false);

/// Attaches the [SessionRefreshInterceptor] to the shared Dio instance so that
/// every API call automatically refreshes an expiring token or retries on 401.
final sessionRefreshInterceptorProvider = Provider<SessionRefreshInterceptor>((ref) {
  final auth = ref.watch(authServiceProvider);
  final dio = ref.watch(apiClientProvider).dio;
  final interceptor = SessionRefreshInterceptor(
    auth: auth,
    retryClient: dio,
    onSessionExpired: () => _notifySessionExpired(ref),
    onReauthRequired: () => _promptRelogin(ref),
  );
  dio.interceptors.add(interceptor);
  return interceptor;
});

/// Registers the [SessionIdleWatcher] so a background stay longer than the
/// fixed `sessionIdleMinutes` config value ends the session on resume.
final sessionIdleWatcherProvider = Provider<SessionIdleWatcher>((ref) {
  final watcher = SessionIdleWatcher(
    auth: ref.watch(authServiceProvider),
    onSessionExpired: () => _notifySessionExpired(ref),
  );
  WidgetsBinding.instance.addObserver(watcher);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(watcher));
  return watcher;
});

void _notifySessionExpired(Ref ref) {
  ref.read(sessionExpiredNoticeProvider.notifier).state = true;
  ref.read(routerRefreshProvider).notifyAuthChanged();
}

/// Presents the in-place re-login sheet over whatever screen is current when
/// the server rejects the session token itself (customer-id claim missing).
/// Returns true when the user signed back in — the interceptor then replays
/// the failed request so the screen keeps working without losing its state.
Future<bool> _promptRelogin(Ref ref) async {
  final auth = ref.read(authServiceProvider);
  // No stored session (mid sign-out) → nothing to re-authenticate.
  final token = await auth.readToken();
  if (token == null || token.isEmpty) return false;
  final context = rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return false;
  return await showReloginSheet(context, auth: auth) ?? false;
}

/// Shared accounts source (CUSTOMER_ACCOUNTS_SEARCH) reused by the home
/// carousel and the All-accounts screen.
final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(
    auth: ref.watch(authServiceProvider),
    api: ref.watch(apiClientProvider),
  );
});

final dashboardObscuredProvider = StateProvider<bool>((ref) => true);

/// Revision counter for the customer's accounts. Screens that cache accounts in
/// local state (home carousel, All-accounts) `ref.listen` this and re-fetch when
/// it changes. Bump it after a server-side mutation — e.g. opening a new account
/// — so the new account appears without a manual pull-to-refresh.
final accountsRevisionProvider = StateProvider<int>((ref) => 0);

// ─── Notification providers ─────────────────────────────────────────────

/// Reads tokens directly from [SessionStore] instead of [AuthService] to
/// break the circular dependency:
///   authServiceProvider → notificationServiceProvider →
///   notificationRepositoryProvider → authServiceProvider  (cycle!)
final Provider<NotificationRepository> notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final store = SessionStore();
  final devices = DeviceStorage();
  return NotificationRepository(
    api: api,
    tokenReader: () => store.readToken(),
    deviceIdReader: () => devices.getOrCreateDeviceId(),
  );
});

final Provider<NotificationService> notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    repository: ref.watch(notificationRepositoryProvider),
  );
});

/// Unread notification count — refreshed on demand.
final unreadNotificationCountProvider = StateProvider<int>((ref) => 0);

/// Single shared, cached source of the customer's accounts.
///
/// PERFORMANCE: this is THE accounts cache. Every screen (home carousel,
/// transfer panels, all-accounts, default-accounts) reads it instead of
/// fetching on its own — after the first load, opening those screens costs
/// zero network calls. It refetches when [accountsRevisionProvider] is bumped
/// (successful transfer, new account, login) or when explicitly invalidated;
/// watchers keep showing the previous list while the refresh is in flight.
final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<BankingAccount>>(
        AccountsNotifier.new);

class AccountsNotifier extends AsyncNotifier<List<BankingAccount>> {
  @override
  Future<List<BankingAccount>> build() async {
    // Bumping the revision invalidates this cache automatically.
    ref.watch(accountsRevisionProvider);
    // Failures must not be served from cache: once nobody is watching an
    // errored state, drop it so the next screen open retries the network.
    ref.onCancel(() {
      if (state.hasError) ref.invalidateSelf();
    });
    final token = await ref.read(authServiceProvider).readToken();
    if (token == null || token.isEmpty) return const [];
    return ref.read(accountsRepositoryProvider).fetchAccounts(token);
  }
}

/// Shared cache of the customer's favorite transfer targets (server-side,
/// JWT-scoped `FAVORITE_*` codes — survive clear-data / new device). Same
/// lifecycle rules as [accountsProvider]. Mutations go through the notifier's
/// [FavoritesNotifier.add] / [FavoritesNotifier.removeByAccount] so every
/// watcher (success-view star, transfer strip) stays in sync.
final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<FavoriteTransfer>>(
        FavoritesNotifier.new);

class FavoritesNotifier extends AsyncNotifier<List<FavoriteTransfer>> {
  @override
  Future<List<FavoriteTransfer>> build() async {
    ref.onCancel(() {
      if (state.hasError) ref.invalidateSelf();
    });
    final token = await ref.read(authServiceProvider).readToken();
    if (token == null || token.isEmpty) return const [];
    final data = await ref.read(apiClientProvider).getFavorites(token);
    return FavoriteTransfer.listFrom(data['favorites']);
  }

  bool isFavorite(String accountNumber) {
    final list = state.valueOrNull;
    if (list == null) return false;
    final target = accountNumber.trim();
    return list.any((f) => f.targetAccountNumber == target);
  }

  /// Adds a favorite on the server, then prepends it locally (idempotent —
  /// re-adding an existing account just re-syncs that row).
  Future<void> add({
    required String targetAccountNumber,
    String? targetName,
    String? nickname,
    String? currency,
    String? transferType,
  }) async {
    final token = await ref.read(authServiceProvider).readToken();
    if (token == null || token.isEmpty) return;
    final data = await ref.read(apiClientProvider).addFavorite(token, {
      'targetAccountNumber': targetAccountNumber.trim(),
      if (targetName?.trim().isNotEmpty == true) 'targetName': targetName!.trim(),
      if (nickname?.trim().isNotEmpty == true) 'nickname': nickname!.trim(),
      if (currency?.trim().isNotEmpty == true) 'currency': currency!.trim(),
      if (transferType?.trim().isNotEmpty == true) 'transferType': transferType!.trim(),
    });
    final added = FavoriteTransfer.fromMap(data);
    final current = state.valueOrNull ?? const <FavoriteTransfer>[];
    state = AsyncData([
      added,
      ...current.where((f) => f.targetAccountNumber != added.targetAccountNumber),
    ]);
  }

  /// Deletes a favorite on the server, then drops it locally.
  Future<void> removeByAccount(String targetAccountNumber) async {
    final token = await ref.read(authServiceProvider).readToken();
    if (token == null || token.isEmpty) return;
    final target = targetAccountNumber.trim();
    await ref
        .read(apiClientProvider)
        .deleteFavorite(token, {'targetAccountNumber': target});
    final current = state.valueOrNull ?? const <FavoriteTransfer>[];
    state = AsyncData(
        current.where((f) => f.targetAccountNumber != target).toList());
  }
}

/// Shared cache of the user's default-account preferences (same lifecycle
/// rules as [accountsProvider]; invalidated after saving new defaults).
final accountPreferencesProvider =
    AsyncNotifierProvider<AccountPreferencesNotifier, AccountPreferencesData>(
        AccountPreferencesNotifier.new);

class AccountPreferencesNotifier extends AsyncNotifier<AccountPreferencesData> {
  @override
  Future<AccountPreferencesData> build() async {
    ref.onCancel(() {
      if (state.hasError) ref.invalidateSelf();
    });
    final token = await ref.read(authServiceProvider).readToken();
    if (token == null || token.isEmpty) return const AccountPreferencesData();
    try {
      final map = await ref.read(apiClientProvider).getAccountPreferences(token);
      return AccountPreferencesData.fromMap(map);
    } catch (_) {
      return const AccountPreferencesData();
    }
  }
}
