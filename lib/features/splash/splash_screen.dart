import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';

import '../../core/theme/bank_sync_colors.dart';

/// A premium cinematic splash screen animation inspired by Al Rajhi Bank and Apple.
///
/// Animation Sequence:
/// 1. Fade in clean background with soft radial gradient and central spotlight.
/// 2. An elegant vertical line grows in the center of the screen.
/// 3. The line glows and expands in brightness.
/// 4. The line shifts left as the brand logo slides out to the right of it.
/// 5. A custom ClipRect reveals the logo as it emerges from behind the line.
/// 6. A diagonal white light sweep gradient sweeps across the logo.
/// 7. The composition settles naturally with a subtle scale-down.
/// 8. Seamlessly transitions to the next target screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  late final Animation<double> _bgOpacity;
  late final Animation<double> _lineHeight;
  late final Animation<double> _lineGlow;
  late final Animation<double> _logoReveal;
  late final Animation<double> _shimmerPosition;
  late final Animation<double> _settleScale;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 1. Background fades in
    _bgOpacity = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.12, curve: Curves.easeIn),
    );

    // 2. Vertical line grows in the center
    _lineHeight = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.08, 0.30, curve: Curves.easeInOutCubic),
    );

    // 3. Line glows and expands
    _lineGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35), weight: 65),
    ]).animate(CurvedAnimation(
      parent: _c,
      curve: const Interval(0.25, 0.52, curve: Curves.easeInOut),
    ));

    // 4. Logo slides out horizontally & line shifts left
    _logoReveal = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.40, 0.72, curve: Curves.easeInOutCubic),
    );

    // 5. Shimmer sweep over the logo
    _shimmerPosition = Tween<double>(begin: -0.3, end: 1.3).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.65, 0.88, curve: Curves.easeInOut),
      ),
    );

    // 6. Natural scale settling effect
    _settleScale = Tween<double>(begin: 1.04, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.40, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _c.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Calibrated delay to match the 3200ms animation duration
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 3500));
    String targetRoute = '/login';
    try {
      final result = await ref
          .read(authServiceProvider)
          .bootstrapRoute()
          .timeout(const Duration(seconds: 5), onTimeout: () => '/login');
      targetRoute = result ?? '/login';
    } catch (_) {
      targetRoute = '/login';
    }
    await minDelay;
    if (!mounted) return;
    context.go(targetRoute);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;

    // Dimensions of composition elements
    const double logoW = 141.0;
    const double logoH = 70.0;
    const double spacing = 16.0;
    const double lineW = 2.0;
    const double lineH = 76.0;
    const double totalW = lineW + spacing + logoW;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final bgVal = _bgOpacity.value;
          final lineHVal = _lineHeight.value;
          final glowVal = _lineGlow.value;
          final revealVal = _logoReveal.value;
          final shimmerVal = _shimmerPosition.value;
          final scaleVal = _settleScale.value;

          // Shifting coordinate for perfect centering
          final double lineX = -(spacing + logoW) / 2 * revealVal;
          // Logo slide inside the ClipRect
          final double logoX = -logoW + (spacing + logoW) * revealVal;

          return Stack(
            children: [
              // ── 1. Faded Gradient Background ──
              Opacity(
                opacity: bgVal,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.3,
                      colors: [
                        Colors.white,
                        Color(0xFFF1F5F9), // soft ice-grey
                        Color(0xFFE2E8F0), // clean lighting edge
                      ],
                      stops: [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // ── 2. Subtle center background glow ──
              Center(
                child: Opacity(
                  opacity: (lineHVal * 0.15).clamp(0.0, 0.15),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.secondary.withValues(alpha: 0.25),
                          colors.secondary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. Animated Brand Logo & Vertical Line Composition ──
              Center(
                child: Transform.scale(
                  scale: scaleVal,
                  child: Transform.translate(
                    offset: Offset(lineX, 0),
                    child: SizedBox(
                      width: totalW,
                      height: lineH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // A. The masking ClipRect for the logo (positioned right of line)
                          Positioned(
                            left: totalW / 2 + lineW / 2,
                            top: (lineH - logoH) / 2,
                            width: spacing + logoW + 80.0,
                            height: logoH,
                            child: ClipRect(
                              child: Stack(
                                alignment: Alignment.topLeft,
                                children: [
                                  Transform.translate(
                                    offset: Offset(logoX, 0),
                                    child: SizedBox(
                                      width: logoW,
                                      height: logoH,
                                      child: ShaderMask(
                                        shaderCallback: (rect) {
                                          return LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withValues(alpha: 0.0),
                                              Colors.white.withValues(alpha: 0.0),
                                              Colors.white.withValues(alpha: 0.75), // sweep glow
                                              Colors.white.withValues(alpha: 0.0),
                                              Colors.white.withValues(alpha: 0.0),
                                            ],
                                            stops: [
                                              0.0,
                                              (shimmerVal - 0.16).clamp(0.0, 1.0),
                                              shimmerVal.clamp(0.0, 1.0),
                                              (shimmerVal + 0.16).clamp(0.0, 1.0),
                                              1.0,
                                            ],
                                          ).createShader(rect);
                                        },
                                        blendMode: BlendMode.srcATop,
                                        child: SvgPicture.asset(
                                          'assets/branding/ubs.svg',
                                          width: logoW,
                                          height: logoH,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // B. The vertical elegant glowing line
                          Positioned(
                            left: totalW / 2 - lineW / 2,
                            top: (lineH - (lineH * lineHVal)) / 2,
                            width: lineW,
                            height: lineH * lineHVal,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.secondary,
                                borderRadius: BorderRadius.circular(lineW),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.secondary.withValues(
                                      alpha: 0.5 * glowVal * lineHVal,
                                    ),
                                    blurRadius: 16 * glowVal,
                                    spreadRadius: 2 * glowVal,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
