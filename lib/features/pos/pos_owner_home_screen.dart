import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/merchant_providers.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_loader.dart';
import '../../l10n/app_localizations.dart';
import 'onboarding_gate_dialog.dart';

class PosOwnerHomeScreen extends ConsumerWidget {
  const PosOwnerHomeScreen({super.key, required this.simulationMode});

  final bool simulationMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final catalogAsync = ref.watch(merchantCatalogProvider);
    final profileAsync = ref.watch(merchantProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Merchant POS'),
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
          ref.invalidate(merchantCatalogProvider);
          ref.invalidate(merchantProfileProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            profileAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (p) => _HeaderCard(
                title: p['merchantName']?.toString() ?? 'Merchant',
                subtitle: simulationMode
                    ? 'Complete registration to unlock services'
                    : (p['customerCode']?.toString() ?? ''),
                colors: colors,
              ),
            ),
            const SizedBox(height: 20),
            Text('Services', style: AppTextStyles.headlineMd().copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            catalogAsync.when(
              loading: () => const Center(child: UffLoader()),
              error: (_, __) => Text('Something went wrong', style: TextStyle(color: colors.error)),
              data: (tiles) => _ServicesGrid(
                tiles: tiles,
                simulationMode: simulationMode,
                onTap: (tile) => _handleTap(context, tile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, Map<String, dynamic> tile) {
    final requiresOnboarding = tile['requiresOnboarding'] == true;
    final comingSoon = tile['comingSoon'] == true;
    if (comingSoon) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.comingSoonToast)));
      return;
    }
    if (simulationMode && requiresOnboarding) {
      showOnboardingGateDialog(context);
      return;
    }
    final route = tile['routeKey']?.toString();
    if (route != null && route.isNotEmpty && context.mounted) {
      context.push(route);
    }
  }
}

class PosSupervisorHomeScreen extends ConsumerWidget {
  const PosSupervisorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text('Supervisor'),
        actions: [
          TextButton(
            onPressed: () => context.push('/pos/transactions'),
            child: Text('Transactions'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(merchantAuthServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Center(child: Text('Supervisor dashboard — scoped POS and transactions')),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.subtitle, required this.colors});

  final String title;
  final String subtitle;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineMd().copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({
    required this.tiles,
    required this.simulationMode,
    required this.onTap,
  });

  final List<dynamic> tiles;
  final bool simulationMode;
  final void Function(Map<String, dynamic> tile) onTap;

  @override
  Widget build(BuildContext context) {
    final maps = tiles.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: maps.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final tile = maps[index];
        final title = tile['title']?.toString() ?? '';
        return Material(
          color: context.bankColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onTap(tile),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_view_rounded, color: context.bankColors.secondary),
                  const SizedBox(height: 8),
                  Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
