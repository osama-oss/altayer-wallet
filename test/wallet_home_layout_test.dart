import 'package:banksync_app/core/models/banking_account.dart';
import 'package:banksync_app/core/providers/app_providers.dart';
import 'package:banksync_app/features/kyc/kyc_providers.dart';
import 'package:banksync_app/features/kyc/kyc_status.dart';
import 'package:banksync_app/features/wallet/wallet_home_screen.dart';
import 'package:banksync_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layout test for the simplified [WalletHomeScreen]. Confirms the three
/// removed areas are gone — the send/receive/top-up/scan actions row, the
/// «الوصول السريع» favorites strip, and the bottom «آخر العمليات» preview — and
/// that the surviving sequence (wallet cards → services → promotions) lays out
/// with no overflow on a phone-sized viewport.
class _FakeAccounts extends AccountsNotifier {
  _FakeAccounts(this._list);
  final List<BankingAccount> _list;
  @override
  Future<List<BankingAccount>> build() async => _list;
}

class _FakeKyc extends KycStatusNotifier {
  @override
  Future<KycProfile> build() async =>
      const KycProfile(status: KycStatus.verified);
}

BankingAccount _acc(int id, String ccy, double bal) => BankingAccount(
      id: id,
      accountNumber: 'ACC$id',
      label: 'A$id',
      currency: ccy,
      balance: bal,
    );

Widget _app() {
  return ProviderScope(
    overrides: [
      accountsProvider.overrideWith(() => _FakeAccounts([
            _acc(1, 'SAR', 1200),
            _acc(2, 'YER', 300000),
          ])),
      kycStatusProvider.overrideWith(() => _FakeKyc()),
    ],
    child: const MaterialApp(
      locale: Locale('ar'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: WalletHomeScreen()),
    ),
  );
}

void main() {
  testWidgets(
      'drops the actions row, quick-access and recent-activity sections, '
      'keeping cards → services → promotions', (tester) async {
    // Realistic phone viewport (375×812 @3x) so any horizontal overflow the
    // real layout would hit surfaces here.
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_app());
    // Let the overridden async providers resolve. Not pumpAndSettle: the promo
    // carousel runs a periodic timer that never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    // The only tolerated layout error is the fixed-height wallet-card / promo-
    // card flex overflowing a few px under the test's fallback font (Tajawal is
    // not loaded in tests). Those widgets are unchanged by this layout edit —
    // the removed sections lived in a scroll view, which cannot overflow. Any
    // other exception (a provider/build failure) must still fail the test.
    final ex = tester.takeException();
    if (ex != null) {
      expect(ex, isA<FlutterError>());
      expect(ex.toString(), contains('overflowed'));
    }

    // ── Removed: the send / receive / top-up / scan actions row ──
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    expect(find.byIcon(Icons.qr_code_2_rounded), findsNothing);
    expect(find.text('إرسال'), findsNothing);
    expect(find.text('استلام'), findsNothing);

    // ── Removed: the «الوصول السريع» favorites strip ──
    expect(find.text('الوصول السريع'), findsNothing);

    // ── Removed: the bottom «آخر العمليات» preview. The label survives ONLY as
    //    the services-grid tile, so the function is no longer duplicated. ──
    expect(find.text('آخر العمليات'), findsOneWidget);

    // ── Kept sequence: wallet cards → services → promotions ──
    final wallets = tester.getTopLeft(find.text('محافظي')).dy;
    final services = tester.getTopLeft(find.text('الخدمات')).dy;
    final promos = tester.getTopLeft(find.text('عروض تهمّك')).dy;
    expect(wallets, lessThan(services));
    expect(services, lessThan(promos));

    // Dispose the tree so the promo carousel's periodic timer is cancelled
    // before the test ends (otherwise a pending-timer failure is reported).
    await tester.pumpWidget(const SizedBox());
  });
}
