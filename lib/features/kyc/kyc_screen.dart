import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/uff_loader.dart';
import '../../l10n/app_localizations.dart';
import 'kyc_providers.dart';
import 'kyc_status.dart';
import 'widgets/kyc_flow.dart';
import 'widgets/kyc_status_result.dart';

/// Account verification (KYC) entry point.
///
/// The screen is fully status-driven off [kycStatusProvider]:
///   • unverified / incomplete / rejected / returned → the document capture flow
///   • pending                            → "under review" result
///   • verified                           → "you're verified" result
///
/// Capturing, previewing, retaking, uploading and submitting are all live;
/// the only server-side dependency (persisting documents + review) is the KYC
/// REST controller described in `mobile-service-scaffold/KYC_BACKEND_PLAN.md`.
class KycScreen extends ConsumerWidget {
  const KycScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final async = ref.watch(kycStatusProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.kycTitle,
          style: const TextStyle(
              fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: UffLoader()),
        error: (_, __) => _ErrorRetry(
          onRetry: () => ref.read(kycStatusProvider.notifier).refresh(),
          colors: colors,
          l10n: l10n,
        ),
        data: (profile) => _body(context, ref, profile),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, KycProfile profile) {
    switch (profile.status) {
      case KycStatus.verified:
        return KycStatusResultView(
          profile: profile,
          primaryLabel: context.l10n.kycBackToHome,
          onPrimary: () => context.go('/home'),
        );
      case KycStatus.pending:
        return KycStatusResultView(
          profile: profile,
          primaryLabel: context.l10n.kycBackToHome,
          onPrimary: () => context.go('/home'),
        );
      case KycStatus.unverified:
      case KycStatus.incomplete:
      case KycStatus.rejected:
      case KycStatus.returned:
        return KycFlow(
          profile: profile,
          onSubmitted: (result) => _onKycVerified(context, ref, result),
        );
    }
  }

  /// After account confirmation the backend writes `customer_id` to Keycloak.
  /// The current JWT was minted before that, so we end the session and ask the
  /// customer to sign in again for a fresh token.
  Future<void> _onKycVerified(
    BuildContext context,
    WidgetRef ref,
    KycProfile result,
  ) async {
    if (!result.status.isVerified || !context.mounted) return;

    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n.kycVerifiedHeadline,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.kycVerifiedSignInAgainBody,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.okButton,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    await ref.read(authServiceProvider).signOut(full: true);
    if (!context.mounted) return;
    context.go('/login');
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({
    required this.onRetry,
    required this.colors,
    required this.l10n,
  });

  final VoidCallback onRetry;
  final BankSyncColors colors;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 44, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              l10n.kycServiceUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: colors.secondary,
                foregroundColor: colors.onSecondary,
              ),
              child: Text(
                l10n.kycRetry,
                style: const TextStyle(
                    fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
