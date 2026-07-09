import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'support_event_service.dart';
import 'support_helpers.dart';
import '../../core/widgets/uff_loader.dart';

class SupportThreadScreen extends ConsumerStatefulWidget {
  const SupportThreadScreen({super.key, required this.caseId});

  final int caseId;

  @override
  ConsumerState<SupportThreadScreen> createState() => _SupportThreadScreenState();
}

class _SupportThreadScreenState extends ConsumerState<SupportThreadScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  final _eventService = SupportEventService();
  Timer? _markReadTimer;
  SupportEventSubscription? _subscription;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _supportCase;
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectSse());
    _markReadTimer = Timer.periodic(const Duration(seconds: 30), (_) => _markRead());
  }

  @override
  void dispose() {
    _markReadTimer?.cancel();
    _subscription?.close();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) throw const ApiException('Not signed in');
      final api = ref.read(apiClientProvider);
      final supportCase = await api.getSupportCase(token, widget.caseId);
      final messages = await api.listSupportMessages(token, widget.caseId);
      if (!mounted) return;
      setState(() {
        _supportCase = supportCase;
        _messages = messages;
        _loading = false;
      });
      _scrollToLatest();
      await _markRead();
    } on ApiException catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _markRead() async {
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) return;
      await ref.read(apiClientProvider).markSupportCaseRead(token, widget.caseId);
    } catch (_) {}
  }

  void _connectSse() {
    _subscription?.close();
    ref.read(authServiceProvider).readToken().then((token) {
      if (!mounted || token == null) return;
      final locale = Localizations.localeOf(context).languageCode;
      _subscription = _eventService.subscribeAuthenticated(
        token: token,
        caseId: widget.caseId,
        currentLanguage: locale,
        onEvent: _handleSseEvent,
      );
    });
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
          _scrollToLatest();
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
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) return;
      final sent = await ref.read(apiClientProvider).sendSupportMessage(token, widget.caseId, text);
      _replyController.clear();
      if (!mounted) return;
      setState(() => _messages = appendSupportMessage(_messages, sent));
      _scrollToLatest();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
      appBar: AppBar(
        title: Text(_supportCase?['subject']?.toString() ?? l10n.supportTitle),
      ),
      body: _loading
          ? const Center(child: UffLoader())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    if (_supportCase != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_supportCase!['caseNumber']} · $status',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
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
                                child: Text(
                                  banner,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            alignment:
                                isCsr ? Alignment.centerLeft : Alignment.centerRight,
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
                                  controller: _replyController,
                                  minLines: 1,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: l10n.supportReply,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _sending ? null : _send,
                                icon: _sending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: UffLoader(),
                                      )
                                    : const Icon(Icons.send),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
