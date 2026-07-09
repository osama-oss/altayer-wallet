/// Immutable notification model aligned with the shared API contract.
///
/// Backend returns already-localized `title` and `body` based on the
/// customer's `preferred_language` or the `Current-Language` header.
///
/// See: docs/NOTIFICATION_API.md — Response model (`NotificationItem`)
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.payload = const {},
    this.expiresAt,
  });

  final int id;

  /// Category: TRANSFER, SECURITY, BILL, OFFER, GENERAL
  final String type;

  /// Priority level: CRITICAL, HIGH, NORMAL, LOW
  final String severity;

  /// Localized title from backend (safe for in-app display).
  final String title;

  /// Localized body from backend (safe for in-app display).
  final String body;

  /// Type-specific payload map (e.g. `reference`, `amount`, `currency`).
  final Map<String, dynamic> payload;

  final bool isRead;
  final DateTime? expiresAt;
  final DateTime createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'GENERAL',
      severity: json['severity'] as String? ?? 'NORMAL',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      payload: json['payload'] as Map<String, dynamic>? ?? const {},
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      severity: severity,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      payload: payload,
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }
}

/// Paginated response wrapper for the notifications inbox endpoint.
class NotificationPage {
  const NotificationPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<NotificationItem> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasMore => page + 1 < totalPages;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>? ?? [];
    return NotificationPage(
      content: contentList
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

/// Notification preferences model from GET/PUT /api/mobile/notification-preferences.
class NotificationPreferences {
  const NotificationPreferences({
    this.pushEnabled = true,
    this.transferEnabled = true,
    this.securityEnabled = true,
    this.billEnabled = true,
    this.offerEnabled = true,
    this.generalEnabled = true,
    this.preferredLanguage = 'en',
  });

  final bool pushEnabled;
  final bool transferEnabled;

  /// Always true — backend ignores attempts to disable.
  final bool securityEnabled;
  final bool billEnabled;
  final bool offerEnabled;
  final bool generalEnabled;
  final String preferredLanguage;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      transferEnabled: json['transferEnabled'] as bool? ?? true,
      securityEnabled: json['securityEnabled'] as bool? ?? true,
      billEnabled: json['billEnabled'] as bool? ?? true,
      offerEnabled: json['offerEnabled'] as bool? ?? true,
      generalEnabled: json['generalEnabled'] as bool? ?? true,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() => {
        'pushEnabled': pushEnabled,
        'transferEnabled': transferEnabled,
        // securityEnabled is intentionally omitted — backend ignores it
        'billEnabled': billEnabled,
        'offerEnabled': offerEnabled,
        'generalEnabled': generalEnabled,
        'preferredLanguage': preferredLanguage,
      };

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? transferEnabled,
    bool? billEnabled,
    bool? offerEnabled,
    bool? generalEnabled,
    String? preferredLanguage,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      transferEnabled: transferEnabled ?? this.transferEnabled,
      securityEnabled: securityEnabled, // always true
      billEnabled: billEnabled ?? this.billEnabled,
      offerEnabled: offerEnabled ?? this.offerEnabled,
      generalEnabled: generalEnabled ?? this.generalEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
