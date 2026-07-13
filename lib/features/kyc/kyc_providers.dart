import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'kyc_reference_data.dart';
import 'kyc_repository.dart';
import 'kyc_status.dart';

/// Master switch for the KYC feature's UI entry points.
///
/// Toggles the KYC entry points (home banner + profile "confirm account" card).
/// When `false`, KYC is "dead code" — present but unreachable through the UI, and
/// the app never hits the KYC backend. Set to `true` to surface the entry points
/// for testing the account-verification screens; the status call falls back to
/// `unverified` while the backend is not yet live, so the CTA still shows.
const bool kycFeatureEnabled = true;

/// Single KYC backend gateway (status / upload / submit).
final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepository(
    auth: ref.watch(authServiceProvider),
    api: ref.watch(apiClientProvider),
  );
});

/// Live country list for the KYC pickers (WALLET_COUNTRY via mobile-service).
/// Falls back to the local [kycCountries] list while loading / on error.
final kycCountriesProvider = FutureProvider<List<KycCountry>>((ref) {
  return ref.read(kycRepositoryProvider).fetchCountries();
});

/// Live business-sector list for the KYC picker (WALLET_SECTOR via mobile-service).
/// Falls back to [kycSectorsFallback] while loading / on error.
final kycSectorsProvider = FutureProvider<List<KycSector>>((ref) {
  return ref.read(kycRepositoryProvider).fetchSectors();
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
