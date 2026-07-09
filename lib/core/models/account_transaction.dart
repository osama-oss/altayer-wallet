import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One row from ACCOUNT-LAST-TEN-TXN (core lastTenTxn/search).
class AccountTransaction {
  const AccountTransaction({
    required this.bookingDate,
    required this.transactionReference,
    required this.transactionDesc,
    required this.currency,
    required this.amount,
    this.narrative,
  });

  final String bookingDate;
  final String transactionReference;
  final String transactionDesc;
  final String currency;
  final String amount;
  final String? narrative;

  static List<AccountTransaction> listFromIntegration(Map<String, dynamic> payload) {
    final rows = _extractRows(payload);
    return rows
        .map((row) {
          if (row is Map) {
            return AccountTransaction.fromMap(Map<String, dynamic>.from(row));
          }
          return null;
        })
        .whereType<AccountTransaction>()
        .toList();
  }

  static int? totalCountFromIntegration(Map<String, dynamic> payload) {
    for (final map in _mapsToSearch(payload)) {
      final top = map['totalCount'];
      if (top is int) return top;
      if (top != null) {
        final parsed = int.tryParse('$top');
        if (parsed != null) return parsed;
      }
      final data = map['data'];
      if (data is Map) {
        final nested = data['totalCount'];
        if (nested is int) return nested;
        return int.tryParse('$nested');
      }
    }
    return null;
  }

  static List<dynamic> _extractRows(Map<String, dynamic> payload) {
    for (final map in _mapsToSearch(payload)) {
      final data = map['data'];
      if (data is List) return data;
      if (data is Map) {
        final nested = data['data'];
        if (nested is List) return nested;
        final items = data['items'];
        if (items is List) return items;
      }
      final items = map['items'];
      if (items is List) return items;
    }
    return const [];
  }

  static List<Map<String, dynamic>> _mapsToSearch(Map<String, dynamic> payload) {
    final out = <Map<String, dynamic>>[];
    void add(Map<String, dynamic> map) {
      out.add(map);
      if (map['success'] == true) {
        final inner = map['data'];
        if (inner is Map) {
          add(Map<String, dynamic>.from(inner));
        }
      }
    }

    add(payload);
    final raw = payload['raw'];
    if (raw is String && raw.trim().isNotEmpty) {
      final parsed = _tryParseJsonMap(raw);
      if (parsed != null) add(parsed);
    }
    return out;
  }

  static Map<String, dynamic>? _tryParseJsonMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  factory AccountTransaction.fromMap(Map<String, dynamic> map) {
    final currency = map['currency']?.toString() ?? '';
    return AccountTransaction(
      bookingDate: map['bookingDate']?.toString() ?? '',
      transactionReference: map['transactionReference']?.toString() ?? '',
      transactionDesc: map['transactionDesc']?.toString() ?? 'Transaction',
      currency: currency,
      amount: _amountForCurrency(map, currency),
      narrative: map['narrative']?.toString(),
    );
  }

  /// YER → local amount; any other currency → foreign amount.
  static String _amountForCurrency(Map<String, dynamic> map, String currency) {
    final isYer = currency.trim().toUpperCase() == 'YER';
    if (isYer) {
      return map['amountLcy']?.toString() ??
          map['amount']?.toString() ??
          '0';
    }
    return map['amountFcy']?.toString() ??
        map['amount']?.toString() ??
        '0';
  }

  double get amountValue => double.tryParse(amount.replaceAll(',', '')) ?? 0;

  bool get isCredit => amountValue >= 0;

  String formattedAmount() {
    final value = amountValue.abs();
    final formatted = NumberFormat('#,##0.00').format(value);
    final sign = isCredit ? '+' : '-';
    final ccy = currency.isNotEmpty ? ' $currency' : '';
    return '$sign$formatted$ccy';
  }

  String formattedDate() {
    if (bookingDate.isEmpty) return '';
    final parsed = DateTime.tryParse(bookingDate);
    if (parsed == null) return bookingDate;
    return DateFormat.yMMMd().format(parsed);
  }

  IconData iconForType() {
    final desc = transactionDesc.toLowerCase();
    if (desc.contains('credit') || desc.contains('deposit')) {
      return Icons.south_west_rounded;
    }
    if (desc.contains('debit') || desc.contains('transfer')) {
      return Icons.north_east_rounded;
    }
    return Icons.receipt_long_outlined;
  }

  String tileTitle() {
    if (transactionDesc.trim().isNotEmpty) return transactionDesc.trim();
    return transactionReference;
  }

  String tileSubtitle() {
    final date = formattedDate();
    if (date.isEmpty) return transactionReference;
    return date;
  }

  String tileStatus() {
    final ref = transactionReference.trim();
    if (ref.length <= 14) return ref;
    return '${ref.substring(0, 11)}…';
  }
}
