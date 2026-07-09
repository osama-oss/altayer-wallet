import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/uff_loader.dart';

class TransferPrimaryButton extends StatelessWidget {
  const TransferPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.secondary,
          foregroundColor: colors.onSecondary,
          disabledBackgroundColor: colors.secondary.withValues(alpha: 0.45),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: UffLoader(size: 20, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTextStyles.labelSm(color: colors.onSecondary)),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

