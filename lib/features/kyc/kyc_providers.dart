import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'kyc_repository.dart';
import 'kyc_status.dart';

/// Single KYC backend gateway (status / upload / submit).
final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepository(
    auth: ref.watch(authServiceProvider),
    api: ref.watch(apiClientProvider),
  );
});

/// Name + gender captured at sign-up, shown read-only atop the KYC form so the
/// customer confirms (but can't change) what they registered with. Resolves to
/// null while loading or if the account predates this being recorded.
final registrationIdentityProvider =
    FutureProvider<Map<String, dynamic>?>((ref) {
  return ref.read(authServiceProvider).readRegistrationIdentity();
});

/// Shared, cached KYC status for the signed-in customer. The home banner, the
/// verification screen and the profile screen all watch this so they stay in
/// sync. Falls back to the profile-derived status when the backend endpoint is
/// not yet available (never fabricates a verified/pending state).
final kycStatusProvider =
    AsyncNotifierProvider<KycStatusNotifier, KycProfile>(KycStatusNotifier.new);

class KycStatusNotifier extends AsyncNotifier<KycProfile> {
  @override
  Future<KycProfile> build() async {
    // Errored states must not be served from cache — retry on next watch.
    ref.onCancel(() {
      if (state.hasError) ref.invalidateSelf();
    });
    return ref.read(kycRepositoryProvider).fetchStatus();
  }

  /// Re-reads the status from the backend.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(kycRepositoryProvider).fetchStatus(),
    );
  }

  /// Applies a status snapshot returned by a successful submit without a round
  /// trip, so every watcher updates immediately.
  void applyLocal(KycProfile profile) {
    state = AsyncData(profile);
  }
}

/// Whether the signed-in customer has completed identity verification.
///
/// Fails safe to `false` while the status is loading, errored, or anything
/// other than VERIFIED — so operations stay locked until the account is
/// confirmed. This is a UX gate only: the server remains the authoritative gate
/// (money operations need a `customer_id` the backend issues only after
/// verification).
final walletVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(kycStatusProvider).valueOrNull?.status.isVerified ?? false;
});
