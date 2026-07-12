import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models/banking_account.dart';
import '../../core/qr/account_qr_payload.dart';
import '../../core/providers/app_providers.dart';
import '../../core/security/screen_security.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/uff_loader.dart';
import '../../l10n/app_localizations.dart';
import '../home/transactions_screen.dart';
import '../kyc/kyc_providers.dart';
import '../kyc/kyc_status.dart';
import '../transfer/qr_scan_screen.dart';
import '../transfer/scan_review_screen.dart';
import 'card_qr_sheet.dart';
import 'wallet_providers.dart';

/// «Ultimate Wallet» wallet home — a streamlined multi-currency dashboard: a
/// horizontal carousel of the customer's wallets (SAR / YER / USD), an
/// organised services grid (real routes + "coming soon" placeholders) and a
/// promo banner carousel.
///
/// Every balance comes from the real UFF integrations (accountsProvider);
/// nothing here is mocked. When data is unavailable the widgets fall back to
/// loading / empty states instead of placeholder numbers.
class WalletHomeScreen extends ConsumerStatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  ConsumerState<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends ConsumerState<WalletHomeScreen> {
  // 0.87 leaves room for a clean slice of BOTH neighbouring cards to peek while
  // the active card stays centred (see [_WalletsCarousel]).
  final PageController _walletPageController =
      PageController(viewportFraction: 0.87);
  int _activeIndex = 0;

  @override
  void dispose() {
    _walletPageController.dispose();
    super.dispose();
  }

  /// Pull-to-refresh and per-card refresh both re-read the wallet balances
  /// source. The dashboard no longer shows favorites or a recent-activity
  /// preview, so only the accounts source needs invalidating.
  Future<void> _refresh() async {
    ref.invalidate(accountsProvider);
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
      body = _ErrorState(
          onRetry: _refresh, colors: colors, l10n: l10n, lang: lang);
    } else if (accounts.isEmpty) {
      body = _EmptyWalletState(colors: colors, l10n: l10n, lang: lang);
    } else {
      final activeIndex = _activeIndex.clamp(0, accounts.length - 1);
      final active = accounts[activeIndex];
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kycFeatureEnabled) _KycBanner(colors: colors, l10n: l10n),
          _SectionHeader(title: l10n.walletMyWallets, lang: lang),
          const SizedBox(height: 12),
          _WalletsCarousel(
            accounts: accounts,
            controller: _walletPageController,
            activeIndex: activeIndex,
            colors: colors,
            l10n: l10n,
            lang: lang,
            onPageChanged: (i) => setState(() => _activeIndex = i),
            onRefresh: (_) => _refresh(),
          ),
          const SizedBox(height: 12),
          _CarouselDots(
            count: accounts.length,
            active: activeIndex,
            colors: colors,
          ),
          const SizedBox(height: 26),
          _SectionHeader(title: l10n.walletServicesTitle, lang: lang),
          const SizedBox(height: 12),
          _ServicesGrid(
              account: active, colors: colors, l10n: l10n, lang: lang),
          const SizedBox(height: 26),
          _SectionHeader(title: l10n.walletPromotionsTitle, lang: lang),
          const SizedBox(height: 12),
          _PromoCarousel(colors: colors, l10n: l10n, lang: lang),
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

/// بانر أعلى الرئيسية يعكس حالة التوثيق (KYC): يظهر للعميل غير المُوثَّق أو
/// المرفوض كدعوة لإكمال/إعادة التحقق، ويظهر بشكل معلوماتي أثناء المراجعة،
/// ويختفي تماماً عند التوثيق. الحالة تُقرأ من [kycStatusProvider].
class _KycBanner extends ConsumerWidget {
  const _KycBanner({required this.colors, required this.l10n});

  final BankSyncColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(kycStatusProvider).valueOrNull?.status ??
        KycStatus.unverified;
    // Verified customers see no banner at all.
    if (status == KycStatus.verified) return const SizedBox.shrink();

