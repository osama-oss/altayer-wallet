import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/notifications/notification_handler.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/security/security_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/bank_sync_colors.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';

class BankSyncApp extends ConsumerStatefulWidget {
  const BankSyncApp({super.key});

  @override
  ConsumerState<BankSyncApp> createState() => _BankSyncAppState();
}

class _BankSyncAppState extends ConsumerState<BankSyncApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationHandler.initialize(
        onNavigate: (path) {
          if (!mounted) return;
          ref.read(routerProvider).push(path);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Activates the interceptor that refreshes/validates the token on every
    // API call — session expiry is otherwise decided entirely by Keycloak —
    // and the lifecycle watcher that enforces the user's idle timeout when
    // the app returns from background.
    ref.watch(sessionRefreshInterceptorProvider);
    ref.watch(sessionIdleWatcherProvider);

    return MaterialApp.router(
      title: 'عَ الطاير',
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
      darkTheme: AppTheme.darkFor(locale),
      themeMode: themeMode,
      builder: (context, child) {
        final palette = context.bankColors;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: palette.background,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: palette.surfaceContainer,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
        );
        // Swaps the whole UI for the security block screen when the threat
        // policy escalates to `block` (enforce mode, high-confidence tamper).
        return SecurityGate(child: child ?? const SizedBox.shrink());
      },
      routerConfig: router,
    );
  }
}
