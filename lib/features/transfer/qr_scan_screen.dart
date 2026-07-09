import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/qr/account_qr_payload.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Opens the professional QR scanner and resolves with the scanned account
/// number, or `null` if the user backs out without a successful scan. The
/// returned value is the decoded [AccountQrPayload.accountNumber]; callers
/// decide what to do next (fill a field, or push the scan-review screen).
Future<String?> openQrScanScreen(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const QrScanScreen()),
  );
}

/// Full-screen, bank-identity QR scanner: a live camera with a softly glowing
/// blue scan frame, a smooth scan-line sweep, a flash toggle and a
/// scan-from-gallery action. It never performs a transfer itself — it only
/// decodes the account and pops it back to the caller.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final _picker = ImagePicker();

  late final AnimationController _lineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  bool _handled = false;
  bool _torchOn = false;
  bool _analyzing = false;

  @override
  void dispose() {
    _lineController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Live-camera detections. Invalid frames are ignored silently so scanning
  /// keeps running until a real account QR appears.
  void _onDetect(BarcodeCapture capture) {
    if (_handled || _analyzing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    final payload = AccountQrPayload.decode(raw);
    if (payload == null) return;
    _finish(payload.accountNumber);
  }

  void _finish(String account) {
    if (_handled) return;
    _handled = true;
    Navigator.of(context).pop(account);
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // Torch may be unavailable (e.g. front camera / emulator) — ignore.
    }
  }

  /// Pick an image from the gallery and decode a QR from it. Shows a graceful
  /// loading state, then either finishes with the account or surfaces an
  /// elegant "no valid QR" sheet.
  Future<void> _scanFromGallery() async {
    if (_analyzing) return;
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      setState(() => _analyzing = true);
      final capture = await _controller.analyzeImage(file.path);
      if (!mounted) return;
      setState(() => _analyzing = false);

      final raw = capture?.barcodes.firstOrNull?.rawValue;
      final payload = raw == null ? null : AccountQrPayload.decode(raw);
      if (payload != null) {
        _finish(payload.accountNumber);
      } else {
        _showNoQrSheet();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      _showNoQrSheet();
    }
  }

  void _showNoQrSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _NoQrFoundSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final size = MediaQuery.of(context).size;
    final side = (size.width * 0.68).clamp(220.0, 300.0);
    final cutout = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.40),
      width: side,
      height: side,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Live camera ──────────────────────────────────────────────
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // ── Dimmed scrim with a clear cut-out + glowing blue corners ──
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(
                  cutout: cutout,
                  frameColor: AppColors.walletBrandAlt,
                ),
              ),
            ),
          ),

          // ── Smooth scan-line sweep, clipped to the frame ─────────────
          Positioned.fromRect(
            rect: cutout,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AnimatedBuilder(
                  animation: _lineController,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(_lineController.value);
                    return Align(
                      alignment: Alignment(0, (t * 2) - 1),
                      child: Container(
                        height: 2.5,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0x0038BDF8),
                              AppColors.walletBrandAlt,
                              Color(0x0038BDF8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.walletBrandAlt
                                  .withValues(alpha: 0.6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Top bar: back + title ────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _RoundGlassButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      'مسح رمز QR',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineMd(
                        color: Colors.white,
                        languageCode: lang,
                      ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),

          // ── Guidance + bottom toolbar ────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'وجّه الكاميرا نحو رمز QR لإتمام العملية',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd(
                        color: Colors.white.withValues(alpha: 0.9),
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ToolbarAction(
                          icon: _torchOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          label: _torchOn ? 'إيقاف الفلاش' : 'تشغيل الفلاش',
                          active: _torchOn,
                          onTap: _toggleTorch,
                          lang: lang,
                        ),
                        const SizedBox(width: 40),
                        _ToolbarAction(
                          icon: Icons.photo_library_rounded,
                          label: 'من المعرض',
                          onTap: _scanFromGallery,
                          lang: lang,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Analysing overlay (gallery decode) ───────────────────────
          if (_analyzing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.walletBrandAlt,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'جارٍ تحليل الصورة…',
                      style: AppTextStyles.bodyMd(
                        color: Colors.white,
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Circular translucent icon button used for the top-bar back action.
class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// A labelled circular action in the scanner's bottom toolbar (flash / gallery).
class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.lang,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String lang;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.walletBrandAlt
                  : Colors.white.withValues(alpha: 0.16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelSm(
              color: Colors.white.withValues(alpha: 0.92),
              languageCode: lang,
            ).copyWith(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Elegant bottom sheet shown when a picked image contains no valid account QR.
class _NoQrFoundSheet extends StatelessWidget {
  const _NoQrFoundSheet();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final scheme = colors.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2_rounded,
                  color: AppColors.error, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              'لم يتم العثور على رمز QR صالح في الصورة',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd(
                color: scheme.onSurface,
                languageCode: lang,
              ).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر صورة أخرى تحتوي على رمز QR واضح، أو وجّه الكاميرا نحو الرمز.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd(
                color: scheme.onSurfaceVariant,
                languageCode: lang,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'حسنًا',
                  style: AppTextStyles.labelSm(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the dark scrim with a rounded transparent cut-out and four softly
/// glowing blue corner brackets around the scan area.
class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.cutout, required this.frameColor});

  final Rect cutout;
  final Color frameColor;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(22);
    final rrect = RRect.fromRectAndRadius(cutout, radius);

    // Scrim everywhere except the cut-out.
    final scrim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.55));

    // Glow pass, then a crisp stroke, for the corner brackets.
    final glow = Paint()
      ..color = frameColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final stroke = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const arm = 30.0;
    const r = 22.0;
    for (final paint in [glow, stroke]) {
      // top-left
      canvas.drawPath(
        Path()
          ..moveTo(cutout.left, cutout.top + arm)
          ..lineTo(cutout.left, cutout.top + r)
          ..arcToPoint(Offset(cutout.left + r, cutout.top),
              radius: const Radius.circular(r))
          ..lineTo(cutout.left + arm, cutout.top),
        paint,
      );
      // top-right
      canvas.drawPath(
        Path()
          ..moveTo(cutout.right - arm, cutout.top)
          ..lineTo(cutout.right - r, cutout.top)
          ..arcToPoint(Offset(cutout.right, cutout.top + r),
              radius: const Radius.circular(r))
          ..lineTo(cutout.right, cutout.top + arm),
        paint,
      );
      // bottom-right
      canvas.drawPath(
        Path()
          ..moveTo(cutout.right, cutout.bottom - arm)
          ..lineTo(cutout.right, cutout.bottom - r)
          ..arcToPoint(Offset(cutout.right - r, cutout.bottom),
              radius: const Radius.circular(r))
          ..lineTo(cutout.right - arm, cutout.bottom),
        paint,
      );
      // bottom-left
      canvas.drawPath(
        Path()
          ..moveTo(cutout.left + arm, cutout.bottom)
          ..lineTo(cutout.left + r, cutout.bottom)
          ..arcToPoint(Offset(cutout.left, cutout.bottom - r),
              radius: const Radius.circular(r))
          ..lineTo(cutout.left, cutout.bottom - arm),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.cutout != cutout || oldDelegate.frameColor != frameColor;
}
