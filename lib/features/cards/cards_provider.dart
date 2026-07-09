import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card_models.dart';

/// In-memory demo card state (freeze, settings, limits). Deliberately not
/// persisted: the external card switch will be the source of truth later.
class CardsNotifier extends Notifier<List<BankCard>> {
  @override
  List<BankCard> build() => demoCards;

  void _update(String id, BankCard Function(BankCard) change) {
    state = [
      for (final card in state)
        if (card.id == id) change(card) else card,
    ];
  }

  void setFrozen(String id, bool frozen) =>
      _update(id, (c) => c.copyWith(frozen: frozen));

  void setOnlinePayments(String id, bool enabled) =>
      _update(id, (c) => c.copyWith(onlinePayments: enabled));

  void setContactless(String id, bool enabled) =>
      _update(id, (c) => c.copyWith(contactless: enabled));

  void setDailyPurchaseLimit(String id, double limit) =>
      _update(id, (c) => c.copyWith(dailyPurchaseLimit: limit));

  void setAtmWithdrawalLimit(String id, double limit) =>
      _update(id, (c) => c.copyWith(atmWithdrawalLimit: limit));
}

final cardsProvider =
    NotifierProvider<CardsNotifier, List<BankCard>>(CardsNotifier.new);
