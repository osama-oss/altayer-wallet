import 'package:banksync_app/core/models/account_preferences.dart';
import 'package:banksync_app/core/models/banking_account.dart';
import 'package:banksync_app/core/providers/app_providers.dart';
import 'package:banksync_app/features/transfer/favorite_merchants_screen.dart';
import 'package:banksync_app/features/transfer/merchant_payment_screen.dart';
import 'package:banksync_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Render tests for the two new "purchases" interfaces:
///  • [MerchantPaymentScreen] — pay a merchant (reuses the transfer pipeline).
///  • [FavoriteMerchantsScreen] — the prepared favourite-merchants interface.
/// They confirm the screens build with the new localized strings and lay out
/// without overflow (the merchant form with a fake accounts source).
class _FakeAccounts extends AccountsNotifier {
  _FakeAccounts(this._list);
  final List<BankingAccount> _list;
  @override
  Future<List<BankingAccount>> build() async => _list;
}

class _FakePrefs extends AccountPreferencesNotifier {
  @override
  Future<AccountPreferencesData> build() async => const AccountPreferencesData();
}

BankingAccount _acc(int id, String ccy, double bal) => BankingAccount(
      id: id,
      accountNumber: 'ACC$id',
      label: 'A$id',
      currency: ccy,
      balance: bal,
    );

Widget _app(Widget home, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  testWidgets('MerchantPaymentScreen renders the payment form with no overflow',
      (tester) async {
    await tester.pumpWidget(_app(
      const MerchantPaymentScreen(),
      overrides: [
        accountsProvider.overrideWith(() => _FakeAccounts([
              _acc(1, 'YER', 1000),
              _acc(2, 'SAR', 500),
            ])),
        accountPreferencesProvider.overrideWith(() => _FakePrefs()),
      ],
    ));
    // Let initState's async account load complete and rebuild the form.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    // Title + the merchant field label + the primary CTA all present.
    expect(find.text('دفع لتاجر'), findsWidgets);
    expect(find.text('رقم التاجر أو المحفظة'), findsOneWidget);
    expect(find.text('متابعة الدفع'), findsOneWidget);
  });

  testWidgets('MerchantPaymentScreen shows the empty state without accounts',
      (tester) async {
    await tester.pumpWidget(_app(
      const MerchantPaymentScreen(),
      overrides: [
        accountsProvider.overrideWith(() => _FakeAccounts(const [])),
        accountPreferencesProvider.overrideWith(() => _FakePrefs()),
      ],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    // No CTA when there are no debit accounts to pay from.
    expect(find.text('متابعة الدفع'), findsNothing);
  });

  testWidgets('FavoriteMerchantsScreen renders the prepared empty state',
      (tester) async {
    await tester.pumpWidget(_app(const FavoriteMerchantsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('لا يوجد تجار مفضلون بعد'), findsOneWidget);
    // The direct "pay a merchant" action is offered.
    expect(find.text('دفع لتاجر'), findsWidgets);
  });
}
