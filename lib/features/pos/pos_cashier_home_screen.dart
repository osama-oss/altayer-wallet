import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/merchant_providers.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_loader.dart';
import '../../l10n/app_localizations.dart';

class PosCashierHomeScreen extends ConsumerStatefulWidget {
  const PosCashierHomeScreen({super.key});

  @override
  ConsumerState<PosCashierHomeScreen> createState() => _PosCashierHomeScreenState();
}

class _PosCashierHomeScreenState extends ConsumerState<PosCashierHomeScreen> {
  Uint8List? _qrBytes;
  bool _qrLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  Future<void> _loadQr() async {
    setState(() => _qrLoading = true);
    try {
      final auth = ref.read(merchantAuthServiceProvider);
      final api = ref.read(merchantApiClientProvider);
      final token = await auth.readToken();
      if (token == null) return;
      final bytes = await api.pointQrPng(token);
      if (mounted) setState(() => _qrBytes = Uint8List.fromList(bytes));
    } catch (_) {
      if (mounted) setState(() => _qrBytes = null);
    } finally {
      if (mounted) setState(() => _qrLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final txAsync = ref.watch(merchantTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cashier POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(merchantAuthServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadQr();
          ref.invalidate(merchantTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Point QR', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Center(
              child: _qrLoading
                  ? const UffLoader()
                  : _qrBytes == null
                      ? Text('QR unavailable', style: TextStyle(color: colors.error))
                      : Image.memory(_qrBytes!, width: 220, height: 220),
            ),
            const SizedBox(height: 24),
            Text('My transactions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            txAsync.when(
              loading: () => const Center(child: UffLoader()),
              error: (_, __) => Text('Something went wrong', style: TextStyle(color: colors.error)),
              data: (items) {
                if (items.isEmpty) {
                  return Text('No transactions yet');
                }
                return Column(
                  children: items.map((raw) {
                    final tx = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tx['reference']?.toString() ?? '—'),
                      subtitle: Text('${tx['type'] ?? ''} · ${tx['amount'] ?? ''} ${tx['currency'] ?? ''}'),
                      trailing: Text(tx['status']?.toString() ?? ''),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
