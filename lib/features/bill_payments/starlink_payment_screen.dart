import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

/// ستارلينك — single-screen internet bill payment: من حساب + رقم المشترك +
/// استعلام together (matches the Aden Net / Yemen 4G layout), unlike the
/// generic two-step BillInquiryScreen → BillReviewScreen flow used for
/// billers with no dedicated screen.
///
/// Demo inquiry/execution — same as Aden Net / Yemen 4G / telecom top-up: a
/// mock result so the flow is presentable without a backend. Wire to
/// `inquireBill` / `payBill` when Starlink's real integrations are ready.
class StarlinkPaymentScreen extends ConsumerStatefulWidget {
  const StarlinkPaymentScreen({super.key});

  @override
  ConsumerState<StarlinkPaymentScreen> createState() => _StarlinkPaymentScreenState();
}

class _StarlinkPaymentScreenState extends ConsumerState<StarlinkPaymentScreen> {
  final _numberController = TextEditingController();
  final _amountController = TextEditingController();
  BankingAccount? _account;
  BillInquiry? _inquiry;
  bool _inquiring = false;
  String? _error;

  @override
  void dispose() {
    _numberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _number => _numberController.text.trim();

  /// The screen's biller from the shared catalog (server rows win), falling
  /// back to the client seed so the flow works before `BILLER_CATALOG` lands.
  Biller _biller(List<Biller> catalog) {
    return catalog.firstWhere(
      (b) => b.code == 'STARLINK',
      orElse: () => Biller.fallbackCatalog.firstWhere((b) => b.code == 'STARLINK'),
    );
  }

  Future<void> _pickAccount(Biller biller) async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const <BankingAccount>[];
    final matching =
        accounts.where((a) => a.currency.toUpperCase() == biller.currency.toUpperCase()).toList();
    final selected = await showModalBottomSheet<BankingAccount>(
      context: context,
      showDragHandle: true,
      builder: (_) => BillAccountSheet(accounts: matching),
    );
    if (selected != null && mounted) setState(() => _account = selected);
  }

  /// Demo balance inquiry — a mock result so the flow is presentable without
  /// a backend. Wire to `inquireBill` when the API is ready.
  Future<void> _inquire(Biller biller) async {
    final l10n = context.l10n;
    if (!biller.matchesInput(_number)) {
      setState(() => _error = l10n.invalidSubscriberNumber);
      return;
    }
    setState(() {
      _inquiring = true;
      _error = null;
      _inquiry = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() {
      _inquiry = BillInquiry(
        subscriberName: biller.localizedName(Localizations.localeOf(context).languageCode),
        balanceDue: 1250.00,
        lineType: isAr ? 'مسبق الدفع' : 'Prepaid',
        message: null,
      );
      _inquiring = false;
      _amountController.text = '1250.00';
    });
  }

  bool get _canPay {
    if (_account == null || _inquiry == null) return false;
    final amount = double.tryParse(_amountController.text.trim());
    return amount != null && amount > 0;
  }

  /// Demo execution — validates the inputs, asks for confirmation, then
  /// builds a receipt and shows the success screen (no API — for the manager
  /// preview, same as Aden Net / Yemen 4G / telecom top-up).
  Future<void> _pay(Biller biller) async {
    final account = _account;
    if (account == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final confirmed = await _showConfirmDialog(biller, amount);
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
            _confirmRow(isAr ? 'المزوّد' : 'Provider', biller.localizedName(lang)),
            _confirmRow(l10n.subscriberNumberLabel, _number, mono: true),
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
    final themeAsset = biller.getThemeAssetIcon(context);
    final inquiry = _inquiry;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(biller.localizedName(languageCode)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (themeAsset != null)
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: biller.accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: themeAsset.endsWith('.svg')
                        ? SvgPicture.asset(themeAsset, width: 46, height: 46, fit: BoxFit.contain)
                        : Image.asset(themeAsset, width: 46, height: 46, fit: BoxFit.cover),
                  ),
                ),
              ),

            // ── من حساب ──────────────────────────────────────────────
            BillSectionLabel(l10n.fromAccountLabel),
            const SizedBox(height: 8),
            BillPickerTile(
              label: _account == null
                  ? l10n.chooseAccount
                  : '${_account!.label}  •  ${_account!.accountNumber}',
              placeholder: _account == null,
              onTap: () => _pickAccount(biller),
            ),
            const SizedBox(height: 20),

            // ── رقم المشترك + استعلام ────────────────────────────────
            BillSectionLabel(l10n.subscriberNumberLabel),
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
                      placeholder: l10n.subscriberNumberLabel,
                      errorText: _error,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: kBillFieldHeight,
                  child: OutlinedButton(
                    onPressed: _inquiring ? null : () => _inquire(biller),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: _inquiring
                        ? const SizedBox(width: 18, height: 18, child: UffLoader())
                        : Text(l10n.inquireBill),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (inquiry != null) ...[
              BillInquiryResultCard(inquiry: inquiry, currency: biller.currency),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                textDirection: TextDirection.ltr,
                style: AppTextStyles.monoLabel(color: colors.onSurface)
                    .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                onChanged: (_) => setState(() {}),
                decoration: uffInputDecoration(
                  context,
                  label: l10n.payAmountLabel,
                  suffixText: biller.currency,
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_error != null && !_inquiring) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 14),
            ],

            FilledButton(
              onPressed: _canPay ? () => _pay(biller) : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(kBillButtonHeight)),
              child: Text(l10n.executeOperation, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
