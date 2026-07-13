import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/models/banking_account.dart';
import '../../core/wallet_account_id.dart';
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
import 'widgets/bill_form_widgets.dart';
import '../../core/widgets/uff_loader.dart';

/// Telecom top-up / bill screen (سداد الاتصالات), modelled on the legacy app:
/// a single screen where the operator is auto-detected from the number prefix
/// (78 → Yemen Mobile, 73 → YOU…) as the user types, then that operator's نوع
/// الخدمة tiles (top-up / packages) reveal with its brand logo. Prefixes come
/// from the catalog, so the server can override them once it is seeded.
class TelecomPaymentScreen extends ConsumerStatefulWidget {
  const TelecomPaymentScreen({super.key});

  @override
  ConsumerState<TelecomPaymentScreen> createState() => _TelecomPaymentScreenState();
}

class _TelecomPaymentScreenState extends ConsumerState<TelecomPaymentScreen> {
  /// Digits typed before we try to match an operator prefix.
  static const _minDigitsForServices = 2;

  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  BankingAccount? _account;
  Biller? _operator;
  TelecomService? _service;
  TelecomPackage? _package;
  BillInquiry? _inquiry;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _phone => _phoneController.text.trim();
  bool get _phoneReady => _phone.length >= _minDigitsForServices;

  /// A complete, valid mobile number: matches the detected operator's format
  /// (9 digits, `^7\d{8}$`) — required before inquiry / execute.
  bool get _phoneComplete =>
      _operator?.matchesInput(_phone) ?? RegExp(r'^7\d{8}$').hasMatch(_phone);

  /// The service tiles for the detected operator; synthesises a single top-up
  /// tile for operators that declare no explicit services.
  List<TelecomService> _servicesFor(Biller operator) {
    if (operator.services.isNotEmpty) return operator.services;
    return [
      TelecomService(
        code: 'TOPUP',
        nameAr: operator.nameAr,
        nameEn: operator.nameEn,
        nameZh: operator.nameZh,
      ),
    ];
  }

  /// Re-detects the operator on every keystroke; auto-selects the top-up
  /// service so the amount field appears immediately (matches the legacy UX).
  void _onPhoneChanged(List<Biller> catalog) {
    final detected = Biller.detectOperator(catalog, _phone);
    setState(() {
      if (detected?.code != _operator?.code) {
        _operator = detected;
        _service = detected == null ? null : _servicesFor(detected).first;
        _package = null;
      }
      _inquiry = null;
      _error = null;
    });
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

  /// Rejects the action when the number is not a complete 9-digit line; sets an
  /// inline error and returns false.
  bool _validatePhone() {
    if (_phoneComplete) return true;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _error = isAr
        ? 'أدخل رقم هاتف صحيح مكوّن من 9 أرقام يبدأ بـ 7'
        : 'Enter a valid 9-digit number starting with 7');
    return false;
  }

