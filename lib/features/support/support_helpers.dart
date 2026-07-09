import '../../l10n/app_localizations.dart';

String supportQueueBanner(AppLocalizations l10n, Map<String, dynamic>? supportCase) {
  if (supportCase == null) return '';
  final queueState = supportCase['queueState']?.toString() ?? '';
  switch (queueState) {
    case 'QUEUED':
      return l10n.supportQueued;
    case 'ASSIGNED':
      final name = supportCase['assignedCsrDisplayName']?.toString() ?? 'CSR';
      return l10n.supportAssignedTo(name);
    case 'WAITING_ON_YOU':
      return l10n.supportWaitingForYou;
    default:
      return supportCase['status']?.toString() ?? '';
  }
}

String? supportReadReceipt(
  AppLocalizations l10n, {
  required Map<String, dynamic> message,
  required bool isMine,
}) {
  if (message['internal'] == true) return null;
  if (isMine) {
    return message['participantReadAt'] != null ? l10n.supportSeen : l10n.supportDelivered;
  }
  return message['csrReadAt'] != null ? l10n.supportSeen : l10n.supportDelivered;
}

void applyMessagesRead(
  List<Map<String, dynamic>> messages,
  Map<String, dynamic>? readPayload,
) {
  if (readPayload == null) return;
  final ids = readPayload['messageIds'];
  if (ids is! List) return;
  final idSet = ids.map((e) => e.toString()).toSet();
  final csrReadAt = readPayload['csrReadAt'];
  final participantReadAt = readPayload['participantReadAt'];
  for (var i = 0; i < messages.length; i++) {
    final id = messages[i]['id']?.toString();
    if (id == null || !idSet.contains(id)) continue;
    messages[i] = {
      ...messages[i],
      if (csrReadAt != null) 'csrReadAt': csrReadAt,
      if (participantReadAt != null) 'participantReadAt': participantReadAt,
    };
  }
}

List<Map<String, dynamic>> withMessagesRead(
  List<Map<String, dynamic>> messages,
  Map<String, dynamic>? readPayload,
) {
  if (readPayload == null) return messages;
  final copy = messages.map((m) => Map<String, dynamic>.from(m)).toList();
  applyMessagesRead(copy, readPayload);
  return copy;
}

List<Map<String, dynamic>> appendSupportMessage(
  List<Map<String, dynamic>> messages,
  Map<String, dynamic> message,
) {
  final id = message['id']?.toString();
  if (id != null && messages.any((m) => m['id']?.toString() == id)) {
    return messages;
  }
  return [...messages, message];
}
