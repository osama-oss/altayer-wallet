import 'dart:convert';

/// QR payload for sharing / scanning account numbers between users.
class AccountQrPayload {
  const AccountQrPayload({
    required this.accountNumber,
    this.currency,
    this.label,
  });

  static const type = 'uff-digital-banking-account';
  static const version = 1;

  final String accountNumber;
  final String? currency;
  final String? label;

  String encode() {
    return jsonEncode({
      'v': version,
      'type': type,
      'account': accountNumber,
      if (currency != null) 'currency': currency,
      if (label != null) 'label': label,
    });
  }

  static AccountQrPayload? decode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      final json = jsonDecode(trimmed);
      if (json is Map<String, dynamic>) {
        final account = json['account']?.toString() ?? json['accountNumber']?.toString();
        if (account != null && account.isNotEmpty) {
          return AccountQrPayload(
            accountNumber: account,
            currency: json['currency']?.toString(),
            label: json['label']?.toString(),
          );
        }
      }
    } catch (_) {}

    if (RegExp(r'^[A-Za-z0-9\-]{4,32}$').hasMatch(trimmed)) {
      return AccountQrPayload(accountNumber: trimmed);
    }
    return null;
  }
}
