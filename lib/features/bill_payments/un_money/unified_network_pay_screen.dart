import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/banking_account.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/uff_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../../transfer/widgets/transfer_account_tile.dart';
import '../../../core/widgets/uff_loader.dart';

/// Front-only mockup of the Unified Network "pay transfer to account" form —
/// no backend integration yet.
class UnifiedNetworkPayScreen extends ConsumerStatefulWidget {
  const UnifiedNetworkPayScreen({super.key});

  @override
  ConsumerState<UnifiedNetworkPayScreen> createState() => _UnifiedNetworkPayScreenState();
}

class _UnifiedNetworkPayScreenState extends ConsumerState<UnifiedNetworkPayScreen> {
  final _reference = TextEditingController();

  List<BankingAccount> _accounts = [];
  bool _loadingAccounts = true;
  String? _account;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await ref.read(accountsProvider.future);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _account = accounts.isNotEmpty ? accounts.first.accountNumber : null;
        _loadingAccounts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAccounts = false);
    }
  }

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  BankingAccount? get _selectedAccount {
    for (final a in _accounts) {
      if (a.accountNumber == _account) return a;
    }
    return null;
  }

  Future<void> _pickAccount() async {
    final l10n = context.l10n;
    final selected = await TransferAccountPicker.show(
      context,
      title: l10n.depositAccountLabel,
      accounts: _accounts,
      selected: _account,
    );
    if (selected != null) setState(() => _account = selected);
  }

  void _confirm() {
    final l10n = context.l10n;
    if ((_account ?? '').isEmpty || _reference.text.trim().isEmpty) {
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
      appBar: AppBar(title: Text(l10n.unifiedNetworkPayTitle), centerTitle: true),
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
                          TransferAccountTile(
                            label: l10n.depositAccountLabel,
                            icon: Icons.account_balance_wallet_rounded,
                            iconColors: [colors.secondary, colors.secondary.withValues(alpha: 0.7)],
                            account: _selectedAccount,
                            onTap: _pickAccount,
                          ),
                          const SizedBox(height: 14),
                          UffField(
                            controller: _reference,
                            label: l10n.referenceNumberHint,
                            prefixIcon: Icons.tag_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            l10n.depositNoteLine1,
                            style: AppTextStyles.bodyMd(
                              color: colors.onSurfaceVariant,
                              languageCode: languageCode,
                            ).copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.depositNoteLine2,
                            style: AppTextStyles.bodyMd(
                              color: colors.onSurfaceVariant,
                              languageCode: languageCode,
                            ).copyWith(fontSize: 13),
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
