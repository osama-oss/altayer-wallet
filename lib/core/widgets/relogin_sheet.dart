import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../network/api_exception.dart';
import '../network/banking_auth_exceptions.dart';
import '../theme/app_text_styles.dart';
import '../theme/bank_sync_colors.dart';
import 'db_error_banner.dart';
import 'uff_ui.dart';
import './uff_loader.dart';

/// In-place re-login sheet shown when the server rejects the current token
/// mid-session (e.g. customer-id claim missing). The user re-enters their
/// password — or uses their fingerprint — without leaving the screen they
/// were on; the failed request is replayed by the caller on `true`.
///
/// Returns `true` when the user signed in again, `false`/`null` when they
/// dismissed the sheet (the caller then ends the session normally).
Future<bool?> showReloginSheet(BuildContext context, {required AuthService auth}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReloginSheet(auth: auth),
  );
}

class ReloginSheet extends StatefulWidget {
  const ReloginSheet({super.key, required this.auth});

  final AuthService auth;

  @override
  State<ReloginSheet> createState() => _ReloginSheetState();
}

class _ReloginSheetState extends State<ReloginSheet> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _canBiometric = false;
  String? _greetingName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final canBiometric = await widget.auth.canUnlockWithBiometric();
    final profile = await widget.auth.readProfile();
    final name = profile?['fullName']?.toString().trim();
    if (!mounted) return;
    setState(() {
      _canBiometric = canBiometric;
      if (name != null && name.isNotEmpty) _greetingName = name;
    });
  }

  Future<void> _submitPassword() async {
    final password = _password.text;
    if (password.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.auth.reauthenticate(password);
      if (mounted) Navigator.of(context).pop(true);
    } on FirstLoginPasswordChangeRequired {
      // Temporary password: the full change-password flow lives on the login
      // screen — the sheet can only tell the user how to get there.
      if (mounted) _fail(context.l10n.reloginPasswordChangeRequired);
    } on KeycloakAuthException catch (e) {
      _fail(e.message);
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (_) {
      if (mounted) _fail(context.l10n.reloginFailedGeneric);
    }
  }

  Future<void> _biometricLogin() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final challenge = await widget.auth.requestBiometricChallenge();
      await widget.auth.completeBiometricLogin(challenge);
      if (mounted) Navigator.of(context).pop(true);
    } on BiometricLockedException catch (e) {
      _fail(e.message ?? e.toString());
    } on BiometricNotEnrolledException catch (e) {
      _fail(e.message ?? e.toString());
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (_) {
      if (mounted) _fail(context.l10n.reloginFailedGeneric);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Padding(
      // Keep the sheet above the software keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_clock_rounded,
                  size: 32,
                  color: colors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _greetingName ?? l10n.signIn,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd(
                color: colors.onSurface,
                languageCode: languageCode,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sessionExpiredMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd(
                color: colors.onSurfaceVariant,
                languageCode: languageCode,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _password,
              obscureText: _obscure,
              enabled: !_loading,
              autofocus: !_canBiometric,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: uffInputDecoration(
                context,
                label: l10n.enterPassword,
                prefixIcon: Icon(Icons.lock_outline_rounded,
                    color: colors.onSurfaceVariant, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _submitPassword(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              DbErrorBanner(message: _error!),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (_canBiometric) ...[
                  InkWell(
                    onTap: _loading ? null : _biometricLogin,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.secondary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(Icons.fingerprint_rounded,
                          color: colors.secondary, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _loading ? null : _submitPassword,
                      style: FilledButton.styleFrom(
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
                              l10n.signIn,
                              style: AppTextStyles.bodyMd(
                                color: colors.onSecondary,
                                languageCode: languageCode,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed:
                  _loading ? null : () => Navigator.of(context).pop(false),
              child: Text(
                MaterialLocalizations.of(context).cancelButtonLabel,
                style: AppTextStyles.labelSm(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
