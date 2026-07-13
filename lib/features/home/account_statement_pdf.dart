import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/models/account_transaction.dart';
import '../../core/models/banking_account.dart';
import '../../core/wallet_account_id.dart';

// uff brand palette (kept in sync with the app theme / transfer receipt).
const _brand = PdfColor.fromInt(0xFF2119F3);
const _ink = PdfColor.fromInt(0xFF14152E);
const _muted = PdfColor.fromInt(0xFF64748B);
const _line = PdfColor.fromInt(0xFFE2E8F0);
const _zebra = PdfColor.fromInt(0xFFF6F8FC);
const _credit = PdfColor.fromInt(0xFF27AE60);
const _debit = PdfColor.fromInt(0xFFEB5757);

// ── Asset cache ─────────────────────────────────────────────────────────────
// PDF generation time is dominated by font work: the `pdf` package parses the
// whole TTF and subsets it on every save. The app's single typeface — Tajawal —
// is lightweight (~60KB per weight), so parsing/subsetting is cheap. We still
// load + parse the fonts and read the logo ONCE per session and reuse them, so
// every export after the first is near-instant.
pw.Font? _regularCache;
pw.Font? _boldCache;
String? _logoCache;

Future<void> _ensureAssets() async {
  _regularCache ??=
      pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
  _boldCache ??=
      pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
  _logoCache ??= await rootBundle.loadString('assets/branding/ultimate_wallet_light.svg');
}

/// Builds a bilingual (AR/EN) A4 account statement PDF from the transactions
/// the app already holds (ACCOUNT-LAST-TEN-TXN). It is honest about scope: the
/// footer states how many rows are shown out of the account's total, so it is
/// never mistaken for a full-period statement (which would need a new core
/// integration).
Future<Uint8List> buildAccountStatementPdf({
  required BankingAccount account,
  required List<AccountTransaction> transactions,
  int? totalCount,
}) async {
  await _ensureAssets();
  final regular = _regularCache!;
  final bold = _boldCache!;
  final svgRaw = _logoCache!;

  final now = DateTime.now();
  final issued = DateFormat('yyyy/MM/dd  -  hh:mm a').format(now);
  final balance = NumberFormat('#,##0.00').format(account.balance);

  final doc = pw.Document(title: 'Ultimate Wallet Account Statement', author: 'Ultimate Wallet');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      textDirection: pw.TextDirection.rtl,
      header: (context) =>
          context.pageNumber == 1 ? pw.SizedBox() : _miniHeader(account),
      footer: (context) => _pageFooter(context),
      build: (context) => [
        _header(svgRaw),
        pw.SizedBox(height: 14),
        _summaryCard(account, balance, issued),
        pw.SizedBox(height: 16),
        _sectionTitle('الحركات', 'Transactions'),
        pw.SizedBox(height: 8),
        if (transactions.isEmpty)
          _emptyNote()
        else
          _transactionsTable(transactions),
        pw.SizedBox(height: 12),
        _scopeNote(transactions.length, totalCount),
      ],
    ),
  );

  return doc.save();
}

/// Generates the statement and opens the native share sheet.
Future<void> shareAccountStatement({
  required BankingAccount account,
  required List<AccountTransaction> transactions,
  int? totalCount,
}) async {
  final bytes = await buildAccountStatementPdf(
    account: account,
    transactions: transactions,
    totalCount: totalCount,
  );
  final safe = account.accountNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'UltimateWallet_statement_${safe.isEmpty ? 'account' : safe}.pdf',
  );
}

pw.Widget _header(String svgRaw) {
  final whiteSvg = svgRaw
      .replaceAll(RegExp('#0050b3', caseSensitive: false), '#FFFFFF')
      .replaceAll(RegExp('#00ab4e', caseSensitive: false), '#B8F5D0');
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: const pw.BoxDecoration(
      color: _brand,
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('كشف حساب',
                style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold)),
            pw.Text('Account Statement',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
          ],
        ),
        pw.SvgImage(svg: whiteSvg, width: 70, height: 35),
      ],
    ),
  );
}

pw.Widget _miniHeader(BankingAccount account) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('كشف حساب — Account Statement',
            style: const pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: _brand)),
        pw.Text(walletDisplayNumber(account.accountNumber),
            style: const pw.TextStyle(fontSize: 9, color: _muted)),
      ],
    ),
  );
}

