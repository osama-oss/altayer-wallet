import 'package:banksync_app/core/models/banking_account.dart';

/// Demo accounts for home carousel (MOBILE_API shape compatible).
class DummyAccounts {
  DummyAccounts._();

  static const List<BankingAccount> all = [
    BankingAccount(
      id: 1,
      accountNumber: 'ACC1001',
      label: 'Primary account',
      currency: 'LYD',
      balance: 12500.75,
      cardColor: 0xFF001643,
    ),
    BankingAccount(
      id: 2,
      accountNumber: 'ACC2002',
      label: 'Savings',
      currency: 'LYD',
      balance: 45800.00,
      cardColor: 0xFF0C2A66,
    ),
    BankingAccount(
      id: 3,
      accountNumber: 'ACC3003',
      label: 'Business',
      currency: 'USD',
      balance: 3200.50,
      cardColor: 0xFF1F4D8C,
    ),
  ];
}
