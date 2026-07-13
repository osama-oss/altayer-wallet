import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/data/accounts_repository.dart';
import '../../core/models/banking_account.dart';
import '../../core/network/api_error_message.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/security/screen_security.dart';
import '../../core/theme/app_colors.dart';
import '../../core/wallet_account_id.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import '../home/account_detail_screen.dart';
import '../../core/widgets/uff_loader.dart';

/// "All accounts" screen — the full list behind the home carousel's *View all*.
///
/// Shows ONLY the signed-in customer's own accounts (scoped by the JWT via the
/// shared [accountsRepositoryProvider] → CUSTOMER_ACCOUNTS_SEARCH), each with
/// its own balance. No cross-currency total is ever computed; per-currency
/// subtotals only. Client-side search, currency filtering, a hide-zero toggle
/// and a balance-privacy toggle operate over the fetched rows — no new backend.
class AllAccountsScreen extends ConsumerStatefulWidget {
  const AllAccountsScreen({super.key, this.initialAccounts});

  /// Already-loaded accounts (from the home carousel) used to seed the list and
  /// skip the first spinner. Pull-to-refresh always re-fetches.
  final List<BankingAccount>? initialAccounts;

  @override
  ConsumerState<AllAccountsScreen> createState() => _AllAccountsScreenState();
}

class _AllAccountsScreenState extends ConsumerState<AllAccountsScreen> {
  static const _currencyAll = 'ALL';

  final TextEditingController _searchController = TextEditingController();

  late bool _loading;
  String? _error;
  List<BankingAccount> _accounts = [];

