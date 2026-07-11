import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:banksync_app/core/widgets/phosphor_icons_bold.dart';
import 'brand_logo.dart';

import '../../features/transfer/qr_scan_screen.dart';
import '../../features/transfer/scan_review_screen.dart';
import '../../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/bank_sync_colors.dart';

enum BankSyncTab { home, transfers, reports, explore }

final dashboardTabProvider =
    StateProvider<BankSyncTab>((ref) => BankSyncTab.home);

/// Diameter of the floating centre scan action, and how far it lifts above the
/// bar's top edge. Kept in sync so the button reads as "partially outside" the
/// bar (a floating action) without exaggeration.
const double _kFabSize = 62;
const double _kFabOverhang = 26;

class BankSyncBottomNav extends StatelessWidget {
  const BankSyncBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final BankSyncTab currentTab;
  final ValueChanged<BankSyncTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    // Elegant white bar with softly rounded top corners. The four tabs sit
    // 2 + 2 around an empty centre slot; the raised scan action floats over it.
    // Labels share one baseline (crossAxisAlignment.end) so every icon sits
    // directly above its label.
    final bar = Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_rounded,
                label: l10n.navHome,
                selected: currentTab == BankSyncTab.home,
                onTap: () => onTabSelected(BankSyncTab.home),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.swap_horiz_rounded,
                label: l10n.navTransfers,
                selected: currentTab == BankSyncTab.transfers,
                onTap: () => onTabSelected(BankSyncTab.transfers),
              ),
            ),
            // Reserved slot beneath the floating centre action.
            const Expanded(child: SizedBox()),
            Expanded(
              child: _NavItem(
                icon: Icons.bar_chart_rounded,
                label: l10n.navReports,
                selected: currentTab == BankSyncTab.reports,
                onTap: () => onTabSelected(BankSyncTab.reports),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.settings_rounded,
                label: l10n.navExplore,
                selected: currentTab == BankSyncTab.explore,
                onTap: () => onTabSelected(BankSyncTab.explore),
              ),
            ),
          ],
        ),
      ),
    );

    // The centre button rises `_kFabOverhang` above the bar's top edge for a
    // floating-action look, yet stays within the widget's own bounds (top: 0)
    // so the whole button remains tappable and nothing is clipped. A partially
    // Positioned child (only `top`) is centred horizontally by the Stack's
    // alignment, so it lands over the reserved centre slot.
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _kFabOverhang),
          child: bar,
        ),
        const Positioned(top: 0, child: _ScanFab()),
      ],
    );
  }
}

/// Raised central action — the most prominent element in the bar, in Ultimate
/// Wallet blue. A larger circular button that floats above the bar's top edge
/// (see [_kFabOverhang]) with a soft professional shadow and a bar-coloured ring
/// so it reads as "lifted out" of the bar in both light and dark themes. Opens
/// the QR scanner and, on a valid account QR, routes into the transfer flow
/// (same behaviour as the home quick-action).
class _ScanFab extends StatelessWidget {
  const _ScanFab();

  Future<void> _scanAndPay(BuildContext context) async {
    final acct = await openQrScanScreen(context);
    if (!context.mounted) return;
    // Scanning never transfers directly — always land on the review screen.
    // A successful scan pre-fills the account; backing out without scanning
    // opens the same screen empty for manual entry.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanReviewScreen(account: acct),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;

    return Semantics(
      button: true,
      label: context.l10n.scanQr,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkResponse(
          onTap: () => _scanAndPay(context),
          radius: _kFabSize / 2,
          child: Container(
            width: _kFabSize,
            height: _kFabSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
              // Ring in the bar's own colour so the button looks cut out of and
              // lifted above the bar; the light halo shows only where it floats.
              border: Border.all(
                color: colors.surfaceContainerLowest,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.secondary.withValues(alpha: 0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 27,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Selected → Ultimate Wallet identity blue. Unselected → a calm, clearly
    // readable slate (not a washed-out grey), keeping the set unified.
    final activeColor = colors.secondary;
    final idleColor = isDark ? colors.onSurfaceVariant : AppColors.inkMuted;
    final iconColor = selected ? activeColor : idleColor;

    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 44,
        containedInkWell: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Reference idea: the active tab lifts into a soft rounded pill
              // in the brand blue; idle tabs stay flat and quiet.
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 56,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm(
                  color: iconColor,
                  languageCode: languageCode,
                ).copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BankSyncTopBar extends ConsumerWidget {
  const BankSyncTopBar({
    super.key,
    this.title = 'UBS',
    this.showAvatar = true,
    this.leading,
    this.centerTitle,
    this.showTrailing = true,
  });

  final String title;
  final bool showAvatar;
  final Widget? leading;
  final String? centerTitle;
  final bool showTrailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;

    // To prevent layout breakage on subpages, if centerTitle is set, render standard header
    if (centerTitle != null) {
      return Container(
        height: 64,
        color: colors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (leading != null) leading! else const SizedBox(width: 40),
            Expanded(
              child: Text(
                centerTitle!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineMd(
                        color: colors.primary, languageCode: languageCode)
                    .copyWith(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      );
    }

    return Container(
      height: 64,
      color: colors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // Physical-edge alignment (not directional) so the profile icon always
      // sits on the far left and notifications on the far right, and the logo
      // stays at the *true* screen centre — regardless of RTL / LTR and of the
      // icons' differing widths (e.g. the notification badge).
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centre: brand logo (true screen centre).
          const Align(
            alignment: Alignment.center,
            child: BrandLogo(height: 38),
          ),

          // Far left: profile / account (user + QR) → Profile screen.
          if (showAvatar)
            Align(
              alignment: Alignment.centerLeft,
              child: _ProfileQrButton(colors: colors),
            ),

          // Far right: notifications.
          Align(
            alignment: Alignment.centerRight,
            child: _NotificationBellIcon(colors: colors),
          ),
        ],
      ),
    );
  }
}

/// Compact profile action for the home header — a clean circular button with a
/// very-light-blue fill and a clear blue user glyph, drawn in the wallet's blue
/// identity and visually balanced with the notification bell on the far side.
/// Tapping opens the Profile screen.
class _ProfileQrButton extends StatelessWidget {
  const _ProfileQrButton({required this.colors});

  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () => context.push('/profile'),
      radius: 26,
      containedInkWell: false,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondaryFixed,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.secondary.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child:
                Icon(Icons.person_rounded, size: 22, color: colors.secondary),
          ),
        ),
      ),
    );
  }
}

/// Bell icon with a dynamic unread-count badge.
///
/// Reads [unreadNotificationCountProvider] and fetches the initial count
/// from the API when the widget first appears.
class _NotificationBellIcon extends ConsumerStatefulWidget {
  const _NotificationBellIcon({required this.colors});
  final BankSyncColors colors;

  @override
  ConsumerState<_NotificationBellIcon> createState() =>
      _NotificationBellIconState();
}

class _NotificationBellIconState extends ConsumerState<_NotificationBellIcon> {
  @override
  void initState() {
    super.initState();
    // Fetch the initial unread count once after the widget mounts.
    Future.microtask(_fetchUnreadCount);
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count =
          await ref.read(notificationRepositoryProvider).getUnreadCount();
      if (mounted) {
        ref.read(unreadNotificationCountProvider.notifier).state = count;
      }
    } catch (_) {
      // Silently ignore — badge will show 0 until next successful fetch.
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(unreadNotificationCountProvider);
    final colors = widget.colors;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(PhosphorIconsBold.bell, size: 24),
          onPressed: () => context.push('/notifications'),
          color: colors.primary,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.background, width: 1.5),
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
