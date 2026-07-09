import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:banksync_app/core/network/api_exception.dart';
import 'package:banksync_app/core/network/banking_auth_exceptions.dart';
import 'package:banksync_app/core/providers/app_providers.dart';
import 'package:banksync_app/core/widgets/db_error_banner.dart';
import 'package:banksync_app/core/widgets/db_primary_button.dart';
import 'package:banksync_app/core/widgets/pin_entry_sheet.dart';

/// MOBILE_API flow E — reset transaction PIN with Keycloak password.
class PinResetScreen extends ConsumerStatefulWidget {
  const PinResetScreen({super.key});

  @override
  ConsumerState<PinResetScreen> createState() => _PinResetScreenState();
}

class _PinResetScreenState extends ConsumerState<PinResetScreen> {
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _resetPin() async {
    final password = _password.text;
    if (password.isEmpty) {
      setState(() => _error = 'Enter your sign-in password');
      return;
    }

    final newPin = await showPinEntrySheet(
      context,
      title: 'Enter new PIN',
    );
    if (newPin == null || !mounted) return;

    final confirm = await showPinEntrySheet(
      context,
      title: 'Confirm new PIN',
    );
    if (confirm == null || !mounted) return;

    if (newPin != confirm) {
      setState(() => _error = 'PINs do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).resetTransactionPin(
            password: password,
            newPin: newPin,
            confirmPin: confirm,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction PIN reset successfully')),
      );
      context.pop();
    } on PinInvalidException catch (e) {
      setState(() => _error = e.message);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Verify your identity with your sign-in password, then set a new transaction PIN.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Sign-in password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              DbErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            DbPrimaryButton(
              label: 'Continue',
              loading: _loading,
              onPressed: _loading ? null : _resetPin,
            ),
          ],
        ),
      ),
    );
  }
}