    final bool pending = status == KycStatus.pending;
    final Color accent = status.color(colors);
    final String text = switch (status) {
      KycStatus.rejected => l10n.kycBannerRejectedText,
      KycStatus.returned => l10n.kycBannerReturnedText,
      KycStatus.pending => l10n.kycBannerPendingText,
      _ => l10n.kycBannerText,
    };
    final IconData leadingIcon = status.icon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: () => context.push('/kyc'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(leadingIcon, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
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
              // Actionable states (unverified / incomplete / rejected) show a
              // call to action; while under review just a chevron into status.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!pending)
                    Text(
                      l10n.kycVerifyAccount,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  Icon(
                    Directionality.of(context) == ui.TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: accent,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wallets carousel ───────────────────────────────────────────────────────

/// Horizontal carousel of the customer's wallets. The active card sits centred
/// and full-size while a clean slice of BOTH neighbours peeks on either side
/// (RTL/LTR handled automatically by [PageView]). Depth comes from a paint-only
/// scale tied to the scroll offset — never a layout resize — so a peeking card
/// can no longer overflow its box and bleed a stray coloured sliver at the edge.
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
    // A lone wallet needs no peek/scroll — render it flush. Its rounded clip
    // lives inside [_WalletCard], so the edges stay crisp here too.
    if (accounts.length == 1) {
      return SizedBox(
        height: 188,
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
      height: 188,
      child: PageView.builder(
        controller: controller,
        // padEnds:true (the default) keeps every page centred in the viewport,
        // so the active card is centred and both neighbours peek symmetrically.
        onPageChanged: onPageChanged,
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          return _WalletCardSlide(
            controller: controller,
            index: index,
            fallbackPage: activeIndex.toDouble(),
            child: _WalletCard(
              account: accounts[index],
              active: index == activeIndex,
              colors: colors,
              l10n: l10n,
              lang: lang,
              onRefresh: onRefresh,
            ),
          );
        },
      ),
    );
  }
}

/// Positions one wallet card inside the carousel. A fixed 6px gutter on each
/// side forms the clean gap between cards, and a scale driven continuously by
/// the [PageController]'s scroll offset lets the centred card grow to full size
/// while its neighbours recede. The scale is a paint-only [Transform] — it never
/// changes the card's layout box, so the card can never be squeezed below its
/// content height and trip the overflow indicator (the yellow/black hazard
/// stripes that used to leak from the peeking card while swiping).
class _WalletCardSlide extends StatelessWidget {
  const _WalletCardSlide({
    required this.controller,
    required this.index,
    required this.fallbackPage,
    required this.child,
  });

  final PageController controller;
  final int index;

  /// Page value to assume before the controller is attached to the viewport
  /// (so the very first frame already scales the settled card correctly).
  final double fallbackPage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          final page = controller.hasClients
              ? (controller.page ?? fallbackPage)
              : fallbackPage;
          // t: 1 when this card is dead-centre, 0 when a full page away.
          final t = (1.0 - (page - index).abs()).clamp(0.0, 1.0);
          final scale = 0.92 + 0.08 * t; // recedes to 0.92, grows to 1.0
          return Transform.scale(scale: scale, child: child);
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
      // Clip content to the rounded rect so nothing paints past the card's
      // corners — crisp edges, no leaked pixels. The drop shadow paints behind
      // and is unaffected by the child clip.
      clipBehavior: Clip.antiAlias,
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
              const SizedBox(width: 10),
              // Per-card receive QR — a soft white tile that never crowds the
              // balance / number; tap opens the large QR sheet (share/save/copy).
              _MiniCardQr(account: account),
            ],
          ),
        ],
      ),
    );
  }
}

/// This card's own account QR, integrated into the card as a soft frosted-glass
/// tile rather than a pasted-on white sticker. Tapping opens the full receive-QR
/// sheet for the same account.
///
/// Colours come entirely from the design system's on-card glass tokens
/// ([BankSyncColors.glassPanelFill] / [glassPanelBorder]) plus [onSurface] for
/// the modules — nothing hardcoded. Because the tokens flip with the active
/// theme (light frost + dark ink in light mode; dark frost + light ink in dark
/// mode), the QR keeps strong module/background contrast — and stays
/// scannable — automatically in both themes, while the panel's translucency
/// lets the card gradient bleed through so it belongs to the card.
class _MiniCardQr extends StatelessWidget {
  const _MiniCardQr({required this.account});

