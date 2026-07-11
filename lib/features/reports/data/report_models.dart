import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

/// Direction filter driving the top segmented tabs on the Reports screen.
/// Mirrors the reference design's «All / Sent / Received / Fees» segments.
enum ReportDirection { all, sent, received, fees }

extension ReportDirectionX on ReportDirection {
  String label(AppLocalizations l10n) => switch (this) {
        ReportDirection.all => l10n.reportsTabAll,
        ReportDirection.sent => l10n.reportsTabSent,
        ReportDirection.received => l10n.reportsTabReceived,
        ReportDirection.fees => l10n.reportsTabFees,
      };
}

/// The operation-type dropdown inside the filter sheet (نوع العملية).
enum ReportOperationType { all, transfer, payment, deposit, withdrawal }

extension ReportOperationTypeX on ReportOperationType {
  String label(AppLocalizations l10n) => switch (this) {
        ReportOperationType.all => l10n.reportsTabAll,
        ReportOperationType.transfer => l10n.reportsOpTransfer,
        ReportOperationType.payment => l10n.reportsOpPayment,
        ReportOperationType.deposit => l10n.reportsOpDeposit,
        ReportOperationType.withdrawal => l10n.reportsOpWithdrawal,
      };
}

/// Currencies offered as selectable chips in the filter sheet.
enum ReportCurrency { sar, usd, yer }

extension ReportCurrencyX on ReportCurrency {
  /// ISO-style code rendered next to amounts.
  String get code => switch (this) {
        ReportCurrency.sar => 'SAR',
        ReportCurrency.usd => 'USD',
        ReportCurrency.yer => 'YER',
      };

  String label(AppLocalizations l10n) => switch (this) {
        ReportCurrency.sar => l10n.walletCurrencySar,
        ReportCurrency.usd => l10n.walletCurrencyUsd,
        ReportCurrency.yer => l10n.walletCurrencyYer,
      };
}

/// A single row in the transaction-report ledger.
///
/// Currently populated from [mockReportEntries]; the shape is deliberately
/// close to a server DTO so it can be swapped for a real API response without
/// touching the UI layer.
@immutable
class ReportEntry {
  const ReportEntry({
    required this.id,
    required this.title,
    required this.phone,
    required this.reference,
    required this.direction,
    required this.operationType,
    required this.amount,
    required this.currency,
    required this.dateTime,
    required this.purpose,
  });

  final String id;

  /// Counterparty / merchant display name.
  final String title;

  /// Counterparty phone (used by the filter's phone field).
  final String phone;
  final String reference;
  final ReportDirection direction;
  final ReportOperationType operationType;
  final double amount;
  final ReportCurrency currency;
  final DateTime dateTime;
  final String purpose;

  /// Signed for display: sent money & fees leave the wallet (negative),
  /// received money comes in (positive).
  bool get isCredit => direction == ReportDirection.received;

  String formattedAmount() {
    final formatted = NumberFormat('#,##0.00').format(amount.abs());
    final sign = isCredit ? '+' : '-';
    return '$sign$formatted ${currency.code}';
  }

  String formattedDate() => DateFormat('yyyy-MM-dd · hh:mm a').format(dateTime);
}

/// Deterministic-ish demo ledger anchored to "now" so the dates always read as
/// recent. Replace with a repository call when the reports API lands.
List<ReportEntry> mockReportEntries() {
  final now = DateTime.now();
  DateTime daysAgo(int d, {int h = 12, int m = 0}) =>
      DateTime(now.year, now.month, now.day, h, m).subtract(Duration(days: d));

  return [
    ReportEntry(
      id: 'r1',
      title: 'Ahmed Al-Sayed',
      phone: '0555102030',
      reference: 'TRX-8842190',
      direction: ReportDirection.received,
      operationType: ReportOperationType.transfer,
      amount: 1250.00,
      currency: ReportCurrency.yer,
      dateTime: daysAgo(0, h: 9, m: 24),
      purpose: 'Salary',
    ),
    ReportEntry(
      id: 'r2',
      title: 'Ultimate Store',
      phone: '0555778812',
      reference: 'TRX-8840021',
      direction: ReportDirection.sent,
      operationType: ReportOperationType.payment,
      amount: 320.50,
      currency: ReportCurrency.sar,
      dateTime: daysAgo(1, h: 18, m: 5),
      purpose: 'Purchase',
    ),
    ReportEntry(
      id: 'r3',
      title: 'Transfer fee',
      phone: '',
      reference: 'FEE-773410',
      direction: ReportDirection.fees,
      operationType: ReportOperationType.transfer,
      amount: 5.00,
      currency: ReportCurrency.sar,
      dateTime: daysAgo(1, h: 18, m: 6),
      purpose: 'Service fee',
    ),
    ReportEntry(
      id: 'r4',
      title: 'Sara Mohammed',
      phone: '0533441122',
      reference: 'TRX-8831900',
      direction: ReportDirection.sent,
      operationType: ReportOperationType.transfer,
      amount: 600.00,
      currency: ReportCurrency.yer,
      dateTime: daysAgo(2, h: 11, m: 40),
      purpose: 'Family support',
    ),
    ReportEntry(
      id: 'r5',
      title: 'Cash deposit',
      phone: '',
      reference: 'DEP-118820',
      direction: ReportDirection.received,
      operationType: ReportOperationType.deposit,
      amount: 2000.00,
      currency: ReportCurrency.sar,
      dateTime: daysAgo(3, h: 14, m: 12),
      purpose: 'Top-up',
    ),
    ReportEntry(
      id: 'r6',
      title: 'Khalid Nasser',
      phone: '0509988776',
      reference: 'TRX-8820014',
      direction: ReportDirection.received,
      operationType: ReportOperationType.transfer,
      amount: 90.00,
      currency: ReportCurrency.usd,
      dateTime: daysAgo(4, h: 8, m: 3),
      purpose: 'Refund',
    ),
    ReportEntry(
      id: 'r7',
      title: 'ATM withdrawal',
      phone: '',
      reference: 'WDR-556201',
      direction: ReportDirection.sent,
      operationType: ReportOperationType.withdrawal,
      amount: 400.00,
      currency: ReportCurrency.sar,
      dateTime: daysAgo(5, h: 20, m: 55),
      purpose: 'Cash out',
    ),
    ReportEntry(
      id: 'r8',
      title: 'Ultimate Wallet',
      phone: '',
      reference: 'FEE-773002',
      direction: ReportDirection.fees,
      operationType: ReportOperationType.payment,
      amount: 2.50,
      currency: ReportCurrency.yer,
      dateTime: daysAgo(6, h: 16, m: 30),
      purpose: 'Monthly fee',
    ),
  ];
}
