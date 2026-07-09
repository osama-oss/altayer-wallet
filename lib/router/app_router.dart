import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:banksync_app/core/auth/auth_service.dart';
import 'package:banksync_app/core/providers/app_providers.dart';
import 'package:banksync_app/core/providers/router_refresh_notifier.dart';
import 'package:banksync_app/core/security/screen_security.dart';
import 'package:banksync_app/router/navigation_keys.dart';
import 'package:banksync_app/features/login/biometric_enroll_screen.dart';
import 'package:banksync_app/features/login/biometric_unlock_screen.dart';
import 'package:banksync_app/features/login/login_screen.dart';
import 'package:banksync_app/features/login/otp_verification_screen.dart';
import 'package:banksync_app/features/login/registration_screen.dart';
import 'package:banksync_app/features/login/account_activation_screen.dart';
import 'package:banksync_app/features/login/reset_password_screen.dart';
import 'package:banksync_app/features/login/set_initial_password_screen.dart';
import 'package:banksync_app/features/pin/pin_change_screen.dart';
import 'package:banksync_app/features/pin/pin_reset_screen.dart';
import 'package:banksync_app/features/pin/pin_setup_screen.dart';
import 'package:banksync_app/features/shell/main_shell.dart';
import 'package:banksync_app/features/support/guest_support_lookup_screen.dart';
import 'package:banksync_app/features/support/guest_support_screen.dart';
import 'package:banksync_app/features/support/support_list_screen.dart';
import 'package:banksync_app/features/support/support_thread_screen.dart';
import 'package:banksync_app/features/splash/splash_screen.dart';
import 'package:banksync_app/features/transfer/beneficiaries_list_screen.dart';
import 'package:banksync_app/features/transfer/add_beneficiary_screen.dart';
import 'package:banksync_app/features/transfer/edit_beneficiary_screen.dart';
import 'package:banksync_app/features/transfer/transfer_screen.dart';
import 'package:banksync_app/features/notifications/notifications_screen.dart';
import 'package:banksync_app/features/notifications/notification_settings_screen.dart';
import 'package:banksync_app/features/transfer/transfer_own_accounts_screen.dart';
import 'package:banksync_app/features/transfer/transfer_others_screen.dart';
import 'package:banksync_app/features/transfer/favorites_screen.dart';
import 'package:banksync_app/features/accounts/add_account_screen.dart';
import 'package:banksync_app/features/bill_payments/biller_list_screen.dart';
import 'package:banksync_app/features/bill_payments/telecom_payment_screen.dart';
import 'package:banksync_app/features/bill_payments/fixed_line_payment_screen.dart';
import 'package:banksync_app/features/bill_payments/package_bill_payment_screen.dart';
import 'package:banksync_app/features/bill_payments/starlink_payment_screen.dart';
import 'package:banksync_app/features/bill_payments/payment_history_screen.dart';
import 'package:banksync_app/features/bill_payments/un_money/un_money_hub_screen.dart';
import 'package:banksync_app/features/transfer_hub/network_transfers_screen.dart';
import 'package:banksync_app/features/cards/my_cards_screen.dart';
import 'package:banksync_app/features/legal/terms_screen.dart';
import 'package:banksync_app/features/kyc/kyc_screen.dart';
import 'package:banksync_app/features/profile/profile_screen.dart';

const _protectedRoutes = {
  '/home',
  '/pin-setup',
  '/pin-change',
  '/pin-reset',
  '/biometric-enroll',
  '/support',
  '/transfer',
  '/transfer/own',
  '/transfer/others',
  '/favorites',
  '/beneficiaries',
  '/beneficiaries/add',
  '/add-account',
  '/beneficiaries/edit',
  '/notifications',
  '/notification-settings',
  '/cards',
  '/bills/providers',
  '/bills/telecom',
  '/bills/landline',
  '/bills/internet',
  '/bills/yemen4g',
  '/bills/adennet',
  '/bills/starlink',
  '/bills/history',
  '/network-transfers',
  '/unmoney',
  '/kyc',
  '/profile',
};