  final BankingAccount account;

  // Tile geometry. The code itself is 40px; the surrounding [_quietZone] frost
  // is the QR quiet zone (~4 modules for a compact account payload), so the
  // camera keeps a clean margin even though there is no white box.
  static const double _codeSize = 40;
  static const double _quietZone = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;

    final data = AccountQrPayload(
      accountNumber: account.accountNumber,
      currency: account.currency,
      label: account.label,
    ).encode();

    // Panel = translucent glass (theme-driven), modules = onSurface so they read
    // dark on the light frost and light on the dark frost. The modules paint on
    // a transparent QR background, letting the glass fill serve as one uniform
    // quiet zone between and around them.
    final moduleColor = colors.onSurface;

    return Semantics(
      button: true,
      label: l10n.walletActionReceive,
      child: InkWell(
        onTap: () => showCardQrSheet(context, account),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(_quietZone),
          decoration: BoxDecoration(
            color: colors.glassPanelFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.glassPanelBorder, width: 1),
          ),
          child: SizedBox(
            width: _codeSize,
            height: _codeSize,
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: moduleColor,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: moduleColor,
              ),
            ),
          ),
        ),
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
            : Icon(icon, color: Colors.white.withValues(alpha: 0.95), size: 17),
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

// ─── Services grid ──────────────────────────────────────────────────────────

/// One service tile in the reorganised "الخدمات" grid. A tile either navigates
/// to a real route, opens a grouped [showServiceOptionsSheet] for its
/// sub-services, or is surfaced honestly as [comingSoon]. The [onTap] closure
/// encodes whichever behaviour applies; [comingSoon] only drives the badge.
class _ServiceData {
  const _ServiceData({
    required this.svg,
    required this.label,
    required this.onTap,
    this.comingSoon = false,
  });

  /// Path to this service's colourful, self-tinted SVG under assets/icons.
  /// The glyph carries its own brand colours (no ColorFilter), so a single
  /// asset reads correctly on both the light and dark tile surfaces.
  final String svg;
  final String label;
  final VoidCallback onTap;
  final bool comingSoon;
}

