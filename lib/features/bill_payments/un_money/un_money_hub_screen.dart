import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/uff_ui.dart';
import '../../../l10n/app_localizations.dart';
import 'unified_network_cancel_screen.dart';
import 'unified_network_pay_screen.dart';
import 'unified_network_send_screen.dart';

/// Unified Network hub: cancel / send / pay-to-account, plus a link into the
/// existing transfers history. The 3 main tiles are pure-UI mockups (no
/// backend yet) — see `unified_network_*_screen.dart`.
class UnMoneyHubScreen extends ConsumerWidget {
  const UnMoneyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.unMoneyTitle), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BadgedServiceTile(
                  icon: Icons.block_rounded,
                  label: l10n.unifiedNetworkCancelTile,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UnifiedNetworkCancelScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: UffServiceTile(
                  icon: Icons.north_east_rounded,
                  label: l10n.unifiedNetworkSendTile,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UnifiedNetworkSendScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: UffServiceTile(
                  icon: Icons.account_balance_rounded,
                  label: l10n.unifiedNetworkPayTile,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UnifiedNetworkPayScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            child: InkWell(
              onTap: () => context.push('/bills/history'),
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppColors.radiusLg),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: colors.secondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.unMoneyHistory,
                        style: AppTextStyles.labelSm(
                          color: colors.onSurface,
                          languageCode: languageCode,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(uffForwardChevron(context), size: 14, color: colors.outline),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [UffServiceTile] with a small red "cancel" badge (circle + white X)
/// overlaid top-end — mirrors the notification-count badge pattern used in
/// `banksync_bottom_nav.dart`.
class _BadgedServiceTile extends StatelessWidget {
  const _BadgedServiceTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UffServiceTile(icon: icon, label: label, onTap: onTap),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              border: Border.all(color: colors.surfaceContainerLowest, width: 1.5),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 10),
          ),
        ),
      ],
    );
  }
}
