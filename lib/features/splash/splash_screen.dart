import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/widgets/animated_splash_logo.dart';

/// Premium splash screen for Ultimate Wallet.
///
/// The logo drops in from just above centre, scaling down from oversized
/// (feels close to the user) to its final large size (~62% of screen width),
/// settles with a soft bounce, then the app name fades in — followed by a
/// smooth fade transition (owned by the /login route) to the next screen.
/// No vertical line or extra decorative elements.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Let the ~2.2s entrance play out, then hold briefly before transitioning.
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 2600));
    String targetRoute = '/login';
    try {
      final result = await ref
          .read(authServiceProvider)
          .bootstrapRoute()
          .timeout(const Duration(seconds: 5), onTimeout: () => '/login');
      targetRoute = result ?? '/login';
    } catch (_) {
      targetRoute = '/login';
    }
    await minDelay;
    if (!mounted) return;
    context.go(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0D11) : Colors.white,
      body: const SafeArea(
        child: Center(
          child: AnimatedSplashLogo(),
        ),
      ),
    );
  }
}
