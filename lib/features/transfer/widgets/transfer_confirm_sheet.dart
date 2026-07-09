import 'package:flutter/material.dart';

import '../../../core/security/screen_security.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../transfer_helpers.dart';

/// Floating bottom card — user confirms here, then PIN sheet opens separately.
Future<bool> showTransferConfirmSheet(
  BuildContext context, {
  required String amount,
  required String currency,
  required List<(String label, String value)> rows,
  Map<String, dynamic>? validation,
}) async {
  // Temporarily lift FLAG_SECURE so customer can screenshot the confirmation
  await ScreenSecurity.instance.release();
  try {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransferConfirmSheet(
        amount: amount,
        currency: currency,
        rows: rows,
        validation: validation,
      ),
    );
    return result == true;
  } finally {
    // Re-acquire FLAG_SECURE
    await ScreenSecurity.instance.acquire();
  }
}

class _TransferConfirmSheet extends StatelessWidget {
  const _TransferConfirmSheet({
    required this.amount,
    required this.currency,
    required this.rows,
    this.validation,
  });

  final String amount;
  final String currency;
  final List<(String, String)> rows;
  final Map<String, dynamic>? validation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final validationRows = labeledValidationRows(validation);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.confirmTransfer, style: AppTextStyles.headlineMd(
                      languageCode: Localizations.localeOf(context).languageCode,
                    )),
                    const SizedBox(height: 16),
                    Text(
                      amount,
                      style: AppTextStyles.balanceDisplay(color: colors.secondary)
                          .copyWith(fontSize: 36),
                    ),
                    Text(
                      currency,
                      style: AppTextStyles.labelSm(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppColors.radiusMd),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < rows.length; i++) ...[
                              if (i > 0) const Divider(height: 20),
                              _ConfirmRow(label: rows[i].$1, value: rows[i].$2),
                            ],
                          ],
                        ),
                      ),
                      if (validationRows.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.validationDetails,
                          style: AppTextStyles.labelSm(
                            color: colors.onSurfaceVariant,
                            languageCode: Localizations.localeOf(context).languageCode,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.secondaryFixed.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(AppColors.radiusMd),
                            border: Border.all(
                              color: colors.secondary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < validationRows.length; i++) ...[
                                if (i > 0) const Divider(height: 16),
                                _ConfirmRow(
                                  label: validationRows[i].$1,
                                  value: validationRows[i].$2,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.secondary,
                          foregroundColor: colors.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(l10n.confirmTransfer),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        l10n.editDetails,
                        style: AppTextStyles.labelSm(
                          color: colors.onSurfaceVariant,
                          languageCode: Localizations.localeOf(context).languageCode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyles.labelSm(color: colors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.monoLabel(color: colors.primary).copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
