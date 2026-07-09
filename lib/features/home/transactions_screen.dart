import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/account_transaction.dart';
import '../../core/models/banking_account.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/transaction_tile.dart';
import '../../l10n/app_localizations.dart';
import 'account_statement_pdf.dart';
import '../../core/widgets/uff_loader.dart';

enum _TxnFilter { all, incoming, outgoing }

/// Full transaction history for a single account with client-side search,
/// in/out filtering and newest-first sorting.
///
/// Backed by the same `ACCOUNT-LAST-TEN-TXN` integration the detail screen
/// already uses — no new backend call. Deeper pagination would require a core
/// change, so this operates over the rows the integration returns.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.account,
    this.initialTransactions,
  });

  final BankingAccount account;

  /// Already-loaded rows (from the detail screen) used to render immediately.
  /// Pull-to-refresh always re-fetches.
  final List<AccountTransaction>? initialTransactions;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  static const _integrationCode = 'ACCOUNT-LAST-TEN-TXN';
  static const _negativeAmount = Color(0xFFEB5757);
  static const _positiveAmount = Color(0xFF27AE60);

  final TextEditingController _searchController = TextEditingController();

  late bool _loading;
  String? _error;
  List<AccountTransaction> _transactions = [];
  int? _totalCount;
  bool _sharing = false;
  String _query = '';
  _TxnFilter _filter = _TxnFilter.all;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialTransactions;
    if (seed != null && seed.isNotEmpty) {
      _transactions = seed;
      _loading = false;
    } else {
      _loading = true;
      _loadTransactions();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final token = await auth.readToken();
      if (token == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final payload = await ref.read(apiClientProvider).invokeIntegration(
        token,
        _integrationCode,
        {'accountNo': widget.account.accountNoForIntegration},
      );

      if (!mounted) return;
      setState(() {
        _transactions = AccountTransaction.listFromIntegration(payload);
        _totalCount = AccountTransaction.totalCountFromIntegration(payload);
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

  /// Applies the active filter + search query, newest first.
  List<AccountTransaction> get _visibleTransactions {
    final query = _query.trim().toLowerCase();
    Iterable<AccountTransaction> list = _transactions;

    switch (_filter) {
      case _TxnFilter.incoming:
        list = list.where((t) => t.isCredit);
      case _TxnFilter.outgoing:
        list = list.where((t) => !t.isCredit);
      case _TxnFilter.all:
        break;
    }

    if (query.isNotEmpty) {
      list = list.where((t) =>
          t.transactionDesc.toLowerCase().contains(query) ||
          t.transactionReference.toLowerCase().contains(query) ||
          (t.narrative ?? '').toLowerCase().contains(query));
    }

    final result = list.toList();
    result.sort((a, b) {
      final da = DateTime.tryParse(a.bookingDate);
      final db = DateTime.tryParse(b.bookingDate);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return result;
  }

  /// All fetched rows, newest-first, ignoring the on-screen search/filter — the
  /// statement is a record of the available transactions, not the ad-hoc view.
  List<AccountTransaction> _statementTransactions() {
    final list = [..._transactions];
    list.sort((a, b) {
      final da = DateTime.tryParse(a.bookingDate);
      final db = DateTime.tryParse(b.bookingDate);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  Future<void> _shareStatement() async {
    if (_sharing || _transactions.isEmpty) return;
    setState(() => _sharing = true);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    try {
      await shareAccountStatement(
        account: widget.account,
        transactions: _statementTransactions(),
        totalCount: _totalCount,
      );
    } catch (e, st) {
      debugPrint('shareAccountStatement failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isAr ? 'تعذّر إنشاء الكشف' : 'Could not generate statement'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final canShare = !_loading && _error == null && _transactions.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.transactionHistory),
        centerTitle: true,
        actions: [
          if (canShare)
            IconButton(
              tooltip: l10n.accountStatement,
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: UffLoader(),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _sharing ? null : _shareStatement,
            ),
        ],
      ),
      body: Column(
        children: [
          _SearchField(
            controller: _searchController,
            hint: l10n.searchTransactions,
            onChanged: (v) => setState(() => _query = v),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          _FilterRow(
            active: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              color: colors.secondary,
              child: _buildList(colors, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BankSyncColors colors, AppLocalizations l10n) {
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

    final items = _visibleTransactions;
    if (items.isEmpty) {
      final isFiltered = _query.trim().isNotEmpty || _filter != _TxnFilter.all;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.28),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                isFiltered
                    ? l10n.noMatchingTransactions
                    : l10n.noTransactionsForAccount,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.transactionsCount(items.length),
              style: AppTextStyles.labelSm(color: colors.onSurfaceVariant),
            ),
          );
        }
        final txn = items[index - 1];
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
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            prefixIcon: Icon(Icons.search_rounded, color: colors.outline, size: 20),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.outline, size: 18),
                    onPressed: onClear,
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          ),
          style: AppTextStyles.bodyMd(color: colors.onSurface),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.active, required this.onChanged});

  final _TxnFilter active;
  final ValueChanged<_TxnFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: l10n.filterAll,
            selected: active == _TxnFilter.all,
            onTap: () => onChanged(_TxnFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.filterIncoming,
            selected: active == _TxnFilter.incoming,
            onTap: () => onChanged(_TxnFilter.incoming),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.filterOutgoing,
            selected: active == _TxnFilter.outgoing,
            onTap: () => onChanged(_TxnFilter.outgoing),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Material(
      color: selected ? colors.secondary : colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
            border: Border.all(
              color: selected ? colors.secondary : colors.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSm(
              color: selected ? colors.onSecondary : colors.onSurfaceVariant,
              languageCode: languageCode,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
