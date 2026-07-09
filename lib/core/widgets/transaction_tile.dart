import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/bank_sync_colors.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    this.iconColor,
    this.iconBackground,
    this.amountColor,
    this.statusColor,
    this.statusBackground,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final Color? iconColor;
  final Color? iconBackground;
  final Color? amountColor;
  final Color? statusColor;
  final Color? statusBackground;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground ?? colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMd(color: colors.primary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSm(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyles.monoLabel(color: amountColor ?? colors.primary)
                    .copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBackground ?? colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor ?? colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
