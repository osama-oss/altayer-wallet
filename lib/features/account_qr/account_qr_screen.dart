import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/transaction_tile.dart';

class AccountQrScreen extends StatelessWidget {
  const AccountQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.secondary, colors.primaryContainer],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT ACCOUNT',
                  style: AppTextStyles.labelSm(
                    color: colors.onPrimary.withValues(alpha: 0.8),
                  ).copyWith(letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$12,850.00',
                            style: AppTextStyles.balanceDisplay(color: colors.onPrimary),
                          ),
                          Text(
                            'Main Savings • 4492',
                            style: AppTextStyles.monoLabel(
                              color: colors.onPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x3322C55E),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x4D22C55E)),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF86EFAC),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text('Scan to Pay Me', style: AppTextStyles.headlineMd()),
                const SizedBox(height: 8),
                Text(
                  'Instant P2P transfer via QR code',
                  style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.surfaceVariant),
                      ),
                      child: Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.secondary.withValues(alpha: 0.2),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: Icon(
                          Icons.qr_code_2,
                          size: 160,
                          color: colors.primary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.verified, size: 18, color: colors.onSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACCOUNT NUMBER',
                              style: AppTextStyles.monoLabel(
                                color: colors.onSurfaceVariant,
                              ).copyWith(fontSize: 10),
                            ),
                            Text(
                              '8834 • 1229 • 0049',
                              style: AppTextStyles.bodyMd(color: colors.primary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(text: '883412290049'),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account number copied')),
                          );
                        },
                        icon: Icon(Icons.content_copy, color: colors.secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text('Share Details'),
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: AppTextStyles.headlineMd()),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See All',
                  style: AppTextStyles.labelSm(color: colors.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const TransactionTile(
            icon: Icons.shopping_bag_outlined,
            title: 'Apple Store',
            subtitle: 'Today, 2:45 PM',
            amount: '- \$1,299.00',
            status: 'Pending',
          ),
          const SizedBox(height: 12),
          TransactionTile(
            icon: Icons.payments_outlined,
            title: 'Salary Deposit',
            subtitle: 'Yesterday, 9:00 AM',
            amount: '+ \$4,500.00',
            status: 'Completed',
            iconBackground: Color(0x1A316BF3),
            iconColor: colors.secondary,
            amountColor: colors.onTertiaryContainer,
            statusColor: colors.onTertiaryContainer,
            statusBackground: Color(0x334EDEA3),
          ),
          const SizedBox(height: 12),
          TransactionTile(
            icon: Icons.restaurant_outlined,
            title: 'Blue Bottle Coffee',
            subtitle: 'Mar 12, 8:15 AM',
            amount: '- \$12.50',
            status: 'Completed',
            iconBackground: Color(0x1AFFDAD6),
            iconColor: colors.error,
            statusColor: colors.onTertiaryContainer,
            statusBackground: Color(0x334EDEA3),
          ),
        ],
      ),
    );
  }
}
