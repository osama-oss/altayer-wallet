import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/uff_ui.dart';

/// Amount input in the shared field language ([uffInputDecoration]): one soft
/// outline, theme surface, currency shown inside as a suffix, with a subtle
/// "Max" link beside the label. No card-in-card boxing.
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
            // Subtle "Max" link — keeps the field itself uncluttered.
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
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          textDirection: TextDirection.ltr,
          textAlign: isAr ? TextAlign.right : TextAlign.left,
          style: AppTextStyles.balanceDisplay(color: colors.onSurface)
              .copyWith(fontSize: 24, fontWeight: FontWeight.w800),
          decoration: uffInputDecoration(
            context,
            placeholder: '0.00',
            prefixIcon: Icon(Icons.payments_outlined, color: colors.outline, size: 20),
            suffixText: currency.trim().isEmpty ? null : currency.trim().toUpperCase(),
          ),
        ),
      ],
    );
  }
}
