import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/account_transaction.dart';
import '../../core/models/banking_account.dart';
import '../../core/models/favorite_transfer.dart';
import '../../core/providers/app_providers.dart';
import '../../core/security/screen_security.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/transaction_tile.dart';
import '../../core/widgets/uff_loader.dart';
import '../../l10n/app_localizations.dart';
import '../home/transactions_screen.dart';
import '../transfer/qr_scan_screen.dart';
import '../transfer/scan_review_screen.dart';
import 'wallet_providers.dart';
import 'wallet_receive_screen.dart';

const _positiveAmount = Color(0xFF27AE60);
const _negativeAmount = Color(0xFFEB5757);

/// «Ultimate Wallet» wallet home — a multi-currency wallet dashboard: a
/// horizontal carousel of the customer's wallets (SAR / YER / USD), primary
/// quick actions (send / receive / top-up / scan), a favorites quick-access
/// strip, an organised services grid (real routes + "coming soon"
/// placeholders), a promo banner carousel and a recent-activity preview.
///
/// Every balance comes from the real UFF integrations (accountsProvider +
/// ACCOUNT-LAST-TEN-TXN) and favorites from favoritesProvider; nothing here is
/// mocked. When data is unavailable the widgets fall back to loading / empty
/// states instead of placeholder numbers.
class WalletHomeScreen extends ConsumerStatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  ConsumerState<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends ConsumerState<WalletHomeScreen> {
  final PageController _walletPageController =
      PageController(viewportFraction: 0.9);
  int _activeIndex = 0;

  @override
  void dispose() {
    _walletPageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final accounts =
        ref.read(accountsProvider).valueOrNull ?? const <BankingAccount>[];
    ref.invalidate(accountsProvider);
    ref.invalidate(favoritesProvider);
    if (accounts.isNotEmpty) {
      final idx = _activeIndex.clamp(0, accounts.length - 1);
      ref.invalidate(
          walletRecentActivityProvider(accounts[idx].accountNoForIntegration));
    }
    try {
      await ref.read(accountsProvider.future);
    } catch (_) {}
  }

  /// Refresh triggered by a single card's refresh button. It only re-reads the
  /// balances source and that card's own recent activity — nothing tied to the
  /// other wallets is invalidated.
  Future<void> _refreshAccount(BankingAccount account) async {
    ref.invalidate(accountsProvider);
    ref.invalidate(
        walletRecentActivityProvider(account.accountNoForIntegration));
    try {
      await ref.read(accountsProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final colors = context.bankColors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;

    final loading = accountsAsync.isLoading && !accountsAsync.hasValue;
    final hasError = accountsAsync.hasError && !accountsAsync.hasValue;
    final accounts = accountsAsync.valueOrNull ?? const <BankingAccount>[];

    Widget body;
    if (loading) {
      body = const SizedBox(height: 340, child: Center(child: UffLoader()));
    } else if (hasError) {
      body =
          _ErrorState(onRetry: _refresh, colors: colors, l10n: l10n, lang: lang);
    } else if (accounts.isEmpty) {
      body = _EmptyWalletState(colors: colors, l10n: l10n, lang: lang);
    } else {
      final activeIndex = _activeIndex.clamp(0, accounts.length - 1);
      final active = accounts[activeIndex];
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KycBanner(colors: colors, l10n: l10n),
          const SizedBox(height: 18),
          _SectionHeader(
              title: l10n.walletMyWallets, lang: lang),
          const SizedBox(height: 12),
          _WalletsCarousel(
            accounts: accounts,
            controller: _walletPageController,
            activeIndex: activeIndex,
            colors: colors,
            l10n: l10n,
            lang: lang,
            onPageChanged: (i) => setState(() => _activeIndex = i),
            onRefresh: _refreshAccount,
          ),
          const SizedBox(height: 12),
          _CarouselDots(
            count: accounts.length,
            active: activeIndex,
            colors: colors,
          ),
          const SizedBox(height: 22),
          _QuickActions(account: active, colors: colors, l10n: l10n, lang: lang),
          const SizedBox(height: 26),
          _SectionHeader(
              title: l10n.walletQuickAccessTitle, lang: lang),
          const SizedBox(height: 12),
          const _FavoritesStrip(),
          const SizedBox(height: 26),
          _SectionHeader(
              title: l10n.walletServicesTitle, lang: lang),
          const SizedBox(height: 12),
          _ServicesGrid(colors: colors, l10n: l10n, lang: lang),
          const SizedBox(height: 26),
          _SectionHeader(
              title: l10n.walletPromotionsTitle, lang: lang),
          const SizedBox(height: 12),
          _PromoCarousel(colors: colors, l10n: l10n, lang: lang),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.walletRecentActivity,
                style: AppTextStyles.headlineMd(languageCode: lang)
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        SecureScreen(child: TransactionsScreen(account: active)),
                  ),
                ),
                child: Text(
                  l10n.viewAll,
                  style: AppTextStyles.labelSm(
                          color: colors.secondary, languageCode: lang)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _RecentActivityList(
              account: active, colors: colors, l10n: l10n, lang: lang),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: colors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: body,
      ),
    );
  }
}

