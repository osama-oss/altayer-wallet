import 'package:flutter/material.dart';

/// «عَ الطاير» (Ala Taier) — digital wallet design tokens. Identity: electric
/// violet-indigo · clean & light · bilingual AR / EN. (Wallet rebrand of the
/// former UBS banking palette; success / positive amounts stay green.)
abstract final class AppColors {
  // ── Brand helpers ────────────────────────────────────────────────────────
  /// «عَ الطاير» primary brand colour — CTAs, active states, accents.
  static const Color brandIndigo = Color(0xFF5B2EE5);

  /// Wallet brand — lighter stop of the signature gradient.
  static const Color walletBrandAlt = Color(0xFF8A63FF);

  /// Green kept for success / positive amounts (base-palette carry-over).
  static const Color brandIndigoLight = Color(0xFF13A438);

  /// Tinted surface used behind selected chips / icon tiles.
  static const Color brandIndigoSurface = Color(0xFFE9F7EE);

  /// Hairline border for tinted surfaces.
  static const Color brandIndigoBorder = Color(0xFFDDE0FA);

  /// Dark navy used for feature / phone-frame surfaces.
  static const Color navy = Color(0xFF090078);

  /// Muted ink for secondary text (darker than [onSurfaceVariant]).
  static const Color inkMuted = Color(0xFF5A6173);

  // ── Semantic extras ──────────────────────────────────────────────────────
  static const Color warning = Color(0xFFFAB901);
  static const Color successContainer = Color(0xFFE9F7EE);
  static const Color onSuccessContainer = Color(0xFF13A438);
  static const Color warningContainer = Color(0xFFFFF4E0);

  static const Color background = Color(0xFFF4F5F8);
  static const Color onBackground = Color(0xFF14152E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF14152E);
  static const Color onSurfaceVariant = Color(0xFF9197A4);
  static const Color primary = Color(0xFF14152E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF090078);
  static const Color onPrimaryContainer = Color(0xFF9197A4);
  static const Color secondary = Color(0xFF5B2EE5);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF13A438);
  static const Color onSecondaryContainer = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF13A438);
  static const Color onTertiaryContainer = Color(0xFF13A438);
  static const Color tertiaryFixedDim = Color(0xFF13A438);
  static const Color tertiaryFixed = Color(0xFFE9F7EE);
  static const Color error = Color(0xFFD0021B);
  static const Color success = Color(0xFF13A438);
  static const Color accentGreen = Color(0xFF13A438);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFDE7EC);
  static const Color outline = Color(0xFFC7CBD8);
  static const Color outlineVariant = Color(0xFFECEDF2);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F5F8);
  static const Color surfaceContainer = Color(0xFFEEF0FF);
  static const Color surfaceContainerHigh = Color(0xFFF1F2F7);
  static const Color surfaceContainerHighest = Color(0xFFE4E6EC);
  static const Color surfaceVariant = Color(0xFFE4E6EC);
  static const Color secondaryFixed = Color(0xFFEEF0FF);
  static const Color onSecondaryFixed = Color(0xFF5B2EE5);
  static const Color primaryFixed = Color(0xFFDDE0FA);

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 22;
  static const double radiusPill = 999;

  /// Corner radius of every text input (matches the reference floating-label
  /// field design — a touch tighter than [radiusMd]).
  static const double radiusField = 12;

  /// Brand gradient used on hero cards / avatars.
  static const Gradient brandGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [walletBrandAlt, brandIndigo],
  );
}
