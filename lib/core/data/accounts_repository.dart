import 'package:banksync_app/core/auth/auth_service.dart';
import 'package:banksync_app/core/models/banking_account.dart';
import 'package:banksync_app/core/network/api_client.dart';
import 'package:banksync_app/core/profile_helpers.dart';

/// Logical (non-network) reasons account loading yields no usable list. Kept
/// separate from [ApiException] so callers can localize a friendly message
/// instead of surfacing a raw backend error.
enum AccountsErrorKind { customerIdMissing, noAccounts }

class AccountsException implements Exception {
  const AccountsException(this.kind);

  final AccountsErrorKind kind;
}

/// Single source of truth for fetching the signed-in customer's core accounts
/// via the `CUSTOMER_ACCOUNTS_SEARCH` integration.
///
/// Shared by the home carousel and the "All accounts" screen so the profile
/// lookup → customer-id resolution → integration call lives in exactly one
/// place. No business logic here — it only orchestrates existing endpoints.
class AccountsRepository {
  AccountsRepository({required AuthService auth, required ApiClient api})
      : _auth = auth,
        _api = api;

  final AuthService _auth;
  final ApiClient _api;

  /// Fetches and maps the customer's accounts. The [token] is passed in so the
  /// caller keeps control over session/redirect handling.
  ///
  /// Throws [AccountsException] for the two logical empty states and
  /// [ApiException] for backend/network failures.
  Future<List<BankingAccount>> fetchAccounts(String token) async {
    // The customer id never changes mid-session, so resolve it from the
    // locally stored profile first — `userDetail` is a full network
    // round-trip and used to run before EVERY accounts load.
    final usernameFallback = await _auth.readUsername();
    var profile = await _auth.readProfile();
    var coreCustomerId = profile == null
        ? ''
        : coreCustomerIdFromProfile(profile, usernameFallback: usernameFallback);
    if (coreCustomerId.isEmpty) {
      profile = await _api.userDetail(token);
      await _auth.saveProfile(profile);
      coreCustomerId =
          coreCustomerIdFromProfile(profile, usernameFallback: usernameFallback);
    }
    if (coreCustomerId.isEmpty) {
      throw const AccountsException(AccountsErrorKind.customerIdMissing);
    }

    final integration = await _api.invokeIntegration(
      token,
      'CUSTOMER_ACCOUNTS_SEARCH',
      {'customerId': coreCustomerId},
    );
    final accounts = BankingAccount.listFromCoreIntegration(integration);
    if (accounts.isEmpty) {
      throw const AccountsException(AccountsErrorKind.noAccounts);
    }
    return accounts;
  }
}
