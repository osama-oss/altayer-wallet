import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'bill_payments_providers.dart';
import 'data/bill_receipt.dart';
import 'data/biller.dart';
import '../../core/widgets/uff_loader.dart';

/// Step 3: the outcome. PENDING is shown honestly ("in progress at the
/// provider") with a manual reconcile button (`BILL_STATUS`); the webhook
/// settles it server-side either way.
class BillSuccessScreen extends ConsumerStatefulWidget {
  const BillSuccessScreen({super.key, required this.receipt, this.biller});

  final BillReceipt receipt;
  final Biller? biller;

  @override
  ConsumerState<BillSuccessScreen> createState() => _BillSuccessScreenState();
}

class _BillSuccessScreenState extends ConsumerState<BillSuccessScreen> {
  late BillReceipt _receipt;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _receipt = widget.receipt;
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null || token.isEmpty) return;
      final data =
          await ref.read(apiClientProvider).refreshBillStatus(token, _receipt.reference);
      if (!mounted) return;
      final updated = BillReceipt.fromMap(data);
      if (updated.status != _receipt.status) {
        ref.read(billPaymentsRevisionProvider.notifier).state++;
      }
      setState(() => _receipt = updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _share(AppLocalizations l10n, String billerName) {
    final lines = <String>[
      l10n.payBills,
      '$billerName — ${_receipt.subscriberNo ?? ''}',
      '${l10n.payAmountLabel}: ${_receipt.formattedAmount()}',
      '${l10n.referenceNumberLabel}: ${_receipt.reference}',
      if (_receipt.providerRef != null)
        '${l10n.providerReferenceLabel}: ${_receipt.providerRef}',
      _receipt.formattedDate(),
    ];
    Share.share(lines.join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final receipt = _receipt;
    final billerName =
        widget.biller?.localizedName(languageCode) ?? receipt.billerCode ?? '';

    final (icon, iconColor, title) = receipt.isCompleted
        ? (Icons.check_circle_rounded, AppColors.success, l10n.paymentSuccessful)
        : receipt.isPending
            ? (Icons.hourglass_top_rounded, AppColors.warning, l10n.paymentPendingTitle)
            : (Icons.error_rounded, AppColors.error, l10n.paymentFailed);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 46),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineMd(
                          color: colors.onSurface,
                          languageCode: languageCode,
                        ),
                      ),
                      if (receipt.isPending) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.paymentPendingBody,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd(
                            color: colors.onSurfaceVariant,
                            languageCode: languageCode,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppColors.radiusXl),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            _ReceiptRow(label: l10n.serviceProviders, value: billerName),
                            if (receipt.subscriberNo != null)
                              _ReceiptRow(
                                label: l10n.subscriberNumberLabel,
                                value: receipt.subscriberNo!,
                                mono: true,
                              ),
                            if (receipt.formattedAmount().isNotEmpty)
                              _ReceiptRow(
                                label: l10n.payAmountLabel,
                                value: receipt.formattedAmount(),
                                mono: true,
                              ),
                            if (receipt.debitAccount != null)
                              _ReceiptRow(
                                label: l10n.debitAccountLabel,
                                value: receipt.debitAccount!,
                                mono: true,
                              ),
                            _ReceiptRow(
                              label: l10n.referenceNumberLabel,
                              value: receipt.reference,
                              mono: true,
                            ),
                            if (receipt.providerRef != null)
                              _ReceiptRow(
                                label: l10n.providerReferenceLabel,
                                value: receipt.providerRef!,
                                mono: true,
                              ),
                            _ReceiptRow(label: '', value: receipt.formattedDate()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (receipt.isPending)
                      OutlinedButton.icon(
                        onPressed: _checking ? null : _checkStatus,
                        icon: _checking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: UffLoader(),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(l10n.checkStatus),
                      ),
                    if (receipt.isCompleted || receipt.isPending) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _share(l10n, billerName),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: Text(l10n.shareBillReceipt),
                      ),
                    ],
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.go('/home'),
                      child: Text(l10n.continueLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSm(
              color: colors.onSurfaceVariant,
              languageCode: languageCode,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: mono
                ? Text(
                    value,
                    textAlign: TextAlign.end,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.monoLabel(color: colors.onSurface)
                        .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.labelSm(
                      color: colors.onSurface,
                      languageCode: languageCode,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}
