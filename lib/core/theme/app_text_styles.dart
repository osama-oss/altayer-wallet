import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  /// Single app-wide typeface: Tajawal. Non-Latin/Arabic glyphs (e.g. CJK)
  /// fall through to the platform's default font automatically.
  static TextStyle _sans({Color? color, String languageCode = 'en'}) {
    return TextStyle(
      fontFamily: 'Tajawal',
      fontFamilyFallback: const ['Segoe UI', 'Arial', 'sans-serif'],
      color: color ?? AppColors.onSurface,
    );
  }

  static TextStyle inter({Color? color, String languageCode = 'en'}) =>
      _sans(color: color, languageCode: languageCode);

  /// Tajawal with tabular (monospaced) figures so amounts/digits align in
  /// columns — used for balances and numeric labels.
  static TextStyle mono({Color? color}) => TextStyle(
        fontFamily: 'Tajawal',
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? AppColors.onSurface,
      );

  static TextStyle displayLgMobile({Color? color, String languageCode = 'en'}) =>
      _sans(color: color, languageCode: languageCode).copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 34 / 28,
        letterSpacing: languageCode == 'ar' || languageCode == 'zh' ? 0 : -0.28,
        color: color,
      );

  static TextStyle headlineMd({Color? color, String languageCode = 'en'}) =>
      _sans(color: color, languageCode: languageCode).copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        color: color,
      );

  static TextStyle balanceDisplay({Color? color}) => mono(color: color).copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        letterSpacing: -0.96,
        color: color,
      );

  static TextStyle bodyMd({Color? color, String languageCode = 'en'}) =>
      _sans(color: color, languageCode: languageCode).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
        color: color,
      );

  static TextStyle labelSm({Color? color, String languageCode = 'en'}) =>
      _sans(color: color, languageCode: languageCode).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: color,
      );

  static TextStyle monoLabel({Color? color}) => mono(color: color).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: color,
      );
}
