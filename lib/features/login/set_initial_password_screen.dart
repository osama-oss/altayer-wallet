import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:banksync_app/core/auth/auth_service.dart';
import 'package:banksync_app/core/network/api_exception.dart';
import 'package:banksync_app/core/network/banking_auth_exceptions.dart';
import 'package:banksync_app/core/providers/app_providers.dart';
import 'package:banksync_app/core/providers/merchant_providers.dart';
import 'package:banksync_app/core/theme/app_colors.dart';
import 'package:banksync_app/core/theme/bank_sync_colors.dart';
import 'package:banksync_app/core/widgets/banksync_auth_header.dart';
import 'package:banksync_app/core/widgets/db_error_banner.dart';
import 'package:banksync_app/core/widgets/uff_loader.dart';
import 'package:banksync_app/core/widgets/uff_ui.dart';
import 'package:banksync_app/l10n/app_localizations.dart';
import 'package:banksync_app/router/app_router.dart';

/// MOBILE_API flow A — step 2: set the permanent Keycloak password.
///
/// Reached from the account-activation step with a temporary password (equal to
/// the phone). Submitting sets the new password *and* logs the user in via
/// [AuthService.completeInitialPasswordAndLogin].
class SetInitialPasswordScreen extends ConsumerStatefulWidget {
  const SetInitialPasswordScreen({
    super.key,
    required this.username,
    this.keycloakUsername,
    required this.currentPassword,
    this.channel,
  });

  final String username;
  final String? keycloakUsername;
  final String currentPassword;

  /// `merchant` for POS registration; otherwise customer/mobile realm.
  final String? channel;

  @override
  ConsumerState<SetInitialPasswordScreen> createState() =>
      _SetInitialPasswordScreenState();
}

class _SetInitialPasswordScreenState
    extends ConsumerState<SetInitialPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final isMerchant = widget.channel == 'merchant';
      if (isMerchant) {
        await ref.read(merchantAuthServiceProvider).completeInitialPasswordAndLogin(
              username: widget.username,
              currentPassword: widget.currentPassword,
              newPassword: _newPassword.text,
              confirmPassword: _confirm.text,
            );
        if (!mounted) return;
        context.go('/pos/home');
        notifyRouterAuthChanged(ref);
        return;
      }
      final result =
          await ref.read(authServiceProvider).completeInitialPasswordAndLogin(
                username: widget.username,
                currentPassword: widget.currentPassword,
                newPassword: _newPassword.text,
                confirmPassword: _confirm.text,
              );
      if (!mounted) return;
      if (result.route == PostLoginRoute.setInitialPassword) {
        setState(() => _error = l10n.passwordNotAccepted);
        return;
      }
      navigateAfterLogin(context, ref, result);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on KeycloakAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      // Slim, title-less bar: the blue header below carries the heading, so a
      // second AppBar title would be redundant. It also keeps the coloured
      // header off the status bar for legible status icons.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BankSyncAuthHeader(
              title: l10n.createYourPassword,
              subtitle: l10n.setPasswordSubtitle,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The account this password belongs to (read-only).
                    _AccountChip(
                      label: l10n.usernameLabel(widget.username),
                      colors: colors,
                    ),
                    const SizedBox(height: 24),

                    // New password.
                    TextFormField(
                      controller: _newPassword,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: uffInputDecoration(
                        context,
                        label: l10n.newPassword,
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            color: colors.outline, size: 20),
                        suffixIcon: _VisibilityToggle(
                          obscured: _obscureNew,
                          color: colors.outline,
                          onTap: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return l10n.atLeast8Characters;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _PasswordHint(text: l10n.passwordLengthHint, colors: colors),
                    const SizedBox(height: 16),

                    // Confirm password.
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: uffInputDecoration(
                        context,
                        label: l10n.confirmPassword,
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            color: colors.outline, size: 20),
                        suffixIcon: _VisibilityToggle(
                          obscured: _obscureConfirm,
                          color: colors.outline,
                          onTap: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v != _newPassword.text) {
                          return l10n.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      DbErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 28),

                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const UffLoader(size: 22, color: Colors.white)
                          : Text(l10n.saveAndContinue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only pill showing which account the new password is being set for.
class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.label, required this.colors});

  final String label;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.radiusField),
        border: Border.all(color: colors.outlineVariant, width: 1.3),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, size: 20, color: colors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Muted helper line under the new-password field (e.g. «8 characters min»).
class _PasswordHint extends StatelessWidget {
  const _PasswordHint({required this.text, required this.colors});

  final String text;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Eye icon that toggles password obscuring.
class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.obscured,
    required this.color,
    required this.onTap,
  });

  final bool obscured;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 20,
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: color,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}
