import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'bank_sync_colors.dart';

abstract final class AppTheme {
  static ThemeData lightFor(Locale locale) => _build(locale, BankSyncColors.light);

  static ThemeData darkFor(Locale locale) => _build(locale, BankSyncColors.dark);

  static ThemeData _build(Locale locale, BankSyncColors palette) {
    final languageCode = locale.languageCode;
    final isDark = palette == BankSyncColors.dark;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SFProArabic',
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: palette.background,
      colorScheme: isDark
          ? ColorScheme.dark(
              surface: palette.surface,
              onSurface: palette.onSurface,
              primary: palette.secondary,
              onPrimary: palette.onSecondary,
              secondary: palette.secondary,
              onSecondary: palette.onSecondary,
              error: palette.error,
              outline: palette.outline,
              surfaceContainerHighest: palette.surfaceContainerHighest,
            )
          : const ColorScheme.light(
              surface: AppColors.surface,
              onSurface: AppColors.onSurface,
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              secondary: AppColors.secondary,
              onSecondary: AppColors.onSecondary,
              error: AppColors.error,
              outline: AppColors.outline,
            ),
      extensions: [palette],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.background,
        foregroundColor: palette.primary,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineMd(
          color: palette.primary,
          languageCode: languageCode,
        ).copyWith(fontSize: 20, fontWeight: FontWeight.w800),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: palette.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          side: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.outlineVariant.withValues(alpha: 0.6)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        // Floating label: the field name sits inside the border while empty and
        // rises above the border on focus / when filled (see reference design).
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusField),
          borderSide: BorderSide(color: palette.outlineVariant, width: 1.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusField),
          borderSide: BorderSide(color: palette.outlineVariant, width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusField),
          borderSide: BorderSide(color: palette.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusField),
          borderSide: BorderSide(color: palette.error, width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusField),
          borderSide: BorderSide(color: palette.error, width: 2),
        ),
        hintStyle: AppTextStyles.bodyMd(color: palette.outline, languageCode: languageCode),
        // Resting label (field empty, unfocused): reads like a placeholder.
        labelStyle: AppTextStyles.bodyMd(
          color: palette.onSurfaceVariant,
          languageCode: languageCode,
        ).copyWith(fontWeight: FontWeight.w500, fontSize: 14.5),
        // Floating label (risen above the border): bold and highly legible —
        // dark ink normally, brand ink while focused, error ink on error.
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          final Color ink;
          if (states.contains(WidgetState.error)) {
            ink = palette.error;
          } else if (states.contains(WidgetState.focused)) {
            ink = palette.secondary;
          } else {
            ink = palette.onSurface;
          }
          return AppTextStyles.labelSm(color: ink, languageCode: languageCode).copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            height: 1,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.secondary,
          foregroundColor: palette.onSecondary,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.labelSm(
            color: palette.onSecondary,
            languageCode: languageCode,
          ).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.secondary,
          foregroundColor: palette.onSecondary,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.labelSm(
            color: palette.onSecondary,
            languageCode: languageCode,
          ).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.secondary,
          textStyle: AppTextStyles.labelSm(
            color: palette.secondary,
            languageCode: languageCode,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceContainerHigh,
        contentTextStyle: AppTextStyles.bodyMd(color: palette.onSurface, languageCode: languageCode),
      ),
      textTheme: TextTheme(
        displaySmall: AppTextStyles.displayLgMobile(
          color: palette.onSurface,
          languageCode: languageCode,
        ),
        headlineSmall: AppTextStyles.headlineMd(
          color: palette.onSurface,
          languageCode: languageCode,
        ),
        bodyMedium: AppTextStyles.bodyMd(
          color: palette.onSurface,
          languageCode: languageCode,
        ),
        labelMedium: AppTextStyles.labelSm(
          color: palette.onSurface,
          languageCode: languageCode,
        ),
      ),
    );
  }

  static ThemeData get light => lightFor(const Locale('en'));
}
