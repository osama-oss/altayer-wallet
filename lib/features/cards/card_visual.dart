import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/payment_card_widget.dart';
import '../../l10n/app_localizations.dart';
import 'card_models.dart';

/// Shared card face used by the list and detail screens: Hero-animated, with
/// an animated "frost" overlay (blur + icy tint) while the card is frozen.
class CardVisual extends StatelessWidget {
  const CardVisual({
    super.key,
    required this.card,
    required this.typeLabel,
    required this.l10n,
    required this.languageCode,
  });

  final BankCard card;
  final String typeLabel;
  final AppLocalizations l10n;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppColors.radiusLg);

    return LayoutBuilder(
      builder: (context, constraints) => Hero(
        tag: 'card-${card.id}',
        child: Stack(
          children: [
            PaymentCardWidget(
              label: typeLabel,
              lastFour: card.lastFour,
              expiry: card.expiry,
              network: card.network,
              cardholderName: card.cardholderName,
              width: constraints.maxWidth,
              gradientColors: card.gradient,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: card.frozen
                      ? ClipRRect(
                          key: const ValueKey('frost'),
                          borderRadius: radius,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: radius,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.30),
                                    const Color(0xFF7DD3FC).withValues(alpha: 0.22),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: CardStatusChip(
                                  frozen: true,
                                  l10n: l10n,
                                  languageCode: languageCode,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.expand(key: ValueKey('clear')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardStatusChip extends StatelessWidget {
  const CardStatusChip({
    super.key,
    required this.frozen,
    required this.l10n,
    required this.languageCode,
  });

  final bool frozen;
  final AppLocalizations l10n;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final background = frozen ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7);
    final foreground = frozen ? const Color(0xFF0369A1) : const Color(0xFF15803D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: frozen
            ? [
                BoxShadow(
                  color: colors.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            frozen ? Icons.ac_unit_rounded : Icons.check_circle_rounded,
            size: 13,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            frozen ? l10n.cardStatusFrozen : l10n.cardStatusActive,
            style: AppTextStyles.labelSm(
              color: foreground,
              languageCode: languageCode,
            ).copyWith(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
