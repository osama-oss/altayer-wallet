import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/models/account_preferences.dart';
import '../../core/models/banking_account.dart';
import '../../core/network/api_error_message.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'transfer_flow.dart';
import 'transfer_helpers.dart';
import 'transfer_receipt.dart';
import 'widgets/transfer_account_tile.dart';
import 'widgets/transfer_amount_field.dart';
import 'widgets/transfer_buttons.dart';
import 'widgets/transfer_error.dart';
import 'widgets/transfer_rate_card.dart';
import 'widgets/transfer_success_view.dart';
import '../../core/widgets/uff_loader.dart';

class TransferToOwnAccountsPanel extends ConsumerStatefulWidget {
  const TransferToOwnAccountsPanel({super.key});

  @override
  ConsumerState<TransferToOwnAccountsPanel> createState() =>
      _TransferToOwnAccountsPanelState();
}

class _TransferToOwnAccountsPanelState extends ConsumerState<TransferToOwnAccountsPanel> {
  final _amount = TextEditingController();

  bool _loading = false;
  bool _loadingAccounts = true;
  bool _success = false;
  Map<String, dynamic>? _result;
  List<BankingAccount> _accounts = [];
  String? _debitAccount;
  String? _creditAccount;
  String _currency = 'YER';

  // Live cross-currency quote (deal rate + converted amount).
  Timer? _quoteTimer;
  int _quoteSeq = 0;
  TransferQuote? _quote;
  bool _loadingQuote = false;

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _amount.removeListener(_scheduleQuote);
    _amount.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _amount.addListener(_scheduleQuote);
    _loadAccounts();
  }

  /// Debounces a validate call to refresh the quote — but only when the two
  /// accounts have different currencies (otherwise there is nothing to convert).
  void _scheduleQuote() {
    _quoteTimer?.cancel();
    final amount = num.tryParse(_amount.text.trim()) ?? 0;
    final credit = _accountByNumber(_creditAccount);
    final crossCurrency = credit != null &&
        credit.currency.trim().toUpperCase() != _currency.trim().toUpperCase();
    if (_debitAccount == null ||
        _creditAccount == null ||
        _debitAccount == _creditAccount ||
        amount <= 0 ||
        !crossCurrency) {
      if (_quote != null || _loadingQuote) {
        setState(() {
          _quote = null;
          _loadingQuote = false;
        });
      }
      return;
    }
    setState(() => _loadingQuote = true);
    _quoteTimer = Timer(const Duration(milliseconds: 600), _fetchQuote);
  }

  Future<void> _fetchQuote() async {
    final seq = ++_quoteSeq;
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) return;
      final data = await ref.read(apiClientProvider).validateTransfer(token, _payload);
      if (!mounted || seq != _quoteSeq) return;
      final quote = parseTransferQuote(data, debitCurrency: _currency);
      setState(() {
        _quote = (quote != null && quote.isCrossCurrency) ? quote : null;
        _loadingQuote = false;
      });
    } catch (_) {
      if (!mounted || seq != _quoteSeq) return;
      setState(() {
        _quote = null;
        _loadingQuote = false;
      });
    }
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
          _debitAccount = defaultDebit?.accountNumber ?? accounts.first.accountNumber;
          _currency = defaultDebit?.currency ?? accounts.first.currency;
          final creditChoices = accounts.where((a) => a.accountNumber != _debitAccount).toList();
          _creditAccount = creditChoices.isNotEmpty
              ? creditChoices.first.accountNumber
              : _debitAccount;
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

  List<BankingAccount> get _creditChoices {
    if (_debitAccount == null) return _accounts;
    return _accounts.where((a) => a.accountNumber != _debitAccount).toList();
  }

  Map<String, dynamic> get _payload => transferPayload(
        debitAccount: _debitAccount ?? '',
        creditAccount: _creditAccount ?? '',
        amountText: _amount.text,
      );

  void _showError(String message) {
    showTransferErrorNotice(context, message);
  }

  Future<void> _reviewTransfer() async {
    final l10n = context.l10n;
    if (_debitAccount == null ||
        _creditAccount == null ||
        _debitAccount == _creditAccount ||
        _amount.text.trim().isEmpty) {
      _showError(l10n.chooseAccountsAndAmount);
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) return;
      final data = await ref.read(apiClientProvider).validateTransfer(token, _payload);
      if (!mounted) return;
      setState(() => _loading = false);
      await confirmTransferWithPin(
        context: context,
        ref: ref,
        payload: _payload,
        amount: _amount.text.trim(),
        currency: _currency,
        validation: data,
        summaryRows: () => [
          (l10n.fromLabel, _debitAccount ?? '—'),
          (l10n.toLabel, _creditAccount ?? '—'),
        ],
        onLoadingChanged: () {
          if (mounted) setState(() => _loading = true);
        },
        onSuccess: (result) {
          if (!mounted) return;
          setState(() {
            _result = result;
            _success = true;
            _loading = false;
          });
        },
        onError: (message) {
          if (!mounted) return;
          setState(() => _loading = false);
          _showError(message);
        },
      );
    } on ApiException catch (e) {
      _showError(e.message);
      setState(() => _loading = false);
    } catch (e) {
      _showError(formatThrowableMessage(e));
      setState(() => _loading = false);
    }
  }

  void _applyTransferMax() {
    final debit = _accountByNumber(_debitAccount);
    if (debit == null) return;
    _amount.text = NumberFormat('#,##0.##').format(debit.balance);
  }

  void _resetForm() {
    setState(() {
      _success = false;
      _result = null;
      _amount.clear();
    });
  }

  Future<void> _pickDebitAccount() async {
    final selected = await TransferAccountPicker.show(
      context,
      title: _pickerTitle(context, true),
      accounts: _accounts,
      selected: _debitAccount,
    );
    if (selected == null) return;
    final account = _accountByNumber(selected);
    setState(() {
      _debitAccount = selected;
      if (account != null) _currency = account.currency;
      if (_creditAccount == selected) {
        _creditAccount = _creditChoices.firstOrNull?.accountNumber ?? selected;
      }
    });
    _scheduleQuote();
  }

  Future<void> _pickCreditAccount() async {
    final selected = await TransferAccountPicker.show(
      context,
      title: _pickerTitle(context, false),
      accounts: _creditChoices,
      selected: _creditAccount,
    );
    if (selected == null) return;
    setState(() {
      _creditAccount = selected;
    });
    _scheduleQuote();
  }

  void _swapAccounts() {
    if (_debitAccount == null || _creditAccount == null || _debitAccount == _creditAccount) return;
    final oldDebit = _debitAccount;
    final oldCredit = _creditAccount;
    final account = _accountByNumber(oldCredit);
    setState(() {
      _debitAccount = oldCredit;
      _creditAccount = oldDebit;
      if (account != null) _currency = account.currency;
    });
    _scheduleQuote();
  }

  String _pickerTitle(BuildContext context, bool isDebit) {
    if (isDebit) {
      return context.l10n.chooseDebitAccount;
    } else {
      return context.l10n.chooseCreditAccount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final colors = context.bankColors;

    if (_loadingAccounts) {
      return const Center(child: UffLoader());
    }
    if (_accounts.isEmpty) {
      return Text(
        l10n.noAccountsForTransfer,
        style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant, languageCode: languageCode),
      );
    }
    if (_accounts.length < 2) {
      return Text(
        l10n.needTwoAccounts,
        style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant, languageCode: languageCode),
      );
    }

    if (_success) {
      return TransferSuccessView(
        reference: transferResultReference(_result),
        onNewTransfer: _resetForm,
        receipt: TransferReceipt(
          typeLabel: 'تحويل بين حساباتي',
          amount: _amount.text.trim(),
          currency: _currency,
          fromName: _accountByNumber(_debitAccount)?.label,
          fromAccount: _debitAccount ?? '—',
          toName: _accountByNumber(_creditAccount)?.label,
          toAccount: _creditAccount ?? '—',
          reference: transferResultReference(_result),
          date: DateTime.now(),
        ),
      );
    }

    final debit = _accountByNumber(_debitAccount);
    final credit = _accountByNumber(_creditAccount) ?? _creditChoices.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                TransferAccountTile(
                  label: l10n.debitAccount,
                  icon: Icons.account_balance_wallet_rounded,
                  iconColors: [colors.secondary, colors.secondary.withValues(alpha: 0.7)],
                  account: debit,
                  currencyOverride: _currency,
                  onTap: _pickDebitAccount,
                ),
                const SizedBox(height: 16),
                TransferAccountTile(
                  label: l10n.creditAccount,
                  icon: Icons.arrow_downward_rounded,
                  iconColors: [colors.accentGreen, colors.accentGreen.withValues(alpha: 0.7)],
                  account: credit,
                  onTap: _pickCreditAccount,
                ),
              ],
            ),
            Positioned(
              child: GestureDetector(
                onTap: _swapAccounts,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.cardShadow,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Icon(Icons.swap_vert_rounded, color: colors.secondary, size: 24),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TransferAmountField(
          controller: _amount,
          currency: _currency,
          onMax: _applyTransferMax,
        ),
        TransferRateCard(quote: _quote, loading: _loadingQuote),
        const SizedBox(height: 32),
        TransferPrimaryButton(
          label: l10n.reviewTransfer,
          loading: _loading,
          icon: Icons.arrow_forward_rounded,
          onPressed: _reviewTransfer,
        ),
      ],
    );
  }
}
