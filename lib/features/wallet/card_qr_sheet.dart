import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/banking_account.dart';
import '../../core/qr/account_qr_payload.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';

/// Opens the large, per-card "receive via QR" sheet: a big scannable QR for the
/// given account plus share / save-image / copy actions. The QR uses the same
/// [AccountQrPayload] the scanner decodes, so receive ↔ scan interoperate.
Future<void> showCardQrSheet(BuildContext context, BankingAccount account) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CardQrSheet(account: account),
  );
}

class _CardQrSheet extends StatelessWidget {
  const _CardQrSheet({required this.account});

  final BankingAccount account;

  String get _payload => AccountQrPayload(
        accountNumber: account.accountNumber,
        currency: account.currency,
        label: account.label,
      ).encode();

  String _currencyName(AppLocalizations l10n) {
    switch (account.currency.trim().toUpperCase()) {
      case 'SAR':
        return l10n.walletCurrencySar;
      case 'YER':
        return l10n.walletCurrencyYer;
      case 'USD':
        return l10n.walletCurrencyUsd;
      default:
        return account.currency.trim().toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _currencyName(l10n),
              style: AppTextStyles.headlineMd(
                color: colors.onSurface,
                languageCode: lang,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.walletReceiveShareHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd(
                color: colors.onSurfaceVariant,
                languageCode: lang,
              ).copyWith(fontSize: 13),
            ),
            const SizedBox(height: 20),
            // Large scannable QR on a soft white card.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppColors.radiusLg),
                border: Border.all(color: colors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: colors.cardShadow,
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: QrImageView(
                data: _payload,
                version: QrVersions.auto,
                size: 232,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0B1B3A),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0B1B3A),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Account number pill.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.secondaryFixed,
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      size: 18, color: colors.secondary),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      account.accountNumber,
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.monoLabel(color: colors.secondary)
                          .copyWith(
                              fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _SheetAction(
                    icon: Icons.ios_share_rounded,
                    label: 'مشاركة',
                    colors: colors,
                    lang: lang,
                    onTap: () => _shareQr(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetAction(
                    icon: Icons.download_rounded,
                    label: 'حفظ الصورة',
                    colors: colors,
                    lang: lang,
                    onTap: () => _saveQr(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetAction(
                    icon: Icons.content_copy_rounded,
                    label: 'نسخ الرقم',
                    colors: colors,
                    lang: lang,
                    onTap: () => _copyAccount(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareQr(BuildContext context) async {
    final bytes = await _renderQrPng(_payload);
    if (bytes == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/uff_receive_qr.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'رقم حسابي في Ultimate Wallet: ${account.accountNumber}',
      );
    } catch (_) {
      // Sharing was cancelled or unavailable — nothing to surface.
    }
  }

  Future<void> _saveQr(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await _renderQrPng(_payload);
    if (bytes == null) return;
    try {
      await Gal.putImageBytes(bytes, name: 'uff_receive_qr');
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('تم حفظ الصورة في المعرض'),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('تعذّر حفظ الصورة'),
        ),
      );
    }
  }

  void _copyAccount(BuildContext context) {
    final l10n = context.l10n;
    Clipboard.setData(ClipboardData(text: account.accountNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.copied),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.colors,
    required this.lang,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final BankSyncColors colors;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.secondary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm(
                color: colors.onSurface,
                languageCode: lang,
              ).copyWith(fontWeight: FontWeight.w600, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the account QR to a white-background PNG (with a quiet-zone margin)
/// suitable for sharing or saving to the gallery.
Future<Uint8List?> _renderQrPng(String data, {double size = 720}) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: true,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Color(0xFF000000),
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Color(0xFF000000),
    ),
  );

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const pad = 48.0;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  canvas.translate(pad, pad);
  painter.paint(canvas, Size(size - pad * 2, size - pad * 2));

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}
