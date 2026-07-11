import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/screen_security.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import '../accounts/all_accounts_screen.dart';
import '../bill_payments/biller_list_screen.dart';
import '../bill_payments/telecom_payment_screen.dart';
import '../transfer/recent_transfers_screen.dart';

/// Transfer hub landing — the "Transfers" tab inside the main shell.
///
/// Two hero actions (new beneficiary / transfer) followed by the main 2x3
/// services grid (moved here from the home dashboard) and a recent-transfers
/// shortcut.
class TransferHubScreen extends StatelessWidget {
  const TransferHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero actions
          Row(
            children: [
              UffHeroAction(
                filled: true,
                svgName: 'ic_person_add',
                label: l10n.btnNewBeneficiary,
                onTap: () => context.push('/beneficiaries/add'),
              ),
              const SizedBox(width: 12),
              UffHeroAction(
                svgName: 'ic_transfer_cash',
                label: l10n.navTransfers,
                onTap: () => context.push('/transfer'),
              ),
            ],
          ),
          const SizedBox(height: 26),
          UffSectionLabel(label: l10n.servicesLabel),
          const SizedBox(height: 16),
          // 3-per-row Services Grid: main 6 (moved from the home dashboard)
          // followed by the 6 transfer-hub-specific services.
          _ServicesGrid(
            l10n: l10n,
            languageCode: languageCode,
            colors: colors,
            onTap: (serviceIndex) {
              // Grid Item Index Mapping:
              // 0 -> Accounts (My Accounts screen)
              // 1 -> Cards (My Cards screen)
              // 2 -> Bills (Switch to payments tab)
              // 3 -> Offers (Show bottom sheet)
              // 4 -> Finance (Show eligibility modal)
              // 5 -> Favorites
              // 6 -> Standing Orders (coming soon)
              // 7 -> Beneficiaries
              // 8 -> Charity (coming soon)
              // 9 -> Network Transfers
              // 10 -> Send Gift (coming soon)
              if (serviceIndex == 0) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const UnsecureScreen(child: AllAccountsScreen()),
                  ),
                );
              } else if (serviceIndex == 1) {
                context.push('/cards');
              } else if (serviceIndex == 2) {
                _showBillPaymentsSheet(context, colors, languageCode);
              } else if (serviceIndex == 3) {
                _showOffersBottomSheet(context, colors, languageCode);
              } else if (serviceIndex == 4) {
                _showFinanceEligibilityDialog(context, colors, languageCode);
              } else if (serviceIndex == 5) {
                context.push('/favorites');
              } else if (serviceIndex == 6) {
                showComingSoonSheet(context,
                    serviceName: l10n.serviceStandingOrders,
                    icon: Icons.event_repeat_rounded);
              } else if (serviceIndex == 7) {
                context.push('/beneficiaries');
              } else if (serviceIndex == 8) {
                showComingSoonSheet(context,
                    serviceName: l10n.serviceCharity,
                    icon: Icons.volunteer_activism_rounded);
              } else if (serviceIndex == 9) {
                context.push('/network-transfers');
              } else if (serviceIndex == 10) {
                showComingSoonSheet(context,
                    serviceName: l10n.serviceSendGift,
                    icon: Icons.card_giftcard_rounded);
              }
            },
          ),
          const SizedBox(height: 22),
          _RecentTransfersCard(
            label: l10n.recentTransfers,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecentTransfersScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // "سداد خدمات" tile → choose between telecom top-up and bill payment.
  void _showBillPaymentsSheet(
      BuildContext context, BankSyncColors colors, String lang) {
    final isAr = lang == 'ar';
    final suffix =
        Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  context.l10n.payServicesSheetTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                    fontFamily: isAr ? 'Tajawal' : null,
                  ),
                ),
                const SizedBox(height: 12),
                _BillOptionRow(
                  svgName: 'ic_payment_services',
                  suffix: suffix,
                  label: context.l10n.telecomYemenMobile,
                  isAr: isAr,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const TelecomPaymentScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _BillOptionRow(
                  svgName: 'ic_payment_method',
                  suffix: suffix,
                  label: context.l10n.payBills,
                  isAr: isAr,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const BillerListScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOffersBottomSheet(
      BuildContext context, BankSyncColors colors, String lang) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isAr = lang == 'ar';
        final suffix =
            Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                context.l10n.exclusiveOffers,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                  fontFamily: isAr ? 'Tajawal' : null,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: SvgPicture.asset(
                  'assets/icons/ic_percent_$suffix.svg',
                  width: 28,
                  height: 28,
                ),
                title: Text(
                  context.l10n.cashBackTitle,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: isAr ? 'Tajawal' : null),
                ),
                subtitle: Text(
                  context.l10n.cashBackSubtitle,
                  style: TextStyle(
                      fontSize: 12, fontFamily: isAr ? 'Tajawal' : null),
                ),
              ),
              const Divider(),
              ListTile(
                leading: SvgPicture.asset(
                  'assets/icons/ic_airplane_$suffix.svg',
                  width: 28,
                  height: 28,
                ),
                title: Text(
                  context.l10n.travelDiscountTitle,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: isAr ? 'Tajawal' : null),
                ),
                subtitle: Text(
                  context.l10n.travelDiscountSubtitle,
                  style: TextStyle(
                      fontSize: 12, fontFamily: isAr ? 'Tajawal' : null),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showFinanceEligibilityDialog(
      BuildContext context, BankSyncColors colors, String lang) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final isAr = lang == 'ar';
        return AlertDialog(
          backgroundColor: colors.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            context.l10n.financeCalculatorTitle,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: isAr ? 'Tajawal' : null),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.financeCalculatorSubtitle,
                style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                    fontFamily: isAr ? 'Tajawal' : null),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: colors.success.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text(
                    '250,000 ${context.l10n.saudiRiyal}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.success,
                      fontFamily: isAr ? 'Tajawal' : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.financeDisclaimer,
                style: TextStyle(
                    fontSize: 10,
                    color: colors.outline,
                    fontStyle: FontStyle.italic,
                    fontFamily: isAr ? 'Tajawal' : null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.l10n.closeButton,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: isAr ? 'Tajawal' : null),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentTransfersCard extends StatelessWidget {
  const _RecentTransfersCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final suffix =
        Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: SvgPicture.asset(
                  'assets/icons/ic_history_$suffix.svg',
                  width: 22,
                  height: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSm(
                    color: colors.onSurface,
                    languageCode: languageCode,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(uffForwardChevron(context), size: 15, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

// 3-per-row Services Grid: main 6 (moved from the home dashboard) followed
// by the 6 transfer-hub-specific services (favorites, standing orders,
// beneficiaries, charity, network transfers, send gift).
class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({
    required this.l10n,
    required this.languageCode,
    required this.colors,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final String languageCode;
  final BankSyncColors colors;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isAr = languageCode == 'ar';
    final services = [
      _ServiceItem(
          label: l10n.serviceAccounts,
          svgName: 'ic_safe',
          color: const Color(0xFF2E7D32)),
      _ServiceItem(
          label: l10n.serviceCards,
          svgName: 'ic_credit_card',
          color: const Color(0xFF1565C0)),
      _ServiceItem(
          label: l10n.serviceBills,
          svgName: 'ic_payment_services',
          color: const Color(0xFFE65100)),
      _ServiceItem(
          label: l10n.serviceOffers,
          svgName: 'ic_offer_tag',
          color: const Color(0xFF8E24AA),
          hasBadge: true),
      _ServiceItem(
          label: l10n.serviceFinance,
          svgName: 'ic_money_growth',
          color: const Color(0xFF00796B)),
      _ServiceItem(
          label: l10n.favoritesLabel,
          svgName: 'ic_favorite_star',
          color: const Color(0xFFC62828)),
      _ServiceItem(
          label: l10n.serviceStandingOrders,
          svgName: 'ic_transfer_complete',
          color: const Color(0xFF3949AB)),
      _ServiceItem(
          label: l10n.beneficiaries,
          svgName: 'ic_beneficiaries',
          color: const Color(0xFF00838F)),
      _ServiceItem(
          label: l10n.serviceCharity,
          svgName: 'ic_charity',
          color: const Color(0xFF6D4C41)),
      _ServiceItem(
          label: l10n.networkTransfersTitle,
          svgName: 'ic_transfer_to_bank',
          color: const Color(0xFF2E7D32)),
      _ServiceItem(
          label: l10n.serviceSendGift,
          svgName: 'ic_send_gift',
          color: const Color(0xFFAD1457)),
    ];

    final suffix =
        Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index];
        return InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: colors.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/${item.svgName}_$suffix.svg',
                      width: 32,
                      height: 32,
                    ),
                    if (item.hasBadge)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                    height: 1.2,
                    fontFamily: isAr ? 'Tajawal' : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceItem {
  final String label;
  final String svgName;
  final Color color;
  final bool hasBadge;
  _ServiceItem(
      {required this.label,
      required this.svgName,
      required this.color,
      this.hasBadge = false});
}

/// One row in the "سداد خدمات" bottom sheet (leading icon + label + chevron).
class _BillOptionRow extends StatelessWidget {
  const _BillOptionRow({
    required this.svgName,
    required this.suffix,
    required this.label,
    required this.isAr,
    required this.onTap,
  });

  final String svgName;
  final String suffix;
  final String label;
  final bool isAr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              SvgPicture.asset('assets/icons/${svgName}_$suffix.svg',
                  width: 34, height: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                    fontFamily: isAr ? 'Tajawal' : null,
                  ),
                ),
              ),
              Icon(
                isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
