import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_text_styles.dart';

/// In-app «Ultimate Wallet» branding (logo + optional title).
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({
    super.key,
    this.showTitle = true,
    this.logoHeight = 48,
    this.titleColor,
    this.compact = false,
  });

  final bool showTitle;
  final double logoHeight;
  final Color? titleColor;
  final bool compact;

  static String logoAsset(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? 'assets/branding/ultimate_wallet_dark.svg'
        : 'assets/branding/ultimate_wallet_light.svg';
  }
  static const String appName = 'Ultimate Wallet';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleStyle = compact
        ? AppTextStyles.headlineMd(color: titleColor ?? (isDark ? Colors.white : const Color(0xFF14152E)))
            .copyWith(fontWeight: FontWeight.w800)
        : AppTextStyles.displayLgMobile(color: titleColor ?? (isDark ? Colors.white : const Color(0xFF14152E)))
            .copyWith(fontSize: compact ? 20 : 24, fontWeight: FontWeight.w800);

    final assetPath = logoAsset(context);

    if (!showTitle) {
      return SvgPicture.asset(
        assetPath,
        height: logoHeight,
        fit: BoxFit.contain,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          assetPath,
          height: logoHeight,
          fit: BoxFit.contain,
        ),
        if (!compact) const SizedBox(height: 12),
        if (compact) const SizedBox(height: 8),
        Text(appName, style: titleStyle),
      ],
    );
  }
}

/// Logo + app name in a horizontal row (login, auth headers).
class AppBrandMarkRow extends StatelessWidget {
  const AppBrandMarkRow({
    super.key,
    this.logoHeight = 36,
    this.titleColor,
  });

  final double logoHeight;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = titleColor ?? (isDark ? Colors.white : const Color(0xFF14152E));
    final assetPath = AppBrandMark.logoAsset(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          assetPath,
          height: logoHeight,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            AppBrandMark.appName,
            style: AppTextStyles.headlineMd(color: color)
                .copyWith(fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

