import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';

/// حوالات الشبكات — the money-transfer networks screen.
///
/// Only the Unified Network (UN Money) is live for now; other networks from the
/// design (Al-Waseet, Lahazat/Al-Qutaibi, Thawani/SYB, Shumool Pay) are added to
/// [_networks] once their logos + integrations are ready.
class NetworkTransfersScreen extends StatelessWidget {
  const NetworkTransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;

    final networks = <_Network>[
      _Network(
        name: l10n.unMoneyTitle,
        asset: 'assets/telecom/unmoney.png',
        onTap: () => context.push('/unmoney'),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.networkTransfersTitle), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        itemCount: networks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _NetworkCard(
          network: networks[i],
          languageCode: languageCode,
        ),
      ),
    );
  }
}

class _Network {
  const _Network({required this.name, required this.asset, required this.onTap});

  final String name;
  final String asset;
  final VoidCallback onTap;
}

class _NetworkCard extends StatelessWidget {
  const _NetworkCard({required this.network, required this.languageCode});

  final _Network network;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppColors.radiusXl),
      child: InkWell(
        onTap: network.onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusXl),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    network.asset,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  network.name,
                  style: AppTextStyles.bodyMd(
                    color: colors.onSurface,
                    languageCode: languageCode,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