  String _query = '';
  String _currencyFilter = _currencyAll;
  bool _hideZero = false;
  bool _balancesVisible = true;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialAccounts;
    if (seed != null && seed.isNotEmpty) {
      _accounts = seed;
      _loading = false;
    } else {
      _loading = true;
      _loadAccounts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Shared cache — instant when warm, single flight when several screens
      // ask at once.
      final accounts = await ref.read(accountsProvider.future);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _error = null;
        _loading = false;
      });
    } on AccountsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _errorText(e.kind);
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
        // Never surface the raw DioException text. Transport failures (timeout,
        // no connection) get the friendly "server unreachable" copy; anything
        // else is passed through the shared humanizer.
        _error = isNetworkError(e)
            ? context.l10n.serverUnreachableMessage
            : formatThrowableMessage(e);
        _loading = false;
      });
    }
  }

  String _errorText(AccountsErrorKind kind) {
    final l10n = context.l10n;
    return switch (kind) {
      AccountsErrorKind.customerIdMissing => l10n.customerIdMissing,
      AccountsErrorKind.noAccounts => l10n.noAccountsFound,
    };
  }

  void _openDetails(BankingAccount account) {
    // Screenshot-able: the account detail's receive QR + recent transactions
    // are meant to be captured/shared (opts out of screen protection).
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UnsecureScreen(child: AccountDetailScreen(account: account)),
      ),
    );
  }

  void _copyAccountNumber(String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.copied)),
    );
  }

  /// Distinct currencies present, first-seen order — drives the filter chips.
  List<String> get _currencies {
    final seen = <String>[];
    for (final a in _accounts) {
      if (!seen.contains(a.currency)) seen.add(a.currency);
    }
    return seen;
  }

  /// Accounts after currency filter + search query + hide-zero toggle.
  List<BankingAccount> get _visibleAccounts {
    final query = _query.trim().toLowerCase();
    return _accounts.where((a) {
      if (_currencyFilter != _currencyAll && a.currency != _currencyFilter) {
        return false;
      }
      if (_hideZero && a.balance == 0) return false;
      if (query.isNotEmpty) {
        final haystack = '${a.accountNumber} ${a.label}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  /// Groups the given accounts by currency, preserving first-seen order.
  Map<String, List<BankingAccount>> _groupByCurrency(List<BankingAccount> accounts) {
    final grouped = <String, List<BankingAccount>>{};
    for (final account in accounts) {
      grouped.putIfAbsent(account.currency, () => []).add(account);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch when accounts change elsewhere (e.g. a new account is opened).
    ref.listen(accountsRevisionProvider, (_, __) => _loadAccounts());

    final l10n = context.l10n;
    final colors = context.bankColors;
    final hasAccounts = !_loading && _error == null && _accounts.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.allAccounts),
        centerTitle: true,
        actions: [
          if (hasAccounts)
            IconButton(
              tooltip: l10n.totalBalance,
              icon: Icon(_balancesVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () =>
                  setState(() => _balancesVisible = !_balancesVisible),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-account'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addAccount),
        backgroundColor: colors.secondary,
        foregroundColor: colors.onSecondary,
      ),
      body: _buildBody(colors, l10n),
    );
  }

  Widget _buildBody(BankSyncColors colors, AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: UffLoader());
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadAccounts,
        color: colors.secondary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.24),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 56, color: colors.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _loadAccounts,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.secondary,
                        foregroundColor: colors.onSecondary,
                      ),
                      label: Text(l10n.walletRetry),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _Toolbar(
          controller: _searchController,
          currencies: _currencies,
          currencyFilter: _currencyFilter,
          hideZero: _hideZero,
          onQueryChanged: (v) => setState(() => _query = v),
          onClearQuery: () {
            _searchController.clear();
            setState(() => _query = '');
          },
          onCurrencyChanged: (c) => setState(() => _currencyFilter = c),
          onHideZeroChanged: (v) => setState(() => _hideZero = v),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAccounts,
            color: colors.secondary,
            child: _buildList(colors, l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildList(BankSyncColors colors, AppLocalizations l10n) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final visible = _visibleAccounts;

    if (visible.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.28),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.noMatchingAccounts,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }

    final groups = _groupByCurrency(visible);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
          child: Text(
            l10n.accountsCount(visible.length),
            style: AppTextStyles.labelSm(color: colors.onSurfaceVariant),
          ),
        ),
        for (final entry in groups.entries) ...[
          _CurrencyHeader(
            currency: entry.key,
            count: entry.value.length,
            subtotal: entry.value.fold<double>(0, (sum, a) => sum + a.balance),
            balancesVisible: _balancesVisible,
            colors: colors,
            languageCode: languageCode,
          ),
          const SizedBox(height: 10),
          for (final account in entry.value) ...[
            _AccountListCard(
              account: account,
              balancesVisible: _balancesVisible,
              colors: colors,
              languageCode: languageCode,
              onTap: () => _openDetails(account),
              onCopy: () =>
                  _copyAccountNumber(walletDisplayNumber(account.accountNumber)),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Masks an amount when balances are hidden, else formats it grouped.
String _formatBalance(double value, {required bool visible}) {
  if (!visible) return '••••••';
  return NumberFormat('#,##0.00').format(value);
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.currencies,
    required this.currencyFilter,
    required this.hideZero,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onCurrencyChanged,
    required this.onHideZeroChanged,
  });

  final TextEditingController controller;
  final List<String> currencies;
  final String currencyFilter;
  final bool hideZero;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<bool> onHideZeroChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    // Currency chips only add value when more than one currency is present.
    final showCurrencyChips = currencies.length > 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.searchAccounts,
                prefixIcon:
                    Icon(Icons.search_rounded, color: colors.outline, size: 20),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: colors.outline, size: 18),
                        onPressed: onClearQuery,
                      ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              ),
              style: AppTextStyles.bodyMd(color: colors.onSurface),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (showCurrencyChips) ...[
                _Chip(
                  label: l10n.filterAll,
                  selected: currencyFilter == _AllAccountsScreenState._currencyAll,
                  onTap: () =>
                      onCurrencyChanged(_AllAccountsScreenState._currencyAll),
                ),
                const SizedBox(width: 8),
                for (final c in currencies) ...[
                  _Chip(
                    label: c,
                    selected: currencyFilter == c,
                    onTap: () => onCurrencyChanged(c),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
              _Chip(
                label: l10n.hideZeroBalances,
                icon: hideZero
                    ? Icons.check_circle_rounded
                    : Icons.remove_circle_outline_rounded,
                selected: hideZero,
                onTap: () => onHideZeroChanged(!hideZero),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final fg = selected ? colors.onSecondary : colors.onSurfaceVariant;
    return Material(
      color: selected ? colors.secondary : colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
            border: Border.all(
              color: selected ? colors.secondary : colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTextStyles.labelSm(color: fg, languageCode: languageCode)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyHeader extends StatelessWidget {
  const _CurrencyHeader({
    required this.currency,
    required this.count,
    required this.subtotal,
    required this.balancesVisible,
    required this.colors,
    required this.languageCode,
  });

  final String currency;
  final int count;
  final double subtotal;
  final bool balancesVisible;
  final BankSyncColors colors;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final formatted = _formatBalance(subtotal, visible: balancesVisible);
    final negative = balancesVisible && subtotal < 0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
          ),
          child: Text(
            currency,
            style: AppTextStyles.labelSm(color: colors.secondary)
                .copyWith(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: AppTextStyles.labelSm(
            color: colors.onSurfaceVariant,
            languageCode: languageCode,
          ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          '$formatted $currency',
          textDirection: TextDirection.ltr,
          style: AppTextStyles.monoLabel(
            color: negative ? AppColors.error : colors.onSurface,
          ).copyWith(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _AccountListCard extends StatelessWidget {
  const _AccountListCard({
    required this.account,
    required this.balancesVisible,
    required this.colors,
    required this.languageCode,
    required this.onTap,
    required this.onCopy,
  });

  final BankingAccount account;
  final bool balancesVisible;
  final BankSyncColors colors;
  final String languageCode;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final formatted = _formatBalance(account.balance, visible: balancesVisible);
    final negative = balancesVisible && account.balance < 0;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      child: InkWell(
        onTap: onTap,
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
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                ),
                child: Icon(Icons.account_balance_wallet_outlined,
                    color: colors.secondary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd(
                        color: colors.onSurface,
                        languageCode: languageCode,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            walletDisplayNumber(account.accountNumber),
                            textDirection: TextDirection.ltr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTextStyles.monoLabel(color: colors.onSurfaceVariant)
                                    .copyWith(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: onCopy,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.content_copy_rounded,
                                size: 14, color: colors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatted,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.monoLabel(
                      color: negative ? AppColors.error : colors.onSurface,
                    ).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.currency,
                    style: AppTextStyles.labelSm(
                      color: colors.onSurfaceVariant,
                      languageCode: languageCode,
                    ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
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
