import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/models/banking_account.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import 'bill_payments_providers.dart';
import 'bill_success_screen.dart';
import 'data/bill_inquiry.dart';
import 'data/bill_receipt.dart';
import 'data/biller.dart';
import 'widgets/bill_form_widgets.dart';
import '../../core/widgets/uff_loader.dart';

/// Which package-based internet biller the screen pays.
enum PackageBillerKind { yemen4g, adenNet }

/// يمن فورجي / عدن نت — subscription-package screens modelled on the legacy
/// app: from account + subscriber number + a نوع الباقة dropdown driven by
/// the biller's own [TelecomService.packages], no free-typed amount. Yemen 4G
/// keeps the balance-inquiry button (image 1); Aden Net has تنفيذ only
/// (image 3), matching the reference screenshots.
class PackageBillPaymentScreen extends ConsumerStatefulWidget {
  const PackageBillPaymentScreen({super.key, required this.kind});

  final PackageBillerKind kind;

  @override
  ConsumerState<PackageBillPaymentScreen> createState() => _PackageBillPaymentScreenState();
}

class _PackageBillPaymentScreenState extends ConsumerState<PackageBillPaymentScreen> {
  final _numberController = TextEditingController();
  BankingAccount? _account;
  TelecomPackage? _package;
  BillInquiry? _inquiry;
  bool _busy = false;
  String? _error;

  bool get _hasInquiry => widget.kind == PackageBillerKind.yemen4g;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  String get _number => _numberController.text.trim();

  /// The screen's biller from the shared catalog (server rows win), falling
  /// back to the client seed so the flow works before `BILLER_CATALOG` lands.
  Biller _biller(List<Biller> catalog) {
    final code = widget.kind == PackageBillerKind.yemen4g ? 'YEMEN-4G' : 'ADENNET';
    return catalog.firstWhere(
      (b) => b.code == code,
      orElse: () => Biller.fallbackCatalog.firstWhere((b) => b.code == code),
    );
  }

  List<TelecomPackage> _packagesFor(Biller biller) {
    return biller.services.isNotEmpty ? biller.services.first.packages : const <TelecomPackage>[];
  }

  Future<void> _pickAccount() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const <BankingAccount>[];
    final selected = await showModalBottomSheet<BankingAccount>(
      context: context,
      showDragHandle: true,
      builder: (_) => BillAccountSheet(accounts: accounts),
    );
    if (selected != null && mounted) setState(() => _account = selected);
  }

  /// Rejects the action when the number does not match the biller's format;
  /// sets an inline error and returns false.
  bool _validateNumber(Biller biller) {
    if (biller.matchesInput(_number)) return true;
    setState(() => _error = context.l10n.invalidSubscriberNumber);
    return false;
  }

  /// Demo balance inquiry (Yemen 4G only) — a mock result so the flow is
  /// presentable to the manager without a backend. Wire to `inquireBill` when
  /// the API is ready.
  Future<void> _runInquiry(Biller biller) async {
    if (!_validateNumber(biller)) return;
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
        balanceDue: 1250.00,
        lineType: isAr ? 'مسبق الدفع' : 'Prepaid',
        message: null,
      );
      _busy = false;
    });
  }

  /// Demo execution — validates the number, asks for confirmation, then builds
  /// a receipt and shows the success screen (no API — for the manager preview).
  Future<void> _execute(Biller biller) async {
    final account = _account;
    final package = _package;
    if (account == null || package == null) return;
    if (!_validateNumber(biller)) return;

    final amount = package.amount;
    if (amount == null || amount <= 0) return;

    final confirmed = await _showConfirmDialog(biller, package, amount);
    if (confirmed != true || !mounted) return;

    final receipt = BillReceipt(
      reference: 'UFF${DateTime.now().millisecondsSinceEpoch}',
      status: 'COMPLETED',
      billerCode: biller.code,
      subscriberNo: _number,
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
  Future<bool?> _showConfirmDialog(Biller biller, TelecomPackage package, double amount) {
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
            _confirmRow(isAr ? 'المزوّد' : 'Provider', biller.localizedName(lang)),
            _confirmRow(l10n.subscriberNumberLabel, _number, mono: true),
            _confirmRow(l10n.packageTypeLabel, package.localizedName(lang)),
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
    final packages = _packagesFor(biller);
    final numberLabel = widget.kind == PackageBillerKind.yemen4g
        ? l10n.mobileNumber
        : l10n.subscriberNumberLabel;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(biller.localizedName(languageCode)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── من حساب ──────────────────────────────────────────────
            BillSectionLabel(l10n.fromAccountLabel),
            const SizedBox(height: 8),
            BillPickerTile(
              label: _account == null
                  ? (languageCode == 'ar' ? 'ادخل من حساب' : 'Choose account')
                  : '${_account!.label}  •  ${_account!.accountNumber}',
              placeholder: _account == null,
              onTap: _pickAccount,
            ),
            const SizedBox(height: 20),

            // ── رقم الموبايل / رقم المشترك ───────────────────────────
            BillSectionLabel(numberLabel),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numberController,
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
                      placeholder: numberLabel,
                      suffixIcon: const BillFieldSuffixBox(icon: Icons.phone_android_rounded),
                      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: kBillFieldHeight),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                BillContactSearchButton(
                  onTap: () {
                    // Contact search logic/placeholder
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── الباقه ───────────────────────────────────────────────
            BillSectionLabel(l10n.packageTypeLabel),
            const SizedBox(height: 8),
            BillPackageDropdown(
              packages: packages,
              selected: _package,
              currency: biller.currency,
              languageCode: languageCode,
              hint: l10n.chooseOffer,
              onChanged: (pkg) => setState(() {
                _package = pkg;
                _error = null;
              }),
            ),
            const SizedBox(height: 20),

            if (_inquiry != null) ...[
              BillInquiryResultCard(inquiry: _inquiry!, currency: biller.currency),
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

            // ── Buttons ──────────────────────────────────────────────
            if (_hasInquiry)
              // Yemen 4G: balance inquiry + execute, matched size (image 1).
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _canInquire ? () => _runInquiry(biller) : null,
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(kBillButtonHeight)),
                      child: _busy
                          ? const SizedBox(width: 18, height: 18, child: UffLoader())
                          : Text(l10n.balanceInquiry, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canExecute ? () => _execute(biller) : null,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(kBillButtonHeight)),
                      child: Text(l10n.executeOperation, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              )
            else
              // Aden Net: single تنفيذ button (image 3).
              FilledButton(
                onPressed: _canExecute ? () => _execute(biller) : null,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(kBillButtonHeight)),
                child: Text(l10n.executeOperation, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }

  bool get _canInquire => _number.isNotEmpty && !_busy;

  bool get _canExecute =>
      _account != null && _number.isNotEmpty && _package != null && !_busy;
}
