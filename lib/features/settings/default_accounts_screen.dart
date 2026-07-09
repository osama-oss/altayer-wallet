import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/banking_account.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../features/transfer/transfer_helpers.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/uff_loader.dart';

class DefaultAccountsScreen extends ConsumerStatefulWidget {
  const DefaultAccountsScreen({super.key});

  @override
  ConsumerState<DefaultAccountsScreen> createState() => _DefaultAccountsScreenState();
}

class _DefaultAccountsScreenState extends ConsumerState<DefaultAccountsScreen> {
  bool _loading = true;
  String? _error;
  List<BankingAccount> _accounts = [];
  String _globalDefault = '';
  final Map<String, String> _currencyDefaults = {};
  bool _saving = false;

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
        setState(() {
          _error = 'Not signed in';
          _loading = false;
        });
        return;
      }
      // Shared caches, read in parallel — instant after the first load.
      final (accounts, prefs) = await (
        ref.read(accountsProvider.future),
        ref.read(accountPreferencesProvider.future),
      ).wait;
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _globalDefault = prefs.globalDefaultAccountNumber ?? '';
        _currencyDefaults
          ..clear()
          ..addAll(prefs.currencyDefaults);
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

  Map<String, List<BankingAccount>> _groupByCurrency() {
    final map = <String, List<BankingAccount>>{};
    for (final account in _accounts) {
      final currency = account.currency.toUpperCase();
      map.putIfAbsent(currency, () => []).add(account);
    }
    return map;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) return;
      await ref.read(apiClientProvider).saveAccountPreferences(token, {
        'globalDefaultAccountNumber': _globalDefault,
        'currencyDefaults': _currencyDefaults,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.defaultAccountsSaved)),
      );
      // The cached preferences are now stale — refetch on reload.
      ref.invalidate(accountPreferencesProvider);
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.defaultAccountsTitle)),
      body: _loading
          ? const Center(child: UffLoader())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: colors.error)))
              : _accounts.isEmpty
                  ? Center(child: Text(l10n.noAccountsFound))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(l10n.defaultAccountsSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        _DropdownField(
                          label: l10n.defaultAccountsGlobal,
                          value: _globalDefault,
                          accounts: _accounts,
                          onChanged: (v) => setState(() => _globalDefault = v ?? ''),
                        ),
                        const SizedBox(height: 20),
                        Text(l10n.defaultAccountsPerCurrency,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ..._groupByCurrency().entries.map((entry) {
                          final currency = entry.key;
                          final accounts = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DropdownField(
                              label: currency,
                              value: _currencyDefaults[currency] ?? '',
                              accounts: accounts,
                              onChanged: (v) => setState(() {
                                if (v == null || v.isEmpty) {
                                  _currencyDefaults.remove(currency);
                                } else {
                                  _currencyDefaults[currency] = v;
                                }
                              }),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(_saving ? l10n.saving : l10n.saveDefaultAccounts),
                        ),
                      ],
                    ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<BankingAccount> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: '', child: Text('—')),
        ...accounts.map(
          (a) => DropdownMenuItem(
            value: a.accountNumber,
            child: Text(accountDropdownLabel(a)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
