import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/db_error_banner.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/uff_loader.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialMobile});

  final String? initialMobile;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _mobile;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _mobile = TextEditingController(text: widget.initialMobile ?? '');
  }

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final mobile = _mobile.text.trim();
    if (mobile.isEmpty) {
      setState(() => _error = l10n.enterRegisteredMobile);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(authServiceProvider).resetPasswordByMobile(mobile);
      if (!mounted) return;
      setState(() => _success = l10n.resetPasswordSuccess);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      context.go('/otp-verification?mobile=${Uri.encodeComponent(mobile)}');
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
    final colors = context.bankColors;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAr = languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Premium light grey background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium iOS Top Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => context.go('/login'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isAr ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    l10n.forgotPasswordTitle, // نسيت كلمة المرور
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14152E),
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(width: 40), // Spacer to balance
                ],
              ),
              const SizedBox(height: 24),

              // Main form card
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gold Lock Icon Circle
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF7ED), // iOS soft orange/gold background
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_open_rounded,
                            color: Color(0xFFF97316),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Reset Password Title
                    Center(
                      child: Text(
                        l10n.resetPasswordHeading, // إعادة تعيين كلمة المرور
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14152E),
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Center(
                      child: Text(
                        l10n.resetPasswordDescription, // أدخل رقم الجوال...
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          height: 1.4,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mobile Number Input
                    TextField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: uffInputDecoration(
                        context,
                        label: l10n.mobileNumber,
                        placeholder: l10n.enterRegisteredMobileHint,
                        prefixIcon: Icon(Icons.phone_android_rounded, color: Colors.grey[500], size: 20),
                        fillColor: const Color(0xFFF1F5F9),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_error != null) ...[
                      DbErrorBanner(message: _error!),
                      const SizedBox(height: 16),
                    ],

                    if (_success != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppColors.radiusMd),
                        ),
                        child: Text(_success!, style: TextStyle(color: colors.success, fontFamily: 'Tajawal')),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5B2EE5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: UffLoader(size: 20, color: Colors.white),
                              )
                            : Text(
                                l10n.requestReset, // طلب إعادة التعيين
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Return to login footer link
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    l10n.backToSignIn, // العودة لتسجيل الدخول
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5B2EE5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
