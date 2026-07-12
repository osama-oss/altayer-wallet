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

/// Extracts the wallet currency from an id like `"<phone>_YER"`, or null when
/// the value carries no known currency suffix. Used to preselect the recipient
/// wallet when prefilling from a favorite / recent transfer / QR that already
/// encodes the currency, so the customer never has to reselect it.
String? walletCurrencyPart(String identifier) {
  final i = identifier.lastIndexOf('_');
  if (i < 0) return null;
  final suffix = identifier.substring(i + 1).trim().toUpperCase();
  return walletCurrencies.contains(suffix) ? suffix : null;
}

/// Strips a trailing wallet currency suffix (`_YER` / `_USD` / `_SAR`) for
/// display only. The wallet stores accounts as `"<number>_<CURRENCY>"`, but the
/// customer must never see the internal currency suffix — they deal with the
/// bare account / wallet number, exactly like a normal banking app.
///
/// Unlike [walletPhonePart] this preserves the number verbatim (leading zeros,
/// no phone trunk normalization) and only strips when the suffix is one of the
/// known wallet currencies, so a real account number that merely contains `_`
/// is left untouched. Keep the original value for anything sent to the API.
String walletDisplayNumber(String value) {
  final v = value.trim();
  final i = v.lastIndexOf('_');
  if (i < 0) return v;
  final suffix = v.substring(i + 1).toUpperCase();
  return walletCurrencies.contains(suffix) ? v.substring(0, i) : v;
}
