import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';

/// «الوكلاء ونقاط الخدمة» — Agents & Service Points.
///
/// The agent / service-point network (find the nearest cash-in / cash-out
/// point on a map) is served by the core and will be wired later, same as the
/// rest of the wallet. Until then this is an honest, on-brand "coming soon"
/// page — no mock locations — reachable from the home services grid so the
/// service already has its own destination.
class ServicePointsScreen extends StatelessWidget {
  const ServicePointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.svcServicePoints), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.support_agent_rounded,
                      size: 50, color: colors.secondary),
                ),
                const SizedBox(height: 22),
                // "قريبًا" badge — same warm accent as the grid / sheet badges.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  ),
                  child: Text(
                    l10n.walletComingSoon,
                    style: AppTextStyles.labelSm(
                      color: const Color(0xFF9A6B00),
                      languageCode: lang,
                    ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.svcServicePoints,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMd(
                    color: colors.onSurface,
                    languageCode: lang,
                  ).copyWith(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.svcServicePointsDesc,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd(
                    color: colors.onSurfaceVariant,
                    languageCode: lang,
                  ).copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
