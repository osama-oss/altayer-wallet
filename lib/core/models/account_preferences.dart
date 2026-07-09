import '../../core/models/banking_account.dart';

class AccountPreferencesData {
  const AccountPreferencesData({
    this.globalDefaultAccountNumber,
    this.currencyDefaults = const {},
  });

  final String? globalDefaultAccountNumber;
  final Map<String, String> currencyDefaults;

  factory AccountPreferencesData.fromMap(Map<String, dynamic> map) {
    final currencyRaw = map['currencyDefaults'];
    final currencyDefaults = <String, String>{};
    if (currencyRaw is Map) {
      currencyRaw.forEach((key, value) {
        final k = '$key'.trim().toUpperCase();
        final v = '$value'.trim();
        if (k.isNotEmpty && v.isNotEmpty) {
          currencyDefaults[k] = v;
        }
      });
    }
    final global = map['globalDefaultAccountNumber']?.toString().trim();
    return AccountPreferencesData(
      globalDefaultAccountNumber: global != null && global.isNotEmpty ? global : null,
      currencyDefaults: currencyDefaults,
    );
  }
}

int indexOfDefaultAccount(
  List<BankingAccount> accounts,
  AccountPreferencesData preferences, {
  String? currency,
}) {
  if (accounts.isEmpty) return 0;
  final target = resolveDefaultAccountNumber(accounts, preferences, currency: currency);
  if (target == null) return 0;
  final index = accounts.indexWhere((a) => a.accountNumber == target);
  return index >= 0 ? index : 0;
}

String? resolveDefaultAccountNumber(
  List<BankingAccount> accounts,
  AccountPreferencesData preferences, {
  String? currency,
}) {
  if (accounts.isEmpty) return null;
  if (currency != null && currency.trim().isNotEmpty) {
    final scoped = preferences.currencyDefaults[currency.trim().toUpperCase()];
    if (scoped != null && accounts.any((a) => a.accountNumber == scoped)) {
      return scoped;
    }
    final firstInCurrency = accounts
        .where((a) => a.currency.toUpperCase() == currency.trim().toUpperCase())
        .map((a) => a.accountNumber)
        .firstOrNull;
    if (firstInCurrency != null) return firstInCurrency;
  }
  final global = preferences.globalDefaultAccountNumber;
  if (global != null && accounts.any((a) => a.accountNumber == global)) {
    return global;
  }
  return accounts.first.accountNumber;
}

BankingAccount? resolveDefaultAccount(
  List<BankingAccount> accounts,
  AccountPreferencesData preferences, {
  String? currency,
}) {
  final number = resolveDefaultAccountNumber(accounts, preferences, currency: currency);
  if (number == null) return null;
  for (final account in accounts) {
    if (account.accountNumber == number) return account;
  }
  return accounts.isNotEmpty ? accounts.first : null;
}
