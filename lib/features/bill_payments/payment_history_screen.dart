import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/mobile_transaction.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import 'bill_payments_providers.dart';
import '../../core/widgets/uff_loader.dart';

/// Bill payment history — the BILL_PAYMENT rows of the server-side log
/// (mobile_transactions, JWT-scoped, follows the customer across devices).
/// Tapping a PENDING row reconciles it against the provider (`BILL_STATUS`).
class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<MobileTransaction> _payments = [];
  String? _refreshingRef;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) {
        if (mounted) {
          notifyRouterAuthChanged(ref);
          context.go('/login');
        }
        return;
      }
      final rows = await ref.read(apiClientProvider).transactions(token);
      if (!mounted) return;
      setState(() {
        _payments = MobileTransaction.listFrom(rows)
            .where((t) => t.type.toUpperCase() == 'BILL_PAYMENT')
            .toList();
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

  Future<void> _reconcile(MobileTransaction tx) async {
    if (_refreshingRef != null) return;
    setState(() => _refreshingRef = tx.reference);
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null || token.isEmpty) return;
      await ref.read(apiClientProvider).refreshBillStatus(token, tx.reference);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _refreshingRef = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    // Re-fetch after a new payment lands anywhere in the app.
    ref.listen(billPaymentsRevisionProvider, (_, __) => _load());

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.paymentHistory), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        color: colors.secondary,
        child: _buildBody(colors, l10n),
      ),
    );
  }

  Widget _buildBody(BankSyncColors colors, AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: UffLoader());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      );
    }
    if (_payments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.26),
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/ic_last_transactions_${Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light'}.svg',
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.billPaymentHistoryEmpty,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _PaymentCard(
        tx: _payments[index],
        refreshing: _refreshingRef == _payments[index].reference,
        onReconcile: () => _reconcile(_payments[index]),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.tx,
    required this.refreshing,
    required this.onReconcile,
  });

  final MobileTransaction tx;
  final bool refreshing;
  final VoidCallback onReconcile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final status = tx.status.toUpperCase();
    final pending = status == 'PENDING';
    final suffix = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';

    final (statusBg, statusFg, statusLabel) = switch (status) {
      'COMPLETED' => (AppColors.successContainer, AppColors.onSuccessContainer, l10n.statusCompleted),
      'PENDING' => (AppColors.warningContainer, AppColors.warning, l10n.statusPending),
      'FAILED' => (AppColors.errorContainer, AppColors.error, l10n.statusFailed),
      _ => (colors.surfaceContainerHigh, colors.onSurfaceVariant, tx.status),
    };

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: pending ? onReconcile : null,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                ),
                child: refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: UffLoader(),
                      )
                    : SvgPicture.asset(
                        'assets/icons/ic_last_transactions_$suffix.svg',
                        width: 22,
                        height: 22,
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.billerCode ?? tx.creditAccount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm(
                        color: colors.onSurface,
                        languageCode: languageCode,
                      ).copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tx.creditAccount,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.monoLabel(color: colors.onSurfaceVariant)
                          .copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tx.formattedDate(),
                      style: AppTextStyles.labelSm(
                        color: colors.onSurfaceVariant,
                        languageCode: languageCode,
                      ).copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tx.formattedAmount(),
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.monoLabel(color: colors.onSurface)
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppColors.radiusPill),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTextStyles.labelSm(color: statusFg, languageCode: languageCode)
                          .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
