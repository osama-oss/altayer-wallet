import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/uff_loader.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';

/// شاشة إنشاء حساب «Ultimate Wallet».
///
/// التصميم مقتبَس من مرجع تدفّق التسجيل (الاسم كما في الهوية → رقم الموبايل →
/// الجنس → الموافقة على الشروط) لكن بهوية «Ultimate Wallet» (أزرق الثقة) بدلاً من الأحمر.
/// عند الضغط على «إنشاء حساب» ننتقل إلى شاشة التحقق (OTP). ربط الكور يأتي لاحقاً.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _secondName = TextEditingController();
  final _thirdName = TextEditingController();
  final _surname = TextEditingController();
  final _mobile = TextEditingController();

  String? _gender; // 'male' | 'female'
  bool _agreed = false;
  bool _submitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _secondName.dispose();
    _thirdName.dispose();
    _surname.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;
    if (_gender == null) {
      _snack(l10n.requiredField);
      return;
    }
    if (!_agreed) {
      _snack(l10n.mustAgreeToTerms);
      return;
    }
    if (_submitting) return;
    final mobile = _mobile.text.trim();
    setState(() => _submitting = true);
    try {
      // Wallet registration: username = the mobile number. Per the backend
      // contract the only usernameMode values are CUSTOMER_ID and CUSTOM, so we
      // use CUSTOM + customUsername to set the Keycloak username to the mobile
      // explicitly. customerId is required by the DTO (1–16 chars), so we pass
      // the mobile there too. The temporary password equals the username
      // (= mobile), which the set-password step then sends as currentPassword.
      final auth = ref.read(authServiceProvider);
      await auth.completeRegistration(
            customerId: mobile,
            usernameMode: 'CUSTOM',
            customUsername: mobile,
          );
      // Keep the name + gender the customer entered here: registration itself
      // only creates the Keycloak user, but the KYC step and the eventual
      // WALLET_CUSTOMER_CREATE call need these. Persisted read-only so KYC shows
      // them without letting the customer change what they signed up with.
      final fullName = [_firstName, _secondName, _thirdName, _surname]
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .join(' ');
      await auth.saveRegistrationIdentity({
        'firstName': _firstName.text.trim(),
        'secondName': _secondName.text.trim(),
        'thirdName': _thirdName.text.trim(),
        'familyName': _surname.text.trim(),
        'givenName': _firstName.text.trim(),
        'fullName': fullName,
        'gender': _gender, // 'male' | 'female'
        'mobile': mobile,
      });
      if (!mounted) return;
      context.push('/register/verify?mobile=${Uri.encodeComponent(mobile)}');
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الشعار
                const Center(child: BrandLogo(height: 60)),
                const SizedBox(height: 28),

                // العنوان الترحيبي
                Text(
                  l10n.registerWelcomeTitle,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.registerWelcomeSubtitle,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // تنبيه: أدخل الاسم كما في الهوية
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.registerNameAsIdHint,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // حقول الاسم (شبكة 2×2). المحاذاة العلوية + المساحة المحجوزة
                // لرسالة الخطأ تُبقي الحقلين على نفس المحور الرأسي حتى لو ظهر
                // خطأ تحت أحدهما فقط.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        colors,
                        controller: _firstName,
                        label: l10n.firstName,
                        requiredMsg: l10n.requiredField,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        colors,
                        controller: _secondName,
                        label: l10n.secondName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        colors,
                        controller: _thirdName,
                        label: l10n.thirdName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        colors,
                        controller: _surname,
                        label: l10n.surname,
                        requiredMsg: l10n.requiredField,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // رقم الموبايل مع مقدمة الدولة
                _mobileField(colors, l10n),
                const SizedBox(height: 10),

                // اختيار الجنس
                Row(
                  children: [
                    Expanded(
                      child: _genderButton(
                        colors,
                        value: 'male',
                        label: l10n.genderMale,
                        icon: Icons.male_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _genderButton(
                        colors,
                        value: 'female',
                        label: l10n.genderFemale,
                        icon: Icons.female_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // الموافقة على الشروط
                _termsRow(colors, l10n),
                const SizedBox(height: 18),

                // زر إنشاء حساب
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.secondary,
                      foregroundColor: colors.onSecondary,
                      disabledBackgroundColor:
                          colors.secondary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting
                        ? const UffLoader(size: 22, color: Colors.white)
                        : Text(
                            l10n.createAccountButton,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // لديك حساب بالفعل؟ تسجيل الدخول
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      l10n.alreadyHaveAccountSignIn,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // أزرار الدعم في الأسفل
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _supportAction(colors, Icons.headset_mic_outlined, l10n.customerService),
                    _supportAction(colors, Icons.location_on_outlined, l10n.servicePoints),
                    _supportAction(colors, Icons.call_outlined, l10n.tollFreeNumber),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── مكوّنات مساعدة ─────────────────────────────────────────────────────────

  Widget _field(
    BankSyncColors colors, {
    required TextEditingController controller,
    required String label,
    String? requiredMsg,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
      decoration: uffInputDecoration(context, label: label, reserveErrorSpace: true),
      validator: requiredMsg == null
          ? null
          : (v) => (v == null || v.trim().isEmpty) ? requiredMsg : null,
    );
  }

  Widget _mobileField(BankSyncColors colors, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // مقدمة الدولة (اليمن +967)
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppColors.radiusField),
            border: Border.all(color: colors.outlineVariant, width: 1.3),
          ),
          child: Row(
            children: [
              const Text('🇾🇪', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                '+967',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
            decoration: uffInputDecoration(context,
                label: l10n.mobileNumber, reserveErrorSpace: true),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return l10n.requiredField;
              if (t.length < 9) return l10n.requiredField;
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _genderButton(
    BankSyncColors colors, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: selected ? colors.secondary : colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.secondary : colors.outlineVariant,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? colors.onSecondary : colors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon,
                size: 20,
                color: selected ? colors.onSecondary : colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _termsRow(BankSyncColors colors, AppLocalizations l10n) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            activeColor: colors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/terms'),
            child: Text(
              l10n.agreeToTerms,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
                decoration: TextDecoration.underline,
                decorationColor: colors.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _supportAction(BankSyncColors colors, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Icon(icon, size: 22, color: colors.secondary),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
