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
    // Seed from the cached profile first so a verified customer never flashes
    // the "not verified" banner while /kyc/status is in flight.
    final seeded = await ref.read(kycRepositoryProvider).profileSeed();
    if (seeded.status.isVerified) {
      // Still refresh from the server in the background, but don't wait.
      Future(() async {
        try {
          final live = await ref.read(kycRepositoryProvider).fetchStatus();
          if (!ref.exists(kycStatusProvider)) return;
          state = AsyncData(live);
        } catch (_) {
          // Keep the seeded verified status.
        }
      });
      return seeded;
    }
    return ref.read(kycRepositoryProvider).fetchStatus();
  }

  /// Re-reads the status from the backend. Keeps the previous value visible
  /// (no AsyncLoading) so the home banner does not flash "not verified".
  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = await AsyncValue.guard(
      () => ref.read(kycRepositoryProvider).fetchStatus(),
    );
    // If the live call failed and we already knew the user was verified, keep it.
    if (state.hasError && previous != null && previous.status.isVerified) {
      state = AsyncData(previous);
    }
  }

  /// Applies a status snapshot returned by a successful submit without a round
  /// trip, so every watcher updates immediately.
  void applyLocal(KycProfile profile) {
    state = AsyncData(profile);
  }
}

/// Whether the signed-in customer has completed identity verification.
///
/// While status is loading, keeps the previous known value (does not treat
/// loading as unverified). Fails safe to `false` only when there is no prior
/// data. This is a UX gate only: the server remains the authoritative gate.
final walletVerifiedProvider = Provider<bool>((ref) {
  final async = ref.watch(kycStatusProvider);
  final status = async.valueOrNull?.status;
  if (status != null) return status.isVerified;
  // Loading/error with no prior value → not verified yet.
  return false;
});
