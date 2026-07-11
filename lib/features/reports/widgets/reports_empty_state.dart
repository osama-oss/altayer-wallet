import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Centred "no items" placeholder shown when the active tab + filter yield an
/// empty ledger — the Ultimate Wallet counterpart of the reference «لا توجد
/// عناصر» state.
class ReportsEmptyState extends StatelessWidget {
  const ReportsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 38,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.reportsEmpty,
            style: AppTextStyles.bodyMd(
              color: colors.onSurfaceVariant,
              languageCode: lang,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
