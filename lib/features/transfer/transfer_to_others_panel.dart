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
import '../../core/wallet_account_id.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import 'qr_scan_screen.dart';
import 'transfer_helpers.dart';
import 'transfer_review_screen.dart';
import 'widgets/transfer_account_tile.dart';
import 'widgets/transfer_amount_field.dart';
import 'widgets/transfer_buttons.dart';
import 'widgets/transfer_error.dart';
import 'widgets/transfer_rate_card.dart';
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
  ConsumerState<TransferToOthersPanel> createState() =>
      _TransferToOthersPanelState();
}

class _TransferToOthersPanelState extends ConsumerState<TransferToOthersPanel> {
  final _beneficiary = TextEditingController();
  final _amount = TextEditingController();

  bool _loadingAccounts = true;
  List<BankingAccount> _accounts = [];
  String? _debitAccount;

  // Currency of the selected debit account — the currency the amount is entered
  // in.
  String _currency = 'YER';

  // The recipient's target wallet currency. The customer only ever types the
  // bare recipient number; this picks which of the recipient's wallets
  // (YER/USD/SAR) is credited, so the full `"<phone>_<currency>"` id is built
  // internally for the API. Defaults to the debit currency (same-currency
  // transfer) until the customer picks a different wallet.
  String _creditCurrency = 'YER';
  bool _creditCurrencyTouched = false;

