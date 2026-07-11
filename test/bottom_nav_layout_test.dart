import 'package:banksync_app/core/widgets/banksync_bottom_nav.dart';
import 'package:banksync_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layout regression tests for the redesigned [BankSyncBottomNav] — an elegant
/// white bar with four tabs (2 + 2) around a raised, floating centre scan
/// action. They guard the risky bits of the new layout: no overflow, the centre
/// button genuinely floats above the tab row, and it stays horizontally centred
/// (it is only partially [Positioned], so it relies on the Stack's alignment).
void main() {
  Widget harness({
    required BankSyncTab tab,
    required ValueChanged<BankSyncTab> onTab,
    Locale locale = const Locale('ar'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: BankSyncBottomNav(
          currentTab: tab,
          onTabSelected: onTab,
        ),
      ),
    );
  }

  double logicalWidth(WidgetTester tester) =>
      tester.view.physicalSize.width / tester.view.devicePixelRatio;

  testWidgets('renders all four tabs + the centre action with no overflow',
      (tester) async {
    await tester.pumpWidget(harness(tab: BankSyncTab.home, onTab: (_) {}));
    await tester.pumpAndSettle();

    // A RenderFlex overflow (or any layout error) would surface here.
    expect(tester.takeException(), isNull);

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
  });

  testWidgets('centre action floats above the tab row and is centred',
      (tester) async {
    await tester.pumpWidget(harness(tab: BankSyncTab.home, onTab: (_) {}));
    await tester.pumpAndSettle();

    final fab = tester.getRect(find.byIcon(Icons.qr_code_scanner_rounded));
    final home = tester.getRect(find.byIcon(Icons.home_rounded));
    final settings = tester.getRect(find.byIcon(Icons.settings_rounded));

    // Raised: the scan glyph sits higher (smaller dy) than the side-tab glyphs.
    expect(fab.center.dy, lessThan(home.center.dy));
    expect(fab.center.dy, lessThan(settings.center.dy));

    // Only partially Positioned (top only) → the Stack must centre it.
    expect((fab.center.dx - logicalWidth(tester) / 2).abs(), lessThan(2.0));

    // It sits between the inner (transfers) and the payments tab horizontally.
    final transfers = tester.getRect(find.byIcon(Icons.swap_horiz_rounded));
    final payments =
        tester.getRect(find.byIcon(Icons.account_balance_wallet_rounded));
    final leftTab = transfers.center.dx < payments.center.dx ? transfers : payments;
    final rightTab = transfers.center.dx < payments.center.dx ? payments : transfers;
    expect(fab.center.dx, greaterThan(leftTab.center.dx));
    expect(fab.center.dx, lessThan(rightTab.center.dx));
  });

  testWidgets('tapping a side tab reports its tab', (tester) async {
    BankSyncTab? tapped;
    await tester.pumpWidget(
        harness(tab: BankSyncTab.home, onTab: (t) => tapped = t));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_balance_wallet_rounded));
    expect(tapped, BankSyncTab.payments);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    expect(tapped, BankSyncTab.explore);
  });

  testWidgets('lays out cleanly in LTR / English too', (tester) async {
    await tester.pumpWidget(harness(
      tab: BankSyncTab.transfers,
      onTab: (_) {},
      locale: const Locale('en'),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
  });
}
