import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/screen_security.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'card_detail_screen.dart';
import 'card_models.dart';
import 'card_visual.dart';
import 'cards_provider.dart';

/// #18 — all cards with their status. Demo data only (external card switch
/// owns real cards later).
class MyCardsScreen extends ConsumerWidget {
  const MyCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final cards = ref.watch(cardsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.myCards),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final card = cards[index];
          return _StaggeredEntrance(
            index: index,
            child: _CardListItem(
              card: card,
              l10n: l10n,
              colors: colors,
              languageCode: languageCode,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SecureScreen(
                      child: CardDetailScreen(cardId: card.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Soft fade + slide-up entrance, staggered per list position.
class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 120),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _CardListItem extends StatelessWidget {
  const _CardListItem({
    required this.card,
    required this.l10n,
    required this.colors,
    required this.languageCode,
    required this.onTap,
  });

  final BankCard card;
  final AppLocalizations l10n;
  final BankSyncColors colors;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeLabel =
        card.type == BankCardType.debit ? l10n.debitCard : l10n.creditCard;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardVisual(
            card: card,
            typeLabel: typeLabel,
            l10n: l10n,
            languageCode: languageCode,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$typeLabel  •••• ${card.lastFour}',
                style: AppTextStyles.labelSm(
                  color: colors.onSurfaceVariant,
                  languageCode: languageCode,
                ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              CardStatusChip(
                frozen: card.frozen,
                l10n: l10n,
                languageCode: languageCode,
              ),
              const SizedBox(width: 4),
              Icon(
                languageCode == 'ar'
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
