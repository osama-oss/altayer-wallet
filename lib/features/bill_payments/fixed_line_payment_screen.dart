import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/models/banking_account.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import 'bill_payments_providers.dart';
import 'bill_success_screen.dart';
import 'data/bill_inquiry.dart';
import 'data/bill_receipt.dart';
import 'data/biller.dart';
import '../../core/widgets/uff_loader.dart';
import 'widgets/bill_form_widgets.dart';

/// Shared height for the account picker, subscriber field and contact button
/// so the three sit on one balanced baseline (matches the telecom screen).
const double _kFieldHeight = 56;

/// Shared height for the action buttons so الاستعلام and تنفيذ match.
const double _kButtonHeight = 52;

/// Which Yemen Telecom fixed-line service the screen pays.
enum FixedLineKind { landline, internet }

/// سداد الهاتف الثابت / سداد الانترنت — the two Yemen Telecom fixed-line
/// services (free-sadad networks 6 and 5), modelled on the legacy app: from
/// account + subscriber number + amount, single تنفيذ for the landline and an
/// extra الاستعلام عن الرصيد for ADSL (the only fixed service with inquiry).
class FixedLinePaymentScreen extends ConsumerStatefulWidget {
  const FixedLinePaymentScreen({super.key, required this.kind});

  final FixedLineKind kind;

  @override
  ConsumerState<FixedLinePaymentScreen> createState() => _FixedLinePaymentScreenState();
}

class _FixedLinePaymentScreenState extends ConsumerState<FixedLinePaymentScreen> {
  final _subscriberController = TextEditingController();
  final _amountController = TextEditingController();
  BankingAccount? _account;
  BillInquiry? _inquiry;
  bool _busy = false;
  String? _error;

  bool get _isInternet => widget.kind == FixedLineKind.internet;

