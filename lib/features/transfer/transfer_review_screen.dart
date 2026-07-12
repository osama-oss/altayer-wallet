import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/models/account_preferences.dart';
import '../../core/models/banking_account.dart';
import '../../core/network/api_error_message.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/wallet_account_id.dart';
import '../../core/widgets/pin_entry_sheet.dart';
import '../../core/widgets/uff_loader.dart';
import '../../l10n/app_localizations.dart';
import 'transfer_helpers.dart';
import 'transfer_receipt.dart';
import 'widgets/transfer_success_view.dart';

/// Read-only confirmation for an outgoing transfer. It never collects input —
/// the account / amount / note are already captured on the entry screen
/// ([ScanReviewScreen]). On open it resolves the default debit account and runs
/// `TRANSFER-TO-ACC-VALIDATE` to surface the recipient name, fees and total,
/// then hands off to the vetted PIN + `..-CONFIRM` flow untouched.
class TransferReviewScreen extends ConsumerStatefulWidget {
  const TransferReviewScreen({
    super.key,
    required this.account,
    required this.amount,
    this.note,
    this.recipientName,
    this.currency,
    this.debitAccount,
  });

  /// Beneficiary account / wallet number entered on the previous screen.
  final String account;

  /// Raw amount text entered on the previous screen.
  final String amount;

  final String? note;
  final String? recipientName;
  final String? currency;

  /// The source account chosen on the entry screen. When null we resolve the
  /// customer's default debit account.
  final BankingAccount? debitAccount;

  @override
  ConsumerState<TransferReviewScreen> createState() =>
      _TransferReviewScreenState();
}

class _TransferReviewScreenState extends ConsumerState<TransferReviewScreen> {
  bool _preparing = true;
  bool _confirming = false;
  bool _success = false;
  String? _error;

