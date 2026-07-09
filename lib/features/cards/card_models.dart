import 'package:flutter/material.dart';

import '../../core/widgets/payment_card_widget.dart';

/// Cards are demo-only by decision: a dedicated external card switch will own
/// real card data later, so nothing here touches the backend or the core.
enum BankCardType { debit, credit }

enum CardTxnCategory {
  shopping,
  grocery,
  restaurant,
  transport,
  atm,
  subscription,
  refund,
}

class BankCard {
  const BankCard({
    required this.id,
    required this.type,
    required this.network,
    required this.lastFour,
    required this.expiry,
    required this.cardholderName,
    required this.gradient,
    required this.linkedAccount,
    required this.currency,
    required this.dailyPurchaseLimit,
    required this.atmWithdrawalLimit,
    this.frozen = false,
    this.onlinePayments = true,
    this.contactless = true,
  });

  final String id;
  final BankCardType type;
  final CardNetwork network;
  final String lastFour;
  final String expiry;
  final String cardholderName;
  final List<Color> gradient;
  final String linkedAccount;
  final String currency;
  final double dailyPurchaseLimit;
  final double atmWithdrawalLimit;
  final bool frozen;
  final bool onlinePayments;
  final bool contactless;

  BankCard copyWith({
    bool? frozen,
    bool? onlinePayments,
    bool? contactless,
    double? dailyPurchaseLimit,
    double? atmWithdrawalLimit,
  }) {
    return BankCard(
      id: id,
      type: type,
      network: network,
      lastFour: lastFour,
      expiry: expiry,
      cardholderName: cardholderName,
      gradient: gradient,
      linkedAccount: linkedAccount,
      currency: currency,
      dailyPurchaseLimit: dailyPurchaseLimit ?? this.dailyPurchaseLimit,
      atmWithdrawalLimit: atmWithdrawalLimit ?? this.atmWithdrawalLimit,
      frozen: frozen ?? this.frozen,
      onlinePayments: onlinePayments ?? this.onlinePayments,
      contactless: contactless ?? this.contactless,
    );
  }
}

class CardTransaction {
  const CardTransaction({
    required this.merchant,
    required this.category,
    required this.amount,
    required this.currency,
    required this.daysAgo,
  });

  final String merchant;
  final CardTxnCategory category;

  /// Negative = spend, positive = refund/credit.
  final double amount;
  final String currency;
  final int daysAgo;

  DateTime get date => DateTime.now().subtract(Duration(days: daysAgo));
}

/// Matches the two demo cards already shown on the home dashboard.
const demoCards = [
  BankCard(
    id: 'debit-8842',
    type: BankCardType.debit,
    network: CardNetwork.visa,
    lastFour: '8842',
    expiry: '12/28',
    cardholderName: 'Ahmed Hassan',
    gradient: [Color(0xFFC39A3C), Color(0xFF906E22)],
    linkedAccount: '•••• 7569',
    currency: 'SAR',
    dailyPurchaseLimit: 10000,
    atmWithdrawalLimit: 5000,
  ),
  BankCard(
    id: 'credit-1204',
    type: BankCardType.credit,
    network: CardNetwork.visa,
    lastFour: '1204',
    expiry: '08/29',
    cardholderName: 'Ahmed Hassan',
    gradient: [Color(0xFF1A1F71), Color(0xFF0D47A1), Color(0xFF1565C0)],
    linkedAccount: '•••• 3310',
    currency: 'SAR',
    dailyPurchaseLimit: 20000,
    atmWithdrawalLimit: 8000,
  ),
];

const demoCardTransactions = <String, List<CardTransaction>>{
  'debit-8842': [
    CardTransaction(
      merchant: 'Panda Hypermarket',
      category: CardTxnCategory.grocery,
      amount: -486.75,
      currency: 'SAR',
      daysAgo: 0,
    ),
    CardTransaction(
      merchant: 'Uber',
      category: CardTxnCategory.transport,
      amount: -34.50,
      currency: 'SAR',
      daysAgo: 1,
    ),
    CardTransaction(
      merchant: 'ATM Withdrawal',
      category: CardTxnCategory.atm,
      amount: -1000.00,
      currency: 'SAR',
      daysAgo: 3,
    ),
    CardTransaction(
      merchant: 'Amazon Refund',
      category: CardTxnCategory.refund,
      amount: 219.00,
      currency: 'SAR',
      daysAgo: 5,
    ),
    CardTransaction(
      merchant: 'Al Baik',
      category: CardTxnCategory.restaurant,
      amount: -58.00,
      currency: 'SAR',
      daysAgo: 6,
    ),
  ],
  'credit-1204': [
    CardTransaction(
      merchant: 'Netflix',
      category: CardTxnCategory.subscription,
      amount: -45.99,
      currency: 'SAR',
      daysAgo: 1,
    ),
    CardTransaction(
      merchant: 'Jarir Bookstore',
      category: CardTxnCategory.shopping,
      amount: -1249.00,
      currency: 'SAR',
      daysAgo: 2,
    ),
    CardTransaction(
      merchant: 'Careem',
      category: CardTxnCategory.transport,
      amount: -62.25,
      currency: 'SAR',
      daysAgo: 4,
    ),
    CardTransaction(
      merchant: 'Spotify',
      category: CardTxnCategory.subscription,
      amount: -21.99,
      currency: 'SAR',
      daysAgo: 8,
    ),
  ],
};
