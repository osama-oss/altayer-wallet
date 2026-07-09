import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:banksync_app/core/network/api_exception.dart';
import 'package:banksync_app/core/network/banking_auth_exceptions.dart';
import 'package:banksync_app/core/providers/app_providers.dart';
import 'package:banksync_app/core/widgets/db_error_banner.dart';
import 'package:banksync_app/core/widgets/db_primary_button.dart';
import 'package:banksync_app/core/widgets/pin_entry_sheet.dart';

/// MOBILE_API — change transaction PIN (current + new).
class PinChangeScreen extends ConsumerStatefulWidget {
  const PinChangeScreen({super.key});

  @override
  ConsumerState<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends ConsumerState<PinChangeScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _changePin() async {
    final current = await showPinEntrySheet(
      context,
      title: 'Enter current PIN',
    );
    if (current == null || !mounted) return;

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
      await ref.read(authServiceProvider).changeTransactionPin(
            currentPin: current,
            newPin: newPin,
            confirmPin: confirm,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction PIN updated')),
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
      appBar: AppBar(title: const Text('Change PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Update your transaction PIN used to authorize transfers and security changes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              DbErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            DbPrimaryButton(
              label: 'Continue',
              loading: _loading,
              onPressed: _loading ? null : _changePin,
            ),
          ],
        ),
      ),
    );
  }
}
