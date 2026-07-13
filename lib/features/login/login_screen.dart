import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/banking_auth_exceptions.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/merchant_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/db_error_banner.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import '../../core/widgets/uff_loader.dart';

/// Brand palette — Ultimate Wallet trust blue (deep + bright), used across the
/// login screen accents.
const Color _brandDeep = Color(0xFF003D8F);
const Color _brandBright = Color(0xFF0050B3);
const Color _screenBg = Color(0xFFF4F5F8);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialTab});

  /// When `merchant`, opens the Point-of-sale tab (e.g. after merchant registration).
  final String? initialTab;

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
  // false → Customer tab, true → Point-of-sale (merchant realm).
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
    _merchant = widget.initialTab == 'merchant';
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
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_merchant) {
        await ref.read(merchantAuthServiceProvider).loginWithPassword(
              _mobile.text,
              _password.text,
            );
        if (!mounted) return;
        context.go('/pos/home');
        notifyRouterAuthChanged(ref);
        return;
      }
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
          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.enableFingerprintMessage,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.okButton,
              style: const TextStyle(fontFamily: 'Tajawal'),
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

  /// Larger, more legible floating label for the two credential fields only.
  /// Mirrors [uffInputDecoration]'s colour logic and motion — the only change
  /// is a bigger [fontSize] (15 vs the shared 13.5).
  TextStyle _floatingLabelStyle(BankSyncColors colors) {
    return WidgetStateTextStyle.resolveWith((states) {
      final Color ink;
      if (states.contains(WidgetState.error)) {
        ink = colors.error;
      } else if (states.contains(WidgetState.focused)) {
        ink = colors.secondary;
      } else {
        ink = colors.onSurface;
      }
      return AppTextStyles.labelSm(color: ink).copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1,
      );
    });
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
              const SizedBox(height: 12),

              // Brand logo — enlarged so it reads as a core identity element.
              Center(
                child: SvgPicture.asset(
                  'assets/branding/ultimate_wallet_light.svg',
                  width: 170,
                ),
              ),
              const SizedBox(height: 26),

              // Welcome title (start-aligned → right in RTL) with animated waving hand.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.welcomeBack,
                    style: const TextStyle(
                      color: Color(0xFF1A1230),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _WavingHandIcon(),
                ],
              ),
              const SizedBox(height: 18),

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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                      ],
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
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
                      ).copyWith(floatingLabelStyle: _floatingLabelStyle(colors)),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? l10n.enterMobileNumber : null,
                    ),
                    const SizedBox(height: 16),

                    // Password with an inline fingerprint (→ biometric) and an
                    // eye toggle, mirroring the reference field.
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
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
                      ).copyWith(floatingLabelStyle: _floatingLabelStyle(colors)),
                      onFieldSubmitted: (_) => _login(),
                      validator: (v) =>
                          v == null || v.isEmpty ? l10n.enterPassword : null,
                    ),

                    // Forgot password (start-aligned).
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => context.push(
                              _merchant
                                  ? '/reset-password?channel=merchant'
                                  : '/reset-password',
                            ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.forgotPassword,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _brandBright,
                          ),
                        ),
                      ),
                    ),

                    if (afterPasswordReset) ...[
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
                                  fontFamily: 'Tajawal',
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
                  fontFamily: 'Tajawal',
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

  Widget _buildCreateAccount(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => context.push(
            _merchant ? '/register?channel=merchant' : '/register',
          ),
      behavior: HitTestBehavior.opaque,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12.5),
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
                fontFamily: 'Tajawal',
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
            fontFamily: 'Tajawal',
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
                      fontFamily: 'Tajawal',
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
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
            ),
            DropdownMenuItem(
              value: const Locale('ar'),
              child: Text(l10n.languageArabic,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
            ),
            DropdownMenuItem(
              value: const Locale('zh'),
              child: Text(l10n.languageChinese,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
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

class _WavingHandIcon extends StatefulWidget {
  const _WavingHandIcon();

  @override
  State<_WavingHandIcon> createState() => _WavingHandIconState();
}

class _WavingHandIconState extends State<_WavingHandIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _animation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Wave 3 times (back and forth) then settle at upright position
    _wave();
  }

  Future<void> _wave() async {
    for (int i = 0; i < 3; i++) {
      await _controller.forward();
      await _controller.reverse();
    }
    _controller.animateTo(0.5); // go to 0 rotation (upright)
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<BankSyncColors>() ?? BankSyncColors.light;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: child,
        );
      },
      child: SvgPicture.string(
        '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="28" height="28">
          <path fill="#FFFFFF" d="M12,2A3,3,0,0,0,9,5V13.5L7.5,12a1.5,1.5,0,0,0-2.12,0,1.5,1.5,0,0,0,0,2.12L10.5,19.25A6,6,0,0,0,15,21h3a4,4,0,0,0,4-4V11a2,2,0,0,0-2-2,2,2,0,0,0-2,2v.5L18,7.5a2,2,0,0,0-4,0V5A3,3,0,0,0,12,2Z"/>
        </svg>''',
        width: 28,
        height: 28,
        colorFilter: ColorFilter.mode(
          colors.secondary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
