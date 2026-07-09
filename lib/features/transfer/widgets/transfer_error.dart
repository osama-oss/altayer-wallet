import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';

Future<void> showTransferErrorNotice(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: _TransferErrorCard(message: message),
    ),
  );
}

class _TransferErrorCard extends StatelessWidget {
  const _TransferErrorCard({required this.message});

  final String message;

  List<String> get _lines =>
      message.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    final colors = context.bankColors;

    return Material(
      color: colors.surfaceContainerLowest,
      elevation: 8,
      shadowColor: colors.error.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: colors.error, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Transfer failed',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd(color: colors.onSurface),
            ),
            const SizedBox(height: 12),
            if (lines.length == 1)
              Text(
                lines.first,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant).copyWith(
                  height: 1.45,
                ),
              )
            else
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Icon(Icons.circle, size: 6, color: colors.error),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          line,
                          style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant).copyWith(
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.secondary,
                  foregroundColor: colors.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text('Got it', style: AppTextStyles.labelSm(color: colors.onSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
