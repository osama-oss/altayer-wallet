import 'package:banksync_app/features/kyc/kyc_document.dart';
import 'package:banksync_app/features/kyc/kyc_form_data.dart';
import 'package:banksync_app/features/kyc/widgets/kyc_data_form_view.dart';
import 'package:banksync_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for the KYC account-confirmation data form (step 1 of the
/// verification flow). The screen is auth-gated in the running app, so these
/// exercise the two pieces of new logic directly: the validation gate that must
/// block "Continue" until the required fields are filled, and the identity-type
/// toggle that swaps the document-number label.
void main() {
  Widget harness({required void Function(KycIdType, KycFormData) onContinue}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: KycDataFormView(
          initialIdType: KycIdType.nationalId,
          initialData: const KycFormData(),
          onContinue: onContinue,
        ),
      ),
    );
  }

  testWidgets('empty form blocks Continue and surfaces required errors',
      (tester) async {
    KycIdType? gotType;
    KycFormData? gotData;
    await tester.pumpWidget(harness(onContinue: (t, d) {
      gotType = t;
      gotData = d;
    }));
    await tester.pumpAndSettle();

    // Both sections rendered.
    expect(find.text('Identity details'), findsOneWidget);
    expect(find.text('Residence details'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Validation blocked the advance …
    expect(gotType, isNull);
    expect(gotData, isNull);
    // … and the required-but-empty fields (text + date) show their message.
    expect(find.text('Required'), findsWidgets);
  });

  testWidgets('selecting Passport swaps the document-number label',
      (tester) async {
    await tester.pumpWidget(harness(onContinue: (_, __) {}));
    await tester.pumpAndSettle();

    expect(find.text('ID card number'), findsOneWidget);
    expect(find.text('Passport number'), findsNothing);

    await tester.tap(find.text('Passport'));
    await tester.pumpAndSettle();

    expect(find.text('Passport number'), findsOneWidget);
    expect(find.text('ID card number'), findsNothing);
  });
}
