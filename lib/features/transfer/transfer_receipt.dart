/// Immutable data for a transfer receipt (rendered to a shareable PDF / text).
class TransferReceipt {
  const TransferReceipt({
    required this.amount,
    required this.currency,
    required this.fromAccount,
    required this.toAccount,
    required this.reference,
    required this.date,
    this.typeLabel,
    this.fromName,
    this.toName,
    this.purpose,
  });

  final String amount; // e.g. "100.00"
  final String currency; // e.g. "SAR"
  final String fromAccount;
  final String toAccount;
  final String reference;
  final DateTime date;

  /// e.g. "حوالة صادرة" / "تحويل بين حساباتي".
  final String? typeLabel;
  final String? fromName;
  final String? toName;
  final String? purpose;
}

/// Masks an account / IBAN to its last 4 digits, e.g. "**** 7045".
String maskAccount(String account) {
  final a = account.trim();
  if (a.length <= 4) return a;
  return '**** ${a.substring(a.length - 4)}';
}
