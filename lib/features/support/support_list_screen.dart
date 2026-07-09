import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/uff_loader.dart';

class SupportListScreen extends ConsumerStatefulWidget {
  const SupportListScreen({super.key});

  @override
  ConsumerState<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends ConsumerState<SupportListScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _cases = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) throw const ApiException('Not signed in');
      final cases = await ref.read(apiClientProvider).listSupportCases(token);
      if (!mounted) return;
      setState(() {
        _cases = cases;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _createCase() async {
    final l10n = context.l10n;
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.supportNewCase),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: InputDecoration(labelText: l10n.supportSubject),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.supportMessage),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.supportSubmit),
          ),
        ],
      ),
    );
    if (created != true || !mounted) return;
    try {
      final token = await ref.read(authServiceProvider).readToken();
      if (token == null) return;
      final result = await ref.read(apiClientProvider).createSupportCase(
            token,
            subject: subjectController.text.trim(),
            message: messageController.text.trim(),
          );
      final id = result['id'];
      if (id != null && mounted) {
        context.push('/support/$id');
      } else {
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      subjectController.dispose();
      messageController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCase,
        label: Text(l10n.supportNewCase),
        icon: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: UffLoader())
          : _error != null
              ? Center(child: Text(_error!))
              : _cases.isEmpty
                  ? Center(child: Text(l10n.supportNoCases))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cases.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _cases[index];
                          final id = item['id'];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: colors.outline),
                            ),
                            title: Text(item['subject']?.toString() ?? ''),
                            subtitle: Text(
                              '${item['caseNumber'] ?? ''} · ${item['status'] ?? ''}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              if (id != null) context.push('/support/$id');
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
