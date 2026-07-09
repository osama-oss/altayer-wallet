import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/db_error_banner.dart';
import '../../core/widgets/uff_ui.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import '../../core/widgets/uff_loader.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerId = TextEditingController();
  final _customUsername = TextEditingController();

  bool _loadingLookup = false;
  bool _loadingRegister = false;
  String? _error;
  Map<String, dynamic>? _preview;
  String _usernameMode = 'CUSTOMER_ID';

  @override
  void dispose() {
    _customerId.dispose();
    _customUsername.dispose();
    super.dispose();
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String _displayFullName(Map<String, dynamic>? fullName) {
    if (fullName == null) return '—';
    final en = _text(fullName['en']);
    final ar = _text(fullName['ar']);
    if (en != null && ar != null) return '$en · $ar';
    return en ?? ar ?? '—';
  }

  Future<void> _fetchPreview() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loadingLookup = true;
      _error = null;
      _preview = null;
    });
    try {
      final data = await ref
          .read(authServiceProvider)
          .lookupRegistration(_customerId.text);
      if (!mounted) return;
      setState(() {
        _preview = data;
        _usernameMode = 'CUSTOMER_ID';
        _customUsername.clear();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingLookup = false);
    }
  }

  Future<void> _register() async {
    final l10n = context.l10n;
    if (_preview == null) return;
    if (_usernameMode == 'CUSTOM' && _customUsername.text.trim().isEmpty) {
      setState(() => _error = l10n.enterCustomUsername);
      return;
    }
    setState(() {
      _loadingRegister = true;
      _error = null;
    });
    try {
      final data = await ref.read(authServiceProvider).completeRegistration(
            customerId: _customerId.text,
            usernameMode: _usernameMode,
            customUsername:
                _usernameMode == 'CUSTOM' ? _customUsername.text : null,
          );
      if (!mounted) return;
      final keycloakUsername = data['keycloakUsername']?.toString() ?? '';
      if (keycloakUsername.isEmpty) {
        setState(() => _error = l10n.registrationUsernameMissing);
        return;
      }
      context.go(
        '/set-initial-password',
        extra: {
          'username': keycloakUsername,
          'keycloakUsername': keycloakUsername,
          'currentPassword': keycloakUsername,
        },
      );
      notifyRouterAuthChanged(ref);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingRegister = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isAr = languageCode == 'ar';
    final preview = _preview;
    final fullName = preview?['fullName'];
    final fullNameMap = fullName is Map
        ? Map<String, dynamic>.from(fullName)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Premium light grey background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
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
                      l10n.registerTitle, // التسجيل
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
                      // Avatar Circle
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF), // iOS soft blue background
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_add_alt_1_outlined,
                              color: Color(0xFF5B2EE5),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Welcome Title
                      Center(
                        child: Text(
                          l10n.createYourAccount, // إنشاء حسابك
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

                      // Subtitle
                      Center(
                        child: Text(
                          l10n.registrationSubtitle, // أدخل معرف العميل...
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

                      if (preview == null) ...[
                        // Customer ID Input Section
                        TextFormField(
                          controller: _customerId,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          enabled: true,
                          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w600),
                          decoration: uffInputDecoration(
                            context,
                            label: l10n.coreCustomerId,
                            placeholder: l10n.coreCustomerIdHint,
                            suffixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF5B2EE5), size: 20),
                            fillColor: const Color(0xFFF1F5F9),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? l10n.enterCoreCustomerId
                              : null,
                          onFieldSubmitted: (_) => _fetchPreview(),
                        ),
                        const SizedBox(height: 8),

                        // Helper info row below field
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: const Color(0xFF5B2EE5), size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.enterCustomerIdHint,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _loadingLookup ? null : _fetchPreview,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF5B2EE5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _loadingLookup
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: UffLoader(size: 20, color: Colors.white),
                                  )
                                : Text(
                                    l10n.fetchProfile, // جلب الملف الشخصي
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ] else ...[
                        // Preview state (looked up profile)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PreviewRow(
                                label: l10n.fullName,
                                value: _displayFullName(fullNameMap),
                              ),
                              const Divider(height: 20),
                              _PreviewRow(
                                label: l10n.mobile,
                                value: _text(preview['mobileNo']) ?? '—',
                              ),
                              const Divider(height: 20),
                              _PreviewRow(
                                label: l10n.gender,
                                value: _text(preview['gender']) ?? '—',
                              ),
                              const Divider(height: 20),
                              _PreviewRow(
                                label: l10n.dateOfBirth,
                                value: _text(preview['dateOfBirth']) ?? '—',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username Selection Mode
                        Text(
                          l10n.mobileLoginUsername,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14152E),
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<String>(
                          value: 'CUSTOMER_ID',
                          groupValue: _usernameMode,
                          activeColor: const Color(0xFF5B2EE5),
                          onChanged: (v) => setState(() => _usernameMode = v!),
                          title: Text(l10n.coreCustomerIdOption, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Text(_customerId.text.trim(), style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<String>(
                          value: 'CUSTOM',
                          groupValue: _usernameMode,
                          activeColor: const Color(0xFF5B2EE5),
                          onChanged: (v) => setState(() => _usernameMode = v!),
                          title: Text(l10n.customUsername, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold)),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_usernameMode == 'CUSTOM') ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _customUsername,
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: uffInputDecoration(
                              context,
                              label: l10n.customUsername,
                              placeholder: l10n.customUsernameHint,
                              prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.grey[500], size: 20),
                              fillColor: const Color(0xFFF1F5F9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.customUsernameRules,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontFamily: 'Tajawal',
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Action Buttons for preview state
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _loadingRegister
                                      ? null
                                      : () => setState(() => _preview = null),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.grey),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.changeId,
                                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: _loadingRegister ? null : _register,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF5B2EE5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loadingRegister
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: UffLoader(size: 20, color: Colors.white),
                                        )
                                      : Text(
                                          l10n.registerButton,
                                          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        DbErrorBanner(message: _error!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Have account footer link
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      l10n.alreadyHaveAccountSignIn,
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
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontFamily: 'Tajawal',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14152E),
              fontFamily: 'Tajawal',
            ),
          ),
        ),
      ],
    );
  }
}
