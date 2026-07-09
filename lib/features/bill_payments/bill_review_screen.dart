import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/models/banking_account.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/banking_auth_exceptions.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/pin_entry_sheet.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import 'bill_payments_providers.dart';
import 'bill_success_screen.dart';
import 'data/bill_inquiry.dart';
import 'data/bill_receipt.dart';
import 'data/biller.dart';
import '../../core/widgets/uff_loader.dart';

/// Step 2: amount (or package) + debit account + PIN → `BILL_PAY`.
/// A `BILL_STATUS_UNKNOWN` reply is surfaced honestly: the payment may have
/// gone through — the user is sent to the history where reconciliation runs.
class BillReviewScreen extends ConsumerStatefulWidget {
  const BillReviewScreen({
    super.key,
    required this.biller,
    required this.subscriberNo,
    required this.inquiry,
  });

  final Biller biller;
  final String subscriberNo;
  final BillInquiry inquiry;

  @override
  ConsumerState<BillReviewScreen> createState() => _BillReviewScreenState();
}

class _BillReviewScreenState extends ConsumerState<BillReviewScreen> {
  late final TextEditingController _amountController;
  BankingAccount? _account;
  BillOffer? _offer;
  List<BillOffer>? _offers;
  bool _loadingOffers = false;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final due = widget.inquiry.balanceDue;
    _amountController = TextEditingController(
      text: due != null && due > 0 ? due.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _payWithOffer => _offer != null;

  bool get _canPay {
    if (_account == null || _paying) return false;
    if (_payWithOffer) return true;
    final amount = double.tryParse(_amountController.text.trim());
    return amount != null && amount > 0;
  }

  Future<void> _pickAccount() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const <BankingAccount>[];
    final matching = accounts
        .where((a) => a.currency.toUpperCase() == widget.biller.currency.toUpperCase())
        .toList();
    final selected = await showModalBottomSheet<BankingAccount>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _AccountSheet(accounts: matching),
    );
    if (selected != null && mounted) {
      setState(() => _account = selected);
    }
  }

  Future<void> _pickOffer() async {
    final l10n = context.l10n;
    if (_offers == null) {
      setState(() => _loadingOffers = true);
      try {
        final token = await ref.read(authServiceProvider).readToken();
        if (token == null || token.isEmpty) return;
        final data = await ref.read(apiClientProvider).listBillOffers(
              token,
              billerCode: widget.biller.code,
              subscriberNo: widget.subscriberNo,
            );
        _offers = BillOffer.listFrom(data);
      } on ApiException catch (e) {
        if (mounted) setState(() => _error = e.message);
      } finally {
        if (mounted) setState(() => _loadingOffers = false);
      }
    }
    final offers = _offers;
    if (offers == null || !mounted) return;
    if (offers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.offersEmpty)),
      );
      return;
    }
    final selected = await showModalBottomSheet<BillOffer>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _OfferSheet(offers: offers, currency: widget.biller.currency),
    );
    if (selected != null && mounted) {
      setState(() => _offer = selected);
    }
  }

  Future<void> _pay() async {
    final l10n = context.l10n;
    final account = _account;
    if (account == null) return;

    final pin = await showPinEntrySheet(
      context,
      title: l10n.confirmWithPin,
      subtitle: widget.biller.localizedName(Localizations.localeOf(context).languageCode),
    );
    if (pin == null || pin.isEmpty || !mounted) return;

    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null || token.isEmpty) return;
      final data = await ref.read(apiClientProvider).payBill(
            token,
            billerCode: widget.biller.code,
            subscriberNo: widget.subscriberNo,
            debitAccount: account.accountNoForIntegration,
            amount: _payWithOffer ? null : _amountController.text.trim(),
            offerCode: _offer?.id,
            pin: pin,
          );
      if (!mounted) return;
      final receipt = BillReceipt.fromMap(data);
      // Balance changed and a new history row exists — refresh both caches.
      ref.read(billPaymentsRevisionProvider.notifier).state++;
      ref.read(accountsRevisionProvider.notifier).state++;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BillSuccessScreen(receipt: receipt, biller: widget.biller),
        ),
      );
    } on PinInvalidException catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = e.message;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      if (e.code == 'BILL_STATUS_UNKNOWN') {
        // The row exists server-side as PENDING even though the outcome is
        // unknown here — reconciliation settles it in the history.
        ref.read(billPaymentsRevisionProvider.notifier).state++;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.paymentPendingTitle),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.paymentHistory),
              ),
            ],
          ),
        );
        if (mounted) context.push('/bills/history');
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final biller = widget.biller;
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.reviewPayment), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryCard(
              biller: biller,
              subscriberNo: widget.subscriberNo,
              subscriberName: widget.inquiry.subscriberName,
              languageCode: languageCode,
            ),
            const SizedBox(height: 20),
            if (biller.supportsAmount && !_payWithOffer) ...[
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
              if (widget.inquiry.minAmount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${l10n.minAmountLabel}: ${NumberFormat('#,##0.00').format(widget.inquiry.minAmount)} ${biller.currency}',
                    style: AppTextStyles.labelSm(
                      color: colors.onSurfaceVariant,
                      languageCode: languageCode,
                    ).copyWith(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            if (biller.supportsOffers) ...[
              _SectionLabel(l10n.offersAndPackages),
              const SizedBox(height: 8),
              _PickerTile(
                icon: Icons.card_giftcard_rounded,
                label: _offer == null
                    ? l10n.chooseOffer
                    : _offer!.price != null
                        ? '${_offer!.name} — ${NumberFormat('#,##0.00').format(_offer!.price)} ${biller.currency}'
                        : _offer!.name,
                loading: _loadingOffers,
                trailing: _offer != null
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _offer = null),
                      )
                    : null,
                onTap: _loadingOffers ? null : _pickOffer,
              ),
              const SizedBox(height: 16),
            ],
            _SectionLabel(l10n.debitAccountLabel),
            const SizedBox(height: 8),
            _PickerTile(
              icon: Icons.account_balance_wallet_outlined,
              label: _account == null
                  ? l10n.chooseAccount
                  : '${_account!.label}  •  ${_account!.accountNumber}',
              loading: accounts.isLoading,
              onTap: _pickAccount,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canPay ? _pay : null,
              child: _paying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: UffLoader(),
                    )
                  : Text(l10n.payNow),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.biller,
    required this.subscriberNo,
    required this.subscriberName,
    required this.languageCode,
  });

  final Biller biller;
  final String subscriberNo;
  final String? subscriberName;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final themeAsset = biller.getThemeAssetIcon(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: biller.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: themeAsset != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: themeAsset.endsWith('.svg')
                        ? SvgPicture.asset(
                            themeAsset,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          )
                        : Image.asset(
                            themeAsset,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                  )
                : Icon(biller.icon, color: biller.accentColor, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  biller.localizedName(languageCode),
                  style: AppTextStyles.labelSm(
                    color: colors.onSurface,
                    languageCode: languageCode,
                  ).copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subscriberName != null ? '$subscriberName  •  $subscriberNo' : subscriberNo,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.monoLabel(color: colors.onSurfaceVariant)
                      .copyWith(fontSize: 12),
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

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.secondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd(color: colors.onSurface)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: UffLoader(),
                )
              else
                trailing ?? Icon(Icons.unfold_more_rounded, color: colors.outline),
            ],
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
                    style: AppTextStyles.monoLabel(color: colors.onSurfaceVariant)
                        .copyWith(fontSize: 12),
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

class _OfferSheet extends StatelessWidget {
  const _OfferSheet({required this.offers, required this.currency});

  final List<BillOffer> offers;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: offers.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: colors.outlineVariant),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.card_giftcard_rounded, color: colors.secondary),
            title: Text(
              offer.name,
              style: AppTextStyles.bodyMd(color: colors.onSurface)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            trailing: offer.price != null
                ? Text(
                    '${NumberFormat('#,##0.00').format(offer.price)} $currency',
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.monoLabel(color: colors.onSurface)
                        .copyWith(fontWeight: FontWeight.w700),
                  )
                : null,
            onTap: () => Navigator.of(context).pop(offer),
          );
        },
      ),
    );
  }
}
