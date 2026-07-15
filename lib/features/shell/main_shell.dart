import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/security/screen_security.dart';
import '../../core/widgets/banksync_bottom_nav.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import '../home/explore_screen.dart';
import '../reports/reports_screen.dart';
import '../transfer_hub/transfer_hub_screen.dart';
import '../wallet/wallet_home_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _homeSecured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncHomeSecurity(ref.read(dashboardTabProvider)),
    );
  }

  @override
  void dispose() {
    if (_homeSecured) ScreenSecurity.instance.release();
    super.dispose();
  }

  /// The home tab is the only shell tab showing balances + cards, so block
  /// screenshots there only. Pushed money/card screens secure themselves.
  void _syncHomeSecurity(BankSyncTab tab) {
    final sensitive = tab == BankSyncTab.home;
    if (sensitive && !_homeSecured) {
      _homeSecured = true;
      ScreenSecurity.instance.acquire();
    } else if (!sensitive && _homeSecured) {
      _homeSecured = false;
      ScreenSecurity.instance.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dashboardTabProvider, (_, next) => _syncHomeSecurity(next));
    final tab = ref.watch(dashboardTabProvider);
    final l10n = context.l10n;
    final topBar = switch (tab) {
      BankSyncTab.explore => BankSyncTopBar(
          showAvatar: false,
          centerTitle: l10n.navExplore,
          showTrailing: false,
        ),
      _ => const BankSyncTopBar(),
    };

    // Final system back soft-locks the session before exiting so a kill that
    // races the lifecycle watcher cannot leave tokens for the next cold start.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await ref.read(authServiceProvider).lockSessionOnBackground();
        invalidateUserSessionCache(ref);
        notifyRouterAuthChanged(ref);
        await SystemNavigator.pop();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              topBar,
              Expanded(
                child: IndexedStack(
                  index: tab.index,
                  children: const [
                    WalletHomeScreen(),
                    TransferHubScreen(),
                    ReportsScreen(),
                    ExploreScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BankSyncBottomNav(
          currentTab: tab,
          onTabSelected: (newTab) =>
              ref.read(dashboardTabProvider.notifier).state = newTab,
        ),
      ),
    );
  }
}
