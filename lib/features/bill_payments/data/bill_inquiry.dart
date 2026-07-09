import 'package:intl/intl.dart';

/// Result of `BILL_INQUIRY` — whatever the provider knows about the subscriber
/// (name and amount come from the provider, never typed by the user).
/// Field names are tolerant: the aggregator returns `mobileBalance`,
/// dedicated providers may map to `balanceDue`/`subscriberName` in Back Office.
class BillInquiry {
  const BillInquiry({
    this.subscriberName,
    this.balanceDue,
    this.availableCredit,
    this.lineType,
    this.expiryDate,
    this.minAmount,
    this.message,
    this.raw = const {},
  });

  final String? subscriberName;
  final double? balanceDue;
  final String? availableCredit;
  final String? lineType;
  final String? expiryDate;
  final double? minAmount;
  final String? message;
  final Map<String, dynamic> raw;

  factory BillInquiry.fromMap(Map<String, dynamic> map) {
    return BillInquiry(
      subscriberName: _string(map, ['subscriberName', 'customerName', 'name']),
      balanceDue: _double(map, ['balanceDue', 'mobileBalance', 'dueAmount', 'amount']),
      availableCredit: _string(map, ['availableCredit']),
      lineType: _string(map, ['mobileTypeName', 'lineType']),
      expiryDate: _string(map, ['expiredDate', 'expiryDate']),
      minAmount: _double(map, ['minAmount']),
      message: _string(map, ['message']),
      raw: map,
    );
  }

  String? formattedBalanceDue(String currency) {
    final due = balanceDue;
    if (due == null) return null;
    return '${NumberFormat('#,##0.00').format(due)} $currency';
  }

  static String? _string(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = map[key]?.toString().trim();
      if (v != null && v.isNotEmpty && v != 'null') return v;
    }
    return null;
  }

  static double? _double(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = map[key];
      if (v is num) return v.toDouble();
      final parsed = double.tryParse(v?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }
}

/// One entry from `BILL_OFFERS` (aggregator: offerID/offerName; dedicated
/// providers can map their package lists to the same keys in Back Office).
class BillOffer {
  const BillOffer({required this.id, required this.name, this.price});

  final String id;
  final String name;
  final double? price;

  factory BillOffer.fromMap(Map<String, dynamic> map) {
    return BillOffer(
      id: map['offerID']?.toString() ?? map['offerId']?.toString() ?? map['id']?.toString() ?? '',
      name: map['offerName']?.toString() ?? map['name']?.toString() ?? '',
      price: map['price'] is num
          ? (map['price'] as num).toDouble()
          : double.tryParse(map['price']?.toString() ?? ''),
    );
  }

  static List<BillOffer> listFrom(Map<String, dynamic> data) {
    final rows = data['data'] ?? data['offers'] ?? data['packages'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => BillOffer.fromMap(Map<String, dynamic>.from(e)))
        .where((o) => o.id.isNotEmpty)
        .toList();
  }
}
