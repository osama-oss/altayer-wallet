import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class BankSyncColors extends ThemeExtension<BankSyncColors> {
  const BankSyncColors({
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.onTertiaryContainer,
    required this.tertiaryFixedDim,
    required this.error,
    required this.success,
    required this.accentGreen,
    required this.onError,
    required this.errorContainer,
    required this.outline,
    required this.outlineVariant,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceVariant,
    required this.secondaryFixed,
    required this.onSecondaryFixed,
    required this.primaryFixed,
    required this.cardShadow,
    required this.glassPanelFill,
    required this.glassPanelBorder,
  });

  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color onTertiaryContainer;
  final Color tertiaryFixedDim;
  final Color error;
  final Color success;
  final Color accentGreen;
  final Color onError;
  final Color errorContainer;
  final Color outline;
  final Color outlineVariant;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceVariant;
  final Color secondaryFixed;
  final Color onSecondaryFixed;
  final Color primaryFixed;
  final Color cardShadow;
  final Color glassPanelFill;
  final Color glassPanelBorder;

  static const light = BankSyncColors(
    background: AppColors.background,
    onBackground: AppColors.onBackground,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    tertiaryFixedDim: AppColors.tertiaryFixedDim,
    error: AppColors.error,
    success: AppColors.success,
    accentGreen: AppColors.accentGreen,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    surfaceVariant: AppColors.surfaceVariant,
    secondaryFixed: AppColors.secondaryFixed,
    onSecondaryFixed: AppColors.onSecondaryFixed,
    primaryFixed: AppColors.primaryFixed,
    cardShadow: Color(0x0A000000),
    glassPanelFill: Color(0xB3FFFFFF),
    glassPanelBorder: Color(0x33FFFFFF),
  );

  static const dark = BankSyncColors(
    background: Color(0xFF0C0D11),
    onBackground: Color(0xFFE2E2E9),
    surface: Color(0xFF0C0D11),
    onSurface: Color(0xFFE2E2E9),
    onSurfaceVariant: Color(0xFF8E92A0),
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF1A2235),
    onPrimaryContainer: Color(0xFFB8C0D4),
    secondary: Color(0xFF9B87FF),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF122342),
    onSecondaryContainer: Color(0xFFDBE5FF),
    onTertiaryContainer: Color(0xFF4C8CFF),
    tertiaryFixedDim: Color(0xFF4C8CFF),
    error: Color(0xFFFFB4AB),
    success: Color(0xFF6DD58C),
    accentGreen: Color(0xFF00C853),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    outline: Color(0xFF383C4A),
    outlineVariant: Color(0xFF1F222C),
    surfaceContainerLowest: Color(0xFF12141A),
    surfaceContainerLow: Color(0xFF161922),
    surfaceContainer: Color(0xFF1A1D29),
    surfaceContainerHigh: Color(0xFF222736),
    surfaceContainerHighest: Color(0xFF2C3246),
    surfaceVariant: Color(0xFF2C3246),
    secondaryFixed: Color(0xFFDBE1FF),
    onSecondaryFixed: Color(0xFF00174B),
    primaryFixed: Color(0xFF2A3145),
    cardShadow: Color(0x66000000),
    glassPanelFill: Color(0xB3161922),
    glassPanelBorder: Color(0x33FFFFFF),
  );

  @override
  BankSyncColors copyWith({
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? onTertiaryContainer,
    Color? tertiaryFixedDim,
    Color? error,
    Color? success,
    Color? accentGreen,
    Color? onError,
    Color? errorContainer,
    Color? outline,
    Color? outlineVariant,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? surfaceVariant,
    Color? secondaryFixed,
    Color? onSecondaryFixed,
    Color? primaryFixed,
    Color? cardShadow,
    Color? glassPanelFill,
    Color? glassPanelBorder,
  }) {
    return BankSyncColors(
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      tertiaryFixedDim: tertiaryFixedDim ?? this.tertiaryFixedDim,
      error: error ?? this.error,
      success: success ?? this.success,
      accentGreen: accentGreen ?? this.accentGreen,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      surfaceContainerLowest: surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      secondaryFixed: secondaryFixed ?? this.secondaryFixed,
      onSecondaryFixed: onSecondaryFixed ?? this.onSecondaryFixed,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      cardShadow: cardShadow ?? this.cardShadow,
      glassPanelFill: glassPanelFill ?? this.glassPanelFill,
      glassPanelBorder: glassPanelBorder ?? this.glassPanelBorder,
    );
  }

  @override
  BankSyncColors lerp(covariant ThemeExtension<BankSyncColors>? other, double t) {
    if (other is! BankSyncColors) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return BankSyncColors(
      background: lerpColor(background, other.background),
      onBackground: lerpColor(onBackground, other.onBackground),
      surface: lerpColor(surface, other.surface),
      onSurface: lerpColor(onSurface, other.onSurface),
      onSurfaceVariant: lerpColor(onSurfaceVariant, other.onSurfaceVariant),
      primary: lerpColor(primary, other.primary),
      onPrimary: lerpColor(onPrimary, other.onPrimary),
      primaryContainer: lerpColor(primaryContainer, other.primaryContainer),
      onPrimaryContainer: lerpColor(onPrimaryContainer, other.onPrimaryContainer),
      secondary: lerpColor(secondary, other.secondary),
      onSecondary: lerpColor(onSecondary, other.onSecondary),
      secondaryContainer: lerpColor(secondaryContainer, other.secondaryContainer),
      onSecondaryContainer: lerpColor(onSecondaryContainer, other.onSecondaryContainer),
      onTertiaryContainer: lerpColor(onTertiaryContainer, other.onTertiaryContainer),
      tertiaryFixedDim: lerpColor(tertiaryFixedDim, other.tertiaryFixedDim),
      error: lerpColor(error, other.error),
      success: lerpColor(success, other.success),
      accentGreen: lerpColor(accentGreen, other.accentGreen),
      onError: lerpColor(onError, other.onError),
      errorContainer: lerpColor(errorContainer, other.errorContainer),
      outline: lerpColor(outline, other.outline),
      outlineVariant: lerpColor(outlineVariant, other.outlineVariant),
      surfaceContainerLowest: lerpColor(surfaceContainerLowest, other.surfaceContainerLowest),
      surfaceContainerLow: lerpColor(surfaceContainerLow, other.surfaceContainerLow),
      surfaceContainer: lerpColor(surfaceContainer, other.surfaceContainer),
      surfaceContainerHigh: lerpColor(surfaceContainerHigh, other.surfaceContainerHigh),
      surfaceContainerHighest: lerpColor(surfaceContainerHighest, other.surfaceContainerHighest),
      surfaceVariant: lerpColor(surfaceVariant, other.surfaceVariant),
      secondaryFixed: lerpColor(secondaryFixed, other.secondaryFixed),
      onSecondaryFixed: lerpColor(onSecondaryFixed, other.onSecondaryFixed),
      primaryFixed: lerpColor(primaryFixed, other.primaryFixed),
      cardShadow: lerpColor(cardShadow, other.cardShadow),
      glassPanelFill: lerpColor(glassPanelFill, other.glassPanelFill),
      glassPanelBorder: lerpColor(glassPanelBorder, other.glassPanelBorder),
    );
  }
}

extension BankSyncThemeX on BuildContext {
  BankSyncColors get bankColors =>
      Theme.of(this).extension<BankSyncColors>() ?? BankSyncColors.light;
}
