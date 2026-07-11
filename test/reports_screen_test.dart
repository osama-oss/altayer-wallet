import 'package:banksync_app/features/reports/data/report_models.dart';
import 'package:banksync_app/features/reports/reports_providers.dart';
import 'package:banksync_app/features/reports/reports_screen.dart';
import 'package:banksync_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget coverage for the Reports tab: it renders the direction tabs + mock
/// ledger, the tabs filter the list, the filter action opens the sheet, and an
/// empty ledger shows the "no items" state.
void main() {
  Widget harness({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ReportsScreen()),
      ),
    );
  }

  testWidgets('renders the four direction tabs and the mock ledger',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('المرسلة'), findsOneWidget);
    expect(find.text('المستلمة'), findsOneWidget);
    expect(find.text('الرسوم'), findsOneWidget);

    // A couple of mock entries are on screen.
    expect(find.text('Ultimate Store'), findsOneWidget);
  });

  testWidgets('tapping a direction tab filters the ledger', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Switch to the Fees tab → sent/received rows drop out.
    await tester.tap(find.text('الرسوم'));
    await tester.pumpAndSettle();

    expect(find.text('Ultimate Store'), findsNothing); // a sent payment
    expect(find.text('Transfer fee'), findsOneWidget); // a fee row
  });

  testWidgets('the filter action opens the filter sheet', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    // Sheet header + confirm button + currency chip are present.
    expect(find.text('تصفية التقارير'), findsOneWidget);
    expect(find.text('تأكيد'), findsOneWidget);
    expect(find.text('الريال السعودي'), findsOneWidget);
  });

  testWidgets('shows the empty state when the ledger is empty',
      (tester) async {
    await tester.pumpWidget(harness(
      overrides: [
        reportEntriesProvider.overrideWithValue(const <ReportEntry>[]),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد عناصر'), findsOneWidget);
  });
}
