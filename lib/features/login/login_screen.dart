import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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

/// Brand palette — kept as UFF purple (the Jaib reference is red; we adopt its
/// *layout*, not its colour). Deep + bright indigo used across the app.
const Color _brandDeep = Color(0xFF3A1D9E);
const Color _brandBright = Color(0xFF5B2EE5);
const Color _screenBg = Color(0xFFF4F5F8);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _biometricLoading = false;
  bool _canBiometric = false;
  // false → Customer tab (real auth), true → Point-of-sale tab (visual only,
  // no merchant backend exists yet).
  bool _merchant = false;
  String? _error;

  @override
  void dispose() {
    _mobile.dispose();
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

  void _selectRole(bool merchant) {
    if (_merchant == merchant) return;
    setState(() {
      _merchant = merchant;
      _error = null;
    });
  }

  Future<void> _login() async {
    // Point-of-sale login has no backend yet — surface a friendly notice.
    if (_merchant) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.merchantLoginComingSoon)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(authServiceProvider).loginWithPassword(
            _mobile.text,
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

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — ${context.l10n.merchantLoginComingSoon}')),
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
      backgroundColor: _screenBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar: compact language switcher on the trailing edge.
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _buildLanguagePill(context, locale, l10n),
              ),
              const SizedBox(height: 8),

              // Brand logo, centred.
              SvgPicture.asset(
                'assets/branding/ubs.svg',
                height: 46,
                colorFilter: const ColorFilter.mode(_brandDeep, BlendMode.srcIn),
              ),
              const SizedBox(height: 32),

              // Welcome title + subtitle (start-aligned → right in RTL).
              Text(
                l10n.welcomeBack,
                style: const TextStyle(
                  color: Color(0xFF1A1230),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'SFProArabic',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.signInWithUsernamePassword,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SFProArabic',
                ),
              ),
              const SizedBox(height: 24),

              // Role toggle: Customer / Point of sale.
              _buildRoleToggle(l10n),
              const SizedBox(height: 22),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mobile number.
                    TextFormField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      enabled: !_merchant,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                      ],
                      style: const TextStyle(
                        fontFamily: 'SFProArabic',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: uffInputDecoration(
                        context,
                        label: l10n.mobileNumber,
                        placeholder: l10n.mobileNumberHint,
                        prefixIcon: Icon(Icons.phone_iphone_rounded,
                            color: Colors.grey[500], size: 20),
                        fillColor: Colors.white,
                      ),
                      validator: (v) => _merchant
                          ? null
                          : (v == null || v.trim().isEmpty ? l10n.enterMobileNumber : null),
                    ),
                    const SizedBox(height: 16),

                    // Password with an inline fingerprint (→ biometric) and an
                    // eye toggle, mirroring the reference field.
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      enabled: !_merchant,
                      style: const TextStyle(
                        fontFamily: 'SFProArabic',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: uffInputDecoration(
                        context,
                        label: l10n.password,
                        prefixIcon: IconButton(
                          icon: _biometricLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: UffLoader(size: 18, color: _brandBright),
                                )
                              : const Icon(Icons.fingerprint_rounded,
                                  color: _brandBright, size: 24),
                          onPressed:
                              (_biometricLoading || _merchant) ? null : _biometricLogin,
                          tooltip: l10n.signInWithBiometrics,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        fillColor: Colors.white,
                      ),
                      onFieldSubmitted: (_) => _login(),
                      validator: (v) => _merchant
                          ? null
                          : (v == null || v.isEmpty ? l10n.enterPassword : null),
                    ),

                    // Forgot password (start-aligned).
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed:
                            _merchant ? null : () => context.push('/reset-password'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.forgotPassword,
                          style: const TextStyle(
                            fontFamily: 'SFProArabic',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _brandBright,
                          ),
                        ),
                      ),
                    ),

                    if (_merchant) ...[
                      const SizedBox(height: 4),
                      _buildComingSoonBanner(l10n),
                    ],
                    if (afterPasswordReset && !_merchant) ...[
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      DbErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 20),

                    // Primary sign-in button (label follows the selected role).
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _loading ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: _brandBright,
                          disabledBackgroundColor: _brandBright.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const UffLoader(size: 22, color: Colors.white)
                            : Text(
                                _merchant
                                    ? l10n.loginTabMerchant
                                    : l10n.signInAsCustomer,
                                style: const TextStyle(
                                  fontFamily: 'SFProArabic',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Create account link.
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: _buildCreateAccount(l10n),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              // Support shortcuts.
              _buildSupportRow(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleToggle(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEBF1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _roleTab(
            label: l10n.loginTabCustomer,
            icon: Icons.person_rounded,
            selected: !_merchant,
            onTap: () => _selectRole(false),
          ),
          _roleTab(
            label: l10n.loginTabMerchant,
            icon: Icons.point_of_sale_rounded,
            selected: _merchant,
            onTap: () => _selectRole(true),
          ),
        ],
      ),
    );
  }

  Widget _roleTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18, color: selected ? _brandBright : Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SFProArabic',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? _brandDeep : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _brandBright.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brandBright.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: _brandBright),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.merchantLoginComingSoon,
              style: const TextStyle(
                fontFamily: 'SFProArabic',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _brandDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccount(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => context.push('/register'),
      behavior: HitTestBehavior.opaque,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'SFProArabic', fontSize: 12.5),
          children: [
            TextSpan(
              text: '${l10n.dontHaveAccount} ',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: l10n.createAccount,
              style: const TextStyle(color: _brandBright, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportRow(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _supportButton(
          icon: Icons.call_rounded,
          label: l10n.supportTollFree,
          onTap: () => _comingSoon(l10n.supportTollFree),
        ),
        _supportButton(
          icon: Icons.location_on_rounded,
          label: l10n.supportServicePoints,
          onTap: () => _comingSoon(l10n.supportServicePoints),
        ),
        _supportButton(
          icon: Icons.headset_mic_rounded,
          label: l10n.supportCustomerService,
          onTap: () => context.push('/guest-support'),
        ),
      ],
    );
  }

  Widget _supportButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: _brandBright, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SFProArabic',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact language switcher tuned for the light background (dark-on-light,
  /// unlike the old white-on-gradient pill).
  Widget _buildLanguagePill(BuildContext context, Locale locale, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E3EA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: locale,
          isDense: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _brandBright, size: 18),
          style: const TextStyle(
            color: _brandDeep,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'SFProArabic',
          ),
          selectedItemBuilder: (context) {
            return const [Locale('en'), Locale('ar'), Locale('zh')].map((value) {
              final label = value.languageCode == 'zh'
                  ? '中文'
                  : value.languageCode == 'ar'
                      ? 'العربية'
                      : 'English';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate_rounded, color: _brandBright, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: _brandDeep,
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
              child: Text(l10n.languageEnglish,
                  style: const TextStyle(fontFamily: 'SFProArabic', fontSize: 13)),
            ),
            DropdownMenuItem(
              value: const Locale('ar'),
              child: Text(l10n.languageArabic,
                  style: const TextStyle(fontFamily: 'SFProArabic', fontSize: 13)),
            ),
            DropdownMenuItem(
              value: const Locale('zh'),
              child: Text(l10n.languageChinese,
                  style: const TextStyle(fontFamily: 'SFProArabic', fontSize: 13)),
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
}
