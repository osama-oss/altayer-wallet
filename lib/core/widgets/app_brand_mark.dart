import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_text_styles.dart';

/// In-app «عَ الطاير» (Ala Taier) branding (logo + optional title).
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

  static const String logoAsset = 'assets/branding/ubs.svg';
  static const String appName = 'عَ الطاير';

  @override
  Widget build(BuildContext context) {
    final titleStyle = compact
        ? AppTextStyles.headlineMd(color: titleColor ?? Colors.white)
            .copyWith(fontWeight: FontWeight.w800)
        : AppTextStyles.displayLgMobile(color: titleColor ?? Colors.white)
            .copyWith(fontSize: compact ? 20 : 24, fontWeight: FontWeight.w800);

    if (!showTitle) {
      return SvgPicture.asset(
        logoAsset,
        height: logoHeight,
        fit: BoxFit.contain,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          logoAsset,
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
    final color = titleColor ?? Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          AppBrandMark.logoAsset,
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

