/// Wallet account identity helpers.
///
/// In the wallet the customer never deals with the real (core) account number.
/// An account is identified by `"<phone>_<currency>"` — the logged-in mobile
/// plus the currency, e.g. `777777777_YER`. The core resolves the real account
/// number from this identifier, so the app builds and passes it everywhere
/// (card display, transfer debit/credit).
library;

/// The fixed set of wallet currencies — one card each.
const List<String> walletCurrencies = ['YER', 'USD', 'SAR'];

/// Reduces a raw phone to its local digits: strips spaces/`+`, a leading `967`
/// country code, and a leading trunk `0`.
String normalizeWalletPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('967')) {
    digits = digits.substring(3);
  } else if (digits.length == 10 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return digits;
}

/// Composes a wallet account id `"<phone>_<CURRENCY>"` from a phone + currency.
String walletAccountId(String phone, String currency) =>
    '${normalizeWalletPhone(phone)}_${currency.trim().toUpperCase()}';

/// Extracts just the phone from a wallet id or a raw phone (the part before
/// `_`), normalized. Used to prefill the recipient field from favorites / QR /
/// beneficiary values that may already carry the `_currency` suffix.
String walletPhonePart(String identifier) {
  final i = identifier.indexOf('_');
  return normalizeWalletPhone(i >= 0 ? identifier.substring(0, i) : identifier);
}
