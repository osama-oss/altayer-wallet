import '../../core/models/banking_account.dart';
import '../../core/wallet_account_id.dart';

// NOTE: accounts + preferences are read from the shared cached providers
// (`accountsProvider` / `accountPreferencesProvider` in app_providers.dart).
// Do not add ad-hoc fetch helpers here — they bypass the cache and made the
// transfer screens re-hit the core on every open.

Map<String, dynamic> transferPayload({
  required String debitAccount,
  required String creditAccount,
  required String amountText,
}) {
  return {
    'debitAmount': num.tryParse(amountText.trim()) ?? 0,
    'myAccount': debitAccount,
    'theirAccount': creditAccount,
  };
}

String transferResultReference(Map<String, dynamic>? result) {
  if (result == null || result.isEmpty) return '—';
  final id = _findTransferReferenceId(result);
  if (id != null) return id;
  final reference = result['reference'];
  if (reference != null && '$reference'.trim().isNotEmpty) {
    return '$reference'.trim();
  }
  return '—';
}

/// Best-effort extraction of the counterparty (beneficiary) name from a
/// validate/confirm response, searching common core keys. Returns null when no
/// name is present (caller then falls back to the account number).
String? transferCounterpartyName(Map<String, dynamic>? result) {
  if (result == null || result.isEmpty) return null;
  const keys = {
    'beneficiaryname',
    'creditcustomername',
    'customername',
    'accountname',
    'theiraccountname',
    'tocustomername',
    'fullname',
    'name',
    'beneficiary',
  };
  return _findNameByKeys(result, keys);
}

String? _findNameByKeys(Map map, Set<String> keys) {
  for (final entry in map.entries) {
    if (keys.contains(entry.key.toString().toLowerCase())) {
      final name = _asNameString(entry.value);
      if (name != null) return name;
    }
  }
  for (final entry in map.entries) {
    final value = entry.value;
    if (value is Map) {
      final found = _findNameByKeys(value, keys);
      if (found != null) return found;
    }
  }
  return null;
}

String? _asNameString(dynamic value) {
  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
  if (value is Map) {
    final ar = value['ar']?.toString().trim();
    if (ar != null && ar.isNotEmpty) return ar;
    final en = value['en']?.toString().trim();
    if (en != null && en.isNotEmpty) return en;
  }
  return null;
}

String? _findTransferReferenceId(Map<String, dynamic> map) {
  for (final key in ['ID', 'id']) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    if (value != null && '$value'.trim().isNotEmpty) return '$value'.trim();
  }
  for (final entry in map.entries) {
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      final nested = _findTransferReferenceId(value);
      if (nested != null) return nested;
    } else if (value is Map) {
      final nested = _findTransferReferenceId(Map<String, dynamic>.from(value));
      if (nested != null) return nested;
    }
  }
  return null;
}

String accountDropdownLabel(BankingAccount account) {
  return '${walletDisplayNumber(account.accountNumber)} (${account.currency})';
}

/// A cross-currency quote read from the `TRANSFER-TO-ACC-VALIDATE` response.
class TransferQuote {
  const TransferQuote({
    required this.debitAmount,
    required this.debitCurrency,
    required this.creditAmount,
    required this.creditCurrency,
    this.dealRate,
  });

  final num debitAmount;
  final String debitCurrency;
  final num creditAmount; // creditNetAmount
  final String creditCurrency;
  final num? dealRate; // units of debit currency per 1 unit of credit currency

  bool get isCrossCurrency =>
      creditCurrency.trim().isNotEmpty &&
      debitCurrency.trim().isNotEmpty &&
      creditCurrency.trim().toUpperCase() != debitCurrency.trim().toUpperCase();
}

num? _numOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString().trim());
}

/// Extracts the deal rate + converted amount from a validate response.
///
/// The channel response carries `creditNetAmount`, `creditCurrency` and
/// `dealRate` (the latter as a string, e.g. "1406.0"), but NOT the debit
/// currency — so it is supplied from the selected debit account. Returns null
/// when the payload lacks credit info.
TransferQuote? parseTransferQuote(
  Map<String, dynamic>? validation, {
  required String debitCurrency,
}) {
  if (validation == null || validation.isEmpty) return null;
  Map<String, dynamic> map = validation;
  final nested = validation['data'];
  if (nested is Map) map = Map<String, dynamic>.from(nested);

  final creditCurrency = map['creditCurrency']?.toString().trim() ?? '';
  final creditAmount = _numOrNull(map['creditNetAmount']);
  if (creditCurrency.isEmpty || creditAmount == null) return null;

  final debitAmount = _numOrNull(map['debitAmount']) ?? 0;
  num? dealRate = _numOrNull(map['dealRate']);
  // Safety net only — the backend now returns dealRate directly.
  if (dealRate == null && debitAmount > 0 && creditAmount > 0) {
    dealRate = debitAmount / creditAmount;
  }

  return TransferQuote(
    debitAmount: debitAmount,
    debitCurrency: debitCurrency,
    creditAmount: creditAmount,
    creditCurrency: creditCurrency,
    dealRate: dealRate,
  );
}

/// Flattens validate API payload into label/value rows for the confirm sheet.
List<(String label, String value)> validationDetailRows(Map<String, dynamic>? raw) {
  if (raw == null || raw.isEmpty) return [];

  var map = raw;
  final nested = raw['data'];
  if (nested is Map<String, dynamic> && nested.isNotEmpty) {
    map = nested;
  } else if (nested is Map && nested.isNotEmpty) {
    map = Map<String, dynamic>.from(nested);
  }

  final rows = <(String, String)>[];
  void walk(Map<String, dynamic> source, [String prefix = '']) {
    for (final entry in source.entries) {
      if (entry.key == 'data' && entry.value is Map && prefix.isEmpty) {
        walk(Map<String, dynamic>.from(entry.value as Map));
        continue;
      }
      final label = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      final value = entry.value;
      if (value == null) continue;
      if (value is Map) {
        walk(Map<String, dynamic>.from(value), label);
      } else if (value is List) {
        if (value.isEmpty) continue;
        rows.add((label, value.map((e) => '$e').join(', ')));
      } else {
        final text = '$value'.trim();
        if (text.isNotEmpty) rows.add((label, text));
      }
    }
  }

  walk(map);
  return rows;
}

String _humanizeValidationKey(String key) {
  return key
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

List<(String label, String value)> labeledValidationRows(Map<String, dynamic>? raw) {
  return validationDetailRows(raw)
      .map((row) => (_humanizeValidationKey(row.$1), row.$2))
      .toList();
}
