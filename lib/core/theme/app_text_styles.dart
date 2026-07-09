import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  /// iOS-style typography: SF Pro Arabic primary, iOS15 Arabic as fallback.
  static TextStyle _sans({Color? color, String languageCode = 'en'}) {
    if (languageCode == 'zh') {
      return GoogleFonts.notoSansSc(color: color ?? AppColors.onSurface);
    }
    return TextStyle(
      fontFamily: 'SFProArabic',
      fontFamilyFallback: const [
        'iOS15Arabic',
        'Segoe UI',
        'Arial',
        'sans-serif',
      ],
      color: color ?? AppColors.onSurface,
    );
  }

  static TextStyle inter({Color? color, String languageCode = 'en'}) =>
      _sans(color: color, languageCode: languageCode);

  static TextStyle jetBrainsMono({Color? color}) =>
      GoogleFonts.jetBrainsMono(color: color ?? AppColors.onSurface);

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

  static TextStyle balanceDisplay({Color? color}) => jetBrainsMono(color: color).copyWith(
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

  static TextStyle monoLabel({Color? color}) => jetBrainsMono(color: color).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: color,
      );
}
