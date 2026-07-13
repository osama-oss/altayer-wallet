import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/merchant_providers.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_loader.dart';
import '../../l10n/app_localizations.dart';

/// Re-export supervisor home from owner file for a thin module split.
export 'pos_owner_home_screen.dart' show PosSupervisorHomeScreen;

class PosTransactionsScreen extends ConsumerWidget {
  const PosTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final txAsync = ref.watch(merchantTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(merchantTransactionsProvider),
        child: txAsync.when(
          loading: () => const Center(child: UffLoader()),
          error: (_, __) => ListView(
            children: [Center(child: Text('Something went wrong', style: TextStyle(color: colors.error)))],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(children: [const Center(child: Text('No transactions yet'))]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final raw = items[index];
                final tx = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                return ListTile(
                  title: Text(tx['reference']?.toString() ?? '—'),
                  subtitle: Text('${tx['type'] ?? ''} · ${tx['amount'] ?? ''} ${tx['currency'] ?? ''}'),
                  trailing: Text(tx['status']?.toString() ?? ''),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