  BankingAccount? _debit;
  String _currency = '';
  Map<String, dynamic>? _validation;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _currency = widget.currency?.trim() ?? '';
    _prepare();
  }

  Map<String, dynamic> get _payload => transferPayload(
        debitAccount: _debit?.accountNumber ?? '',
        creditAccount: widget.account.trim(),
        amountText: widget.amount,
      );

  /// Resolves the debit account then validates so we can show the recipient
  /// name, fees and total before the customer commits.
  Future<void> _prepare() async {
    try {
      BankingAccount? debit = widget.debitAccount;
      if (debit == null) {
        final (accounts, preferences) = await (
          ref.read(accountsProvider.future),
          ref.read(accountPreferencesProvider.future),
        ).wait;
        if (!mounted) return;
        debit = resolveDefaultAccount(accounts, preferences);
      }
      _debit = debit;
      if (_currency.isEmpty) _currency = debit?.currency ?? '';

      Map<String, dynamic>? validation;
      if (debit != null) {
        final token = await ref.read(authServiceProvider).readToken();
        if (token != null) {
          validation =
              await ref.read(apiClientProvider).validateTransfer(token, _payload);
        }
      }
      if (!mounted) return;
      setState(() {
        _validation = validation;
        _preparing = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _preparing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = formatThrowableMessage(e);
        _preparing = false;
      });
    }
  }

  Future<void> _confirm() async {
    final l10n = context.l10n;
    if (_debit == null) {
      setState(() => _error = l10n.noAccountsForTransfer);
      return;
    }
    final pin = await showPinEntrySheet(
      context,
      title: l10n.authorizeTransfer,
      subtitle: l10n.enterPinToComplete,
    );
    if (pin == null || pin.isEmpty || !mounted) return;

    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) return;
      final data =
          await ref.read(apiClientProvider).confirmTransfer(token, _payload, pin);
      // Balances changed — refresh the shared accounts cache.
      ref.read(accountsRevisionProvider.notifier).state++;
      if (!mounted) return;
      setState(() {
        _result = data;
        _success = true;
        _confirming = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _error = formatThrowableMessage(e);
      });
    }
  }

  String get _recipientName {
    final fromValidation = transferCounterpartyName(_validation);
    if (fromValidation != null && fromValidation.trim().isNotEmpty) {
      return fromValidation.trim();
    }
    final passed = widget.recipientName?.trim();
    return (passed != null && passed.isNotEmpty) ? passed : '';
  }

  /// Best-effort fee pulled from the validate payload (commission / charge /
  /// fee keys). Null when the core reports no fee.
  num? get _fee {
    for (final row in validationDetailRows(_validation)) {
      final key = row.$1.toLowerCase();
      if (key.contains('commission') ||
          key.contains('charge') ||
          key.contains('fee')) {
        final value = num.tryParse(row.$2.replaceAll(',', '').trim());
        if (value != null && value > 0) return value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          isAr ? 'مراجعة التحويل' : 'Review transfer',
          style: AppTextStyles.headlineMd(color: colors.primary, languageCode: lang)
              .copyWith(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _preparing
            ? const Center(child: UffLoader())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: _success ? _buildSuccess(lang) : _buildReview(colors, lang, isAr),
              ),
      ),
    );
  }

  Widget _buildSuccess(String lang) {
    return TransferSuccessView(
      reference: transferResultReference(_result),
      onNewTransfer: () => Navigator.of(context).popUntil((r) => r.isFirst),
      receipt: TransferReceipt(
        typeLabel: lang == 'ar' ? 'حوالة صادرة' : 'Outgoing transfer',
        amount: widget.amount.trim(),
        currency: _currency,
        fromName: _debit?.label,
        fromAccount: walletDisplayNumber(_debit?.accountNumber ?? '—'),
        toName: _recipientName.isEmpty ? null : _recipientName,
        toAccount: widget.account.trim(),
        reference: transferResultReference(_result),
        date: DateTime.now(),
      ),
    );
  }

  Widget _buildReview(BankSyncColors colors, String lang, bool isAr) {
    final amount = num.tryParse(widget.amount.trim()) ?? 0;
    final fee = _fee;
    final total = amount + (fee ?? 0);
    final money = NumberFormat('#,##0.##');
    final rateFmt = NumberFormat('#,##0.####');
    final note = widget.note?.trim() ?? '';
    // Surface the FX breakdown when the recipient is paid in another currency.
    final quote = parseTransferQuote(_validation, debitCurrency: _currency);
    final crossCurrency = quote != null && quote.isCrossCurrency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecipientHeader(name: _recipientName, colors: colors, lang: lang),
        const SizedBox(height: 24),

        // Hero amount — the single most important figure, read-only.
        Center(
          child: Column(
            children: [
              Text(
                isAr ? 'مبلغ التحويل' : 'Transfer amount',
                style: AppTextStyles.labelSm(
                  color: colors.onSurfaceVariant,
                  languageCode: lang,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    money.format(amount),
                    style: AppTextStyles.balanceDisplay(color: colors.onSurface)
                        .copyWith(fontSize: 40, fontWeight: FontWeight.w800),
                  ),
                  if (_currency.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      _currency.toUpperCase(),
                      style: AppTextStyles.labelSm(
                        color: colors.secondary,
                        languageCode: lang,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Read-only detail rows: account, fees, total, note.
        _DetailCard(
          colors: colors,
          lang: lang,
          rows: [
            _Detail(
              label: isAr ? 'الحساب أو المحفظة' : 'Account / wallet',
              value: maskAccount(walletDisplayNumber(widget.account)),
              mono: true,
            ),
            _Detail(
              label: isAr ? 'المبلغ' : 'Amount',
              value: '${money.format(amount)}'
                  '${_currency.isEmpty ? '' : ' ${_currency.toUpperCase()}'}',
            ),
            if (fee != null)
              _Detail(
                label: isAr ? 'الرسوم' : 'Fees',
                value: '${money.format(fee)}'
                    '${_currency.isEmpty ? '' : ' ${_currency.toUpperCase()}'}',
              ),
            _Detail(
              label: isAr ? 'الإجمالي' : 'Total',
              value: '${money.format(total)}'
                  '${_currency.isEmpty ? '' : ' ${_currency.toUpperCase()}'}',
              emphasize: true,
            ),
            if (crossCurrency && quote.dealRate != null)
              _Detail(
                label: isAr ? 'سعر الصرف' : 'Deal rate',
                value:
                    '1 ${quote.creditCurrency} = ${rateFmt.format(quote.dealRate)} ${quote.debitCurrency}',
                mono: true,
              ),
            if (crossCurrency)
              _Detail(
                label: isAr ? 'يستلم المستفيد' : 'Recipient gets',
                value: '${money.format(quote.creditAmount)} ${quote.creditCurrency}',
                emphasize: true,
              ),
            if (note.isNotEmpty)
              _Detail(label: isAr ? 'ملاحظة' : 'Note', value: note),
          ],
        ),

        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              border: Border.all(color: colors.error.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: colors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodyMd(color: colors.error, languageCode: lang)
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),

        // Primary action — commits the transfer via PIN + confirm.
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _confirming ? null : _confirm,
            style: FilledButton.styleFrom(
              backgroundColor: colors.secondary,
              foregroundColor: colors.onSecondary,
              disabledBackgroundColor: colors.secondary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _confirming
                ? const UffLoader(size: 22, color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: colors.onSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? 'تأكيد التحويل' : 'Confirm transfer',
                        style: AppTextStyles.labelSm(color: colors.onSecondary, languageCode: lang)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Compact recipient header — small avatar + name + wallet type. Deliberately
/// light so it reads as a header, not another card.
class _RecipientHeader extends StatelessWidget {
  const _RecipientHeader({
    required this.name,
    required this.colors,
    required this.lang,
  });

  final String name;
  final BankSyncColors colors;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final isAr = lang == 'ar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: colors.secondary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? (isAr ? 'المستلم' : 'Recipient') : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd(color: colors.onSurface, languageCode: lang)
                      .copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  isAr ? 'محفظة Ultimate Wallet' : 'Ultimate Wallet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm(color: colors.onSurfaceVariant, languageCode: lang)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail {
  const _Detail({
    required this.label,
    required this.value,
    this.mono = false,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool mono;
  final bool emphasize;
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.colors,
    required this.lang,
    required this.rows,
  });

  final BankSyncColors colors;
  final String lang;
  final List<_Detail> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.outlineVariant),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rows[i].label,
                    style: AppTextStyles.labelSm(
                      color: colors.onSurfaceVariant,
                      languageCode: lang,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.end,
                      textDirection: rows[i].mono ? TextDirection.ltr : null,
                      style: rows[i].mono
                          ? AppTextStyles.monoLabel(color: colors.onSurface)
                              .copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4)
                          : AppTextStyles.bodyMd(
                              color: colors.onSurface,
                              languageCode: lang,
                            ).copyWith(
                              fontWeight: rows[i].emphasize
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              fontSize: rows[i].emphasize ? 16 : 14,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
