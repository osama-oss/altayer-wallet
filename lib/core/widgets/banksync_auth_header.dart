import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

import 'app_brand_mark.dart';

class BankSyncAuthHeader extends StatelessWidget {
  const BankSyncAuthHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {

    final languageCode = Localizations.localeOf(context).languageCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF003EA8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBrandMarkRow(
            logoHeight: 32,
            titleColor: Colors.white,
            logoColor: Colors.white,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTextStyles.displayLgMobile(color: Colors.white, languageCode: languageCode),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: AppTextStyles.bodyMd(color: Colors.white.withValues(alpha: 0.9), languageCode: languageCode),
            ),
          ],
        ],
      ),
    );
  }
}
