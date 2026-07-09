class BankingAccount {
  const BankingAccount({
    required this.id,
    required this.accountNumber,
    required this.label,
    required this.currency,
    required this.balance,
    this.cardColor,
  });

  final int id;
  final String accountNumber;
  final String label;
  final String currency;
  final double balance;
  final int? cardColor;

  /// Account number sent to core integrations (e.g. lastTenTxn), zero-padded when numeric.
  String get accountNoForIntegration {
    final n = accountNumber.trim();
    if (RegExp(r'^\d+$').hasMatch(n) && n.length < 12) {
      return n.padLeft(12, '0');
    }
    return n;
  }

  static double _parseBalance(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  factory BankingAccount.fromMap(Map<String, dynamic> map) {
    return BankingAccount(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}') ?? 0,
      accountNumber: map['accountNumber']?.toString() ?? '',
      label: map['label']?.toString() ?? map['accountNumber']?.toString() ?? 'Account',
      currency: map['currency']?.toString() ?? 'LYD',
      balance: _parseBalance(map['balance']),
      cardColor: map['cardColor'] as int?,
    );
  }

  /// Maps CUSTOMER_ACCOUNTS_SEARCH core/integration payload to carousel accounts.
  static List<BankingAccount> listFromCoreIntegration(Map<String, dynamic> payload) {
    List<dynamic> rows = const [];
    final nested = payload['data'];
    if (nested is Map && nested['data'] is List) {
      rows = nested['data'] as List;
    } else if (payload['data'] is List) {
      rows = payload['data'] as List;
    }
    return rows.map((row) {
      final map = row as Map<String, dynamic>;
      final name = map['customerName'];
      var label = map['ID']?.toString() ?? 'Account';
      if (name is String && name.trim().isNotEmpty) {
        label = name.trim();
      } else if (name is Map) {
        label = name['en']?.toString() ?? name['ar']?.toString() ?? label;
      }
      return BankingAccount(
        id: int.tryParse('${map['ID']}') ?? map.hashCode,
        accountNumber: map['ID']?.toString() ?? '',
        label: label,
        currency: map['ccy']?.toString() ?? 'YER',
        balance: _parseBalance(map['balance']),
      );
    }).toList();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'accountNumber': accountNumber,
        'label': label,
        'currency': currency,
        'balance': balance,
        if (cardColor != null) 'cardColor': cardColor,
      };
}
