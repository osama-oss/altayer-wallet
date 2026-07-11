import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../data/report_models.dart';

/// A single reports-ledger row, styled in the Ultimate Wallet card idiom:
/// a directional leading icon, the counterparty + date, and a colour-coded
/// signed amount (green in, red out, muted for fees).
class ReportEntryTile extends StatelessWidget {
  const ReportEntryTile({super.key, required this.entry, this.onTap});

  final ReportEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;

    final (iconData, accent) = switch (entry.direction) {
      ReportDirection.received => (Icons.south_west_rounded, colors.success),
      ReportDirection.sent => (Icons.north_east_rounded, colors.error),
      ReportDirection.fees => (Icons.receipt_long_rounded, AppColors.warning),
      ReportDirection.all => (Icons.swap_horiz_rounded, colors.secondary),
    };
    final amountColor = switch (entry.direction) {
      ReportDirection.received => colors.success,
      ReportDirection.fees => colors.onSurfaceVariant,
      _ => colors.error,
    };

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, color: accent, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm(
                        color: colors.onSurface,
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.formattedDate(),
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm(
                        color: colors.onSurfaceVariant,
                        languageCode: lang,
                      ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                entry.formattedAmount(),
                textDirection: TextDirection.ltr,
                style: AppTextStyles.monoLabel(color: amountColor)
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
