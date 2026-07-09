import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'transfer_receipt.dart';

// uff brand palette (kept in sync with the app theme).
const _brand = PdfColor.fromInt(0xFF2119F3);
const _ink = PdfColor.fromInt(0xFF14152E);
const _muted = PdfColor.fromInt(0xFF64748B);
const _line = PdfColor.fromInt(0xFFE2E8F0);
const _successBg = PdfColor.fromInt(0xFFECFDF5);
const _success = PdfColor.fromInt(0xFF10B981);

// Cache parsed fonts/logo across exports — re-parsing the Tajawal TTF on
// every tap is what makes the first (and every) receipt share feel stuck with
// no feedback (see the same fix in account_statement_pdf.dart).
pw.Font? _regularCache;
pw.Font? _boldCache;
String? _logoCache;

Future<void> _ensureAssets() async {
  _regularCache ??=
      pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
  _boldCache ??=
      pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
  _logoCache ??= await rootBundle.loadString('assets/branding/ubs.svg');
}

/// Builds a lightweight, bilingual (AR/EN) A5 transfer receipt PDF.
Future<Uint8List> buildTransferReceiptPdf(TransferReceipt r) async {
  await _ensureAssets();
  final regular = _regularCache!;
  final bold = _boldCache!;
  final svgRaw = _logoCache!;

  final doc = pw.Document(title: 'UBS Transfer Receipt', author: 'UBS Mobile');
  final dateStr = DateFormat('yyyy/MM/dd  -  hh:mm a').format(r.date);
  final qrData = 'UBS Transfer Receipt\n'
      'Ref: ${r.reference}\n'
      'Amount: ${r.amount} ${r.currency}\n'
      'To: ${maskAccount(r.toAccount)}\n'
      'Date: ${r.date.toIso8601String()}';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(22),
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      build: (context) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header(svgRaw),
            pw.SizedBox(height: 14),
            _dateRow(dateStr),
            pw.SizedBox(height: 14),
            _successBadge(r),
            pw.SizedBox(height: 16),
            _detailsCard(r),
            pw.SizedBox(height: 22),
            _footer(qrData),
          ],
        ),
      ),
    ),
  );

  return doc.save();
}

/// Generates the receipt and opens the native share sheet.
Future<void> shareTransferReceipt(TransferReceipt r) async {
  final bytes = await buildTransferReceiptPdf(r);
  final ref = r.reference.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'UBS_transfer_${ref.isEmpty ? 'receipt' : ref}.pdf',
  );
}

pw.Widget _header(String svgRaw) {
  // Recolor the SVG paths to white + light green for the blue background
  final whiteSvg = svgRaw
      .replaceAll(RegExp('#2119f3', caseSensitive: false), '#FFFFFF')
      .replaceAll(RegExp('#1ba64a', caseSensitive: false), '#B8F5D0');
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
            pw.Text('إيصال التحويل',
                style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold)),
            pw.Text('Transfer Receipt',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
          ],
        ),
        pw.SvgImage(svg: whiteSvg, width: 70, height: 35),
      ],
    ),
  );
}

pw.Widget _dateRow(String dateStr) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text('التاريخ  Date',
          style: const pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold, color: _muted)),
      pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10, color: _ink)),
    ],
  );
}

pw.Widget _successBadge(TransferReceipt r) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: const pw.BoxDecoration(
      color: _successBg,
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
    ),
    child: pw.Row(
      children: [
        pw.Container(
          width: 26,
          height: 26,
          decoration:
              const pw.BoxDecoration(color: _success, shape: pw.BoxShape.circle),
          child: pw.Center(
            child: pw.Text('✓',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 15)),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('تم تنفيذ التحويل بنجاح',
                  style: const pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink)),
              pw.Text('${r.amount} ${r.currency}',
                  style: const pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: _success)),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _detailsCard(TransferReceipt r) {
  final from = (r.fromName != null && r.fromName!.isNotEmpty)
      ? '${r.fromName}\n${maskAccount(r.fromAccount)}'
      : maskAccount(r.fromAccount);
  final to = (r.toName != null && r.toName!.isNotEmpty)
      ? '${r.toName}\n${r.toAccount}'
      : r.toAccount;

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text('تفاصيل التحويل',
            style: const pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: _brand)),
        pw.Text('Transfer Details',
            style: const pw.TextStyle(fontSize: 9, color: _muted)),
        pw.SizedBox(height: 6),
        if (r.typeLabel != null && r.typeLabel!.isNotEmpty) ...[
          _row('نوع الحوالة', 'Type', r.typeLabel!),
          _divider(),
        ],
        _row('المبلغ', 'Amount', '${r.amount} ${r.currency}'),
        _divider(),
        _row('من', 'From', from),
        _divider(),
        _row('إلى', 'To', to),
        _divider(),
        _row('المرجع', 'Reference', r.reference),
        if (r.purpose != null && r.purpose!.isNotEmpty) ...[
          _divider(),
          _row('الغرض', 'Purpose', r.purpose!),
        ],
      ],
    ),
  );
}

pw.Widget _divider() =>
    pw.Container(height: 0.6, color: _line, margin: const pw.EdgeInsets.symmetric(vertical: 9));

pw.Widget _row(String ar, String en, String value) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 95,
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
            style: const pw.TextStyle(fontSize: 11, color: _ink)),
      ),
    ],
  );
}

pw.Widget _footer(String qrData) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Container(height: 0.6, color: _line),
      pw.SizedBox(height: 10),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('UBS Mobile — UBS Digital Banking',
                    style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _brand)),
                pw.SizedBox(height: 3),
                pw.Text(
                    'هذا إيصال إلكتروني صادر عبر التطبيق ولا يحتاج إلى توقيع.',
                    style: const pw.TextStyle(fontSize: 8, color: _muted)),
                pw.Text(
                    'This is a system-generated e-receipt and needs no signature.',
                    style: const pw.TextStyle(fontSize: 7, color: _muted)),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrData,
              width: 54,
              height: 54,
              color: _ink,
              drawText: false,
            ),
          ),
        ],
      ),
    ],
  );
}

/// Plain-text version of the receipt (for the "share as text" action).
String transferReceiptText(TransferReceipt r) {
  final from = '${r.fromName ?? ''} ${maskAccount(r.fromAccount)}'.trim();
  final to = '${r.toName ?? ''} ${r.toAccount}'.trim();
  final date = DateFormat('yyyy-MM-dd  HH:mm').format(r.date);
  final lines = <String>[
    'UBS — إيصال التحويل / Transfer Receipt',
    if (r.typeLabel != null && r.typeLabel!.isNotEmpty)
      'نوع الحوالة: ${r.typeLabel}',
    'المبلغ: ${r.amount} ${r.currency}',
    'من: $from',
    'إلى: $to',
    'المرجع: ${r.reference}',
    if (r.purpose != null && r.purpose!.isNotEmpty) 'الغرض: ${r.purpose}',
    'التاريخ: $date',
  ];
  return lines.join('\n');
}

/// Opens the native share sheet with the receipt as plain text.
Future<void> shareTransferReceiptText(TransferReceipt r) async {
  await Share.share(transferReceiptText(r), subject: 'UBS Transfer Receipt');
}
