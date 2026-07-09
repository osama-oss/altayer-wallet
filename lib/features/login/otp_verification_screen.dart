import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:banksync_app/core/auth/otp_service.dart';
import '../../core/widgets/uff_loader.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String mobile;

  const OtpVerificationScreen({
    super.key,
    required this.mobile,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  String _otpCode = '';
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _isSuccessVisible = false;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _onKeyPress(String val) {
    if (_otpCode.length < 4) {
      setState(() {
        _otpCode += val;
        _error = null;
      });
    }
  }

  void _onBackspace() {
    if (_otpCode.isNotEmpty) {
      setState(() {
        _otpCode = _otpCode.substring(0, _otpCode.length - 1);
      });
    }
  }

  String _maskPhoneNumber(String mobile) {
    if (mobile.isEmpty) return '';
    final cleaned = mobile.trim();
    if (cleaned.length > 6) {
      final start = cleaned.substring(0, 4);
      final end = cleaned.substring(cleaned.length - 2);
      final mask = '*' * (cleaned.length - 6);
      return '$start$mask$end';
    }
    return cleaned;
  }

  String _getLocaleString(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'ar':
        switch (key) {
          case 'verification': return 'التحقق';
          case 'sent_to': return 'أدخل رمز التحقق المرسل إلى الرقم';
          case 'resend_in': return 'إعادة الإرسال خلال';
          case 'resend_code': return 'إعادة إرسال الرمز';
          case 'confirm': return 'تأكيد';
          case 'success_title': return 'تم التحقق بنجاح';
          case 'success_msg': return 'تمت إعادة تعيين كلمة المرور بنجاح، يمكنك تسجيل الدخول الآن';
          case 'invalid_code': return 'رمز التحقق غير صحيح';
          default: return '';
        }
      case 'zh':
        switch (key) {
          case 'verification': return '验证';
          case 'sent_to': return '请输入发送至手机号的验证码';
          case 'resend_in': return '重新发送';
          case 'resend_code': return '重新发送验证码';
          case 'confirm': return '确认';
          case 'success_title': return '验证成功';
          case 'success_msg': return '密码重置成功，您现在可以登录';
          case 'invalid_code': return '验证码不正确';
          default: return '';
        }
      default: // en
        switch (key) {
          case 'verification': return 'Verification';
          case 'sent_to': return 'Enter the verification code sent to';
          case 'resend_in': return 'Resend in';
          case 'resend_code': return 'Resend Code';
          case 'confirm': return 'Confirm';
          case 'success_title': return 'Verified Successfully';
          case 'success_msg': return 'Password has been reset successfully. You can now log in.';
          case 'invalid_code': return 'Invalid verification code';
          default: return '';
        }
    }
  }

  Future<void> _submitVerification() async {
    if (_otpCode.length != 4 || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });

    // Functional check: matches the entered code against the fixed OTP
    // (no SMS provider yet). Swap OtpService for the real backend later.
    final valid = await OtpService().verify(_otpCode);
    if (!mounted) return;

    if (!valid) {
      setState(() {
        _verifying = false;
        _otpCode = '';
        _error = _getLocaleString(context, 'invalid_code');
      });
      return;
    }

    // Show Apple-style success overlay dialog
    setState(() {
      _verifying = false;
      _isSuccessVisible = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // Redirect to login with parameter to trigger temporary password message banner
    context.go('/login?afterPasswordReset=1');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAr = languageCode == 'ar';

    final textStyle = const TextStyle(fontFamily: 'Tajawal');

    return Scaffold(
      backgroundColor: isDarkTheme ? const Color(0xFF0F1115) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium iOS Top Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => context.go('/reset-password'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDarkTheme ? const Color(0xFF161921) : Colors.white,
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
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        _getLocaleString(context, 'verification'),
                        style: textStyle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkTheme ? Colors.white : const Color(0xFF14152E),
                        ),
                      ),
                      const SizedBox(width: 40), // Spacer to balance
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        // Locked Envelope Icon Header Card
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.mark_email_unread_rounded,
                                color: Color(0xFF5B2EE5),
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          _getLocaleString(context, 'verification'),
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDarkTheme ? Colors.white : const Color(0xFF14152E),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          '${_getLocaleString(context, 'sent_to')} ${_maskPhoneNumber(widget.mobile)}',
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(
                            fontSize: 14,
                            color: isDarkTheme ? Colors.grey[400] : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // OTP Code Cells
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) {
                            final isActive = _otpCode.length == index;
                            final hasVal = _otpCode.length > index;
                            final val = hasVal ? _otpCode[index] : '';

                            return Container(
                              width: 64,
                              height: 68,
                              decoration: BoxDecoration(
                                color: isDarkTheme ? const Color(0xFF161921) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFF5B2EE5)
                                      : (isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  width: isActive ? 2.5 : 1.5,
                                ),
                                boxShadow: [
                                  if (isActive)
                                    BoxShadow(
                                      color: const Color(0xFF5B2EE5).withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  else
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                val,
                                style: textStyle.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkTheme ? Colors.white : const Color(0xFF14152E),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 32),

                        // Countdown Timer / Resend Button
                        Center(
                          child: _secondsRemaining > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDarkTheme
                                        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color: isDarkTheme ? Colors.grey[400] : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_getLocaleString(context, 'resend_in')} 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                        style: textStyle.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkTheme ? Colors.grey[300] : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : TextButton(
                                  onPressed: _startTimer,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF5B2EE5),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text(
                                    _getLocaleString(context, 'resend_code'),
                                    style: textStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: textStyle.copyWith(
                              color: const Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),

                        // Action Confirm Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: (_otpCode.length == 4 && !_verifying)
                                ? _submitVerification
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF5B2EE5),
                              disabledBackgroundColor: isDarkTheme
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _verifying
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: UffLoader(size: 20, color: Colors.white),
                                  )
                                : Text(
                                    _getLocaleString(context, 'confirm'),
                                    style: textStyle.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _otpCode.length == 4
                                          ? Colors.white
                                          : (isDarkTheme ? Colors.grey[600] : Colors.grey[400]),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Beautiful iOS Keypad Grid
                _buildPasscodeKeypad(isDarkTheme),
              ],
            ),
          ),

          // High fidelity iOS style success overlay dialog
          if (_isSuccessVisible)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isSuccessVisible ? 1.0 : 0.0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dynamic ring green check spinner
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _getLocaleString(context, 'success_title'),
                          style: textStyle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkTheme ? Colors.white : const Color(0xFF14152E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getLocaleString(context, 'success_msg'),
                          textAlign: TextAlign.center,
                          style: textStyle.copyWith(
                            fontSize: 13,
                            color: isDarkTheme ? Colors.grey[400] : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasscodeKeypad(bool isDarkTheme) {
    final keypadRows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'backspace'],
    ];

    final alphabeticLabels = {
      '1': '',
      '2': 'A B C',
      '3': 'D E F',
      '4': 'G H I',
      '5': 'J K L',
      '6': 'M N O',
      '7': 'P Q R S',
      '8': 'T U V',
      '9': 'W X Y Z',
      '0': '+',
    };

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 20),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF0F1115) : const Color(0xFFF1F5F9),
      ),
      child: Column(
        children: keypadRows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 72, height: 72);
                }

                if (key == 'backspace') {
                  return InkWell(
                    onTap: _onBackspace,
                    borderRadius: BorderRadius.circular(36),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.backspace_outlined,
                          size: 22,
                          color: isDarkTheme ? Colors.white : const Color(0xFF14152E),
                        ),
                      ),
                    ),
                  );
                }

                final label = alphabeticLabels[key] ?? '';
                final isZero = key == '0';

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onKeyPress(key),
                    borderRadius: BorderRadius.circular(36),
                    child: Ink(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isDarkTheme ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            key,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: isDarkTheme ? Colors.white : const Color(0xFF14152E),
                              height: 1.1,
                            ),
                          ),
                          if (label.isNotEmpty)
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isDarkTheme ? Colors.grey[500] : const Color(0xFF94A3B8),
                                height: 1.0,
                              ),
                            )
                          else if (isZero)
                            const SizedBox(height: 9),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
