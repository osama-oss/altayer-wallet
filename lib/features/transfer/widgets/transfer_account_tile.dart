import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/models/banking_account.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/wallet_account_id.dart';

/// Light, tappable account card shared by both transfer tabs (debit/credit).
/// Flat and easy on the eye: soft tint, thin border, no heavy shadow.
class TransferAccountTile extends StatelessWidget {
  const TransferAccountTile({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColors,
    required this.account,
    required this.onTap,
    this.currencyOverride,
  });

  final String label;
  final IconData icon;
  final List<Color> iconColors;
  final BankingAccount? account;
  final VoidCallback onTap;
  final String? currencyOverride;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final number =
        account != null ? walletDisplayNumber(account!.accountNumber) : '—';
    final balance =
        account != null ? NumberFormat('#,##0.00').format(account!.balance) : '0.00';
    final currency = currencyOverride ?? account?.currency ?? 'YER';
    final accent = iconColors.isNotEmpty ? iconColors.first : colors.secondary;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSm(
                        color: colors.onSurfaceVariant,
                        languageCode: lang,
                      ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      number,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.monoLabel(color: colors.onSurface)
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    balance,
                    style: AppTextStyles.monoLabel(color: colors.onSurface)
                        .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency,
                    style: AppTextStyles.labelSm(color: accent, languageCode: lang)
                        .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.unfold_more_rounded, color: colors.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Searchable, **virtualized** account picker — built for thousands of accounts.
///
/// The old version laid every account out at once inside a Column, which froze
/// the UI for large customers. This uses a search box + `ListView.builder`, so
/// only visible rows are built regardless of list size.
class TransferAccountPicker extends StatefulWidget {
  const TransferAccountPicker({
    super.key,
    required this.title,
    required this.accounts,
    required this.selected,
  });

  final String title;
  final List<BankingAccount> accounts;
  final String? selected;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<BankingAccount> accounts,
    required String? selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          TransferAccountPicker(title: title, accounts: accounts, selected: selected),
    );
  }

  @override
  State<TransferAccountPicker> createState() => _TransferAccountPickerState();
}

class _TransferAccountPickerState extends State<TransferAccountPicker> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BankingAccount> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.accounts;
    return widget.accounts.where((a) {
      return a.accountNumber.toLowerCase().contains(q) ||
          a.currency.toLowerCase().contains(q) ||
          a.label.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final filtered = _filtered;
    final height = MediaQuery.sizeOf(context).height * 0.82;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: AppTextStyles.headlineMd(color: colors.onSurface, languageCode: lang)
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                _SearchBox(
                  controller: _search,
                  hint: isAr ? 'ابحث برقم الحساب أو العملة' : 'Search by number or currency',
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
                const SizedBox(height: 8),
                if (widget.accounts.length > 20) ...[
                  Align(
                    alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      isAr
                          ? '${filtered.length} من ${widget.accounts.length} حساب'
                          : '${filtered.length} of ${widget.accounts.length} accounts',
                      style: AppTextStyles.labelSm(color: colors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            isAr ? 'لا توجد حسابات مطابقة' : 'No matching accounts',
                            style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 2, bottom: 8),
                          itemCount: filtered.length,
                          itemExtent: 70,
                          itemBuilder: (context, index) {
                            final a = filtered[index];
                            return _AccountRow(
                              account: a,
                              selected: a.accountNumber == widget.selected,
                              colors: colors,
                              lang: lang,
                              onTap: () => Navigator.of(context).pop(a.accountNumber),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bodyMd(color: colors.onSurface),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          prefixIcon: Icon(Icons.search_rounded, color: colors.outline, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.outline, size: 18),
                  onPressed: onClear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.selected,
    required this.colors,
    required this.lang,
    required this.onTap,
  });

  final BankingAccount account;
  final bool selected;
  final BankSyncColors colors;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? colors.secondary.withValues(alpha: 0.08)
            : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? colors.secondary : colors.outlineVariant,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.account_balance_wallet_outlined,
                      color: colors.secondary, size: 19),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        walletDisplayNumber(account.accountNumber),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                        style: AppTextStyles.monoLabel(color: colors.onSurface)
                            .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${NumberFormat('#,##0.00').format(account.balance)} ${account.currency}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm(
                          color: colors.onSurfaceVariant,
                          languageCode: lang,
                        ).copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: colors.secondary, size: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
