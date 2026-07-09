import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'support_event_service.dart';
import 'support_helpers.dart';

class GuestSupportLookupScreen extends ConsumerStatefulWidget {
  const GuestSupportLookupScreen({
    super.key,
    this.initialCaseNumber,
    this.initialMobile,
  });

  final String? initialCaseNumber;
  final String? initialMobile;

  @override
  ConsumerState<GuestSupportLookupScreen> createState() =>
      _GuestSupportLookupScreenState();
}

class _GuestSupportLookupScreenState extends ConsumerState<GuestSupportLookupScreen> {
  final _caseNumber = TextEditingController();
  final _mobile = TextEditingController();
  final _reply = TextEditingController();
  final _eventService = SupportEventService();
  Timer? _markReadTimer;
  SupportEventSubscription? _subscription;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _supportCase;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCaseNumber != null) {
      _caseNumber.text = widget.initialCaseNumber!;
    }
    if (widget.initialMobile != null) {
      _mobile.text = widget.initialMobile!;
    }
    if (widget.initialCaseNumber != null && widget.initialMobile != null) {
      _load();
    }
    _markReadTimer = Timer.periodic(const Duration(seconds: 30), (_) => _markRead());
  }

  @override
  void dispose() {
    _markReadTimer?.cancel();
    _subscription?.close();
    _caseNumber.dispose();
    _mobile.dispose();
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final caseNumber = _caseNumber.text.trim();
      final mobile = _mobile.text.trim();
      final supportCase = await api.getGuestSupportCase(
        caseNumber: caseNumber,
        mobile: mobile,
      );
      final messages = await api.listGuestSupportMessages(
        caseNumber: caseNumber,
        mobile: mobile,
      );
      if (!mounted) return;
      setState(() {
        _supportCase = supportCase;
        _messages = messages;
        _error = null;
        _loading = false;
      });
      await _markRead();
      _connectSse(caseNumber: caseNumber, mobile: mobile);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _markRead() async {
    final caseNumber = _caseNumber.text.trim();
    final mobile = _mobile.text.trim();
    if (caseNumber.isEmpty || mobile.isEmpty) return;
    try {
      await ref.read(apiClientProvider).markGuestSupportCaseRead(
            caseNumber: caseNumber,
            mobile: mobile,
          );
    } catch (_) {}
  }

  void _connectSse({required String caseNumber, required String mobile}) {
    _subscription?.close();
    final locale = Localizations.localeOf(context).languageCode;
    _subscription = _eventService.subscribeGuest(
      caseNumber: caseNumber,
      mobile: mobile,
      currentLanguage: locale,
      onEvent: _handleSseEvent,
    );
  }

  void _handleSseEvent(SupportSseEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event.type) {
        case SupportSseEventType.caseUpdated:
          if (event.data != null) _supportCase = event.data;
          break;
        case SupportSseEventType.messageNew:
          final data = event.data;
          if (data == null) break;
          _messages = appendSupportMessage(_messages, data);
          if (data['senderType'] == 'CSR') {
            _markRead();
          }
          break;
        case SupportSseEventType.messagesRead:
          _messages = withMessagesRead(_messages, event.data);
          break;
        case SupportSseEventType.unknown:
          break;
      }
    });
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    try {
      final sent = await ref.read(apiClientProvider).sendGuestSupportMessage(
            caseNumber: _caseNumber.text.trim(),
            mobile: _mobile.text.trim(),
            message: text,
          );
      _reply.clear();
      if (!mounted) return;
      setState(() => _messages = appendSupportMessage(_messages, sent));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final status = _supportCase?['status']?.toString() ?? '';
    final closed = status == 'RESOLVED' || status == 'CLOSED';
    final banner = supportQueueBanner(l10n, _supportCase);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trackExistingCase)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _caseNumber,
                  decoration: InputDecoration(labelText: l10n.supportCaseNumber),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _mobile,
                  decoration: InputDecoration(labelText: l10n.guestMobile),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading ? null : _load,
                  child: Text(l10n.continueLabel),
                ),
              ],
            ),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
          if (_supportCase != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_supportCase!['subject']} · $status'),
                  if (banner.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_supportCase!['queueState'] == 'QUEUED'
                                ? colors.error
                                : colors.accentGreen)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(banner),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isCsr = message['senderType'] == 'CSR';
                  final receipt = supportReadReceipt(
                    l10n,
                    message: message,
                    isMine: !isCsr,
                  );
                  return Align(
                    alignment: isCsr ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: isCsr
                            ? colors.accentGreen.withValues(alpha: 0.12)
                            : colors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message['body']?.toString() ?? ''),
                          if (receipt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                receipt,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!closed)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reply,
                          decoration: InputDecoration(hintText: l10n.supportReply),
                        ),
                      ),
                      IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
