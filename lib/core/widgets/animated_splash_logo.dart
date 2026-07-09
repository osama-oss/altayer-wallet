import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// أنيميشن دخول الشعار في السبلاش — قابل لإعادة الاستخدام.
///
/// التسلسل: يبدأ الشعار كبيراً جداً (scale 2.5) وأعلى المنتصف قليلاً، ثم ينزل
/// إلى المركز مع تصغير متزامن (easeOutCubic)، يستقر بارتداد خفيف
/// (0.92 → 1.03 → 1.0)، ثم يظهر اسم التطبيق بتلاشٍ وانزلاق بسيط، مع مرور لمسة
/// ضوئية خفيفة مرة واحدة. لا خطوط أو عناصر إضافية.
class AnimatedSplashLogo extends StatefulWidget {
  const AnimatedSplashLogo({
    super.key,
    this.widthFactor = 0.62,
    this.showName = true,
  });

  /// نسبة العرض النهائي للشعار من عرض الشاشة (0.55–0.70 موصى بها).
  final double widthFactor;
  final bool showName;

  @override
  State<AnimatedSplashLogo> createState() => _AnimatedSplashLogoState();
}

class _AnimatedSplashLogoState extends State<AnimatedSplashLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _scale;
  late final Animation<double> _translateY;
  late final Animation<double> _sweep;
  late final Animation<double> _nameOpacity;
  late final Animation<double> _nameSlide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // تلاشٍ سريع للشعار عند البداية حتى لا يظهر فجأة.
    _logoOpacity = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.10, curve: Curves.easeIn),
    );

    // النزول + التصغير المتزامن ثم الارتداد الخفيف (scale 2.5 → 0.92 → 1.03 → 1.0).
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 2.5, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 62,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.03)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.03, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 18,
      ),
    ]).animate(CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.55)));

    // النزول من أعلى المنتصف إلى المركز (Y: -120 → 0) متزامن مع بداية التصغير.
    _translateY = Tween(begin: -120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    // لمسة ضوئية خفيفة تمر مرة واحدة من اليسار لليمين.
    _sweep = Tween(begin: -0.3, end: 1.3).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.45, 0.72, curve: Curves.easeInOut),
      ),
    );

    // ظهور اسم التطبيق (تلاشٍ + انزلاق بسيط) بعد استقرار الشعار.
    _nameOpacity = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.58, 0.80, curve: Curves.easeOut),
    );
    _nameSlide = Tween(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.58, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/branding/ultimate_wallet_dark.svg'
        : 'assets/branding/ultimate_wallet_light.svg';
    final logoW = MediaQuery.of(context).size.width * widget.widthFactor;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final p = _sweep.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: Offset(0, _translateY.value),
                child: Transform.scale(
                  scale: _scale.value,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.45), // سطوع اللمسة
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: [
                          0.0,
                          (p - 0.12).clamp(0.0, 1.0),
                          p.clamp(0.0, 1.0),
                          (p + 0.12).clamp(0.0, 1.0),
                          1.0,
                        ],
                      ).createShader(rect),
                      blendMode: BlendMode.srcATop,
                      child: SvgPicture.asset(
                        asset,
                        width: logoW,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showName) ...[
                const SizedBox(height: 20),
                Opacity(
                  opacity: _nameOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _nameSlide.value),
                    child: Text(
                      'Ultimate Wallet',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark
                            ? const Color(0xFF5B9DFF)
                            : const Color(0xFF0050B3),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
