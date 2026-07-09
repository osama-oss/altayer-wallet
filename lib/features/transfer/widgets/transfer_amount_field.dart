import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';

/// Light, airy amount card: a clean amount + currency pill, with the "Max"
/// shortcut moved up to a subtle link beside the label (nothing inside the
/// card but the number itself).
class TransferAmountField extends StatelessWidget {
  const TransferAmountField({
    super.key,
    required this.controller,
    required this.currency,
    required this.onMax,
    this.label,
  });

  final TextEditingController controller;
  final String currency;
  final VoidCallback onMax;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label ?? (isAr ? 'المبلغ المراد تحويله' : 'Amount to transfer'),
                style: AppTextStyles.labelSm(
                  color: colors.onSurfaceVariant,
                  languageCode: lang,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            // Subtle "Max" link — keeps the card itself uncluttered.
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onMax,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: colors.secondary),
                      const SizedBox(width: 3),
                      Text(
                        isAr ? 'الحد الأقصى' : 'Max',
                        style: AppTextStyles.labelSm(
                          color: colors.secondary,
                          languageCode: lang,
                        ).copyWith(fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currency,
                  style: AppTextStyles.labelSm(color: colors.secondary, languageCode: lang)
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  textDirection: TextDirection.ltr,
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: AppTextStyles.balanceDisplay(color: colors.onSurface)
                      .copyWith(fontSize: 30, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: AppTextStyles.balanceDisplay(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.25),
                    ).copyWith(fontSize: 30, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
