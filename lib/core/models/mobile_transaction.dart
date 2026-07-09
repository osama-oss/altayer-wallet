import 'package:intl/intl.dart';

/// One row from `GET /api/mobile/transactions` — the server-side log of a
/// transfer the customer made through the app (db_mobile.mobile_transactions),
/// scoped to the signed-in customer by the backend.
///
/// Shape mirrors the backend `TransactionResponse` DTO: it exposes the
/// destination (`creditAccount`) but not the debit account or beneficiary name.
class MobileTransaction {
  const MobileTransaction({
    required this.id,
    required this.reference,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.creditAccount,
    this.billerCode,
    this.createdAt,
  });

  final int id;
  final String reference;
  final String type;
  final double amount;
  final String currency;
  final String status;
  final String creditAccount;

  /// Set for BILL_PAYMENT rows — which provider the payment went to.
  final String? billerCode;
  final DateTime? createdAt;

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  factory MobileTransaction.fromMap(Map<String, dynamic> map) {
    return MobileTransaction(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}') ?? 0,
      reference: map['reference']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      currency: map['currency']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      creditAccount: map['creditAccount']?.toString() ?? '',
      billerCode: (map['billerCode']?.toString().isNotEmpty ?? false)
          ? map['billerCode'].toString()
          : null,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '')?.toLocal(),
    );
  }

  /// Maps the raw list from `api_client.transactions()`, newest first.
  static List<MobileTransaction> listFrom(List<dynamic> rows) {
    final list = rows
        .whereType<Map>()
        .map((e) => MobileTransaction.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    list.sort((a, b) {
      final da = a.createdAt;
      final db = b.createdAt;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  String formattedAmount() {
    final formatted = NumberFormat('#,##0.00').format(amount.abs());
    final ccy = currency.isNotEmpty ? ' $currency' : '';
    return '$formatted$ccy';
  }

  String formattedDate() {
    final date = createdAt;
    if (date == null) return '';
    return DateFormat.yMMMd().add_jm().format(date);
  }
}
