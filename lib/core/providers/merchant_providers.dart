import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:banksync_app/core/auth/merchant_auth_service.dart';
import 'package:banksync_app/core/network/merchant_api_client.dart';

final merchantApiClientProvider = Provider<MerchantApiClient>((ref) {
  return MerchantApiClient();
});

final merchantAuthServiceProvider = Provider<MerchantAuthService>((ref) {
  return MerchantAuthService(api: ref.watch(merchantApiClientProvider));
});

final merchantProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(merchantAuthServiceProvider);
  final token = await auth.readToken();
  if (token == null || token.isEmpty) return const {};
  return auth.readProfile();
});

final merchantCatalogProvider = FutureProvider<List<dynamic>>((ref) async {
  final auth = ref.watch(merchantAuthServiceProvider);
  final api = ref.watch(merchantApiClientProvider);
  final token = await auth.readToken();
  if (token == null || token.isEmpty) return const [];
  final data = await api.catalogServices(token);
  if (data.isNotEmpty) return data;
  return const [];
});

final merchantTransactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final auth = ref.watch(merchantAuthServiceProvider);
  final api = ref.watch(merchantApiClientProvider);
  final token = await auth.readToken();
  if (token == null || token.isEmpty) return const [];
  return api.transactions(token);
});