  @override
  void dispose() {
    _subscriberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _subscriberNo => _subscriberController.text.trim();

  /// The screen's biller from the shared catalog (server rows win), falling
  /// back to the client seed so the flow works before `BILLER_CATALOG` lands.
  Biller _biller(List<Biller> catalog) {
    final code = _isInternet ? Biller.internetBillerCode : Biller.landlineBillerCode;
    return catalog.firstWhere(
      (b) => b.code == code,
      orElse: () => Biller.fallbackCatalog.firstWhere((b) => b.code == code),
    );
  }

  Future<void> _pickAccount() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const <BankingAccount>[];
    final selected = await showModalBottomSheet<BankingAccount>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AccountSheet(accounts: accounts),
    );
    if (selected != null && mounted) setState(() => _account = selected);
  }

  /// Rejects the action when the subscriber number does not match the biller's
  /// format; sets an inline error and returns false.
  bool _validateSubscriber(Biller biller) {
    if (biller.matchesInput(_subscriberNo)) return true;
    setState(() => _error = context.l10n.invalidSubscriberNumber);
    return false;
  }

  /// Demo balance inquiry (internet only) — a mock ADSL result so the flow is
  /// presentable to the manager without a backend. Wire to `inquireBill` when
  /// the API is ready (network 5 returns expiredDate + minAmount).
  Future<void> _runInquiry(Biller biller) async {
    if (!_validateSubscriber(biller)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() {
      _inquiry = BillInquiry(
        subscriberName: biller.localizedName(
          Localizations.localeOf(context).languageCode,
        ),
        balanceDue: 3500.00,
        expiryDate: '2026-08-01',
        lineType: isAr ? 'اشتراك شهري' : 'Monthly subscription',
        message: null,
      );
      _busy = false;
    });
  }

  /// Demo execution — validates the number, asks for confirmation, then builds
  /// a receipt and shows the success screen (no API — for the manager preview).
  Future<void> _execute(Biller biller) async {
    final account = _account;
    if (account == null) return;
    if (!_validateSubscriber(biller)) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final confirmed = await _showConfirmDialog(biller, amount);
    if (confirmed != true || !mounted) return;

    final receipt = BillReceipt(
      reference: 'UFF${DateTime.now().millisecondsSinceEpoch}',
      status: 'COMPLETED',
      billerCode: biller.code,
      subscriberNo: _subscriberNo,
      debitAccount: account.accountNumber,
      amount: amount,
      currency: biller.currency,
      providerRef: 'DEMO-${DateTime.now().millisecondsSinceEpoch % 1000000}',
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillSuccessScreen(receipt: receipt, biller: biller),
      ),
    );
  }

  /// Pre-execution confirmation dialog summarising the operation.
  Future<bool?> _showConfirmDialog(Biller biller, double amount) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final amountText = '${NumberFormat('#,##0').format(amount)} ${biller.currency}';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'تأكيد العملية' : 'Confirm operation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _confirmRow(isAr ? 'الخدمة' : 'Service', biller.localizedName(lang)),
            _confirmRow(l10n.subscriberNumberLabel, _subscriberNo, mono: true),
            _confirmRow(l10n.payAmountLabel, amountText, mono: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAr ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value, {bool mono = false}) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSm(color: colors.onSurfaceVariant, languageCode: lang),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: mono ? TextDirection.ltr : null,
              style: (mono
                      ? AppTextStyles.monoLabel(color: colors.onSurface)
                      : AppTextStyles.labelSm(color: colors.onSurface, languageCode: lang))
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final biller = _biller(ref.watch(billerCatalogProvider).valueOrNull ?? const <Biller>[]);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_isInternet ? l10n.internetPaymentTitle : l10n.landlinePaymentTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── من حساب ──────────────────────────────────────────────
            _SectionLabel(l10n.fromAccountLabel),
            const SizedBox(height: 8),
            _PickerTile(
              label: _account == null
                  ? (languageCode == 'ar' ? 'ادخل من حساب' : 'Choose account')
                  : '${_account!.label}  •  ${_account!.accountNumber}',
              placeholder: _account == null,
              onTap: _pickAccount,
            ),
            const SizedBox(height: 20),

            // ── رقم المشترك ──────────────────────────────────────────
            _SectionLabel(l10n.subscriberNumberLabel),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subscriberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoLabel(color: colors.onSurface)
                        .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                    onChanged: (_) => setState(() {
                      _inquiry = null;
                      _error = null;
                    }),
                    decoration: uffInputDecoration(
                      context,
                      placeholder: l10n.subscriberNumberLabel,
                      suffixIcon: BillFieldSuffixBox(icon: _isInternet ? Icons.wifi_rounded : Icons.phone_rounded),
                      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: _kFieldHeight),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _ContactSearchButton(
                  onTap: () {
                    // Contact search logic/placeholder
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── مبلغ السداد ──────────────────────────────────────────
            _SectionLabel(l10n.payAmountLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: AppTextStyles.monoLabel(color: colors.onSurface)
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              onChanged: (_) => setState(() {}),
              decoration: uffInputDecoration(
                context,
                placeholder: languageCode == 'ar' ? 'مبلغ السداد' : 'Payment Amount',
                suffixText: biller.currency,
                suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: _kFieldHeight),
                suffixIcon: BillFieldSuffixBox(
                  height: _kFieldHeight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.secondary, width: 1.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '100',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: colors.secondary,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_inquiry != null) ...[
              _InquiryResult(inquiry: _inquiry!, currency: biller.currency),
              const SizedBox(height: 16),
            ],

            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 8),

            // ── Buttons ──────────────────────────────────────────────
            if (_isInternet)
              // Internet (ADSL): balance inquiry + execute, matched size.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _canInquire ? () => _runInquiry(biller) : null,
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(_kButtonHeight)),
                      child: _busy
                          ? const SizedBox(width: 18, height: 18, child: UffLoader())
                          : Text(l10n.balanceInquiry, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canExecute ? () => _execute(biller) : null,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(_kButtonHeight)),
                      child: Text(l10n.executeOperation, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              )
            else
              // Landline: single execute button (no inquiry on network 6).
              FilledButton(
                onPressed: _canExecute ? () => _execute(biller) : null,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(_kButtonHeight)),
                child: Text(l10n.executeOperation, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }

  bool get _canInquire => _subscriberNo.isNotEmpty && !_busy;

  bool get _canExecute {
    if (_account == null || _subscriberNo.isEmpty || _busy) return false;
    final amount = double.tryParse(_amountController.text.trim());
    return amount != null && amount > 0;
  }
}

class _InquiryResult extends StatelessWidget {
  const _InquiryResult({required this.inquiry, required this.currency});

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
      if (inquiry.lineType != null) (l10n.lineTypeLabel, inquiry.lineType!),
      if (inquiry.expiryDate != null) (l10n.expiresLabel, inquiry.expiryDate!),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

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

class _ContactSearchButton extends StatelessWidget {
  const _ContactSearchButton({required this.onTap});

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
          width: _kFieldHeight,
          height: _kFieldHeight,
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

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.label, required this.placeholder, required this.onTap});

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
      height: _kFieldHeight,
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
          height: _kFieldHeight,
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

class _AccountSheet extends StatelessWidget {
  const _AccountSheet({required this.accounts});

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
                    account.accountNumber,
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
