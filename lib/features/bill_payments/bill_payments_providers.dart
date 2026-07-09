import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'data/biller.dart';

/// Shared cache of the enabled billers (`BILLER_CATALOG`, db_mobile.billers).
/// Same lifecycle rules as [accountsProvider]: errors are not served from
/// cache once the last watcher leaves.
final billerCatalogProvider =
    AsyncNotifierProvider<BillerCatalogNotifier, List<Biller>>(
        BillerCatalogNotifier.new);

class BillerCatalogNotifier extends AsyncNotifier<List<Biller>> {
  @override
  Future<List<Biller>> build() async {
    ref.onCancel(() {
      if (state.hasError) ref.invalidateSelf();
    });
    final token = await ref.read(authServiceProvider).readToken();
    if (token == null || token.isEmpty) return Biller.fallbackCatalog;
    // Until the server `BILLER_CATALOG` is seeded (plan phase 1) the gateway
    // returns nothing (or the code is undefined) — fall back to the client
    // seed so the whole flow works from the UI now. Real server rows win.
    try {
      final data = await ref.read(apiClientProvider).getBillerCatalog(token);
      final billers = Biller.listFrom(data['billers']);
      return billers.isNotEmpty ? billers : Biller.fallbackCatalog;
    } catch (_) {
      return Biller.fallbackCatalog;
    }
  }
}

/// Bumped after every successful/pending payment so the hub's recent list and
/// the history screen re-fetch (mirrors [accountsRevisionProvider]).
final billPaymentsRevisionProvider = StateProvider<int>((ref) => 0);
