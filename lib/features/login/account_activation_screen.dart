import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/otp_service.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/uff_loader.dart';
import '../../l10n/app_localizations.dart';

/// شاشة إدخال «كود تفعيل الحساب» ضمن تدفّق التسجيل الجديد.
///
/// مستقلة عن [OtpVerificationScreen] (المستخدمة في تدفّقات إعادة تعيين كلمة
/// المرور / PIN) حتى لا نكسر سلوكها. واجهة فقط الآن — التحقق الفعلي عبر الكور
/// يُضاف لاحقاً؛ عند اكتمال 6 خانات والضغط على «تأكيد» ننتقل لتسجيل الدخول.
class AccountActivationScreen extends StatefulWidget {
  final String mobile;

  /// Keycloak username returned by registration (normalized digits). It doubles
  /// as the temporary password. Null for legacy entry points that only know the
  /// raw mobile — in that case we fall back to [mobile].
  final String? keycloakUsername;

  /// `merchant` for POS registration; otherwise customer/mobile realm.
  final String? channel;

  const AccountActivationScreen({
    super.key,
    required this.mobile,
    this.keycloakUsername,
    this.channel,
  });

  @override
  State<AccountActivationScreen> createState() =>
      _AccountActivationScreenState();
}

class _AccountActivationScreenState extends State<AccountActivationScreen> {
  static const int _codeLength = 4;
  static const int _expirySeconds = 600; // 10:00

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _timer;
  int _remaining = _expirySeconds;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _expirySeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _complete => _controller.text.length == _codeLength;

  Future<void> _confirm() async {
    if (!_complete || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    // TEMPORARY: no SMS provider yet — verify the entered code against the
    // fixed activation code (1234) from config via OtpService. Swap the body of
    // OtpService.verify for the real backend verify endpoint later.
    final valid = await OtpService().verify(_controller.text.trim());
    if (!mounted) return;
    if (!valid) {
      setState(() {
        _verifying = false;
        _controller.clear();
        _error = _invalidCodeMessage(context);
      });
      return;
    }
    setState(() => _verifying = false);
    // Registration flow: after activation, the user sets a permanent password.
    // The account was created in Keycloak with a temporary password EQUAL to the
    // (normalized) keycloakUsername, so we pass that as both the username and the
    // currentPassword. The set-initial-password screen then sets the new password
    // AND logs the user in (completeInitialPasswordAndLogin). Fall back to the
    // raw mobile only when no keycloakUsername was provided.
    final loginUsername =
        (widget.keycloakUsername != null && widget.keycloakUsername!.isNotEmpty)
            ? widget.keycloakUsername!
            : widget.mobile;
    context.go('/set-initial-password', extra: <String, String>{
      'username': loginUsername,
      'currentPassword': loginUsername,
      if (widget.channel != null && widget.channel!.isNotEmpty)
        'channel': widget.channel!,
    });
  }

  String _invalidCodeMessage(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ar':
        return 'رمز التفعيل غير صحيح';
      case 'zh':
        return '激活码不正确';
      default:
        return 'Invalid activation code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: BrandLogo(height: 54)),
              const SizedBox(height: 40),

              Text(
                l10n.activationTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.activationSubtitle(widget.mobile),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              _CodeBoxes(
                controller: _controller,
                focus: _focus,
                length: _codeLength,
                colors: colors,
                onChanged: () {
                  setState(() => _error = null);
                  if (_complete) _focus.unfocus();
                },
              ),
              const SizedBox(height: 20),

              // العدّاد التنازلي
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.activationExpiresIn,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formattedTime,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // إعادة الإرسال
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${l10n.didntReceiveCode} ',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: _remaining == 0 ? _startTimer : () {},
                    child: Text(
                      l10n.contactCustomerService,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: (_complete && !_verifying) ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.onSecondary,
                    disabledBackgroundColor: colors.secondary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _verifying
                      ? const UffLoader(size: 22, color: Colors.white)
                      : Text(
                          l10n.activationConfirm,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صفّ من الخانات لعرض رمز التفعيل، مدعوم بحقل إدخال شفّاف يلتقط لوحة المفاتيح.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focus,
    required this.length,
    required this.colors,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final int length;
  final BankSyncColors colors;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final code = controller.text;
    return Stack(
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(length, (i) {
              final filled = i < code.length;
              final isCurrent = i == code.length && focus.hasFocus;
              return Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? colors.secondary
                        : (filled ? colors.secondary.withValues(alpha: 0.5) : colors.outlineVariant),
                    width: isCurrent ? 2 : 1.3,
                  ),
                ),
                child: Text(
                  filled ? code[i] : '',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              );
            }),
          ),
        ),
        Positioned.fill(
          child: TextField(
            controller: controller,
            focusNode: focus,
            keyboardType: TextInputType.number,
            showCursor: false,
            enableInteractiveSelection: false,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(length),
            ],
            style: const TextStyle(color: Colors.transparent, height: 1),
            decoration: const InputDecoration(
              counterText: '',
              filled: false,
              fillColor: Colors.transparent,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}
