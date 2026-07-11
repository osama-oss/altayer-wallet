import 'package:flutter/foundation.dart';

import 'report_models.dart';

/// Immutable set of criteria applied by the reports filter sheet. An empty
/// [currencies] set means "all currencies"; likewise [ReportOperationType.all].
@immutable
class ReportFilter {
  const ReportFilter({
    required this.currencies,
    required this.phone,
    required this.operationType,
    required this.fromDate,
    required this.toDate,
    required this.purpose,
  });

  final Set<ReportCurrency> currencies;
  final String phone;
  final ReportOperationType operationType;
  final DateTime fromDate;
  final DateTime toDate;
  final String purpose;

  /// Default filter: the trailing 7-day window, no other constraints.
  factory ReportFilter.initial() {
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day);
    return ReportFilter(
      currencies: const {},
      phone: '',
      operationType: ReportOperationType.all,
      fromDate: to.subtract(const Duration(days: 7)),
      toDate: to,
      purpose: '',
    );
  }

  /// True when any constraint beyond the default date window is active — used
  /// to badge the filter button.
  bool get hasActiveConstraints =>
      currencies.isNotEmpty ||
      phone.trim().isNotEmpty ||
      operationType != ReportOperationType.all ||
      purpose.trim().isNotEmpty;

  ReportFilter copyWith({
    Set<ReportCurrency>? currencies,
    String? phone,
    ReportOperationType? operationType,
    DateTime? fromDate,
    DateTime? toDate,
    String? purpose,
  }) {
    return ReportFilter(
      currencies: currencies ?? this.currencies,
      phone: phone ?? this.phone,
      operationType: operationType ?? this.operationType,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      purpose: purpose ?? this.purpose,
    );
  }

  /// Whether [e] passes every active criterion (currency, phone, type, date
  /// range, purpose). Direction is filtered separately by the top tabs.
  bool matches(ReportEntry e) {
    if (currencies.isNotEmpty && !currencies.contains(e.currency)) return false;

    final phoneQuery = phone.trim();
    if (phoneQuery.isNotEmpty && !e.phone.contains(phoneQuery)) return false;

    if (operationType != ReportOperationType.all &&
        e.operationType != operationType) {
      return false;
    }

    final day = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
    if (day.isBefore(fromDate) || day.isAfter(toDate)) return false;

    final purposeQuery = purpose.trim().toLowerCase();
    if (purposeQuery.isNotEmpty &&
        !e.purpose.toLowerCase().contains(purposeQuery)) {
      return false;
    }
    return true;
  }
}
