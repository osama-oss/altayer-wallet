import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/models/account_preferences.dart';
import '../../core/models/banking_account.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_loader.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import 'qr_scan_screen.dart';
import 'transfer_review_screen.dart';
import 'widgets/transfer_account_tile.dart';
import 'widgets/transfer_amount_field.dart';
import 'widgets/transfer_buttons.dart';
import 'widgets/transfer_error.dart';

/// "دفع لتاجر" — pay a merchant by their merchant / wallet number.
///
/// In the UFF model a merchant is simply a payee, so this reuses the real
/// transfer pipeline rather than mocking anything: the form feeds
/// [TransferReviewScreen], which runs `TRANSFER-TO-ACC-VALIDATE`, PIN entry and
/// the confirm call (cross-currency is resolved there too). Accounts/preferences
/// come from the shared cached providers.
class MerchantPaymentScreen extends ConsumerStatefulWidget {
  const MerchantPaymentScreen({super.key, this.initialMerchant});

  /// Pre-fills the merchant number (e.g. from a future favourite merchant).
  final String? initialMerchant;

  @override
  ConsumerState<MerchantPaymentScreen> createState() =>
      _MerchantPaymentScreenState();
}

class _MerchantPaymentScreenState extends ConsumerState<MerchantPaymentScreen> {
  final _merchant = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  bool _loadingAccounts = true;
  List<BankingAccount> _accounts = [];
  String? _debitAccount;
  String _currency = 'YER';

  @override
  void initState() {
    super.initState();
    final prefill = widget.initialMerchant?.trim();
    if (prefill != null && prefill.isNotEmpty) _merchant.text = prefill;
    _loadAccounts();
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() => _loadingAccounts = true);
    try {
      // Shared caches, read in parallel — instant after the first load.
      final (accounts, preferences) = await (
        ref.read(accountsProvider.future),
        ref.read(accountPreferencesProvider.future),
      ).wait;
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        if (accounts.isNotEmpty) {
          final defaultDebit = resolveDefaultAccount(accounts, preferences);
          _debitAccount =
              defaultDebit?.accountNumber ?? accounts.first.accountNumber;
          _currency = defaultDebit?.currency ?? accounts.first.currency;
        }
        _loadingAccounts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAccounts = false);
    }
  }

  BankingAccount? _accountByNumber(String? number) {
    if (number == null) return null;
    for (final a in _accounts) {
      if (a.accountNumber == number) return a;
    }
    return null;
  }

  Future<void> _pickDebitAccount() async {
    final selected = await TransferAccountPicker.show(
      context,
      title: context.l10n.chooseDebitAccount,
      accounts: _accounts,
      selected: _debitAccount,
    );
    if (selected == null) return;
    final account = _accountByNumber(selected);
    setState(() {
      _debitAccount = selected;
      if (account != null) _currency = account.currency;
    });
  }

  void _applyMax() {
    final debit = _accountByNumber(_debitAccount);
    if (debit == null) return;
    _amount.text = NumberFormat('#,##0.##').format(debit.balance);
  }

  Future<void> _scanQr() async {
    final account = await openQrScanScreen(context);
    if (account != null && account.isNotEmpty) {
      setState(() => _merchant.text = account);
    }
  }

  /// Validates the inputs then moves to the shared read-only review screen,
  /// which runs validate → PIN → confirm against the core.
  void _continueToReview() {
    final l10n = context.l10n;
    if ((_debitAccount ?? '').isEmpty ||
        _merchant.text.trim().isEmpty ||
        _amount.text.trim().isEmpty ||
        (num.tryParse(_amount.text.trim()) ?? 0) <= 0) {
      showTransferErrorNotice(context, l10n.chooseDebitBeneficiaryAmount);
      return;
    }
    final note = _note.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransferReviewScreen(
          account: _merchant.text.trim(),
          amount: _amount.text.trim(),
          note: note.isEmpty ? null : note,
          currency: _currency,
          debitAccount: _accountByNumber(_debitAccount),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;

    Widget body;
    if (_loadingAccounts) {
      body = const Center(child: UffLoader());
    } else if (_accounts.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.noAccountsForTransfer,
          style: AppTextStyles.bodyMd(
              color: colors.onSurfaceVariant, languageCode: lang),
        ),
      );
    } else {
      body = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            TransferAccountTile(
              label: l10n.debitAccount,
              icon: Icons.account_balance_wallet_rounded,
              iconColors: [
                colors.secondary,
                colors.secondary.withValues(alpha: 0.7),
              ],
              account: _accountByNumber(_debitAccount),
              currencyOverride: _currency,
              onTap: _pickDebitAccount,
            ),
            const SizedBox(height: 16),
            _MerchantField(
              controller: _merchant,
              onScanQr: _scanQr,
              scanTooltip: l10n.scanQr,
            ),
            const SizedBox(height: 16),
            TransferAmountField(
              controller: _amount,
              currency: _currency,
              onMax: _applyMax,
              label: l10n.amount,
            ),
            const SizedBox(height: 16),
            _NoteField(controller: _note),
            const SizedBox(height: 32),
            TransferPrimaryButton(
              label: l10n.merchantPayContinue,
              icon: Icons.arrow_forward_rounded,
              onPressed: _continueToReview,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.svcPayMerchant), centerTitle: true),
      body: SafeArea(child: body),
    );
  }
}

/// Merchant / wallet number field with an inline QR-scan action, mirroring the
/// beneficiary field's field language.
class _MerchantField extends StatelessWidget {
  const _MerchantField({
    required this.controller,
    required this.onScanQr,
    required this.scanTooltip,
  });

  final TextEditingController controller;
  final VoidCallback onScanQr;
  final String scanTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      textAlign: isAr ? TextAlign.right : TextAlign.left,
      style: AppTextStyles.monoLabel(color: colors.onSurface)
          .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      decoration: uffInputDecoration(
        context,
        label: context.l10n.merchantNumberLabel,
        prefixIcon:
            Icon(Icons.storefront_outlined, color: colors.outline, size: 20),
        suffixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Tooltip(
            message: scanTooltip,
            child: Material(
              color: colors.secondary.withValues(alpha: 0.08),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onScanQr,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.qr_code_scanner_rounded,
                      color: colors.secondary, size: 19),
                ),
              ),
            ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

/// Optional free-text note attached to the payment.
class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    return TextField(
      controller: controller,
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      textAlign: isAr ? TextAlign.right : TextAlign.left,
      maxLines: 1,
      style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: lang),
      decoration: uffInputDecoration(
        context,
        label: context.l10n.noteOptionalLabel,
        placeholder: context.l10n.transferNotesHint,
        prefixIcon: Icon(Icons.edit_note_rounded, color: colors.outline, size: 20),
      ),
    );
  }
}
