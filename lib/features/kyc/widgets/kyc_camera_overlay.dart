import 'package:flutter/material.dart';

import '../kyc_document.dart';

/// Geometry helper: computes the document/face cutout rectangle for a given
/// screen size and frame shape so the painter and the instruction text agree
/// on where the frame sits.
class KycFrameGeometry {
  const KycFrameGeometry._();

  /// Width:height ratio of each frame (landscape >1, portrait <1).
  static double aspectRatio(KycFrameShape shape) => switch (shape) {
        KycFrameShape.card => 1.585, // ID-1 (85.6 × 54 mm)
        KycFrameShape.passport => 1.42, // passport data page (125 × 88 mm)
        KycFrameShape.faceOval => 0.74, // portrait oval
      };

  /// The centered cutout for [shape] within [size]. Vertically biased slightly
  /// above center to leave room for actions at the bottom.
  static Rect cutout(Size size, KycFrameShape shape) {
    final ratio = aspectRatio(shape);
    final center = Offset(size.width / 2, size.height * 0.42);
    if (shape == KycFrameShape.faceOval) {
      final width = (size.width * 0.62).clamp(200.0, 320.0);
      final height = width / ratio; // ratio < 1 → taller than wide
      return Rect.fromCenter(center: center, width: width, height: height);
    }
    final width = (size.width * 0.86).clamp(260.0, 460.0);
    final height = width / ratio;
    return Rect.fromCenter(center: center, width: width, height: height);
  }
}

/// Paints the dark scrim with a clear cutout for the document/face, plus the
/// glowing brand-blue frame (corner brackets for cards/passports, a ring for
/// the selfie oval). Colors are passed in from the theme — nothing hardcoded.
class KycCameraOverlayPainter extends CustomPainter {
  KycCameraOverlayPainter({
    required this.cutout,
    required this.shape,
    required this.frameColor,
    required this.scrimColor,
    required this.glow,
  });

  final Rect cutout;
  final KycFrameShape shape;
  final Color frameColor;
  final Color scrimColor;

  /// 0..1 breathing value for the glow.
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = shape == KycFrameShape.faceOval;
    final radius = oval ? Radius.zero : const Radius.circular(20);

    // ── Dark scrim with the cutout punched out ──────────────────────────
    final scrimPaint = Paint()..color = scrimColor;
    final full = Path()..addRect(Offset.zero & size);
    final holePath = Path();
    if (oval) {
      holePath.addOval(cutout);
    } else {
      holePath.addRRect(RRect.fromRectAndRadius(cutout, radius));
    }
    final scrim = Path.combine(PathOperation.difference, full, holePath);
    canvas.drawPath(scrim, scrimPaint);

    // ── Frame ───────────────────────────────────────────────────────────
    final glowAlpha = 0.35 + 0.45 * glow;
    if (oval) {
      _paintOval(canvas, glowAlpha);
    } else {
      _paintCorners(canvas, glowAlpha);
    }
  }

  void _paintOval(Canvas canvas, double glowAlpha) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = frameColor.withValues(alpha: glowAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * glow + 1);
    canvas.drawOval(cutout, ring);

    final solid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = frameColor.withValues(alpha: 0.9);
    canvas.drawOval(cutout, solid);
  }

  void _paintCorners(Canvas canvas, double glowAlpha) {
    const len = 30.0;
    const r = 20.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = frameColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * glow + 0.5);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = frameColor.withValues(alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (final paths in [glowPaint, paint]) {
      // Top-left
      canvas.drawPath(
        Path()
          ..moveTo(cutout.left, cutout.top + r + len)
          ..lineTo(cutout.left, cutout.top + r)
          ..arcToPoint(Offset(cutout.left + r, cutout.top),
              radius: const Radius.circular(r))
          ..lineTo(cutout.left + r + len, cutout.top),
        paths,
      );
      // Top-right
      canvas.drawPath(
        Path()
          ..moveTo(cutout.right - r - len, cutout.top)
          ..lineTo(cutout.right - r, cutout.top)
          ..arcToPoint(Offset(cutout.right, cutout.top + r),
              radius: const Radius.circular(r))
          ..lineTo(cutout.right, cutout.top + r + len),
        paths,
      );
      // Bottom-right
      canvas.drawPath(
        Path()
          ..moveTo(cutout.right, cutout.bottom - r - len)
          ..lineTo(cutout.right, cutout.bottom - r)
          ..arcToPoint(Offset(cutout.right - r, cutout.bottom),
              radius: const Radius.circular(r))
          ..lineTo(cutout.right - r - len, cutout.bottom),
        paths,
      );
      // Bottom-left
      canvas.drawPath(
        Path()
          ..moveTo(cutout.left + r + len, cutout.bottom)
          ..lineTo(cutout.left + r, cutout.bottom)
          ..arcToPoint(Offset(cutout.left, cutout.bottom - r),
              radius: const Radius.circular(r))
          ..lineTo(cutout.left, cutout.bottom - r - len),
        paths,
      );
    }
  }

  @override
  bool shouldRepaint(covariant KycCameraOverlayPainter old) =>
      old.glow != glow ||
      old.cutout != cutout ||
      old.shape != shape ||
      old.frameColor != frameColor;
}