/// Simple bold section title used across the dashboard.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.lang});

  final String title;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.headlineMd(languageCode: lang)
          .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }
}

/// بانر أعلى الرئيسية يدعو العميل غير المُوثَّق لإكمال التحقق (KYC).
class _KycBanner extends StatelessWidget {
  const _KycBanner({required this.colors, required this.l10n});

  final BankSyncColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/kyc'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.error.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.gpp_maybe_outlined, color: colors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.kycBannerText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.kycVerifyAccount,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: colors.error,
                  ),
                ),
                Icon(
                  Directionality.of(context) == ui.TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: colors.error,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wallets carousel ───────────────────────────────────────────────────────

/// Horizontal carousel of the customer's wallets. The active card renders in
/// full while a slice of the next card peeks at the trailing edge (LTR right /
/// RTL left, handled automatically by [PageView]'s directionality).
class _WalletsCarousel extends StatelessWidget {
  const _WalletsCarousel({
    required this.accounts,
    required this.controller,
    required this.activeIndex,
    required this.colors,
    required this.l10n,
    required this.lang,
    required this.onPageChanged,
    required this.onRefresh,
  });

  final List<BankingAccount> accounts;
  final PageController controller;
  final int activeIndex;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function(BankingAccount) onRefresh;

  @override
  Widget build(BuildContext context) {
    // A lone wallet needs no peek/scroll — render it flush.
    if (accounts.length == 1) {
      return SizedBox(
        height: 182,
        child: _WalletCard(
          account: accounts.first,
          active: true,
          colors: colors,
          l10n: l10n,
          lang: lang,
          onRefresh: onRefresh,
        ),
      );
    }
    return SizedBox(
      height: 182,
      child: PageView.builder(
        controller: controller,
        padEnds: false,
        onPageChanged: onPageChanged,
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final active = index == activeIndex;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(vertical: active ? 0 : 10),
              child: _WalletCard(
                account: accounts[index],
                active: active,
                colors: colors,
                l10n: l10n,
                lang: lang,
                onRefresh: onRefresh,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WalletCard extends ConsumerStatefulWidget {
  const _WalletCard({
    required this.account,
    required this.active,
    required this.colors,
    required this.l10n,
    required this.lang,
    required this.onRefresh,
  });

  final BankingAccount account;
  final bool active;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;
  final Future<void> Function(BankingAccount) onRefresh;

  @override
  ConsumerState<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends ConsumerState<_WalletCard> {
  bool _refreshing = false;

  BankingAccount get account => widget.account;
  AppLocalizations get l10n => widget.l10n;
  String get lang => widget.lang;

  String get _code => account.currency.trim().toUpperCase();

  String _currencyName() {
    switch (_code) {
      case 'SAR':
        return l10n.walletCurrencySar;
      case 'YER':
        return l10n.walletCurrencyYer;
      case 'USD':
        return l10n.walletCurrencyUsd;
      default:
        return _code;
    }
  }

  /// All variants stay inside the blue brand family so the carousel reads as
  /// one identity while still distinguishing the wallets.
  Gradient _gradient() {
    switch (_code) {
      case 'YER':
        return const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.brandIndigo, AppColors.navy],
        );
      case 'USD':
        return const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF2F80ED), Color(0xFF063A80)],
        );
      case 'SAR':
      default:
        return AppColors.brandGradient;
    }
  }

  /// Full account number, lightly grouped for readability. Uses this card's
  /// own account — never a shared/placeholder value.
  String get _accountNumberText {
    final n = account.accountNumber.trim();
    if (n.isEmpty) return '—';
    // Group runs of 4 for long numeric account numbers; leave short ones as-is.
    if (RegExp(r'^\d+$').hasMatch(n) && n.length > 4) {
      final buf = StringBuffer();
      for (var i = 0; i < n.length; i++) {
        if (i > 0 && (n.length - i) % 4 == 0) buf.write(' ');
        buf.write(n[i]);
      }
      return buf.toString();
    }
    return n;
  }

  Future<void> _handleRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh(account);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Independent per-card visibility — keyed by this wallet's own id.
    final obscured = ref.watch(walletBalanceVisibilityProvider
        .select((revealed) => !revealed.contains(account.walletKey)));

    final balanceText =
        obscured ? '••••••' : NumberFormat('#,##0.00').format(account.balance);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _gradient(),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: widget.active
            ? [
                BoxShadow(
                  color: AppColors.brandIndigo.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Currency badge
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25), width: 1),
                ),
                child: Text(
                  _code,
                  style: AppTextStyles.mono(color: Colors.white).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currencyName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm(
                        color: Colors.white,
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      l10n.walletBalanceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm(
                        color: Colors.white.withValues(alpha: 0.75),
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w500, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _CircleIconButton(
                icon: Icons.refresh_rounded,
                busy: _refreshing,
                onTap: _handleRefresh,
              ),
              const SizedBox(width: 4),
              _CircleIconButton(
                icon: obscured
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                onTap: () => ref
                    .read(walletBalanceVisibilityProvider.notifier)
                    .toggle(account.walletKey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  balanceText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.balanceDisplay(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w900, fontSize: 30),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _code,
                style: AppTextStyles.labelSm(
                  color: Colors.white.withValues(alpha: 0.85),
                  languageCode: lang,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.walletNumberLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm(
                        color: Colors.white.withValues(alpha: 0.65),
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w500, fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _accountNumberText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: ui.TextDirection.ltr,
                      style: AppTextStyles.monoLabel(
                        color: Colors.white.withValues(alpha: 0.95),
                      ).copyWith(fontSize: 14, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkResponse(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: account.accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.copied)),
                  );
                },
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.content_copy_rounded,
                      color: Colors.white.withValues(alpha: 0.85), size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small translucent circular icon button used on the wallet cards. When
/// [busy] is set it shows an inline spinner instead of the icon (used by the
/// per-card refresh button so only the tapped card indicates activity).
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: busy ? null : onTap,
      radius: 22,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: busy
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.95)),
                ),
              )
            : Icon(icon,
                color: Colors.white.withValues(alpha: 0.95), size: 17),
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({
    required this.count,
    required this.active,
    required this.colors,
  });

  final int count;
  final int active;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == active
                  ? colors.secondary
                  : colors.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

// ─── Primary actions ────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.account,
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankingAccount account;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  Future<void> _scanAndPay(BuildContext context) async {
    final acct = await openQrScanScreen(context);
    if (acct == null || acct.isEmpty) return;
    if (!context.mounted) return;
    // Scanning never transfers directly — review the recipient first.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanReviewScreen(account: acct),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionItem(
          icon: Icons.arrow_upward_rounded,
          label: l10n.walletActionSend,
          colors: colors,
          lang: lang,
          onTap: () => context.push('/transfer/others'),
        ),
        _ActionItem(
          icon: Icons.qr_code_2_rounded,
          label: l10n.walletActionReceive,
          colors: colors,
          lang: lang,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WalletReceiveScreen(account: account),
            ),
          ),
        ),
        _ActionItem(
          icon: Icons.add_rounded,
          label: l10n.walletActionTopUp,
          colors: colors,
          lang: lang,
          onTap: () => context.push('/transfer/own'),
        ),
        _ActionItem(
          icon: Icons.qr_code_scanner_rounded,
          label: l10n.walletActionScan,
          colors: colors,
          lang: lang,
          onTap: () => _scanAndPay(context),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.colors,
    required this.lang,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final BankSyncColors colors;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.secondary, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm(
                        color: colors.onSurface, languageCode: lang)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Favorites quick-access ─────────────────────────────────────────────────

/// Four-slot favorites strip. Real server-side favorites fill the slots (tap →
/// prefilled transfer); empty slots show an "add favorite" affordance that opens
/// the beneficiaries screen. Uses the shared [favoritesProvider] — no mock data.
class _FavoritesStrip extends ConsumerWidget {
  const _FavoritesStrip();

  static const int _slots = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final favoritesAsync = ref.watch(favoritesProvider);

    final favorites =
        favoritesAsync.valueOrNull ?? const <FavoriteTransfer>[];
    final loading = favoritesAsync.isLoading && !favoritesAsync.hasValue;

    return Row(
      children: [
        for (var i = 0; i < _slots; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: loading
                ? _FavoriteSkeleton(colors: colors)
                : (i < favorites.length
                    ? _FavoriteChip(
                        favorite: favorites[i],
                        colors: colors,
                        lang: lang,
                        onTap: () => context.push(
                          '/transfer/others?to=${Uri.encodeComponent(favorites[i].targetAccountNumber)}',
                        ),
                      )
                    : _AddFavoriteSlot(
                        colors: colors,
                        lang: lang,
                        label: l10n.walletAddFavorite,
                        onTap: () => context.push('/beneficiaries'),
                      )),
          ),
        ],
      ],
    );
  }
}