  // Live cross-currency quote (deal rate + converted amount).
  Timer? _quoteTimer;
  int _quoteSeq = 0;
  TransferQuote? _quote;
  bool _loadingQuote = false;

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _beneficiary.removeListener(_onBeneficiaryChanged);
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
      // Prefills (transfer-again / favorite / deep link) may carry the internal
      // "_<currency>" suffix — strip it for display and use it to preselect the
      // recipient wallet. Fields are set directly (setState is illegal here).
      _beneficiary.text = walletPhonePart(prefill);
      final ccy = walletCurrencyPart(prefill);
      if (ccy != null) {
        _creditCurrency = ccy;
        _creditCurrencyTouched = true;
      }
    }
    final amountPrefill = widget.initialAmount?.trim();
    if (amountPrefill != null && amountPrefill.isNotEmpty) {
      _amount.text = amountPrefill;
    }
    _beneficiary.addListener(_onBeneficiaryChanged);
    _amount.addListener(_scheduleQuote);
    _loadAccounts();
  }

  /// Rebuilds so the recipient-wallet selector appears once a number is typed,
  /// then refreshes the live quote.
  void _onBeneficiaryChanged() {
    if (mounted) setState(() {});
    _scheduleQuote();
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
      final data =
          await ref.read(apiClientProvider).validateTransfer(token, _payload);
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
          _debitAccount =
              defaultDebit?.accountNumber ?? accounts.first.accountNumber;
          _currency = defaultDebit?.currency ?? accounts.first.currency;
          if (!_creditCurrencyTouched) _creditCurrency = _currency;
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
        // The customer types only the bare recipient number; the internal wallet
        // id "<phone>_<currency>" is built here using the recipient wallet the
        // customer picked, so the currency suffix never surfaces in the UI.
        creditAccount:
            walletAccountId(_beneficiary.text.trim(), _creditCurrency),
        amountText: _amount.text,
      );

  void _showError(String message) {
    showTransferErrorNotice(context, message);
  }

  /// Validates the inputs then moves to the read-only review screen, which
  /// runs `TRANSFER-TO-ACC-VALIDATE`, PIN entry and the confirm call.
  void _continueToReview() {
    final l10n = context.l10n;
    if ((_debitAccount ?? '').isEmpty ||
        _beneficiary.text.trim().isEmpty ||
        _amount.text.trim().isEmpty) {
      _showError(l10n.chooseDebitBeneficiaryAmount);
      return;
    }
    if ((num.tryParse(_amount.text.trim()) ?? 0) <= 0) {
      _showError(l10n.chooseDebitBeneficiaryAmount);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransferReviewScreen(
          account: walletAccountId(_beneficiary.text.trim(), _creditCurrency),
          amount: _amount.text.trim(),
          currency: _currency,
          debitAccount: _accountByNumber(_debitAccount),
        ),
      ),
    );
  }

  /// Prefills the recipient field from a picked value (QR / beneficiary /
  /// favorite), stripping the internal currency suffix for display and using it
  /// to preselect the recipient wallet when present.
  void _applyBeneficiary(String raw) {
    final ccy = walletCurrencyPart(raw);
    // Assigning the text fires `_onBeneficiaryChanged`, which rebuilds.
    _beneficiary.text = walletPhonePart(raw);
    if (ccy != null && mounted) {
      setState(() {
        _creditCurrency = ccy;
        _creditCurrencyTouched = true;
      });
    }
  }

  Future<void> _scanQr() async {
    final account = await openQrScanScreen(context);
    if (account != null && account.isNotEmpty) {
      _applyBeneficiary(account);
    }
  }

  Future<void> _pickBeneficiary() async {
    final selectedAccount = await context.push<String>('/beneficiaries');
    if (selectedAccount != null && selectedAccount.isNotEmpty) {
      _applyBeneficiary(selectedAccount);
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
      if (account != null) {
        _currency = account.currency;
        // Keep the recipient wallet in step with the debit currency until the
        // customer deliberately picks a different one (cross-currency send).
        if (!_creditCurrencyTouched) _creditCurrency = account.currency;
      }
    });
    _scheduleQuote();
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
        style: AppTextStyles.bodyMd(
            color: colors.onSurfaceVariant, languageCode: languageCode),
      );
    }
    final debit = _accountByNumber(_debitAccount);
    final isAr = languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        TransferAccountTile(
          label: l10n.debitAccount,
          icon: Icons.account_balance_wallet_rounded,
          iconColors: [
            colors.secondary,
            colors.secondary.withValues(alpha: 0.7)
          ],
          account: debit,
          currencyOverride: _currency,
          onTap: _pickDebitAccount,
        ),
        const SizedBox(height: 16),
        _FavoritesStrip(
          onPick: _applyBeneficiary,
        ),
        _BeneficiaryField(
          controller: _beneficiary,
          onPickBeneficiary: _pickBeneficiary,
          onScanQr: _scanQr,
          beneficiariesTooltip: l10n.beneficiaries,
          scanTooltip: l10n.scanQr,
        ),
        // Recipient wallet (YER/USD/SAR) — shown once a number is entered so the
        // customer can send to any of the recipient's wallets without ever
        // seeing or typing the internal currency suffix.
        if (_beneficiary.text.trim().isNotEmpty)
          _RecipientWalletSelector(
            selected: _creditCurrency,
            onSelected: (ccy) {
              setState(() {
                _creditCurrency = ccy;
                _creditCurrencyTouched = true;
              });
              _scheduleQuote();
            },
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
          label: isAr ? 'متابعة التحويل' : 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _continueToReview,
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
              ? walletDisplayNumber(favorite.targetAccountNumber)
              : '${favorite.displayName}\n${walletDisplayNumber(favorite.targetAccountNumber)}',
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
    final suffix =
        Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';

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
                        SvgPicture.asset(
                            'assets/icons/ic_favorite_star_$suffix.svg',
                            width: 15,
                            height: 15),
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

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      textAlign: isAr ? TextAlign.right : TextAlign.left,
      style: AppTextStyles.monoLabel(color: colors.onSurface)
          .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      decoration: uffInputDecoration(
        context,
        label: isAr ? 'رقم جوال المستلم' : 'Recipient mobile number',
        placeholder: context.l10n.hintBeneficiaryAccountOrIban,
        prefixIcon:
            Icon(Icons.account_balance_wallet_outlined, color: colors.outline, size: 20),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CircularIconButton(
              icon: Icons.qr_code_scanner_rounded,
              onPressed: onScanQr,
              tooltip: scanTooltip,
            ),
            _CircularIconButton(
              icon: Icons.people_alt_rounded,
              onPressed: onPickBeneficiary,
              tooltip: beneficiariesTooltip,
            ),
            const SizedBox(width: 6),
          ],
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

/// Pills to pick which of the recipient's wallets (YER / USD / SAR) receives the
/// transfer. Only the bare number is ever typed; this chooses the currency the
/// full wallet id is built from, without exposing the internal suffix.
class _RecipientWalletSelector extends StatelessWidget {
  const _RecipientWalletSelector({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          isAr ? 'محفظة المستلم' : 'Recipient wallet',
          style: AppTextStyles.labelSm(
            color: colors.onSurfaceVariant,
            languageCode: lang,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final ccy in walletCurrencies) ...[
              Expanded(
                child: _CurrencyChip(
                  currency: ccy,
                  selected: ccy == selected,
                  onTap: () => onSelected(ccy),
                ),
              ),
              if (ccy != walletCurrencies.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  final String currency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;

    return Material(
      color: selected
          ? colors.secondary.withValues(alpha: 0.12)
          : colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            border: Border.all(
              color: selected ? colors.secondary : colors.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            currency,
            style: AppTextStyles.labelSm(
              color: selected ? colors.secondary : colors.onSurface,
              languageCode: lang,
            ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: colors.secondary.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, color: colors.secondary, size: 19),
            ),
          ),
        ),
      ),
    );
  }
}
