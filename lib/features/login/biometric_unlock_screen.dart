import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/biometric_challenge_result.dart';
import '../../core/auth/device_signing_service.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/banking_auth_exceptions.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import '../../core/widgets/uff_loader.dart';

class BiometricUnlockScreen extends ConsumerStatefulWidget {
  const BiometricUnlockScreen({super.key, this.returnTo});

  /// In-app location the user was on when the session ended. After a
  /// successful unlock they are sent back here instead of /home, so an idle
  /// timeout never loses their place.
  final String? returnTo;

  @override
  ConsumerState<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends ConsumerState<BiometricUnlockScreen> {
  bool _loading = false;
  bool _challengeLoading = true;
  String? _error;
  BiometricChallengeResult? _challenge;
  String? _greetingName;

  @override
  void initState() {
    super.initState();
    _loadGreetingName();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _showSessionExpiredNotice();
      await _loadChallenge();
      if (mounted && _challenge != null && !_challengeLoading) {
        await _unlock();
      }
    });
  }

  /// Soft sign-out keeps the profile exactly so this screen can greet the
  /// user and make clear whose account is being unlocked.
  Future<void> _loadGreetingName() async {
    final profile = await ref.read(authServiceProvider).readProfile();
    final name = profile?['fullName']?.toString().trim();
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _greetingName = name);
    }
  }

  /// Tells the user *why* they landed back here when the session ended
  /// (idle timeout / refresh rejected). One-shot: the flag resets on read.
  void _showSessionExpiredNotice() {
    if (!mounted || !ref.read(sessionExpiredNoticeProvider)) return;
    ref.read(sessionExpiredNoticeProvider.notifier).state = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.sessionExpiredMessage)),
    );
  }

  Future<void> _loadChallenge() async {
    setState(() {
      _challengeLoading = true;
      _error = null;
    });
    try {
      final challenge = await ref.read(authServiceProvider).requestBiometricChallenge();
      if (mounted) {
        setState(() {
          _challenge = challenge;
          _challengeLoading = false;
        });
      }
    } on BiometricLockedException catch (e) {
      await _goPasswordLoginAfterError(e.message);
    } on BiometricNotEnrolledException catch (e) {
      await _goPasswordLoginAfterError(e.message);
    } catch (e) {
      if (mounted) {
        setState(() {
          _challengeLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _usePasswordInstead() async {
    await ref.read(authServiceProvider).switchToPasswordLogin();
    if (!mounted) return;
    notifyRouterAuthChanged(ref);
    context.go('/login');
  }

  Future<void> _goPasswordLoginAfterError([String? message]) async {
    await ref.read(authServiceProvider).signOut(full: true);
    if (!mounted) return;
    invalidateUserSessionCache(ref);
    notifyRouterAuthChanged(ref);
    context.go('/login');
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _unlock() async {
    final challenge = _challenge;
    if (challenge == null || _challengeLoading) return;

    final l10n = context.l10n;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(authServiceProvider).completeBiometricLogin(challenge);
      if (!mounted) return;
      final returnTo = widget.returnTo;
      // Only plain in-app locations are honoured (defence against anything
      // that isn't a local route). PIN-setup etc. still take precedence.
      if (result.route == PostLoginRoute.home &&
          returnTo != null &&
          returnTo.startsWith('/') &&
          !returnTo.startsWith('//')) {
        context.go(returnTo);
        notifyRouterAuthChanged(ref);
      } else {
        navigateAfterLogin(context, ref, result);
      }
    } on DeviceSigningException {
      setState(() => _error = l10n.biometricVerificationFailed);
    } on BiometricLockedException catch (e) {
      await _goPasswordLoginAfterError(e.message);
    } on DeviceAlreadyBoundException catch (e) {
      setState(() => _error = e.message);
    } on DeviceNotRegisteredException catch (e) {
      await _goPasswordLoginAfterError(e.message);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _challengeLoading;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Premium Deep Blue Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3A1D9E), Color(0xFF5B2EE5)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/branding/ultimate_wallet_light.svg',
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  // Locale-neutral: name on its own line, no comma needed.
                  _greetingName == null
                      ? l10n.biometricSignIn // الدخول بالبصمة
                      : '${l10n.welcomeBack}\n$_greetingName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.biometricSignInSubtitle, // استخدم بصمة الإصبع أو الوجه...
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontFamily: 'Tajawal',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  const Spacer(),

                  // Biometric Icon Circle with dynamic states (failed vs verifying)
                  if (busy)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEFF6FF), // soft blue background
                          ),
                        ),
                        const SizedBox(
                          width: 130,
                          height: 130,
                          child: UffLoader(size: 130),
                        ),
                        const Icon(
                          Icons.fingerprint_rounded,
                          size: 64,
                          color: Color(0xFF5B2EE5),
                        ),
                      ],
                    )
                  else
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _error != null ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF), // light red if error, otherwise light blue
                          ),
                        ),
                        Icon(
                          Icons.fingerprint_rounded,
                          size: 64,
                          color: _error != null ? const Color(0xFFEF4444) : const Color(0xFF5B2EE5),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Header title "Confirm Identity"
                  Text(
                    l10n.confirmYourIdentity, // تأكيد هويتك
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14152E),
                      fontFamily: 'Tajawal',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Subtitle message (verifying vs request verification)
                  Text(
                    busy
                        ? l10n.verifyingStatus
                        : l10n.biometricPromptMessage, // سيطلب جهازك التحقق البيومتري.
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Failed warning message inside red capsule box
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            l10n.biometricFailed,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: busy ? null : _unlock,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5B2EE5),
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.unlock, // فتح
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: busy ? Colors.grey[400] : Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Use password instead footer link
                  TextButton(
                    onPressed: busy ? null : _usePasswordInstead,
                    child: Text(
                      l10n.usePasswordInstead, // استخدم كلمة المرور بدلاً من ذلك
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: busy ? Colors.grey[400] : const Color(0xFF5B2EE5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