const _guestOnlyRoutes = {
  '/',
  '/login',
  '/register',
};

/// Pre-auth onboarding (no JWT yet). Must not redirect to /home when session exists.
const _preAuthFlowRoutes = {
  '/set-initial-password',
  '/reset-password',
  '/register',
  '/register/verify',
  '/otp-verification',
};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);
  final auth = ref.read(authServiceProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final location = state.matchedLocation;

      final token = await auth.readToken();
      final hasSession = token != null && token.isNotEmpty;

      if (hasSession) {
        if (_preAuthFlowRoutes.contains(location)) {
          return await auth.postRestoreRoute() ?? '/home';
        }
        if (_guestOnlyRoutes.contains(location)) {
          return await auth.postRestoreRoute() ?? '/home';
        }
        return null;
      }

      if (_preAuthFlowRoutes.contains(location)) {
        return null;
      }

      if (await auth.canUnlockWithBiometric()) {
        if (await auth.prefersPasswordLogin() && location == '/login') {
          return null;
        }
        if (location == '/login') {
          return '/biometric-unlock';
        }
        if (_protectedRoutes.contains(location) || location.startsWith('/support/')) {
          // Remember where the user was so the unlock screen can send them
          // straight back instead of dumping them on /home.
          return '/biometric-unlock?from=${Uri.encodeComponent(state.uri.toString())}';
        }
        return null;
      }

      if (_protectedRoutes.contains(location) || location.startsWith('/support/')) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),
      GoRoute(path: '/register', builder: (_, __) => const RegistrationScreen()),
      GoRoute(
        path: '/register/verify',
        builder: (_, state) => AccountActivationScreen(
          mobile: state.uri.queryParameters['mobile'] ?? '',
        ),
      ),
      GoRoute(
        path: '/biometric-unlock',
        builder: (_, state) => BiometricUnlockScreen(
          returnTo: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(path: '/biometric-enroll', builder: (_, __) => const BiometricEnrollScreen()),
      GoRoute(
        path: '/set-initial-password',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>?;
          return SetInitialPasswordScreen(
            username: extra?['username'] ?? '',
            keycloakUsername: extra?['keycloakUsername'],
            currentPassword: extra?['currentPassword'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final mobile = state.uri.queryParameters['mobile'];
          return ResetPasswordScreen(initialMobile: mobile);
        },
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (_, state) {
          final mobile = state.uri.queryParameters['mobile'] ?? '';
          return OtpVerificationScreen(mobile: mobile);
        },
      ),
      GoRoute(path: '/pin-setup', builder: (_, __) => const PinSetupScreen()),
      GoRoute(path: '/pin-change', builder: (_, __) => const PinChangeScreen()),
      GoRoute(path: '/pin-reset', builder: (_, __) => const PinResetScreen()),
      GoRoute(path: '/home', builder: (_, __) => const MainShell()),
      GoRoute(path: '/support', builder: (_, __) => const SupportListScreen()),
      // Transfer flow (input → confirm → receipt) is intentionally NOT
      // screenshot-blocked: it shows no balances, and the success receipt is
      // meant to be captured/shared. Balances/cards screens stay protected.
      GoRoute(path: '/transfer', builder: (_, __) => const TransferScreen()),
      GoRoute(
        path: '/transfer/own',
        builder: (_, __) => const TransferOwnAccountsScreen(),
      ),
      GoRoute(
        path: '/transfer/others',
        builder: (_, state) => TransferOthersScreen(
          initialBeneficiary: state.uri.queryParameters['to'],
          initialAmount: state.uri.queryParameters['amount'],
        ),
      ),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: '/beneficiaries', builder: (_, __) => const BeneficiariesListScreen()),
      // Add-beneficiary is a form with no balances — keep it screenshot-able
      // even though the home tab stays mounted underneath (suspend protection).
      GoRoute(
        path: '/beneficiaries/add',
        builder: (_, __) => const UnsecureScreen(child: AddBeneficiaryScreen()),
      ),
      GoRoute(
        path: '/add-account',
        builder: (_, __) => const UnsecureScreen(child: AddAccountScreen()),
      ),
      // Cards show PANs (masked) and balances — keep them screenshot-blocked.
      GoRoute(
        path: '/cards',
        builder: (_, __) => const SecureScreen(child: MyCardsScreen()),
      ),
      GoRoute(
        path: '/beneficiaries/edit',
        builder: (_, state) {
          final beneficiary = state.extra as Map<String, dynamic>;
          return UnsecureScreen(
            child: EditBeneficiaryScreen(beneficiary: beneficiary),
          );
        },
      ),
      // Bill payments (Section 7). Like the transfer flow, the pay screens
      // show no balances until the account sheet — kept screenshot-able so
      // receipts can be captured/shared.
      GoRoute(
        path: '/bills/providers',
        builder: (_, state) => BillerListScreen(
          category: state.uri.queryParameters['cat'],
        ),
      ),
      GoRoute(
        path: '/bills/telecom',
        builder: (_, __) => const TelecomPaymentScreen(),
      ),
      GoRoute(
        path: '/bills/landline',
        builder: (_, __) => const FixedLinePaymentScreen(kind: FixedLineKind.landline),
      ),
      GoRoute(
        path: '/bills/internet',
        builder: (_, __) => const FixedLinePaymentScreen(kind: FixedLineKind.internet),
      ),
      GoRoute(
        path: '/bills/yemen4g',
        builder: (_, __) => const PackageBillPaymentScreen(kind: PackageBillerKind.yemen4g),
      ),
      GoRoute(
        path: '/bills/adennet',
        builder: (_, __) => const PackageBillPaymentScreen(kind: PackageBillerKind.adenNet),
      ),
      GoRoute(
        path: '/bills/starlink',
        builder: (_, __) => const StarlinkPaymentScreen(),
      ),
      GoRoute(
        path: '/bills/history',
        builder: (_, __) => const PaymentHistoryScreen(),
      ),
      GoRoute(path: '/unmoney', builder: (_, __) => const UnMoneyHubScreen()),
      GoRoute(
        path: '/network-transfers',
        builder: (_, __) => const NetworkTransfersScreen(),
      ),
      GoRoute(
        path: '/support/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return SupportThreadScreen(caseId: id);
        },
      ),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/kyc', builder: (_, __) => const KycScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/guest-support', builder: (_, __) => const GuestSupportScreen()),
      GoRoute(
        path: '/guest-support/lookup',
        builder: (_, state) => GuestSupportLookupScreen(
          initialCaseNumber: state.uri.queryParameters['caseNumber'],
          initialMobile: state.uri.queryParameters['mobile'],
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (_, __) => const NotificationSettingsScreen(),
      ),
    ],
  );
});

void notifyRouterAuthChanged(WidgetRef ref) {
  ref.read(routerRefreshProvider).notifyAuthChanged();
}

void navigateAfterLogin(BuildContext context, WidgetRef ref, LoginResult result) {
  // Fresh (possibly different) user → never serve another session's cache.
  ref.invalidate(accountsProvider);
  ref.invalidate(accountPreferencesProvider);
  switch (result.route) {
    case PostLoginRoute.setInitialPassword:
      context.go(
        '/set-initial-password',
        extra: {
          'username': result.username ?? '',
          if (result.keycloakUsername != null)
            'keycloakUsername': result.keycloakUsername!,
          'currentPassword': result.tempPassword ?? '',
        },
      );
    case PostLoginRoute.pinSetup:
      context.go('/pin-setup');
    case PostLoginRoute.biometricEnroll:
      context.go('/biometric-enroll');
    case PostLoginRoute.home:
      context.go('/home');
  }
  notifyRouterAuthChanged(ref);
}