  /// Demo balance inquiry — a mock result so the flow is presentable to the
  /// manager without a backend. Wire to `inquireBill` when the API is ready.
  Future<void> _runInquiry() async {
    final operator = _operator;
    if (operator == null) return;
    if (!_validatePhone()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _inquiry = BillInquiry(
        subscriberName: operator.localizedName(
          Localizations.localeOf(context).languageCode,
        ),
        balanceDue: 1250.00,
        lineType: 'مسبق الدفع',
        message: null,
      );
      _busy = false;
    });
  }

  /// Demo execution — validates the number, asks for confirmation, then builds a
  /// receipt and shows the success screen (no API — for the manager preview).
  Future<void> _execute() async {
    final operator = _operator;
    final account = _account;
    final service = _service;
    if (operator == null || account == null || service == null) return;
    if (!_validatePhone()) return;

    final amount = service.isPackages
        ? _package?.amount
        : double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final confirmed = await _showConfirmDialog(operator, service, amount);
    if (confirmed != true || !mounted) return;

    final receipt = BillReceipt(
      reference: 'UFF${DateTime.now().millisecondsSinceEpoch}',
      status: 'COMPLETED',
      billerCode: operator.code,
      subscriberNo: _phone,
      debitAccount: account.accountNumber,
      amount: amount,
      currency: operator.currency,
      providerRef: 'DEMO-${DateTime.now().millisecondsSinceEpoch % 1000000}',
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillSuccessScreen(receipt: receipt, biller: operator),
      ),
    );
  }

  /// Pre-execution confirmation sheet summarising the operation.
  Future<bool?> _showConfirmDialog(
    Biller operator,
    TelecomService service,
    double amount,
  ) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final amountText = '${NumberFormat('#,##0').format(amount)} ${operator.currency}';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'تأكيد العملية' : 'Confirm operation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _confirmRow(isAr ? 'المزوّد' : 'Provider', operator.localizedName(lang)),
            _confirmRow(l10n.phoneNumberLabel, _phone, mono: true),
            if (service.isPackages && _package != null)
              _confirmRow(l10n.packageTypeLabel, _package!.localizedName(lang)),
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
    final catalog = ref.watch(billerCatalogProvider);
    final billers = catalog.valueOrNull ?? const <Biller>[];
    final operator = _operator;
    final services = operator == null ? const <TelecomService>[] : _servicesFor(operator);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.telecomPaymentTitle), centerTitle: true),
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
                  : '${_account!.label}  •  ${walletDisplayNumber(_account!.accountNumber)}',
              placeholder: _account == null,
              onTap: _pickAccount,
            ),
            const SizedBox(height: 20),

            // ── رقم الهاتف ───────────────────────────────────────────
            BillSectionLabel(l10n.phoneNumberLabel),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.monoLabel(color: colors.onSurface)
                        .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                    onChanged: (_) => _onPhoneChanged(billers),
                    decoration: uffInputDecoration(
                      context,
                      placeholder: languageCode == 'ar' ? 'رقم الهاتف' : 'Phone Number',
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

            // ── نوع الخدمة (revealed once an operator is detected) ────
            if (_phoneReady) ...[
              BillSectionLabel(l10n.serviceTypeLabel),
              const SizedBox(height: 10),
              if (catalog.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(width: 22, height: 22, child: UffLoader()),
                ))
              else if (operator == null || services.isEmpty)
                Text(
                  l10n.noProvidersFound,
                  style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant, languageCode: languageCode),
                )
              else
                Row(
                  children: [
                    for (int i = 0; i < services.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _ServiceTile(
                          operator: operator,
                          service: services[i],
                          languageCode: languageCode,
                          selected: _service?.code == services[i].code,
                          onTap: () => setState(() {
                            _service = services[i];
                            _package = null;
                            _inquiry = null;
                            _error = null;
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 20),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.enterPhoneForServices,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm(
                    color: colors.onSurfaceVariant,
                    languageCode: languageCode,
                  ).copyWith(fontSize: 12),
                ),
              ),

            // ── نوع الباقة (package services only) ───────────────────
            if (_service != null && _service!.isPackages) ...[
              BillSectionLabel(l10n.packageTypeLabel),
              const SizedBox(height: 8),
              BillPackageDropdown(
                packages: _service!.packages,
                selected: _package,
                currency: operator?.currency ?? 'YER',
                languageCode: languageCode,
                hint: l10n.chooseOffer,
                onChanged: (pkg) => setState(() {
                  _package = pkg;
                  _error = null;
                }),
              ),
              const SizedBox(height: 20),
            ],

            // ── مبلغ السداد (top-up services only) ───────────────────
            if (_service != null && !_service!.isPackages) ...[
              BillSectionLabel(l10n.payAmountLabel),
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
                  suffixText: operator?.currency,
                  suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: kBillFieldHeight),
                  suffixIcon: BillFieldSuffixBox(
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
                BillInquiryResultCard(inquiry: _inquiry!, currency: operator?.currency ?? 'YER'),
                const SizedBox(height: 16),
              ],
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
            if (_service != null && !_service!.isPackages)
              // Top-up: balance inquiry + execute, matched size (image 3).
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _canInquire ? _runInquiry : null,
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(kBillButtonHeight)),
                      child: _busy
                          ? const SizedBox(width: 18, height: 18, child: UffLoader())
                          : Text(l10n.balanceInquiry, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canExecute ? _execute : null,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(kBillButtonHeight)),
                      child: Text(l10n.executeOperation, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              )
            else
              // Packages / initial state: single execute button (images 2, 4, 5).
              FilledButton(
                onPressed: _canExecute ? _execute : null,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(kBillButtonHeight)),
                child: Text(l10n.executeOperation, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }

  bool get _canInquire => _service != null && _phoneReady && !_busy;

  bool get _canExecute {
    if (_account == null || _service == null || !_phoneReady || _busy) return false;
    if (_service!.isPackages) return _package != null;
    final amount = double.tryParse(_amountController.text.trim());
    return amount != null && amount > 0;
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.operator,
    required this.service,
    required this.languageCode,
    required this.selected,
    required this.onTap,
  });

  final Biller operator;
  final TelecomService service;
  final String languageCode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final accent = operator.accentColor;
    final themeAsset = operator.getThemeAssetIcon(context);
    return Material(
      color: selected ? accent.withValues(alpha: 0.10) : colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(
              color: selected ? accent : colors.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: themeAsset != null
                      ? ClipOval(
                          child: themeAsset.endsWith('.svg')
                              ? SvgPicture.asset(
                                  themeAsset,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  themeAsset,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Icon(operator.icon, color: accent, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  service.localizedName(languageCode),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm(
                    color: colors.onSurface,
                    languageCode: languageCode,
                  ).copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.2),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
