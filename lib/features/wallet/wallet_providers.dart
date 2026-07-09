import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/account_transaction.dart';
import '../../core/models/banking_account.dart';
import '../../core/providers/app_providers.dart';

/// The customer's "wallet" is a real UFF account presented with a single-balance
/// wallet UX. We pick the primary spending account: the first YER account when
/// present (the local wallet currency), otherwise the first account returned by
/// [accountsProvider]. Returns null while accounts are still loading or empty.
final primaryWalletProvider = Provider<BankingAccount?>((ref) {
  final accounts =
      ref.watch(accountsProvider).valueOrNull ?? const <BankingAccount>[];
  if (accounts.isEmpty) return null;
  for (final a in accounts) {
    if (a.currency.trim().toUpperCase() == 'YER') return a;
  }
  return accounts.first;
});

/// Last-ten transactions for a wallet account, via the same
/// `ACCOUNT-LAST-TEN-TXN` integration the full history screen uses — no new
/// backend call. Keyed by the integration account number so switching the
/// active wallet refetches cleanly. autoDispose so it re-fetches on revisit.
final walletRecentActivityProvider = FutureProvider.autoDispose
    .family<List<AccountTransaction>, String>((ref, accountNo) async {
  final token = await ref.read(authServiceProvider).readToken();
  if (token == null || token.isEmpty) return const [];
  final payload = await ref.read(apiClientProvider).invokeIntegration(
        token,
        'ACCOUNT-LAST-TEN-TXN',
        {'accountNo': accountNo},
      );
  return AccountTransaction.listFromIntegration(payload);
});
