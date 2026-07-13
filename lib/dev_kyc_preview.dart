// TEMPORARY dev-only entry point used to visually verify the KYC account-
// verification data form (and its newly added identity/compliance fields)
// without needing a live backend/login. Not wired into the real app entry
// point — safe to delete after verification.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/kyc/kyc_document.dart';
import 'features/kyc/kyc_form_data.dart';
import 'features/kyc/kyc_providers.dart';
import 'features/kyc/widgets/kyc_data_form_view.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // The read-only "your details" card reads this; feed it a fixed name so
        // the card renders without touching secure storage.
        registrationIdentityProvider.overrideWith(
          (ref) async => <String, dynamic>{'fullName': 'محمد أحمد الشريف'},
        ),
      ],
      child: const _PreviewApp(),
    ),
  );
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    const locale = Locale('ar');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightFor(locale),
      home: const _KycPreviewHost(),
    );
  }
}

class _KycPreviewHost extends StatelessWidget {
  const _KycPreviewHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الحساب — KYC')),
      body: KycDataFormView(
        initialIdType: KycIdType.nationalId,
        initialData: const KycFormData(),
        onContinue: (idType, data) {
          // Dump the collected wire payload so we can eyeball the new fields.
          debugPrint('KYC continue → idType=${idType.wireCode}');
          debugPrint('KYC profile → ${data.toWire()}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم — ${data.toWire()}')),
          );
        },
      ),
    );
  }
}
