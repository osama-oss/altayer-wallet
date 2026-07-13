import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/models/banking_account.dart';
import '../../../core/wallet_account_id.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/banking_auth_exceptions.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/pin_entry_sheet.dart';
import '../../../core/widgets/uff_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../bill_payments_providers.dart';
import '../data/bill_inquiry.dart';
import '../../../core/widgets/uff_loader.dart';

/// UN Money receive: transfer code → `BILL_INQUIRY` (UNMONEY) shows the
/// remittance → PIN → `UNMONEY-RECEIVE-CONFIRM` credits the chosen account.
class UnMoneyReceiveScreen extends ConsumerStatefulWidget {
  const UnMoneyReceiveScreen({super.key});

  @override
  ConsumerState<UnMoneyReceiveScreen> createState() => _UnMoneyReceiveScreenState();
}

class _UnMoneyReceiveScreenState extends ConsumerState<UnMoneyReceiveScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _confirming = false;
  String? _error;
  BillInquiry? _remittance;
  BankingAccount? _account;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _remittance = null;
    });
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null || token.isEmpty) return;
      final data = await ref.read(apiClientProvider).inquireBill(
            token,
            billerCode: 'UNMONEY',
            subscriberNo: code,
          );
      if (!mounted) return;
      setState(() {
        _remittance = BillInquiry.fromMap(data);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickAccount() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const <BankingAccount>[];
    final selected = await showModalBottomSheet<BankingAccount>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          itemCount: accounts.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: ctx.bankColors.outlineVariant),
          itemBuilder: (sheetContext, index) {
            final account = accounts[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.account_balance_outlined,
                  color: sheetContext.bankColors.secondary),
              title: Text(account.label),
              subtitle: Text(walletDisplayNumber(account.accountNumber),
                  textDirection: TextDirection.ltr),
              trailing: Text(
                '${NumberFormat('#,##0.00').format(account.balance)} ${account.currency}',
                textDirection: TextDirection.ltr,
              ),
              onTap: () => Navigator.of(sheetContext).pop(account),
            );
          },
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _account = selected);
    }
  }

  Future<void> _confirm() async {
    final l10n = context.l10n;
    final account = _account;
    if (account == null || _remittance == null) return;

    final pin = await showPinEntrySheet(context, title: l10n.confirmWithPin);
    if (pin == null || pin.isEmpty || !mounted) return;

    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null || token.isEmpty) return;
      await ref.read(apiClientProvider).confirmUnMoneyReceive(
        token,
        {
          'pickupCode': _controller.text.trim(),
          'creditAccount': account.accountNoForIntegration,
        },
        pin,
      );
      if (!mounted) return;
      ref.read(accountsRevisionProvider.notifier).state++;
      ref.read(billPaymentsRevisionProvider.notifier).state++;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 42),
          title: Text(l10n.paymentSuccessful),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      );
      if (mounted) context.go('/home');
    } on PinInvalidException catch (e) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _error = e.message;
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
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final remittance = _remittance;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.unMoneyReceive), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textDirection: TextDirection.ltr,
              style: AppTextStyles.monoLabel(color: colors.onSurface)
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
              onChanged: (_) {
                if (_error != null || _remittance != null) {
                  setState(() {
                    _error = null;
                    _remittance = null;
                  });
                }
              },
              decoration: uffInputDecoration(
                context,
                label: l10n.unMoneyPickupCode,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _lookup,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: UffLoader(),
                    )
                  : Text(l10n.unMoneyLookup),
            ),
            if (remittance != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppColors.radiusXl),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (remittance.subscriberName != null)
                      _Row(l10n.subscriberNameLabel, remittance.subscriberName!),
                    if (remittance.balanceDue != null)
                      _Row(
                        l10n.payAmountLabel,
                        '${NumberFormat('#,##0.00').format(remittance.balanceDue)} YER',
                      ),
                    if (remittance.message != null &&
                        remittance.subscriberName == null &&
                        remittance.balanceDue == null)
                      Text(
                        remittance.message!,
                        style: AppTextStyles.bodyMd(
                          color: colors.onSurface,
                          languageCode: languageCode,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppColors.radiusLg),
                child: InkWell(
                  onTap: _pickAccount,
                  borderRadius: BorderRadius.circular(AppColors.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppColors.radiusLg),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            color: colors.secondary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _account == null
                                ? l10n.chooseAccount
                                : '${_account!.label}  •  ${walletDisplayNumber(_account!.accountNumber)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMd(color: colors.onSurface)
                                .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        Icon(Icons.unfold_more_rounded, color: colors.outline),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _account == null || _confirming ? null : _confirm,
                child: _confirming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: UffLoader(),
                      )
                    : Text(l10n.unMoneyReceiveConfirm),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
            child: Text(
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
