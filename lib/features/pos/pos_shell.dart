import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/merchant_auth_service.dart';
import '../../core/providers/merchant_providers.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_loader.dart';
import '../../l10n/app_localizations.dart';
import 'pos_cashier_home_screen.dart';
import 'pos_owner_home_screen.dart';

/// Role-based POS shell after merchant login.
class PosShell extends ConsumerWidget {
  const PosShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(merchantProfileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: UffLoader())),
      error: (_, __) => _ErrorScaffold(onRetry: () => ref.invalidate(merchantProfileProvider)),
      data: (profile) {
        final role = MerchantAuthService.resolveRole(profile);
        return switch (role) {
          MerchantPosRole.cashier => const PosCashierHomeScreen(),
          MerchantPosRole.supervisor => const PosSupervisorHomeScreen(),
          MerchantPosRole.owner => PosOwnerHomeScreen(
              simulationMode: profile['simulationMode'] == true,
            ),
          MerchantPosRole.unknown => _ErrorScaffold(
              message: 'Unrecognized merchant role',
              onRetry: () => ref.invalidate(merchantProfileProvider),
            ),
        };
      },
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return Scaffold(
      appBar: AppBar(title: const Text('POS')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message ?? 'Something went wrong', style: TextStyle(color: colors.error)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
