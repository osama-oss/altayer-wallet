import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/models/account_preferences.dart';
import '../../core/models/banking_account.dart';
import '../../core/models/favorite_transfer.dart';
import '../../core/network/api_error_message.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'qr_scan_screen.dart';
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

class TransferToOthersPanel extends ConsumerStatefulWidget {
  const TransferToOthersPanel({
    super.key,
    this.initialBeneficiary,
    this.initialAmount,
  });

  /// Pre-fills the beneficiary account (e.g. "transfer again" from history).
  final String? initialBeneficiary;

  /// Pre-fills the amount (e.g. carried over from the scan-review screen).
  final String? initialAmount;

  @override
  ConsumerState<TransferToOthersPanel> createState() => _TransferToOthersPanelState();
}

class _TransferToOthersPanelState extends ConsumerState<TransferToOthersPanel> {
  final _beneficiary = TextEditingController();
  final _amount = TextEditingController();

  bool _loading = false;
  bool _loadingAccounts = true;
  bool _success = false;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _validation;
  List<BankingAccount> _accounts = [];
  String? _debitAccount;
  String _currency = 'YER';

  // Live cross-currency quote (deal rate + converted amount).
  Timer? _quoteTimer;
  int _quoteSeq = 0;
  TransferQuote? _quote;
  bool _loadingQuote = false;

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _beneficiary.removeListener(_scheduleQuote);
    _amount.removeListener(_scheduleQuote);
    _beneficiary.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final prefill = widget.initialBeneficiary?.trim();
    if (prefill != null && prefill.isNotEmpty) {
      _beneficiary.text = prefill;
    }
    final amountPrefill = widget.initialAmount?.trim();
    if (amountPrefill != null && amountPrefill.isNotEmpty) {
      _amount.text = amountPrefill;
    }
    _beneficiary.addListener(_scheduleQuote);
    _amount.addListener(_scheduleQuote);
    _loadAccounts();
  }

  /// Debounces a validate call to refresh the live exchange quote as the user
  /// types the beneficiary / amount.
  void _scheduleQuote() {
    _quoteTimer?.cancel();
    final account = _beneficiary.text.trim();
    final amount = num.tryParse(_amount.text.trim()) ?? 0;
    if ((_debitAccount ?? '').isEmpty || account.length < 6 || amount <= 0) {
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

  Map<String, dynamic> get _payload => transferPayload(
        debitAccount: _debitAccount ?? '',
        creditAccount: _beneficiary.text.trim(),
        amountText: _amount.text,
      );

  void _showError(String message) {
    showTransferErrorNotice(context, message);
  }

  Future<void> _reviewTransfer() async {
    final l10n = context.l10n;
    if ((_debitAccount ?? '').isEmpty ||
        _beneficiary.text.trim().isEmpty ||
        _amount.text.trim().isEmpty) {
      _showError(l10n.chooseDebitBeneficiaryAmount);
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) return;
      final data = await ref.read(apiClientProvider).validateTransfer(token, _payload);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _validation = data;
      });
      await confirmTransferWithPin(
        context: context,
        ref: ref,
        payload: _payload,
        amount: _amount.text.trim(),
        currency: _currency,
        validation: data,
        summaryRows: () => [
          (l10n.fromLabel, _debitAccount ?? '—'),
          (l10n.toLabel, _beneficiary.text.trim()),
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

  Future<void> _scanQr() async {
    final account = await openQrScanScreen(context);
    if (account != null && account.isNotEmpty) {
      setState(() => _beneficiary.text = account);
    }
  }

  Future<void> _pickBeneficiary() async {
    final selectedAccount = await context.push<String>('/beneficiaries');
    if (selectedAccount != null && selectedAccount.isNotEmpty) {
      setState(() => _beneficiary.text = selectedAccount);
    }
  }

  void _applyTransferMax() {
    final debit = _accountByNumber(_debitAccount);
    if (debit == null) return;
    _amount.text = NumberFormat('#,##0.##').format(debit.balance);
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
    _scheduleQuote();
  }

  void _resetForm() {
    setState(() {
      _success = false;
      _result = null;
      _beneficiary.clear();
      _amount.clear();
    });
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
    if (_success) {
      return TransferSuccessView(
        reference: transferResultReference(_result),
        onNewTransfer: _resetForm,
        receipt: TransferReceipt(
          typeLabel: 'حوالة صادرة',
          amount: _amount.text.trim(),
          currency: _currency,
          fromName: _accountByNumber(_debitAccount)?.label,
          fromAccount: _debitAccount ?? '—',
          toName: transferCounterpartyName(_validation) ??
              transferCounterpartyName(_result),
          toAccount: _beneficiary.text.trim(),
          reference: transferResultReference(_result),
          date: DateTime.now(),
        ),
      );
    }

    final debit = _accountByNumber(_debitAccount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        TransferAccountTile(
          label: l10n.debitAccount,
          icon: Icons.account_balance_wallet_rounded,
          iconColors: [colors.secondary, colors.secondary.withValues(alpha: 0.7)],
          account: debit,
          currencyOverride: _currency,
          onTap: _pickDebitAccount,
        ),
        const SizedBox(height: 16),
        _FavoritesStrip(
          onPick: (account) => setState(() => _beneficiary.text = account),
        ),
        _BeneficiaryField(
          controller: _beneficiary,
          onPickBeneficiary: _pickBeneficiary,
          onScanQr: _scanQr,
          beneficiariesTooltip: l10n.beneficiaries,
          scanTooltip: l10n.scanQr,
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

/// Horizontal chips of the customer's server-side favorite transfer targets.
/// Tap prefills the beneficiary field ("transfer again" in one tap);
/// long-press offers removal. Hidden while empty or loading.
class _FavoritesStrip extends ConsumerWidget {
  const _FavoritesStrip({required this.onPick});

  final ValueChanged<String> onPick;

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, FavoriteTransfer favorite) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeFavorite),
        content: Text(
          favorite.displayName == favorite.targetAccountNumber
              ? favorite.targetAccountNumber
              : '${favorite.displayName}\n${favorite.targetAccountNumber}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.removeFavorite),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(favoritesProvider.notifier)
          .removeByAccount(favorite.targetAccountNumber);
    } on ApiException catch (e) {
      if (context.mounted) showTransferErrorNotice(context, e.message);
    } catch (e) {
      if (context.mounted) {
        showTransferErrorNotice(context, formatThrowableMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? const [];
    if (favorites.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final colors = context.bankColors;
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SvgPicture.asset('assets/icons/ic_favorite_star_$suffix.svg',
                width: 16, height: 16),
            const SizedBox(width: 6),
            Text(
              l10n.favoritesLabel,
              style: AppTextStyles.labelSm(
                color: colors.onSurfaceVariant,
                languageCode: lang,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return Material(
                color: colors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppColors.radiusPill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  onTap: () => onPick(favorite.targetAccountNumber),
                  onLongPress: () => _confirmRemove(context, ref, favorite),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/icons/ic_favorite_star_$suffix.svg',
                            width: 15, height: 15),
                        const SizedBox(width: 6),
                        Text(
                          favorite.displayName,
                          style: AppTextStyles.labelSm(
                            color: colors.onSurface,
                            languageCode: lang,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BeneficiaryField extends StatelessWidget {
  const _BeneficiaryField({
    required this.controller,
    required this.onPickBeneficiary,
    required this.onScanQr,
    required this.beneficiariesTooltip,
    required this.scanTooltip,
  });

  final TextEditingController controller;
  final VoidCallback onPickBeneficiary;
  final VoidCallback onScanQr;
  final String beneficiariesTooltip;
  final String scanTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.cardShadow, blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.person_search_rounded, color: colors.secondary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              textDirection: TextDirection.ltr,
              textAlign: isAr ? TextAlign.right : TextAlign.left,
              style: AppTextStyles.monoLabel(color: colors.onSurface)
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                border: InputBorder.none,
                hintText: context.l10n.hintBeneficiaryAccountOrIban,
                hintStyle: AppTextStyles.bodyMd(color: colors.onSurfaceVariant, languageCode: lang)
                    .copyWith(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CircularIconButton(
                icon: Icons.qr_code_scanner_rounded,
                onPressed: onScanQr,
                tooltip: scanTooltip,
              ),
              const SizedBox(width: 8),
              _CircularIconButton(
                icon: Icons.people_alt_rounded,
                onPressed: onPickBeneficiary,
                tooltip: beneficiariesTooltip,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  const _CircularIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.secondary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(icon, color: colors.secondary, size: 20),
          ),
        ),
      ),
    );
  }
}
