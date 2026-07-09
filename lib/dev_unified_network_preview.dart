// TEMPORARY dev-only entry point used to visually verify the Unified Network
// screens without needing a live backend/login. Not wired into the real app
// entry point — safe to delete after verification.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/models/banking_account.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/bill_payments/un_money/un_money_hub_screen.dart';
import 'l10n/app_localizations.dart';

class _FakeAccountsNotifier extends AccountsNotifier {
  @override
  Future<List<BankingAccount>> build() async {
    return const [
      BankingAccount(
        id: 1,
        accountNumber: 'YER-3068400111',
        label: 'جاري',
        currency: 'YER',
        balance: 125430.50,
      ),
      BankingAccount(
        id: 2,
        accountNumber: 'USD-2041200222',
        label: 'توفير',
        currency: 'USD',
        balance: 980.00,
      ),
    ];
  }
}

void main() {
  runApp(
    ProviderScope(
      overrides: [accountsProvider.overrideWith(() => _FakeAccountsNotifier())],
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
      home: const UnMoneyHubScreen(),
    );
  }
}
