import 'package:banksync_app/core/auth/auth_service.dart';
import 'package:banksync_app/core/models/banking_account.dart';
import 'package:banksync_app/core/network/api_client.dart';
import 'package:banksync_app/core/profile_helpers.dart';
import 'package:banksync_app/core/wallet_account_id.dart';

/// Logical (non-network) reasons account loading yields no usable list. Kept
/// separate from [ApiException] so callers can localize a friendly message
/// instead of surfacing a raw backend error.
enum AccountsErrorKind { customerIdMissing, noAccounts }

class AccountsException implements Exception {
  const AccountsException(this.kind);

  final AccountsErrorKind kind;
}

/// Single source of truth for fetching the signed-in customer's wallet accounts
/// via the `CUSTOMER_WALLET_ACCOUNTS_SEARCH` integration.
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
    // In the wallet, an account is identified by "<phone>_<currency>" — the
    // logged-in mobile plus the currency (e.g. 777777777_YER). The three cards
    // (YER/USD/SAR) are always built here so they render even before the
    // customer exists server-side; balances are merged in by currency below.
    final username = await _auth.readUsername();
    final phone = normalizeWalletPhone(username ?? '');
    if (phone.isEmpty) {
      throw const AccountsException(AccountsErrorKind.customerIdMissing);
    }

    // Best-effort core CIF for the search body. Prefer profile fields from
    // userDetail / KYC; never treat the login phone as a CIF. Refresh profile
    // when the cached value is missing so post-login sessions pick up
    // customerCode after KYC link.
    var profile = await _auth.readProfile();
    var customerId = profile == null
        ? ''
        : coreCustomerIdFromProfile(profile, usernameFallback: username);
    if (customerId.isEmpty) {
      try {
        profile = await _api.userDetail(token);
        await _auth.saveProfile(profile);
        customerId =
            coreCustomerIdFromProfile(profile, usernameFallback: username);
      } catch (_) {
        // Leave empty — cards still render with zero balances.
      }
    }

    // Balances come from the wallet core keyed by currency. Any failure is
    // non-fatal: the three cards still render (zero balances) so the wallet is
    // usable pre-verification and a refresh retries.
    final balanceByCurrency = <String, double>{};
    if (customerId.isNotEmpty) {
      try {
        final integration = await _api.invokeIntegration(
          token,
          'CUSTOMER_WALLET_ACCOUNTS_SEARCH',
          {'customerId': customerId},
        );
        for (final acc in BankingAccount.listFromCoreIntegration(integration)) {
          balanceByCurrency[acc.currency.trim().toUpperCase()] = acc.balance;
        }
      } catch (_) {
        // non-fatal — render the three cards with zero balances
      }
    }

    return [
      for (final ccy in walletCurrencies)
        BankingAccount(
          id: walletAccountId(phone, ccy).hashCode,
          accountNumber: walletAccountId(phone, ccy),
          label: ccy,
          currency: ccy,
          balance: balanceByCurrency[ccy] ?? 0,
        ),
    ];
  }
}
