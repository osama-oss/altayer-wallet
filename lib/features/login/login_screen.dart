import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/banking_auth_exceptions.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/db_error_banner.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import '../../core/widgets/uff_loader.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _biometricLoading = false;
  bool _canBiometric = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadBiometricOption();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpiredNotice());
  }

  Future<void> _loadBiometricOption() async {
    final can = await ref.read(authServiceProvider).canUnlockWithBiometric();
    if (mounted) setState(() => _canBiometric = can);
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(authServiceProvider).loginWithPassword(
            _username.text,
            _password.text,
          );
      if (!mounted) return;
      navigateAfterLogin(context, ref, result);
      notifyRouterAuthChanged(ref);
    } on KeycloakAuthException catch (e) {
      setState(() => _error = e.message);
    } on DeviceAlreadyBoundException catch (e) {
      setState(() => _error = e.message);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showBiometricSetupDialog() {
    final l10n = context.l10n;
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          l10n.enableFingerprintTitle,
          style: const TextStyle(fontFamily: 'SFProArabic', fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.enableFingerprintMessage,
          style: const TextStyle(fontFamily: 'SFProArabic'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.okButton,
              style: const TextStyle(fontFamily: 'SFProArabic'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _biometricLogin() async {
    if (!_canBiometric) {
      _showBiometricSetupDialog();
      return;
    }
    setState(() {
      _biometricLoading = true;
      _error = null;
    });
    try {
      if (!mounted) return;
      context.go('/biometric-unlock');
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  Widget _buildLanguageDropdown(BuildContext context, Locale locale, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: locale,
          isDense: true,
          dropdownColor: const Color(0xFF3A1D9E),
          borderRadius: BorderRadius.circular(16),
          icon: const Padding(
            padding: EdgeInsets.only(left: 4, right: 4),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'SFProArabic',
          ),
          selectedItemBuilder: (BuildContext context) {
            return [
              const Locale('en'),
              const Locale('ar'),
              const Locale('zh'),
            ].map((Locale value) {
              final label = value.languageCode == 'zh'
                  ? '中文'
                  : value.languageCode == 'ar'
                      ? 'العربية'
                      : 'English';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'SFProArabic',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: [
            DropdownMenuItem(
              value: const Locale('en'),
              child: Text(
                l10n.languageEnglish,
                style: const TextStyle(fontFamily: 'SFProArabic', color: Colors.white, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: const Locale('ar'),
              child: Text(
                l10n.languageArabic,
                style: const TextStyle(fontFamily: 'SFProArabic', color: Colors.white, fontSize: 13),
              ),
            ),
            DropdownMenuItem(
              value: const Locale('zh'),
              child: Text(
                l10n.languageChinese,
                style: const TextStyle(fontFamily: 'SFProArabic', color: Colors.white, fontSize: 13),
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(localeProvider.notifier).setLocale(value);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;
    final afterPasswordReset =
        GoRouterState.of(context).uri.queryParameters['afterPasswordReset'] == '1';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F8), // Premium light grey background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Blue Gradient Header
            Container(
              width: double.infinity,
              height: 290,
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
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top row: UBS and Language dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.asset(
                            'assets/branding/ubs.svg',
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          _buildLanguageDropdown(context, locale, l10n),
                        ],
                      ),
                      const Spacer(),
                      // Welcome title
                      Text(
                        l10n.welcomeBack, // مرحباً بعودتك
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'SFProArabic',
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Subtitle
                      Text(
                        l10n.signInWithUsernamePassword, // سجّل الدخول للمتابعة
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SFProArabic',
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),

            // Form container overlapping slightly
            Transform.translate(
              offset: const Offset(0, -32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username TextFormField
                        TextFormField(
                          controller: _username,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontFamily: 'SFProArabic', fontSize: 15, fontWeight: FontWeight.w600),
                          decoration: uffInputDecoration(
                            context,
                            label: l10n.username,
                            placeholder: l10n.usernameHint,
                            prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.grey[500], size: 20),
                            suffixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF5B2EE5), size: 20),
                            fillColor: const Color(0xFFF4F5F8),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? l10n.enterUsername : null,
                        ),
                        const SizedBox(height: 20),

                        // Password TextFormField
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          style: const TextStyle(fontFamily: 'SFProArabic', fontSize: 15, fontWeight: FontWeight.w600),
                          decoration: uffInputDecoration(
                            context,
                            label: l10n.password,
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey[500], size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey[500],
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            fillColor: const Color(0xFFF4F5F8),
                          ),
                          onFieldSubmitted: (_) => _login(),
                          validator: (v) =>
                              v == null || v.isEmpty ? l10n.enterPassword : null,
                        ),
                        if (afterPasswordReset) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.signInAfterPasswordResetBanner,
                              style: AppTextStyles.bodyMd(
                                color: colors.onSurfaceVariant,
                                languageCode: languageCode,
                              ),
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          DbErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 24),

                        // Biometrics & Login Row
                        Row(
                          children: [
                            // Biometrics Square Button
                            InkWell(
                              onTap: _biometricLoading ? null : _biometricLogin,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF5B2EE5).withValues(alpha: 0.3), width: 1.5),
                                ),
                                child: const Center(
                                  child: Icon(Icons.fingerprint_rounded, color: Color(0xFF5B2EE5), size: 28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Login button
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: FilledButton(
                                  onPressed: _loading ? null : _login,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF5B2EE5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: UffLoader(size: 20, color: Colors.white),
                                        )
                                      : Text(
                                          l10n.signIn,
                                          style: const TextStyle(
                                            fontFamily: 'SFProArabic',
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Forgot password
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () => context.push('/reset-password'),
                            icon: const Icon(Icons.lock_reset_outlined, size: 18, color: const Color(0xFF5B2EE5)),
                            label: Text(
                              l10n.forgotPassword,
                              style: const TextStyle(
                                fontFamily: 'SFProArabic',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5B2EE5),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer
            Transform.translate(
              offset: const Offset(0, -12),
              child: Column(
                children: [
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: Text(
                      l10n.newCustomerRegister,
                      style: TextStyle(
                        fontFamily: 'SFProArabic',
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => context.push('/guest-support'),
                    child: Text(
                      l10n.needHelp,
                      style: TextStyle(
                        fontFamily: 'SFProArabic',
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
