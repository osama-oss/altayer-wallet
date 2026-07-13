import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/models/banking_account.dart';
import '../../../core/wallet_account_id.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/uff_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../data/bill_inquiry.dart';
import '../data/biller.dart';

/// Shared height for the account picker, number field and contact button so
/// the three sit on one balanced baseline (telecom + internet bill screens).
const double kBillFieldHeight = 56;

/// Shared height for the action buttons so الاستعلام and تنفيذ العملية match.
const double kBillButtonHeight = 52;

/// RTL-aware suffix icon box for [TextField] decoration — sits flush on the
/// trailing edge of the field matching the same visual treatment as the arrow
/// box inside [BillPickerTile] (tinted background, inner separator, rounded
/// outer corner). Uses [ClipRRect] so nothing leaks outside the field border.
///
/// Pass an [icon] (e.g. `Icons.phone_android_rounded`) or a custom [child]
/// widget (e.g. the «100» badge on the amount field).
class BillFieldSuffixBox extends StatelessWidget {
  const BillFieldSuffixBox({
    super.key,
    this.icon,
    this.child,
    this.height = kBillFieldHeight,
    this.width = 48,
  }) : assert(icon != null || child != null, 'Provide either icon or child');

  final IconData? icon;
  final Widget? child;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // The suffix sits on the logical-end side of the field. In LTR that is the
    // right edge; in RTL the left edge. We round only the outer corners to
    // match the field's own border radius and draw a single inner separator.
    final borderRadius = BorderRadius.only(
      topRight: isRtl ? Radius.zero : const Radius.circular(AppColors.radiusField - 1),
      bottomRight: isRtl ? Radius.zero : const Radius.circular(AppColors.radiusField - 1),
      topLeft: isRtl ? const Radius.circular(AppColors.radiusField - 1) : Radius.zero,
      bottomLeft: isRtl ? const Radius.circular(AppColors.radiusField - 1) : Radius.zero,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondary.withValues(alpha: 0.10),
          borderRadius: borderRadius,
          border: Border(
            left: isRtl ? BorderSide.none : BorderSide(color: colors.outlineVariant),
            right: isRtl ? BorderSide(color: colors.outlineVariant) : BorderSide.none,
          ),
        ),
        child: child ??
            Icon(
              icon,
              color: colors.secondary,
              size: 22,
            ),
      ),
    );
  }
}

/// Small muted section label above each form field (من حساب, رقم الهاتف…).
class BillSectionLabel extends StatelessWidget {
  const BillSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Text(
      label,
      style: AppTextStyles.labelSm(color: colors.onSurfaceVariant, languageCode: languageCode)
          .copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// Tappable field-look tile with a trailing dropdown arrow — the من حساب
/// picker on the bill screens.
class BillPickerTile extends StatelessWidget {
  const BillPickerTile({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
  });

  final String label;

  /// True when nothing is selected yet (renders in the quiet placeholder ink).
  final bool placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final arrowBox = Container(
      width: 48,
      height: kBillFieldHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.only(
          topRight: isRtl ? Radius.zero : const Radius.circular(AppColors.radiusField - 1),
          bottomRight: isRtl ? Radius.zero : const Radius.circular(AppColors.radiusField - 1),
          topLeft: isRtl ? const Radius.circular(AppColors.radiusField - 1) : Radius.zero,
          bottomLeft: isRtl ? const Radius.circular(AppColors.radiusField - 1) : Radius.zero,
        ),
        border: Border(
          left: isRtl ? BorderSide.none : BorderSide(color: colors.outlineVariant),
          right: isRtl ? BorderSide(color: colors.outlineVariant) : BorderSide.none,
        ),
      ),
      child: Icon(
        Icons.arrow_drop_down_rounded,
        color: colors.secondary,
        size: 28,
      ),
    );

    final textBox = Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd(color: placeholder ? colors.onSurfaceVariant : colors.onSurface)
              .copyWith(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
    );

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusField),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusField),
        child: Container(
          height: kBillFieldHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusField),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [textBox, arrowBox],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet listing the customer's accounts; pops the tapped account.
class BillAccountSheet extends StatelessWidget {
  const BillAccountSheet({super.key, required this.accounts});

  final List<BankingAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    return SafeArea(
      child: accounts.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                l10n.noProvidersFound,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: colors.outlineVariant),
              itemBuilder: (context, index) {
                final account = accounts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.account_balance_outlined, color: colors.secondary),
                  title: Text(
                    account.label,
                    style: AppTextStyles.bodyMd(color: colors.onSurface)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    walletDisplayNumber(account.accountNumber),
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.monoLabel(color: colors.onSurfaceVariant).copyWith(fontSize: 12),
                  ),
                  trailing: Text(
                    '${NumberFormat('#,##0.00').format(account.balance)} ${account.currency}',
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.monoLabel(color: colors.onSurface)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  onTap: () => Navigator.of(context).pop(account),
                );
              },
            ),
    );
  }
}

/// Square contact-search button that sits beside the number field.
class BillContactSearchButton extends StatelessWidget {
  const BillContactSearchButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusField),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusField),
        child: Container(
          width: kBillFieldHeight,
          height: kBillFieldHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusField),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Icon(
            Icons.person_search_rounded,
            color: colors.secondary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// نوع الباقة dropdown — package name plus its price when one is declared.
class BillPackageDropdown extends StatelessWidget {
  const BillPackageDropdown({
    super.key,
    required this.packages,
    required this.selected,
    required this.currency,
    required this.languageCode,
    required this.hint,
    required this.onChanged,
  });

  final List<TelecomPackage> packages;
  final TelecomPackage? selected;
  final String currency;
  final String languageCode;
  final String hint;
  final ValueChanged<TelecomPackage?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return DropdownButtonFormField<TelecomPackage>(
      initialValue: selected,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.onSurfaceVariant),
      hint: Text(
        hint,
        style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant, languageCode: languageCode),
      ),
      decoration: uffInputDecoration(context),
      items: [
        for (final pkg in packages)
          DropdownMenuItem<TelecomPackage>(
            value: pkg,
            child: Text(
              pkg.amount != null
                  ? '${pkg.localizedName(languageCode)}  —  ${NumberFormat('#,##0').format(pkg.amount)} $currency'
                  : pkg.localizedName(languageCode),
              style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: languageCode)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Bordered card summarising a balance-inquiry result on the bill screens.
class BillInquiryResultCard extends StatelessWidget {
  const BillInquiryResultCard({super.key, required this.inquiry, required this.currency});

  final BillInquiry inquiry;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;

    final rows = <(String, String)>[
      if (inquiry.subscriberName != null) (l10n.subscriberNameLabel, inquiry.subscriberName!),
      if (inquiry.formattedBalanceDue(currency) != null)
        (l10n.balanceDueLabel, inquiry.formattedBalanceDue(currency)!),
      if (inquiry.availableCredit != null) (l10n.availableCreditLabel, inquiry.availableCredit!),
      if (inquiry.lineType != null) (l10n.lineTypeLabel, inquiry.lineType!),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.billDetails,
            style: AppTextStyles.labelSm(color: colors.onSurfaceVariant, languageCode: languageCode)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty && inquiry.message != null)
            Text(
              inquiry.message!,
              style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: languageCode),
            ),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSm(color: colors.onSurfaceVariant, languageCode: languageCode),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.labelSm(color: colors.onSurface, languageCode: languageCode)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
