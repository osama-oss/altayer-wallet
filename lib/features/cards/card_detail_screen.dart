import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'card_models.dart';
import 'card_visual.dart';
import 'cards_provider.dart';

/// #19 — freeze/unfreeze, payment settings, limits and recent transactions.
/// Demo data only; actions mutate in-memory state.
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final cards = ref.watch(cardsProvider);
    final card = cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) return const SizedBox.shrink();

    final typeLabel =
        card.type == BankCardType.debit ? l10n.debitCard : l10n.creditCard;
    final transactions = demoCardTransactions[card.id] ?? const [];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.cardDetails),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          CardVisual(
            card: card,
            typeLabel: typeLabel,
            l10n: l10n,
            languageCode: languageCode,
          ),
          const SizedBox(height: 12),
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
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                l10n.linkedAccount,
                style: AppTextStyles.labelSm(
                  color: colors.onSurfaceVariant,
                  languageCode: languageCode,
                ).copyWith(fontSize: 12),
              ),
              const Spacer(),
              Text(
                card.linkedAccount,
                style: AppTextStyles.monoLabel(color: colors.primary)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          // Frozen banner slides open/closed instead of popping in.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              alignment: Alignment.topCenter,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: card.frozen
                ? Padding(
                    key: const ValueKey('frozen-banner'),
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.ac_unit_rounded,
                              color: Color(0xFF0369A1), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.cardFrozenBanner,
                              style: AppTextStyles.labelSm(
                                color: const Color(0xFF0369A1),
                                languageCode: languageCode,
                              ).copyWith(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-banner')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _onFreezePressed(context, ref, card, l10n),
              style: FilledButton.styleFrom(
                backgroundColor:
                    card.frozen ? colors.secondary : const Color(0xFF0369A1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Row(
                  key: ValueKey(card.frozen),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      card.frozen
                          ? Icons.wb_sunny_rounded
                          : Icons.ac_unit_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(card.frozen ? l10n.unfreezeCard : l10n.freezeCard),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(text: l10n.cardSettings),
          const SizedBox(height: 8),
          _GroupCard(
            colors: colors,
            children: [
              SwitchListTile(
                value: card.onlinePayments && !card.frozen,
                onChanged: card.frozen
                    ? null
                    : (v) => ref
                        .read(cardsProvider.notifier)
                        .setOnlinePayments(card.id, v),
                activeTrackColor: colors.accentGreen,
                secondary: const _TileIcon(
                  icon: Icons.language_rounded,
                  background: Color(0xFFEFF6FF),
                  color: Color(0xFF2119F3),
                ),
                title: Text(l10n.onlinePayments),
                subtitle: Text(l10n.onlinePaymentsSubtitle),
              ),
              const Divider(height: 1, indent: 56, endIndent: 16),
              SwitchListTile(
                value: card.contactless && !card.frozen,
                onChanged: card.frozen
                    ? null
                    : (v) => ref
                        .read(cardsProvider.notifier)
                        .setContactless(card.id, v),
                activeTrackColor: colors.accentGreen,
                secondary: const _TileIcon(
                  icon: Icons.contactless_rounded,
                  background: Color(0xFFECFDF5),
                  color: Color(0xFF059669),
                ),
                title: Text(l10n.contactlessPayments),
                subtitle: Text(l10n.contactlessPaymentsSubtitle),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel(text: l10n.cardLimits),
          const SizedBox(height: 8),
          _GroupCard(
            colors: colors,
            children: [
              _LimitTile(
                icon: Icons.shopping_bag_outlined,
                iconBackground: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF9333EA),
                title: l10n.dailyPurchaseLimit,
                value: card.dailyPurchaseLimit,
                currency: card.currency,
                enabled: !card.frozen,
                onTap: () => _editLimit(
                  context,
                  l10n,
                  title: l10n.dailyPurchaseLimit,
                  current: card.dailyPurchaseLimit,
                  min: 1000,
                  max: 50000,
                  onSave: (v) => ref
                      .read(cardsProvider.notifier)
                      .setDailyPurchaseLimit(card.id, v),
                ),
              ),
              const Divider(height: 1, indent: 56, endIndent: 16),
              _LimitTile(
                icon: Icons.local_atm_rounded,
                iconBackground: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFD97706),
                title: l10n.atmWithdrawalLimit,
                value: card.atmWithdrawalLimit,
                currency: card.currency,
                enabled: !card.frozen,
                onTap: () => _editLimit(
                  context,
                  l10n,
                  title: l10n.atmWithdrawalLimit,
                  current: card.atmWithdrawalLimit,
                  min: 500,
                  max: 20000,
                  onSave: (v) => ref
                      .read(cardsProvider.notifier)
                      .setAtmWithdrawalLimit(card.id, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel(text: l10n.recentTransactions),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.noCardTransactions,
                  style: AppTextStyles.labelSm(
                    color: colors.onSurfaceVariant,
                    languageCode: languageCode,
                  ),
                ),
              ),
            )
          else
            _GroupCard(
              colors: colors,
              children: [
                for (var i = 0; i < transactions.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 56, endIndent: 16),
                  _CardTxnTile(
                    txn: transactions[i],
                    languageCode: languageCode,
                    colors: colors,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _onFreezePressed(
    BuildContext context,
    WidgetRef ref,
    BankCard card,
    AppLocalizations l10n,
  ) async {
    final notifier = ref.read(cardsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    if (card.frozen) {
      notifier.setFrozen(card.id, false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.cardUnfrozenToast)));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.freezeCardConfirmTitle),
        content: Text(l10n.freezeCardConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0369A1),
            ),
            child: Text(l10n.freezeCard),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    notifier.setFrozen(card.id, true);
    messenger.showSnackBar(SnackBar(content: Text(l10n.cardFrozenToast)));
  }

  Future<void> _editLimit(
    BuildContext context,
    AppLocalizations l10n, {
    required String title,
    required double current,
    required double min,
    required double max,
    required ValueChanged<double> onSave,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final selected = await showDialog<double>(
      context: context,
      builder: (context) {
        var value = current.clamp(min, max).toDouble();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  NumberFormat('#,##0').format(value),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: ((max - min) / 500).round(),
                  onChanged: (v) => setState(() => value = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child:
                    Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(value),
                child: Text(l10n.okButton),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == current) return;
    onSave(selected);
    messenger.showSnackBar(SnackBar(content: Text(l10n.limitUpdated)));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          fontFamily: 'SFProArabic',
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.colors, required this.children});

  final BankSyncColors colors;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Icon(icon, color: color, size: 20)),
    );
  }
}

class _LimitTile extends StatelessWidget {
  const _LimitTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.currency,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final double value;
  final String currency;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return ListTile(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      leading: _TileIcon(icon: icon, background: iconBackground, color: iconColor),
      title: Text(title),
      trailing: Text(
        '${NumberFormat('#,##0').format(value)} $currency',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: colors.secondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CardTxnTile extends StatelessWidget {
  const _CardTxnTile({
    required this.txn,
    required this.languageCode,
    required this.colors,
  });

  static const _negativeAmount = Color(0xFFEB5757);
  static const _positiveAmount = Color(0xFF27AE60);

  final CardTransaction txn;
  final String languageCode;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.amount > 0;
    final amountText =
        '${isCredit ? '+' : ''}${NumberFormat('#,##0.00').format(txn.amount)} ${txn.currency}';

    return ListTile(
      leading: _TileIcon(
        icon: _categoryIcon(txn.category),
        background: const Color(0xFFF1F5F9),
        color: const Color(0xFF475569),
      ),
      title: Text(txn.merchant),
      subtitle: Text(DateFormat('d MMM yyyy', languageCode).format(txn.date)),
      trailing: Text(
        amountText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isCredit ? _positiveAmount : _negativeAmount,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  IconData _categoryIcon(CardTxnCategory category) {
    switch (category) {
      case CardTxnCategory.shopping:
        return Icons.shopping_bag_outlined;
      case CardTxnCategory.grocery:
        return Icons.local_grocery_store_outlined;
      case CardTxnCategory.restaurant:
        return Icons.restaurant_rounded;
      case CardTxnCategory.transport:
        return Icons.directions_car_outlined;
      case CardTxnCategory.atm:
        return Icons.local_atm_rounded;
      case CardTxnCategory.subscription:
        return Icons.subscriptions_outlined;
      case CardTxnCategory.refund:
        return Icons.replay_rounded;
    }
  }
}
