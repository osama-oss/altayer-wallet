import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/account_transaction.dart';
import '../../core/models/banking_account.dart';
import '../../core/providers/app_providers.dart';
import '../../core/security/screen_security.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/transaction_tile.dart';
import '../../core/widgets/uff_loader.dart';
import '../../l10n/app_localizations.dart';
import '../home/transactions_screen.dart';
import '../transfer/qr_scan_screen.dart';
import 'wallet_providers.dart';
import 'wallet_receive_screen.dart';

const _positiveAmount = Color(0xFF27AE60);
const _negativeAmount = Color(0xFFEB5757);

/// «عَ الطاير» wallet home — single-balance dashboard (Jeeb-style): a hero
/// wallet-balance card, primary quick actions (send / receive / top-up / scan),
/// a services row and a recent-activity preview. All data comes from the real
/// UFF integrations (accountsProvider + ACCOUNT-LAST-TEN-TXN); nothing here is
/// mocked.
class WalletHomeScreen extends ConsumerStatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  ConsumerState<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends ConsumerState<WalletHomeScreen> {
  Future<void> _refresh() async {
    final primary = ref.read(primaryWalletProvider);
    ref.invalidate(accountsProvider);
    if (primary != null) {
      ref.invalidate(
          walletRecentActivityProvider(primary.accountNoForIntegration));
    }
    try {
      await ref.read(accountsProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final primary = ref.watch(primaryWalletProvider);
    final colors = context.bankColors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final obscured = ref.watch(dashboardObscuredProvider);

    final loading = accountsAsync.isLoading && !accountsAsync.hasValue;
    final hasError = accountsAsync.hasError && !accountsAsync.hasValue;

    Widget body;
    if (loading) {
      body = const SizedBox(height: 340, child: Center(child: UffLoader()));
    } else if (hasError) {
      body = _ErrorState(onRetry: _refresh, colors: colors, l10n: l10n, lang: lang);
    } else if (primary == null) {
      body = _EmptyWalletState(colors: colors, l10n: l10n, lang: lang);
    } else {
      body = _Dashboard(
        account: primary,
        obscured: obscured,
        colors: colors,
        l10n: l10n,
        lang: lang,
        onToggleBalance: () =>
            ref.read(dashboardObscuredProvider.notifier).state = !obscured,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: colors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: body,
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.account,
    required this.obscured,
    required this.colors,
    required this.l10n,
    required this.lang,
    required this.onToggleBalance,
  });

  final BankingAccount account;
  final bool obscured;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;
  final VoidCallback onToggleBalance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BalanceCard(
          account: account,
          obscured: obscured,
          onToggle: onToggleBalance,
          colors: colors,
          l10n: l10n,
          lang: lang,
        ),
        const SizedBox(height: 22),
        _QuickActions(account: account, colors: colors, l10n: l10n, lang: lang),
        const SizedBox(height: 26),
        _ServicesRow(colors: colors, l10n: l10n, lang: lang),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.walletRecentActivity,
              style: AppTextStyles.headlineMd(languageCode: lang)
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      SecureScreen(child: TransactionsScreen(account: account)),
                ),
              ),
              child: Text(
                l10n.viewAll,
                style: AppTextStyles.labelSm(color: colors.secondary, languageCode: lang)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _RecentActivityList(account: account, colors: colors, l10n: l10n, lang: lang),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.account,
    required this.obscured,
    required this.onToggle,
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankingAccount account;
  final bool obscured;
  final VoidCallback onToggle;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  String get _maskedTail {
    final n = account.accountNumber.replaceAll(' ', '');
    if (n.length <= 4) return n;
    return '•••• ${n.substring(n.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final balanceText =
        obscured ? '••••••' : NumberFormat('#,##0.00').format(account.balance);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandIndigo.withValues(alpha: 0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.walletBalanceLabel,
                style: AppTextStyles.labelSm(
                  color: Colors.white.withValues(alpha: 0.85),
                  languageCode: lang,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    obscured
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  balanceText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.balanceDisplay(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                account.currency,
                style: AppTextStyles.labelSm(
                  color: Colors.white.withValues(alpha: 0.85),
                  languageCode: lang,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _maskedTail,
                style: AppTextStyles.monoLabel(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              InkResponse(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: account.accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.copied)),
                  );
                },
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.content_copy_rounded,
                      color: Colors.white.withValues(alpha: 0.85), size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.account,
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankingAccount account;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  Future<void> _scanAndPay(BuildContext context) async {
    final acct = await openQrScanScreen(context);
    if (acct == null || acct.isEmpty) return;
    if (!context.mounted) return;
    context.push('/transfer/others?to=${Uri.encodeComponent(acct)}');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionItem(
          icon: Icons.arrow_upward_rounded,
          label: l10n.walletActionSend,
          colors: colors,
          lang: lang,
          onTap: () => context.push('/transfer/others'),
        ),
        _ActionItem(
          icon: Icons.qr_code_2_rounded,
          label: l10n.walletActionReceive,
          colors: colors,
          lang: lang,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WalletReceiveScreen(account: account),
            ),
          ),
        ),
        _ActionItem(
          icon: Icons.add_rounded,
          label: l10n.walletActionTopUp,
          colors: colors,
          lang: lang,
          onTap: () => context.push('/transfer/own'),
        ),
        _ActionItem(
          icon: Icons.qr_code_scanner_rounded,
          label: l10n.walletActionScan,
          colors: colors,
          lang: lang,
          onTap: () => _scanAndPay(context),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.colors,
    required this.lang,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final BankSyncColors colors;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.secondary, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm(color: colors.onSurface, languageCode: lang)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicesRow extends StatelessWidget {
  const _ServicesRow({
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final items = <_ServiceData>[
      _ServiceData(Icons.receipt_long_rounded, l10n.walletPayBills,
          () => context.push('/bills/providers')),
      _ServiceData(Icons.account_balance_rounded, l10n.walletTransferToBank,
          () => context.push('/network-transfers')),
      _ServiceData(Icons.people_alt_rounded, l10n.walletBeneficiaries,
          () => context.push('/beneficiaries')),
      _ServiceData(Icons.star_rounded, l10n.walletFavorites,
          () => context.push('/favorites')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.walletServicesTitle,
          style: AppTextStyles.headlineMd(languageCode: lang)
              .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              for (final it in items)
                Expanded(
                  child: InkWell(
                    onTap: it.onTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          Icon(it.icon, color: colors.secondary, size: 24),
                          const SizedBox(height: 8),
                          Text(
                            it.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSm(
                              color: colors.onSurface,
                              languageCode: lang,
                            ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceData {
  const _ServiceData(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _RecentActivityList extends ConsumerWidget {
  const _RecentActivityList({
    required this.account,
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankingAccount account;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async =
        ref.watch(walletRecentActivityProvider(account.accountNoForIntegration));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: UffLoader()),
      ),
      error: (_, __) => _hint(l10n.serverUnreachableMessage),
      data: (list) {
        if (list.isEmpty) return _hint(l10n.walletNoRecentActivity);
        final items = [...list]..sort((a, b) {
            final da = DateTime.tryParse(a.bookingDate);
            final db = DateTime.tryParse(b.bookingDate);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
        final top = items.take(5).toList();
        return Column(
          children: [
            for (final txn in top) ...[
              _tile(txn),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _tile(AccountTransaction txn) {
    final credit = txn.isCredit;
    return TransactionTile(
      icon: txn.iconForType(),
      title: txn.tileTitle(),
      subtitle: txn.tileSubtitle(),
      amount: txn.formattedAmount(),
      status: txn.tileStatus(),
      amountColor: credit ? _positiveAmount : _negativeAmount,
      iconBackground: credit
          ? colors.secondary.withValues(alpha: 0.1)
          : colors.primaryContainer,
      iconColor: credit ? colors.secondary : colors.onPrimaryContainer,
      statusColor: colors.onSurfaceVariant,
      statusBackground: colors.surfaceContainer,
    );
  }

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant, languageCode: lang),
          ),
        ),
      );
}

class _EmptyWalletState extends StatelessWidget {
  const _EmptyWalletState({
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 72, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            l10n.noAccountsFound,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant, languageCode: lang),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/add-account'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.newAccount),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.onRetry,
    required this.colors,
    required this.l10n,
    required this.lang,
  });

  final Future<void> Function() onRetry;
  final BankSyncColors colors;
  final AppLocalizations l10n;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            l10n.serverUnreachableMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant, languageCode: lang),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.walletRetry),
          ),
        ],
      ),
    );
  }
}