class _FavoriteChip extends StatelessWidget {
  const _FavoriteChip({
    required this.favorite,
    required this.colors,
    required this.lang,
    required this.onTap,
  });

  final FavoriteTransfer favorite;
  final BankSyncColors colors;
  final String lang;
  final VoidCallback onTap;

  String get _initial {
    final name = favorite.displayName.trim();
    if (name.isEmpty) return '#';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: colors.secondary.withValues(alpha: 0.25), width: 1),
            ),
            child: Text(
              _initial,
              style: AppTextStyles.headlineMd(color: colors.secondary)
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            favorite.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSm(
                    color: colors.onSurface, languageCode: lang)
                .copyWith(fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AddFavoriteSlot extends StatelessWidget {
  const _AddFavoriteSlot({
    required this.colors,
    required this.lang,
    required this.label,
    required this.onTap,
  });

  final BankSyncColors colors;
  final String lang;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          _DottedCircle(
            size: 56,
            color: colors.outline,
            child: Icon(Icons.add_rounded,
                color: colors.onSurfaceVariant, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSm(
                    color: colors.onSurfaceVariant, languageCode: lang)
                .copyWith(fontWeight: FontWeight.w500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FavoriteSkeleton extends StatelessWidget {
  const _FavoriteSkeleton({required this.colors});

  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 9,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// A circle drawn with a dashed outline — used for the empty "add favorite" slot.
class _DottedCircle extends StatelessWidget {
  const _DottedCircle({
    required this.size,
    required this.color,
    required this.child,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(color),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    const dashCount = 26;
    const gap = 0.32; // fraction of each segment left empty
    const sweep = 2 * 3.1415926535 / dashCount;
    for (var i = 0; i < dashCount; i++) {
      final start = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * (1 - gap),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── Services grid ──────────────────────────────────────────────────────────

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final items = <_ServiceData>[
      _ServiceData(Icons.arrow_upward_rounded, l10n.walletActionSend,
          onTap: () => context.push('/transfer/others')),
      _ServiceData(Icons.receipt_long_rounded, l10n.walletPayBills,
          onTap: () => context.push('/bills/providers')),
      _ServiceData(Icons.account_balance_rounded, l10n.walletTransferToBank,
          onTap: () => context.push('/network-transfers')),
      _ServiceData(Icons.people_alt_rounded, l10n.walletBeneficiaries,
          onTap: () => context.push('/beneficiaries')),
      _ServiceData(Icons.credit_card_rounded, l10n.serviceCards,
          onTap: () => context.push('/cards')),
      _ServiceData(Icons.wifi_rounded, l10n.walletServiceInternet,
          onTap: () => context.push('/bills/internet')),
      _ServiceData(Icons.star_rounded, l10n.walletFavorites,
          onTap: () => context.push('/favorites')),
      // Not built yet — surfaced honestly with a "coming soon" badge.
      _ServiceData(Icons.trending_up_rounded, l10n.serviceInvestmentWallet,
          comingSoon: true),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.74,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _ServiceTile(
        data: items[index],
        colors: colors,
        lang: lang,
        comingSoonLabel: l10n.walletComingSoon,
        onComingSoon: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.comingSoonToast),
            behavior: SnackBarBehavior.floating,
          ),
        ),
      ),
    );
  }
}

class _ServiceData {
  const _ServiceData(this.icon, this.label,
      {this.onTap, this.comingSoon = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool comingSoon;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.data,
    required this.colors,
    required this.lang,
    required this.comingSoonLabel,
    required this.onComingSoon,
  });

  final _ServiceData data;
  final BankSyncColors colors;
  final String lang;
  final String comingSoonLabel;
  final VoidCallback onComingSoon;

  @override
  Widget build(BuildContext context) {
    final disabled = data.comingSoon;
    return InkWell(
      onTap: disabled ? onComingSoon : data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: disabled
                        ? colors.surfaceContainerHigh
                        : colors.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    data.icon,
                    color: disabled
                        ? colors.onSurfaceVariant
                        : colors.secondary,
                    size: 24,
                  ),
                ),
                if (disabled)
                  PositionedDirectional(
                    end: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        comingSoonLabel,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14152E),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              data.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm(
                color: disabled ? colors.onSurfaceVariant : colors.onSurface,
                languageCode: lang,
              ).copyWith(
                  fontWeight: FontWeight.w600, fontSize: 10.5, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Promo banners ──────────────────────────────────────────────────────────

/// Auto-advancing promo carousel, styled in the wallet's blue identity. Content
/// reuses existing marketing strings; it is decorative and taps do nothing
/// destructive (no fake pages).
class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel({
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _index = 0;

  late final List<_PromoData> _promos = [
    _PromoData(
      icon: Icons.card_giftcard_rounded,
      title: widget.l10n.exclusiveOffers,
      subtitle: widget.l10n.cashBackSubtitle,
      colors: const [Color(0xFF2F80ED), Color(0xFF0050B3)],
    ),
    _PromoData(
      icon: Icons.flight_takeoff_rounded,
      title: widget.l10n.travelDiscountTitle,
      subtitle: widget.l10n.travelDiscountSubtitle,
      colors: const [Color(0xFF3B82F6), AppColors.navy],
    ),
    _PromoData(
      icon: Icons.savings_rounded,
      title: widget.l10n.financeCalculatorTitle,
      subtitle: widget.l10n.financeCalculatorSubtitle,
      colors: const [Color(0xFF0050B3), Color(0xFF063A80)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _promos.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: _promos.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: _PromoCard(data: _promos[i], lang: widget.lang),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _CarouselDots(
          count: _promos.length,
          active: _index,
          colors: widget.colors,
        ),
      ],
    );
  }
}

class _PromoData {
  const _PromoData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.data, required this.lang});

  final _PromoData data;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: data.colors,
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm(
                          color: Colors.white, languageCode: lang)
                      .copyWith(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm(
                    color: Colors.white.withValues(alpha: 0.85),
                    languageCode: lang,
                  ).copyWith(
                      fontWeight: FontWeight.w500, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

// ─── Recent activity ────────────────────────────────────────────────────────

class _RecentActivityList extends ConsumerWidget {
  const _RecentActivityList({
    required this.account,
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankingAccount account;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async =
        ref.watch(walletRecentActivityProvider(account.accountNoForIntegration));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: UffLoader()),
      ),
      error: (_, __) => _hint(l10n.serverUnreachableMessage),
      data: (list) {
        if (list.isEmpty) return _hint(l10n.walletNoRecentActivity);
        final items = [...list]..sort((a, b) {
            final da = DateTime.tryParse(a.bookingDate);
            final db = DateTime.tryParse(b.bookingDate);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
        final top = items.take(5).toList();
        return Column(
          children: [
            for (final txn in top) ...[
              _tile(txn),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _tile(AccountTransaction txn) {
    final credit = txn.isCredit;
    return TransactionTile(
      icon: txn.iconForType(),
      title: txn.tileTitle(),
      subtitle: txn.tileSubtitle(),
      amount: txn.formattedAmount(),
      status: txn.tileStatus(),
      amountColor: credit ? _positiveAmount : _negativeAmount,
      iconBackground: credit
          ? colors.secondary.withValues(alpha: 0.1)
          : colors.primaryContainer,
      iconColor: credit ? colors.secondary : colors.onPrimaryContainer,
      statusColor: colors.onSurfaceVariant,
      statusBackground: colors.surfaceContainer,
    );
  }

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd(
                color: colors.onSurfaceVariant, languageCode: lang),
          ),
        ),
      );
}

class _EmptyWalletState extends StatelessWidget {
  const _EmptyWalletState({
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 72, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            l10n.noAccountsFound,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd(
                color: colors.onSurfaceVariant, languageCode: lang),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/add-account'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.newAccount),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.onRetry,
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final Future<void> Function() onRetry;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            l10n.serverUnreachableMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd(
                color: colors.onSurfaceVariant, languageCode: lang),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.walletRetry),
          ),
        ],
      ),
    );
  }
}
