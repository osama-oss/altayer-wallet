/// One row from the `FAVORITE_LIST` integration — a transfer target the
/// customer pinned for one-tap re-transfer. Server-side in db_mobile
/// (favorite_transfers), scoped to the signed-in customer by the backend, so
/// favorites survive clear-data / reinstall / new device.
class FavoriteTransfer {
  const FavoriteTransfer({
    required this.id,
    required this.targetAccountNumber,
    this.targetName,
    this.nickname,
    this.currency = 'YER',
    this.transferType,
    this.beneficiaryId,
    this.createdAt,
  });

  final int id;
  final String targetAccountNumber;
  final String? targetName;
  final String? nickname;
  final String currency;
  final String? transferType;
  final int? beneficiaryId;
  final DateTime? createdAt;

  factory FavoriteTransfer.fromMap(Map<String, dynamic> map) {
    return FavoriteTransfer(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}') ?? 0,
      targetAccountNumber: map['targetAccountNumber']?.toString() ?? '',
      targetName: _optional(map['targetName']),
      nickname: _optional(map['nickname']),
      currency: map['currency']?.toString() ?? 'YER',
      transferType: _optional(map['transferType']),
      beneficiaryId: map['beneficiaryId'] is int
          ? map['beneficiaryId'] as int
          : int.tryParse('${map['beneficiaryId']}'),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '')?.toLocal(),
    );
  }

  /// Maps the `favorites` list from `FAVORITE_LIST` (already newest-first).
  static List<FavoriteTransfer> listFrom(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => FavoriteTransfer.fromMap(Map<String, dynamic>.from(e)))
        .where((f) => f.targetAccountNumber.isNotEmpty)
        .toList();
  }

  /// Preferred display name: nickname → target name → account number.
  String get displayName {
    if (nickname?.trim().isNotEmpty == true) return nickname!.trim();
    if (targetName?.trim().isNotEmpty == true) return targetName!.trim();
    return targetAccountNumber;
  }

  static String? _optional(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}
