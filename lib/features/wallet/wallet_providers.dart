import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/account_transaction.dart';
import '../../core/models/banking_account.dart';
import '../../core/providers/app_providers.dart';

/// Per-wallet-card balance visibility. Every wallet card owns its own eye
/// toggle, so revealing/hiding the balance on one card (e.g. the YER wallet)
/// must never touch the others. State is the set of *revealed* wallet keys
/// (the card's account number); a key that is absent means the balance is
/// obscured — the secure default when the screen first opens.
final walletBalanceVisibilityProvider =
    StateNotifierProvider<WalletBalanceVisibility, Set<String>>(
  (ref) => WalletBalanceVisibility(),
);

class WalletBalanceVisibility extends StateNotifier<Set<String>> {
  WalletBalanceVisibility() : super(const <String>{});

  /// True when the wallet keyed by [walletKey] should hide its balance.
  bool isObscured(String walletKey) => !state.contains(walletKey);

  /// Flip a single wallet's visibility without disturbing any other card.
  void toggle(String walletKey) {
    final next = Set<String>.of(state);
    if (!next.remove(walletKey)) next.add(walletKey);
    state = next;
  }
}

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
