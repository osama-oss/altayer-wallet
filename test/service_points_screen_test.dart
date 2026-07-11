import 'package:banksync_app/features/wallet/service_points_screen.dart';
import 'package:banksync_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Render test for [ServicePointsScreen] — the 9th home service («الوكلاء
/// ونقاط الخدمة»). Confirms the page builds with its localized title and the
/// honest "coming soon" state (no mock data, no backend).
Widget _app(Widget home) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  testWidgets('ServicePointsScreen renders the coming-soon state',
      (tester) async {
    await tester.pumpWidget(_app(const ServicePointsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Title appears in the AppBar and again as the body headline.
    expect(find.text('الوكلاء ونقاط الخدمة'), findsWidgets);
    // "قريباً" badge marks the honest not-yet-live status.
    expect(find.text('قريباً'), findsOneWidget);
    // The descriptive line explaining what the service will do.
    expect(find.text('اعثر على أقرب وكيل أو نقطة خدمة على الخريطة.'),
        findsOneWidget);
  });
}
