import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models/account_transaction.dart';
import '../../core/models/banking_account.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/qr/account_qr_payload.dart';
import '../../core/security/screen_security.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/transaction_tile.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import 'transactions_screen.dart';
import '../../core/widgets/uff_loader.dart';

class AccountDetailScreen extends ConsumerStatefulWidget {
  const AccountDetailScreen({super.key, required this.account});

  final BankingAccount account;

  @override
  ConsumerState<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  static const _integrationCode = 'ACCOUNT-LAST-TEN-TXN';
  static const _negativeAmount = Color(0xFFEB5757);
  static const _positiveAmount = Color(0xFF27AE60);

  bool _loadingTxns = true;
  String? _txnsError;
  List<AccountTransaction> _transactions = [];
  int? _totalCount;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _loadingTxns = true;
      _txnsError = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final token = await auth.readToken();
      if (token == null) {
        if (mounted) {
          notifyRouterAuthChanged(ref);
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
        return;
      }

      final api = ref.read(apiClientProvider);
      final payload = await api.invokeIntegration(
        token,
        _integrationCode,
        {'accountNo': widget.account.accountNoForIntegration},
      );

      if (!mounted) return;
      setState(() {
        _transactions = AccountTransaction.listFromIntegration(payload);
        _totalCount = AccountTransaction.totalCountFromIntegration(payload);
        _loadingTxns = false;
        if (_transactions.isEmpty) {
          _txnsError = null;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _txnsError = e.message;
        _loadingTxns = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _txnsError = e.toString();
        _loadingTxns = false;
      });
    }
  }

  void _openAllTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SecureScreen(
          child: TransactionsScreen(
            account: widget.account,
            initialTransactions: _transactions,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final colors = context.bankColors;
    final account = widget.account;
    final formatted = NumberFormat('#,##0.00').format(account.balance);
    final qrData = AccountQrPayload(
      accountNumber: account.accountNumber,
      currency: account.currency,
      label: account.label,
    ).encode();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(account.label),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.secondary, colors.secondaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.label.toUpperCase(),
                      style: AppTextStyles.labelSm(
                        color: colors.onSecondary.withValues(alpha: 0.85),
                        languageCode: languageCode,
                      ).copyWith(letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$formatted ${account.currency}',
                      style: AppTextStyles.balanceDisplay(color: colors.onSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      account.accountNumber,
                      style: AppTextStyles.monoLabel(
                        color: colors.onSecondary.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(l10n.scanToPay, style: AppTextStyles.headlineMd(languageCode: languageCode)),
                    const SizedBox(height: 8),
                    Text(
                      l10n.shareQrForTransfers,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd(
                        color: colors.onSurfaceVariant,
                        languageCode: languageCode,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 192,
                        backgroundColor: colors.surfaceContainerLowest,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            account.accountNumber,
                            style: AppTextStyles.bodyMd(
                              color: colors.primary,
                              languageCode: languageCode,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: account.accountNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.accountNumberCopied)),
                            );
                          },
                          icon: Icon(Icons.content_copy, color: colors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.recentTransactions,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd(languageCode: languageCode),
                    ),
                  ),
                  if (_totalCount != null && _totalCount! > _transactions.length) ...[
                    Text(
                      l10n.transactionsShowingCount(_transactions.length, _totalCount!),
                      style: AppTextStyles.labelSm(
                        color: colors.onSurfaceVariant,
                        languageCode: languageCode,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (_transactions.isNotEmpty)
                    TextButton(
                      onPressed: _openAllTransactions,
                      child: Text(
                        l10n.viewAll,
                        style: AppTextStyles.labelSm(
                          color: colors.secondary,
                          languageCode: languageCode,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loadingTxns)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: UffLoader()),
                )
              else if (_txnsError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _txnsError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                )
              else if (_transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.noTransactionsForAccount,
                    style: AppTextStyles.bodyMd(
                      color: colors.onSurfaceVariant,
                      languageCode: languageCode,
                    ),
                  ),
                )
              else
                ..._transactions.map((txn) {
                  final credit = txn.isCredit;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TransactionTile(
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
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