/// The reorganised "الخدمات" area — a single, balanced 3-per-row grid of the
/// primary wallet services. Services with sub-actions open a grouped bottom
/// sheet (same chrome as the rest of the app); not-yet-built ones open the
/// shared "coming soon" sheet. Real services keep their existing routes — no
/// new backend or fake data.
class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({
    required this.account,
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankingAccount account;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  // Cohesive on-brand accents for the sub-service bottom sheets (the grid tiles
  // themselves now use self-coloured SVG glyphs). Blue/green are theme-aware so
  // they stay legible in dark mode; the sky is a fixed brand tint.
  Color get _blue => colors.secondary;
  Color get _green => colors.success;
  Color get _sky => AppColors.walletBrandAlt;

  /// Same behaviour as the home "scan" quick-action: scan an account QR, then
  /// always land on the review screen (never a silent transfer).
  Future<void> _scanAndReview(BuildContext context) async {
    final acct = await openQrScanScreen(context);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ScanReviewScreen(account: acct)),
    );
  }

  void _openTransfers(BuildContext context) {
    showServiceOptionsSheet(
      context,
      title: l10n.svcMoneyTransfers,
      icon: Icons.swap_horiz_rounded,
      options: [
        ServiceSheetOption(
          icon: Icons.send_rounded,
          title: l10n.svcTransferToSubscriber,
          subtitle: l10n.svcTransferToSubscriberDesc,
          accent: _blue,
          onTap: () => context.push('/transfer/others'),
        ),
        ServiceSheetOption(
          icon: Icons.currency_exchange_rounded,
          title: l10n.svcExchange,
          subtitle: l10n.svcExchangeDesc,
          accent: _green,
          // Currency exchange = a transfer between the customer's own accounts
          // in different currencies (the "إلى حساباتي" screen handles the FX).
          onTap: () => context.push('/transfer/own'),
        ),
      ],
    );
  }

  void _openRechargePay(BuildContext context) {
    showServiceOptionsSheet(
      context,
      title: l10n.svcRechargeAndPay,
      icon: Icons.bolt_rounded,
      options: [
        ServiceSheetOption(
          icon: Icons.receipt_long_rounded,
          title: l10n.svcPayBillsFull,
          subtitle: l10n.svcPayBillsDesc,
          accent: _blue,
          onTap: () => context.push('/bills/providers'),
        ),
        ServiceSheetOption(
          icon: Icons.smartphone_rounded,
          title: l10n.svcRechargeBalance,
          subtitle: l10n.svcRechargeBalanceDesc,
          accent: _green,
          onTap: () => context.push('/bills/telecom'),
        ),
      ],
    );
  }

  void _openPurchases(BuildContext context) {
    showServiceOptionsSheet(
      context,
      title: l10n.svcPurchasePayment,
      icon: Icons.shopping_bag_rounded,
      options: [
        ServiceSheetOption(
          icon: Icons.storefront_rounded,
          title: l10n.svcPayMerchant,
          subtitle: l10n.svcPayMerchantDesc,
          accent: _blue,
          onTap: () => context.push('/merchant-payment'),
        ),
        ServiceSheetOption(
          icon: Icons.qr_code_scanner_rounded,
          title: l10n.svcScanToPay,
          subtitle: l10n.svcScanToPayDesc,
          accent: _green,
          onTap: () => _scanAndReview(context),
        ),
        ServiceSheetOption(
          icon: Icons.star_rounded,
          title: l10n.svcFavoriteMerchants,
          subtitle: l10n.svcFavoriteMerchantsDesc,
          accent: _sky,
          onTap: () => context.push('/favorite-merchants'),
        ),
      ],
    );
  }

  List<_ServiceData> _services(BuildContext context) => [
        _ServiceData(
          svg: 'assets/icons/ic_svc_transfers.svg',
          label: l10n.svcMoneyTransfers,
          onTap: () => _openTransfers(context),
        ),
        _ServiceData(
          svg: 'assets/icons/ic_svc_withdraw.svg',
          label: l10n.svcWithdrawFunds,
          comingSoon: true,
          onTap: () => showComingSoonSheet(
            context,
            serviceName: l10n.svcWithdrawFunds,
            description: l10n.svcCashWithdrawalDesc,
            icon: Icons.payments_rounded,
          ),
        ),
        _ServiceData(
          svg: 'assets/icons/ic_svc_recharge.svg',
          label: l10n.svcRechargeAndPay,
          onTap: () => _openRechargePay(context),
        ),
        _ServiceData(
          svg: 'assets/icons/ic_svc_purchases.svg',
          label: l10n.svcPurchasePayment,
          onTap: () => _openPurchases(context),
        ),
        _ServiceData(
          svg: 'assets/icons/ic_svc_banks.svg',
          label: l10n.svcOtherBanksWallets,
          comingSoon: true,
          onTap: () => showComingSoonSheet(
            context,
            serviceName: l10n.svcOtherBanksWallets,
            description: l10n.svcOtherBanksWalletsDesc,
            icon: Icons.account_balance_rounded,
          ),
        ),
        _ServiceData(
          svg: 'assets/icons/ic_svc_internet.svg',
          label: l10n.svcInternetCards,
          comingSoon: true,
          onTap: () => showComingSoonSheet(
            context,
            serviceName: l10n.svcInternetCards,
            description: l10n.svcInternetCardsDesc,
            icon: Icons.sim_card_rounded,
          ),
        ),
        _ServiceData(
          svg: 'assets/icons/ic_svc_favorites.svg',
          label: l10n.walletFavorites,
          onTap: () => context.push('/favorites'),
        ),
        _ServiceData(
          svg: 'assets/icons/ic_svc_recent.svg',
          label: l10n.walletRecentActivity,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  SecureScreen(child: TransactionsScreen(account: account)),
            ),
          ),
        ),
        // 9th service — completes the balanced 3×3 grid. Agents & service
        // points (nearest cash-in/out locations) is served by the core and
        // wired later; until then the tile behaves exactly like the other
        // not-yet-built services — it opens the shared "coming soon" sheet
        // (same chrome as Internet Cards) rather than a placeholder page.
        _ServiceData(
          svg: 'assets/icons/ic_svc_agents.svg',
          label: l10n.svcServicePoints,
          comingSoon: true,
          onTap: () => showComingSoonSheet(
            context,
            serviceName: l10n.svcServicePoints,
            description: l10n.svcServicePointsDesc,
            icon: Icons.support_agent_rounded,
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final services = _services(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        // Fixed row height (not aspect-ratio) keeps every tile identical across
        // screen widths. Tightened from the old boxed layout: the bare icon +
        // reserved two-line label block sits centred inside this height, so the
        // grid reads compact and precisely aligned without label overflow.
        mainAxisExtent: 100,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) => _ServiceTile(
        data: services[index],
        colors: colors,
        lang: lang,
        comingSoonLabel: l10n.walletComingSoon,
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.data,
    required this.colors,
    required this.lang,
    required this.comingSoonLabel,
  });

  final _ServiceData data;
  final BankSyncColors colors;
  final String lang;
  final String comingSoonLabel;

  @override
  Widget build(BuildContext context) {
    final soon = data.comingSoon;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
        // A single, very soft lift — enough to separate the tile from the page
        // without the heavy "template card" drop shadow.
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: data.onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // No tinted tile behind the glyph: the colourful SVG is the
                    // card's primary element, sized up so it reads clearly on
                    // the bare surface. Each glyph carries its own brand colours
                    // (no ColorFilter) and stays full-colour even for "coming
                    // soon" services — the corner badge alone carries that status.
                    SvgPicture.asset(data.svg, width: 34, height: 34),
                    const SizedBox(height: 10),
                    // Fixed two-line label region. Because its height is
                    // constant, the icon above always lands at the same Y and
                    // the icon→label gap is identical on every tile, whether the
                    // label is one line (most Arabic) or two (longer strings).
                    // The text top-aligns inside it, so that gap never drifts.
                    SizedBox(
                      height: 30,
                      width: double.infinity,
                      child: Text(
                        data.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSm(
                          color: colors.onSurface,
                          languageCode: lang,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (soon)
                PositionedDirectional(
                  top: 7,
                  end: 7,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  late final List<_PromoData> _promos = const [
    _PromoData(
      imagePath: 'assets/promos/Picture1.png',
      aspectRatio: 1017 / 233,
    ),
    _PromoData(
      imagePath: 'assets/promos/Picture2.png',
      aspectRatio: 1017 / 207,
    ),
    _PromoData(
      imagePath: 'assets/promos/Picture3.png',
      aspectRatio: 1017 / 207,
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
        AspectRatio(
          // Average aspect ratio of the images (~4.73) divided by 0.92 viewport fraction = 5.14
          aspectRatio: 5.14,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: _promos.length,
            itemBuilder: (context, i) {
              return _PromoCardSlide(
                controller: _controller,
                index: i,
                fallbackPage: _index.toDouble(),
                child: _PromoCard(data: _promos[i]),
              );
            },
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
    required this.imagePath,
    required this.aspectRatio,
  });

  final String imagePath;
  final double aspectRatio;
}

class _PromoCardSlide extends StatelessWidget {
  const _PromoCardSlide({
    required this.controller,
    required this.index,
    required this.fallbackPage,
    required this.child,
  });

  final PageController controller;
  final int index;
  final double fallbackPage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final page = controller.hasClients
            ? (controller.page ?? fallbackPage)
            : fallbackPage;
        // Continuous scale transition driving professional slide scaling
        final t = (1.0 - (page - index).abs()).clamp(0.0, 1.0);
        final scale = 0.94 + 0.06 * t; // scales between 0.94 and 1.0
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.data});

  final _PromoData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        // Modern premium soft shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          data.imagePath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
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
          Icon(Icons.cloud_off_rounded,
              size: 64, color: colors.onSurfaceVariant),
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
