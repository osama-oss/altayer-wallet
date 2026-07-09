import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// شعار «Ultimate Wallet» المتوافق مع الثيم — يختار النسخة الفاتحة أو الداكنة
/// تلقائياً حسب سطوع الثيم الحالي.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 56, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/branding/ultimate_wallet_dark.svg'
        : 'assets/branding/ultimate_wallet_light.svg';
    return SvgPicture.asset(
      asset,
      height: height,
      width: width,
      fit: BoxFit.contain,
    );
  }
}
