import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:banksync_app/core/widgets/phosphor_icons_bold.dart';

import '../../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../theme/app_text_styles.dart';
import '../theme/bank_sync_colors.dart';

enum BankSyncTab { home, transfers, payments, explore }

final dashboardTabProvider = StateProvider<BankSyncTab>((ref) => BankSyncTab.home);

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
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              svgName: 'ic_home',
              label: l10n.navHome,
              selected: currentTab == BankSyncTab.home,
              onTap: () => onTabSelected(BankSyncTab.home),
            ),
            _NavItem(
              svgName: 'ic_swap',
              label: l10n.navTransfers,
              selected: currentTab == BankSyncTab.transfers,
              onTap: () => onTabSelected(BankSyncTab.transfers),
            ),
            _NavItem(
              svgName: 'ic_wallet',
              label: l10n.navPayments,
              selected: currentTab == BankSyncTab.payments,
              onTap: () => onTabSelected(BankSyncTab.payments),
            ),
            _NavItem(
              svgName: 'ic_transfer_settings',
              label: l10n.navExplore,
              selected: currentTab == BankSyncTab.explore,
              onTap: () => onTabSelected(BankSyncTab.explore),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.svgName,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String svgName;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    final nonSelectedColor = colors.onSurfaceVariant.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/${svgName}_$suffix.svg',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      selected ? colors.secondary : nonSelectedColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm(
                  color: selected ? colors.secondary : nonSelectedColor,
                  languageCode: languageCode,
                ).copyWith(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
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
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isObscured = ref.watch(dashboardObscuredProvider);
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';

    // To prevent layout breakage on subpages, if centerTitle is set, render standard header
    if (centerTitle != null) {
      return Container(
        height: 64,
        color: colors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (leading != null)
              leading!
            else
              const SizedBox(width: 40),
            Expanded(
              child: Text(
                centerTitle!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineMd(color: colors.primary, languageCode: languageCode)
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Centered «عَ الطاير» wordmark
          Align(
            alignment: Alignment.center,
            child: Text(
              'عَ الطاير',
              style: AppTextStyles.headlineMd(
                color: colors.secondary,
                languageCode: languageCode,
              ).copyWith(fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ),
          
          // 2. Row with actions on left and avatar/login on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Actions (Notifications, Search)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NotificationBellIcon(colors: colors),
                ],
              ),

              // Right side: Avatar widget (Screen A Login vs Screen B points)
              if (showAvatar)
                isObscured
                    ? InkWell(
                        onTap: () {
                          ref.read(dashboardObscuredProvider.notifier).state = false;
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.secondary.withValues(alpha: 0.15),
                                colors.secondary.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.secondary.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.secondary.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.clickToAccess,
                                style: AppTextStyles.labelSm(color: colors.secondary, languageCode: languageCode)
                                    .copyWith(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.2),
                              ),
                              const SizedBox(width: 6),
                              SvgPicture.asset(
                                'assets/icons/ic_fingerprint_$suffix.svg',
                                width: 18,
                                height: 18,
                              ),
                            ],
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: () => ref.read(dashboardTabProvider.notifier).state =
                            BankSyncTab.explore,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.secondary.withValues(alpha: 0.1),
                            border: Border.all(color: colors.outlineVariant, width: 1.5),
                          ),
                          child: Icon(Icons.person_rounded, color: colors.secondary, size: 20),
                        ),
                      )
              else
                const SizedBox(width: 40),
            ],
          ),
        ],
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
  ConsumerState<_NotificationBellIcon> createState() => _NotificationBellIconState();
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
      final count = await ref.read(notificationRepositoryProvider).getUnreadCount();
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
