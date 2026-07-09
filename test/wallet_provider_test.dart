import 'package:banksync_app/core/models/banking_account.dart';
import 'package:banksync_app/core/providers/app_providers.dart';
import 'package:banksync_app/features/wallet/wallet_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Overrides [accountsProvider] with a fixed list so [primaryWalletProvider]'s
/// selection logic can be tested without the network / auth layer.
class _FakeAccountsNotifier extends AccountsNotifier {
  _FakeAccountsNotifier(this._list);
  final List<BankingAccount> _list;

  @override
  Future<List<BankingAccount>> build() async => _list;
}

BankingAccount _acc(int id, String ccy, double bal) => BankingAccount(
      id: id,
      accountNumber: 'ACC$id',
      label: 'A$id',
      currency: ccy,
      balance: bal,
    );

Future<BankingAccount?> _primaryFor(List<BankingAccount> list) async {
  final container = ProviderContainer(overrides: [
    accountsProvider.overrideWith(() => _FakeAccountsNotifier(list)),
  ]);
  addTearDown(container.dispose);
  await container.read(accountsProvider.future);
  return container.read(primaryWalletProvider);
}

void main() {
  group('primaryWalletProvider', () {
    test('prefers the YER (local wallet currency) account when present', () async {
      final primary = await _primaryFor([
        _acc(1, 'USD', 100),
        _acc(2, 'YER', 200),
        _acc(3, 'SAR', 300),
      ]);
      expect(primary?.currency, 'YER');
      expect(primary?.id, 2);
    });

    test('falls back to the first account when no YER account exists', () async {
      final primary = await _primaryFor([
        _acc(1, 'USD', 100),
        _acc(2, 'SAR', 300),
      ]);
      expect(primary?.id, 1);
    });

    test('returns null when the customer has no accounts', () async {
      final primary = await _primaryFor(const []);
      expect(primary, isNull);
    });
  });
}
