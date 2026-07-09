import 'package:intl/intl.dart';

/// Result of `BILL_PAY` / `BILL_STATUS` — the mobile_transactions row as the
/// orchestrator returns it. `PENDING` is a first-class state here: the
/// aggregator may settle asynchronously (webhook / BILL_STATUS reconciliation).
class BillReceipt {
  const BillReceipt({
    required this.reference,
    required this.status,
    this.billerCode,
    this.subscriberNo,
    this.debitAccount,
    this.amount,
    this.currency = 'YER',
    this.providerRef,
    this.message,
    this.createdAt,
  });

  final String reference;
  final String status;
  final String? billerCode;
  final String? subscriberNo;
  final String? debitAccount;
  final double? amount;
  final String currency;
  final String? providerRef;
  final String? message;
  final DateTime? createdAt;

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isPending => status.toUpperCase() == 'PENDING';

  factory BillReceipt.fromMap(Map<String, dynamic> map) {
    return BillReceipt(
      reference: map['reference']?.toString() ?? '',
      status: map['status']?.toString() ?? 'PENDING',
      billerCode: map['billerCode']?.toString(),
      subscriberNo: map['subscriberNo']?.toString(),
      debitAccount: map['debitAccount']?.toString(),
      amount: map['amount'] is num
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount']?.toString() ?? ''),
      currency: map['currency']?.toString() ?? 'YER',
      providerRef: map['providerRef']?.toString(),
      message: map['message']?.toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '')?.toLocal(),
    );
  }

  String formattedAmount() {
    final value = amount;
    if (value == null) return '';
    return '${NumberFormat('#,##0.00').format(value)} $currency';
  }

  String formattedDate() {
    final date = createdAt ?? DateTime.now();
    return DateFormat.yMMMd().add_jm().format(date);
  }

  BillReceipt copyWith({String? status, String? providerRef, double? amount}) {
    return BillReceipt(
      reference: reference,
      status: status ?? this.status,
      billerCode: billerCode,
      subscriberNo: subscriberNo,
      debitAccount: debitAccount,
      amount: amount ?? this.amount,
      currency: currency,
      providerRef: providerRef ?? this.providerRef,
      message: message,
      createdAt: createdAt,
    );
  }
}