pw.Widget _summaryCard(BankingAccount account, String balance, String issued) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _row('اسم العميل', 'Customer name', account.label),
        _divider(),
        _row('رقم الحساب', 'Account number', walletDisplayNumber(account.accountNumber)),
        _divider(),
        _row('العملة', 'Currency', account.currency),
        _divider(),
        _row('الرصيد الحالي', 'Current balance', '$balance ${account.currency}',
            emphasize: true),
        _divider(),
        _row('تاريخ الإصدار', 'Issued at', issued),
      ],
    ),
  );
}

pw.Widget _transactionsTable(List<AccountTransaction> txns) {
  final headers = ['التاريخ\nDate', 'البيان\nDescription', 'المرجع\nReference', 'المبلغ\nAmount'];
  // Mirror a real bank statement: show the transaction narrative as a
  // "ملاحظة" sub-line under the description when the core provides one.
  final rows = txns.map((t) {
    final note = t.narrative?.trim() ?? '';
    final desc =
        note.isEmpty ? t.tileTitle() : '${t.tileTitle()}\nملاحظة: $note';
    return [
      t.formattedDate(),
      desc,
      t.transactionReference,
      t.formattedAmount(),
    ];
  }).toList();

  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    border: pw.TableBorder.all(color: _line, width: 0.5),
    headerStyle: const pw.TextStyle(
        color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
    headerDecoration: const pw.BoxDecoration(color: _brand),
    headerHeight: 28,
    cellStyle: const pw.TextStyle(fontSize: 9, color: _ink),
    cellHeight: 24,
    oddRowDecoration: const pw.BoxDecoration(color: _zebra),
    cellAlignments: {
      0: pw.Alignment.topRight,
      1: pw.Alignment.topRight,
      2: pw.Alignment.topRight,
      3: pw.Alignment.topLeft,
    },
    columnWidths: {
      0: const pw.FixedColumnWidth(70),
      1: const pw.FlexColumnWidth(2.2),
      2: const pw.FlexColumnWidth(1.6),
      3: const pw.FixedColumnWidth(95),
    },
    cellDecoration: (index, data, rowNum) {
      // Colour the amount column by sign.
      if (index == 3) {
        final credit = !data.toString().trimLeft().startsWith('-');
        return pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(
                color: credit ? _credit : _debit, width: 2),
          ),
        );
      }
      return const pw.BoxDecoration();
    },
  );
}

pw.Widget _emptyNote() {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
    ),
    child: pw.Text('لا توجد حركات لعرضها — No transactions to display',
        style: const pw.TextStyle(fontSize: 10, color: _muted)),
  );
}

pw.Widget _scopeNote(int shown, int? total) {
  final ar = (total != null && total > shown)
      ? 'يعرض هذا الكشف آخر $shown حركة من أصل $total.'
      : 'يعرض هذا الكشف $shown حركة.';
  final en = (total != null && total > shown)
      ? 'This statement shows the latest $shown of $total transactions.'
      : 'This statement shows $shown transactions.';
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(ar, style: const pw.TextStyle(fontSize: 8, color: _muted)),
      pw.Text(en, style: const pw.TextStyle(fontSize: 7, color: _muted)),
    ],
  );
}

pw.Widget _sectionTitle(String ar, String en) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(ar,
          style: const pw.TextStyle(
              fontSize: 13, fontWeight: pw.FontWeight.bold, color: _brand)),
      pw.Text(en, style: const pw.TextStyle(fontSize: 8, color: _muted)),
    ],
  );
}

pw.Widget _pageFooter(pw.Context context) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 10),
    padding: const pw.EdgeInsets.only(top: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
            'Ultimate Wallet — كشف إلكتروني صادر عبر التطبيق، لا يحتاج توقيعاً / system-generated, no signature required.',
            style: const pw.TextStyle(fontSize: 7, color: _muted)),
        pw.Text('${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _muted)),
      ],
    ),
  );
}

pw.Widget _divider() => pw.Container(
    height: 0.6, color: _line, margin: const pw.EdgeInsets.symmetric(vertical: 8));

pw.Widget _row(String ar, String en, String value, {bool emphasize = false}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 120,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(ar,
                style: const pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.Text(en, style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ],
        ),
      ),
      pw.Expanded(
        child: pw.Text(value,
            textAlign: pw.TextAlign.left,
            style: pw.TextStyle(
                fontSize: emphasize ? 13 : 11,
                fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: emphasize ? _brand : _ink)),
      ),
    ],
  );
}
