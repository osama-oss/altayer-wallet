import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/mobile_transaction.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import '../../core/widgets/uff_loader.dart';

/// "Recent transfers" — the customer's app-initiated transfers, read from the
/// server-side log (`GET /api/mobile/transactions`, scoped by JWT). Durable and
/// secure with no new backend. Tapping an entry re-runs it (prefilling the
/// beneficiary on the transfer screen).
class RecentTransfersScreen extends ConsumerStatefulWidget {
  const RecentTransfersScreen({super.key});

  @override
  ConsumerState<RecentTransfersScreen> createState() => _RecentTransfersScreenState();
}

class _RecentTransfersScreenState extends ConsumerState<RecentTransfersScreen> {
  bool _loading = true;
  String? _error;
  List<MobileTransaction> _transfers = [];

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
      final auth = ref.read(authServiceProvider);
      final token = await auth.readToken();
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
        _transfers = MobileTransaction.listFrom(rows);
        _error = null;
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

  void _transferAgain(MobileTransaction tx) {
    if (tx.creditAccount.isEmpty) return;
    context.push('/transfer/others?to=${Uri.encodeComponent(tx.creditAccount)}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.recentTransfers), centerTitle: true),
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

    if (_transfers.isEmpty) {
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
                  child: Icon(Icons.history_rounded, size: 40, color: colors.secondary),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noRecentTransfers,
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
      itemCount: _transfers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _TransferCard(
        tx: _transfers[index],
        colors: colors,
        l10n: l10n,
        onTransferAgain: () => _transferAgain(_transfers[index]),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.tx,
    required this.colors,
    required this.l10n,
    required this.onTransferAgain,
  });

  final MobileTransaction tx;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final VoidCallback onTransferAgain;

  String _statusLabel() {
    switch (tx.status.toUpperCase()) {
      case 'COMPLETED':
        return l10n.statusCompleted;
      case 'PENDING':
        return l10n.statusPending;
      default:
        return tx.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final completed = tx.isCompleted;
    final statusBg = completed ? AppColors.successContainer : colors.surfaceContainerHigh;
    final statusFg = completed ? AppColors.onSuccessContainer : colors.onSurfaceVariant;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTransferAgain,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    ),
                    child: Icon(Icons.north_east_rounded, color: colors.secondary, size: 22),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${l10n.toLabel}  ',
                              style: AppTextStyles.labelSm(
                                color: colors.onSurfaceVariant,
                                languageCode: languageCode,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                tx.creditAccount,
                                textDirection: TextDirection.ltr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.monoLabel(color: colors.onSurface)
                                    .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tx.formattedDate(),
                          style: AppTextStyles.labelSm(
                            color: colors.onSurfaceVariant,
                            languageCode: languageCode,
                          ).copyWith(fontSize: 12),
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
                            .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(AppColors.radiusPill),
                        ),
                        child: Text(
                          _statusLabel(),
                          style: AppTextStyles.labelSm(color: statusFg, languageCode: languageCode)
                              .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Divider(height: 22, color: colors.outlineVariant),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.replay_rounded, size: 16, color: colors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.transferAgain,
                    style: AppTextStyles.labelSm(color: colors.secondary, languageCode: languageCode)
                        .copyWith(fontWeight: FontWeight.w600),
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
