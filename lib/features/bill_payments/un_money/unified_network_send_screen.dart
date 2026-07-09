import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/banking_account.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/uff_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../../transfer/widgets/transfer_account_tile.dart';
import '../../../core/widgets/uff_loader.dart';

/// Front-only mockup of the Unified Network "send transfer" form — no
/// backend integration yet (see docs/PLAN_ note in the hub screen).
class UnifiedNetworkSendScreen extends ConsumerStatefulWidget {
  const UnifiedNetworkSendScreen({super.key});

  @override
  ConsumerState<UnifiedNetworkSendScreen> createState() => _UnifiedNetworkSendScreenState();
}

class _UnifiedNetworkSendScreenState extends ConsumerState<UnifiedNetworkSendScreen> {
  final _beneficiaryName = TextEditingController();
  final _beneficiaryNumber = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  List<BankingAccount> _accounts = [];
  bool _loadingAccounts = true;
  String? _debitAccount;
  late String _purpose = 'personal';

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _notes.addListener(() => setState(() {}));
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await ref.read(accountsProvider.future);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _debitAccount = accounts.isNotEmpty ? accounts.first.accountNumber : null;
        _loadingAccounts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAccounts = false);
    }
  }

  @override
  void dispose() {
    _beneficiaryName.dispose();
    _beneficiaryNumber.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  BankingAccount? get _selectedAccount {
    for (final a in _accounts) {
      if (a.accountNumber == _debitAccount) return a;
    }
    return null;
  }

  Future<void> _pickAccount() async {
    final l10n = context.l10n;
    final selected = await TransferAccountPicker.show(
      context,
      title: l10n.chooseDebitAccount,
      accounts: _accounts,
      selected: _debitAccount,
    );
    if (selected != null) setState(() => _debitAccount = selected);
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.comingSoonToast),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirm() {
    final l10n = context.l10n;
    if ((_debitAccount ?? '').isEmpty ||
        _beneficiaryName.text.trim().isEmpty ||
        _beneficiaryNumber.text.trim().isEmpty ||
        _amount.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chooseDebitBeneficiaryAmount),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.comingSoonToast), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.unifiedNetworkSendTitle), centerTitle: true),
      body: _loadingAccounts
          ? const Center(child: UffLoader())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _NetworkTabToggle(
                            selectedSecond: true,
                            firstLabel: l10n.tabTransferToBeneficiary,
                            secondLabel: l10n.tabSendUnifiedNetwork,
                            onFirstTap: _comingSoon,
                          ),
                          const SizedBox(height: 20),
                          TransferAccountTile(
                            label: l10n.debitAccount,
                            icon: Icons.account_balance_wallet_rounded,
                            iconColors: [colors.secondary, colors.secondary.withValues(alpha: 0.7)],
                            account: _selectedAccount,
                            onTap: _pickAccount,
                          ),
                          const SizedBox(height: 14),
                          UffField(
                            controller: _beneficiaryName,
                            label: l10n.beneficiaryNameLabel,
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 14),
                          UffField(
                            controller: _beneficiaryNumber,
                            label: l10n.beneficiaryNumberLabel,
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _amount,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: AppTextStyles.bodyMd(color: colors.onSurface)
                                .copyWith(fontWeight: FontWeight.w600),
                            decoration: uffInputDecoration(
                              context,
                              label: l10n.amount,
                              suffixText: _selectedAccount?.currency ?? 'YER',
                            ),
                          ),
                          const SizedBox(height: 14),
                          UffDropdownField<String>(
                            value: _purpose,
                            items: const ['personal', 'work'],
                            labelBuilder: (v) =>
                                v == 'personal' ? l10n.purposePersonal : l10n.purposeWork,
                            onChanged: (v) => setState(() => _purpose = v),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            l10n.transferNotesWarning,
                            style: AppTextStyles.labelSm(
                              color: colors.error,
                              languageCode: languageCode,
                            ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notes,
                            maxLines: 4,
                            maxLength: 30,
                            style: AppTextStyles.bodyMd(color: colors.onSurface),
                            decoration: uffInputDecoration(context, placeholder: l10n.transferNotesHint)
                                .copyWith(
                              counterText: _arabicIndicCounter(_notes.text.length, 30, languageCode),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                    child: UffPrimaryButton(
                      label: l10n.confirmLabel,
                      trailingChevron: false,
                      onPressed: _confirm,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

const _easternArabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String _arabicIndicCounter(int count, int max, String languageCode) {
  if (languageCode != 'ar') return '$count/$max';
  String toEastern(int n) => n
      .toString()
      .split('')
      .map((d) => _easternArabicDigits[int.parse(d)])
      .join();
  return '${toEastern(count)}/${toEastern(max)}';
}

/// Small two-way segmented toggle used only on this screen — no `TabBar` is
/// used elsewhere in the app, so this mirrors that convention instead of
/// introducing a new one.
class _NetworkTabToggle extends StatelessWidget {
  const _NetworkTabToggle({
    required this.selectedSecond,
    required this.firstLabel,
    required this.secondLabel,
    required this.onFirstTap,
  });

  final bool selectedSecond;
  final String firstLabel;
  final String secondLabel;
  final VoidCallback onFirstTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;

    Widget tab(String label, bool active, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? AppColors.warning : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm(
                color: active ? colors.onSurface : colors.onSurfaceVariant,
                languageCode: languageCode,
              ).copyWith(fontSize: 13.5, fontWeight: active ? FontWeight.w800 : FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(firstLabel, !selectedSecond, onFirstTap),
        tab(secondLabel, selectedSecond, () {}),
      ],
    );
  }
}
