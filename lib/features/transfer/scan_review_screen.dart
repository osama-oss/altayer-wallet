import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/wallet_account_id.dart';
import '../../core/widgets/uff_ui.dart';
import 'qr_scan_screen.dart';
import 'transfer_review_screen.dart';

/// Transfer data-entry screen. Two ways in: after a successful QR scan (account
/// is pre-filled), or when the user backs out of the scanner without scanning
/// ([account] is null) to type the recipient manually. It never moves money —
/// it collects the account / amount / note and hands off to the read-only
/// [TransferReviewScreen], which runs validation + PIN confirmation.
///
/// The field language mirrors the login screen (shared [uffInputDecoration]):
/// clean floating labels, a single soft outline, unified heights, theme-driven
/// surfaces — no card-in-card nesting.
class ScanReviewScreen extends StatefulWidget {
  const ScanReviewScreen({
    super.key,
    this.account,
    this.recipientName,
    this.currency,
  });

  /// Scanned account, or null when the user chose manual entry.
  final String? account;
  final String? recipientName;
  final String? currency;

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  // The field shows only the bare recipient number — the internal
  // "_<currency>" suffix is stripped for display and preserved separately in
  // [_creditCurrency] so the full wallet id is rebuilt for the API on continue.
  late final _account =
      TextEditingController(text: walletDisplayNumber(widget.account?.trim() ?? ''));
  final _amount = TextEditingController();
  final _note = TextEditingController();

  // Recipient wallet currency carried by the scanned / picked value (e.g. a QR
  // that encoded "<phone>_YER"). Null when the customer typed a bare number.
  late String? _creditCurrency = walletCurrencyPart(widget.account?.trim() ?? '');

  @override
  void dispose() {
    _account.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _rescan() async {
    final acct = await openQrScanScreen(context);
    if (acct != null && acct.isNotEmpty) {
      setState(() {
        _account.text = walletDisplayNumber(acct);
        _creditCurrency = walletCurrencyPart(acct) ?? _creditCurrency;
      });
    }
  }

  Future<void> _pickBeneficiary() async {
    final selected = await context.push<String>('/beneficiaries');
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _account.text = walletDisplayNumber(selected);
        _creditCurrency = walletCurrencyPart(selected) ?? _creditCurrency;
      });
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  void _continue() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final account = _account.text.trim();
    if (account.isEmpty) {
      _snack(isAr
          ? 'أدخل رقم حساب أو محفظة المستلم'
          : 'Enter the recipient account or wallet');
      return;
    }
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      _snack(isAr ? 'أدخل مبلغًا صحيحًا للمتابعة' : 'Enter a valid amount');
      return;
    }
    // Rebuild the internal "<number>_<currency>" wallet id for the API from the
    // bare number the customer sees plus the currency carried by the scan/QR.
    final creditAccount = _creditCurrency != null
        ? walletAccountId(account, _creditCurrency!)
        : account;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransferReviewScreen(
          account: creditAccount,
          amount: _amount.text.trim(),
          note: _note.text.trim(),
          recipientName: widget.recipientName,
          currency: widget.currency,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final isAr = lang == 'ar';
    final currency = widget.currency?.trim();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          isAr ? 'تحويل الأموال' : 'Send money',
          style: AppTextStyles.headlineMd(color: colors.primary, languageCode: lang)
              .copyWith(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RecipientHeader(
                name: widget.recipientName,
                colors: colors,
                lang: lang,
              ),
              const SizedBox(height: 26),

              // Account / wallet — login field language with inline QR +
              // beneficiary actions.
              TextField(
                controller: _account,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: isAr ? TextAlign.right : TextAlign.left,
                style: AppTextStyles.monoLabel(color: colors.onSurface)
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                decoration: uffInputDecoration(
                  context,
                  label: isAr ? 'رقم الحساب أو المحفظة' : 'Account or wallet number',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                      color: colors.outline, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _InlineAction(
                        icon: Icons.qr_code_scanner_rounded,
                        tooltip: isAr ? 'مسح رمز QR' : 'Scan QR',
                        onTap: _rescan,
                        colors: colors,
                      ),
                      _InlineAction(
                        icon: Icons.people_alt_rounded,
                        tooltip: isAr ? 'المستفيدون' : 'Beneficiaries',
                        onTap: _pickBeneficiary,
                        colors: colors,
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
              ),
              const SizedBox(height: 16),

              // Amount — larger figure, currency sits inside the field.
              TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                textDirection: TextDirection.ltr,
                textAlign: isAr ? TextAlign.right : TextAlign.left,
                style: AppTextStyles.balanceDisplay(color: colors.onSurface)
                    .copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                decoration: uffInputDecoration(
                  context,
                  label: isAr ? 'المبلغ' : 'Amount',
                  placeholder: '0.00',
                  prefixIcon: Icon(Icons.payments_outlined,
                      color: colors.outline, size: 20),
                  suffixText:
                      (currency == null || currency.isEmpty) ? null : currency.toUpperCase(),
                ),
              ),
              const SizedBox(height: 16),

              // Note — plain field, same identity, not a boxed card.
              TextField(
                controller: _note,
                maxLength: 140,
                minLines: 1,
                maxLines: 3,
                textAlign: isAr ? TextAlign.right : TextAlign.left,
                style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: lang)
                    .copyWith(fontWeight: FontWeight.w600),
                decoration: uffInputDecoration(
                  context,
                  label: isAr ? 'ملاحظة (اختياري)' : 'Note (optional)',
                  prefixIcon: Icon(Icons.edit_note_rounded,
                      color: colors.outline, size: 22),
                ).copyWith(counterText: ''),
              ),
              const SizedBox(height: 28),

              // Primary action — same shape/height/radius as the login CTA.
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.onSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAr ? 'متابعة التحويل' : 'Continue',
                        style: AppTextStyles.labelSm(color: colors.onSecondary, languageCode: lang)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Icon(uffForwardChevron(context),
                          color: colors.onSecondary, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact recipient header — small avatar + name + wallet type. Light on
/// purpose so it reads as a header rather than a heavy card.
class _RecipientHeader extends StatelessWidget {
  const _RecipientHeader({
    required this.name,
    required this.colors,
    required this.lang,
  });

  final String? name;
  final BankSyncColors colors;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final isAr = lang == 'ar';
    final displayName =
        (name != null && name!.trim().isNotEmpty) ? name!.trim() : (isAr ? 'المستلم' : 'Recipient');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
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
                  displayName,
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

/// Small circular in-field action (QR / beneficiary picker), tinted with the
/// theme's secondary so it stays legible in both light and dark.
class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: colors.secondary.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
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
