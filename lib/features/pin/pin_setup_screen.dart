import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:banksync_app/core/network/api_exception.dart';

import 'package:banksync_app/core/providers/app_providers.dart';

import 'package:banksync_app/core/widgets/banksync_auth_header.dart';

import 'package:banksync_app/router/app_router.dart';

import 'package:banksync_app/core/widgets/db_error_banner.dart';

import 'package:banksync_app/core/widgets/pin_entry_sheet.dart';

import 'package:banksync_app/l10n/app_localizations.dart';
import '../../core/widgets/uff_loader.dart';



/// MOBILE_API flow A — steps 5–6: transaction PIN + device register.

class PinSetupScreen extends ConsumerStatefulWidget {

  const PinSetupScreen({super.key});



  @override

  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();

}



class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {

  bool _loading = false;

  String? _error;

  String? _firstPin;

  bool _confirmStep = false;



  Future<void> _onPinEntered(String pin) async {

    final l10n = context.l10n;

    if (!_confirmStep) {

      setState(() {

        _firstPin = pin;

        _confirmStep = true;

        _error = null;

      });

      return;

    }



    if (pin != _firstPin) {

      setState(() {

        _error = l10n.pinsDoNotMatch;

        _confirmStep = false;

        _firstPin = null;

      });

      return;

    }



    setState(() {

      _loading = true;

      _error = null;

    });

    try {

      await ref.read(authServiceProvider).setupPinAndDevice(pin, pin);

      if (!mounted) return;

      final hw = await ref.read(authServiceProvider).isBiometricHardwareAvailable();

      if (!mounted) return;

      context.go(hw ? '/biometric-enroll' : '/home');

      notifyRouterAuthChanged(ref);

    } on ApiException catch (e) {

      setState(() => _error = e.message);

    } catch (e) {

      setState(() => _error = e.toString());

    } finally {

      if (mounted) setState(() => _loading = false);

    }

  }



  void _onCancel() {

    if (_confirmStep) {

      setState(() {

        _confirmStep = false;

        _firstPin = null;

        _error = null;

      });

    } else if (context.canPop()) {

      context.pop();

    }

  }



  @override

  Widget build(BuildContext context) {

    final l10n = context.l10n;



    return Scaffold(

      body: SafeArea(

        bottom: false,

        child: Column(

          children: [

            BankSyncAuthHeader(

              title: l10n.transactionPinTitle,

              subtitle: l10n.transactionPinSubtitle,

            ),

            if (_error != null)

              Padding(

                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),

                child: DbErrorBanner(message: _error!),

              ),

            if (_loading)

              const Padding(

                padding: EdgeInsets.all(24),

                child: Center(child: UffLoader()),

              )

            else

              Expanded(

                child: PinEntryView(

                  key: ValueKey(_confirmStep),

                  title: _confirmStep ? l10n.confirmYourPin : l10n.createYourPin,

                  subtitle: _confirmStep

                      ? l10n.confirmPinSubtitle

                      : l10n.choosePinSubtitle,

                  onCompleted: _onPinEntered,

                  onCancel: _onCancel,

                  showContinueButton: true,

                ),

              ),

          ],

        ),

      ),

    );

  }

}

