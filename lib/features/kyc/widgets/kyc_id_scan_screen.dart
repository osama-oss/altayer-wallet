import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Opens a full-screen barcode scanner tuned for the barcode printed on an
/// identity card, resolving with the extracted **ID number** — or `null` if the
/// user backs out without a successful scan.
///
/// Detection accepts any 1D/2D symbology (`mobile_scanner` scans the whole
/// frame regardless of the on-screen guide). The number is pulled from the
/// decoded payload via [extractIdNumber] so it works whether the card encodes
/// the bare number or a delimited PDF417 block. If nothing usable is read the
/// customer can still type the number by hand — the caller keeps the field
/// editable.
Future<String?> openIdBarcodeScanScreen(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => const KycIdScanScreen(),
      fullscreenDialog: true,
    ),
  );
}

/// Pulls the most likely ID number out of a decoded barcode payload: the
/// longest run of digits (handles PDF417 blocks that embed the number among
/// other fields), falling back to the trimmed raw text. Returns `null` for an
/// empty payload.
String? extractIdNumber(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final runs = RegExp(r'\d{4,}')
      .allMatches(trimmed)
      .map((m) => m.group(0)!)
      .toList();
  if (runs.isEmpty) return trimmed;
  runs.sort((a, b) => b.length.compareTo(a.length));
  return runs.first;
}

/// Full-screen, bank-identity barcode scanner: a live camera with a softly
/// glowing blue frame sized for a card barcode, a sweeping scan beam, and a
/// flash toggle. It never fills anything itself — it only decodes the number
/// and pops it back to the caller.
class KycIdScanScreen extends StatefulWidget {
  const KycIdScanScreen({super.key});

  @override
  State<KycIdScanScreen> createState() => _KycIdScanScreenState();
}

class _KycIdScanScreenState extends State<KycIdScanScreen>
    with TickerProviderStateMixin {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  late final AnimationController _lineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  bool _handled = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _lineController.dispose();
    _glowController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    final number = extractIdNumber(raw);
    if (number == null) return;
    _handled = true;
    Navigator.of(context).pop(number);
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // Torch may be unavailable (emulator / no flash) — ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final size = MediaQuery.of(context).size;
    // A landscape window sized for a card barcode (wider than tall).
    final w = (size.width * 0.78).clamp(240.0, 340.0);
    final cutout = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.40),
      width: w,
      height: w * 0.62,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, _) =>
                _CameraError(lang: lang, message: error.errorDetails?.message),
          ),

          // Dimmed scrim + glowing blue corners around the barcode window.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) => CustomPaint(
                  painter: _IdScanOverlayPainter(
                    cutout: cutout,
                    frameColor: AppColors.walletBrandAlt,
                    glow: Curves.easeInOut.transform(_glowController.value),
                  ),
                ),
              ),
            ),
          ),

          // Sweeping scan beam clipped to the window.
          Positioned.fromRect(
            rect: cutout,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AnimatedBuilder(
                  animation: _lineController,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(_lineController.value);
                    return Align(
                      alignment: Alignment(0, (t * 2) - 1),
                      child: const _ScanBeam(color: AppColors.walletBrandAlt),
                    );
                  },
                ),
              ),
            ),
          ),

          // Top bar: back + title.
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
                      'امسح باركود الهوية',
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

          // Guidance + flash.
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
                      'وجّه الكاميرا نحو الباركود الموجود على بطاقتك',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd(
                        color: Colors.white.withValues(alpha: 0.92),
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'إذا تعذّرت القراءة يمكنك إدخال الرقم يدويًا',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm(
                        color: Colors.white.withValues(alpha: 0.7),
                        languageCode: lang,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    _ToolbarAction(
                      icon: _torchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      label: _torchOn ? 'إيقاف الفلاش' : 'تشغيل الفلاش',
                      active: _torchOn,
                      onTap: _toggleTorch,
                      lang: lang,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly full-screen message when the camera can't start (e.g. permission
/// denied) — the customer can back out and type the number by hand.
class _CameraError extends StatelessWidget {
  const _CameraError({required this.lang, this.message});

  final String lang;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_outlined,
                  color: Colors.white.withValues(alpha: 0.85), size: 44),
              const SizedBox(height: 16),
              Text(
                'تعذّر فتح الكاميرا. تأكّد من منح صلاحية الكاميرا، أو أدخل رقم الهوية يدويًا.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd(
                  color: Colors.white,
                  languageCode: lang,
                ).copyWith(fontWeight: FontWeight.w600, height: 1.5),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'رجوع',
                  style: AppTextStyles.labelSm(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

/// The sweeping scan beam: a soft halo with a crisp bright core, fading at the
/// horizontal edges so it reads as a polished laser band.
class _ScanBeam extends StatelessWidget {
  const _ScanBeam({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.0),
                  color.withValues(alpha: 0.26),
                  color.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Container(
            height: 2.5,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.0),
                  color,
                  color.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the dark scrim with a rounded transparent cut-out and four softly
/// breathing glowing corner brackets around the barcode window.
class _IdScanOverlayPainter extends CustomPainter {
  _IdScanOverlayPainter({
    required this.cutout,
    required this.frameColor,
    this.glow = 0.5,
  });

  final Rect cutout;
  final Color frameColor;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(20);
    final rrect = RRect.fromRectAndRadius(cutout, radius);

    final scrim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
        scrim, Paint()..color = Colors.black.withValues(alpha: 0.58));

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = frameColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final glowAlpha = 0.35 + 0.30 * glow;
    final glowBlur = 5.0 + 4.0 * glow;
    final glowPaint = Paint()
      ..color = frameColor.withValues(alpha: glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur);
    final stroke = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const arm = 30.0;
    const r = 20.0;
    for (final paint in [glowPaint, stroke]) {
      canvas.drawPath(
        Path()
          ..moveTo(cutout.left, cutout.top + arm)
          ..lineTo(cutout.left, cutout.top + r)
          ..arcToPoint(Offset(cutout.left + r, cutout.top),
              radius: const Radius.circular(r))
          ..lineTo(cutout.left + arm, cutout.top),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(cutout.right - arm, cutout.top)
          ..lineTo(cutout.right - r, cutout.top)
          ..arcToPoint(Offset(cutout.right, cutout.top + r),
              radius: const Radius.circular(r))
          ..lineTo(cutout.right, cutout.top + arm),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(cutout.right, cutout.bottom - arm)
          ..lineTo(cutout.right, cutout.bottom - r)
          ..arcToPoint(Offset(cutout.right - r, cutout.bottom),
              radius: const Radius.circular(r))
          ..lineTo(cutout.right - arm, cutout.bottom),
        paint,
      );
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
  bool shouldRepaint(covariant _IdScanOverlayPainter oldDelegate) =>
      oldDelegate.cutout != cutout ||
      oldDelegate.frameColor != frameColor ||
      oldDelegate.glow != glow;
}
