import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:banksync_app/core/network/api_exception.dart';

import 'package:banksync_app/core/network/banking_auth_exceptions.dart';

import 'package:banksync_app/core/providers/app_providers.dart';

import 'package:banksync_app/core/widgets/banksync_auth_header.dart';

import 'package:banksync_app/core/widgets/db_error_banner.dart';

import 'package:banksync_app/core/widgets/pin_entry_sheet.dart';

import 'package:banksync_app/l10n/app_localizations.dart';
import '../../core/widgets/uff_loader.dart';



/// MOBILE_API flow A step 7 — optional biometric enroll after PIN + device register.

class BiometricEnrollScreen extends ConsumerStatefulWidget {

  const BiometricEnrollScreen({super.key});



  @override

  ConsumerState<BiometricEnrollScreen> createState() => _BiometricEnrollScreenState();

}



class _BiometricEnrollScreenState extends ConsumerState<BiometricEnrollScreen> {

  bool _loading = false;

  String? _error;



  Future<void> _enable(String pin) async {

    final l10n = context.l10n;

    if (pin.length < 4) {

      setState(() => _error = l10n.enterTransactionPin);

      return;

    }

    setState(() {

      _loading = true;

      _error = null;

    });

    try {

      final ok = await ref.read(authServiceProvider).enableBiometricLogin(pin);

      if (!mounted) return;

      if (ok) {

        context.go('/login');

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(l10n.biometricLoginEnabledMessage)),

        );

      } else {

        setState(() => _error = l10n.biometricSetupUnavailable);

      }

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



  void _skip() {

    if (_loading) return;

    context.go('/home');

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

              title: l10n.enableBiometricLoginTitle,

              subtitle: l10n.enableBiometricLoginSubtitle,

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

                  title: l10n.enterYourPin,

                  subtitle: l10n.biometricEnrollPinSubtitle,

                  onCompleted: _enable,

                  showContinueButton: true,

                  trailingActions: [

                    SizedBox(

                      width: double.infinity,

                      child: OutlinedButton(

                        onPressed: _skip,

                        child: Text(l10n.skipForNow),

                      ),

                    ),

                  ],

                ),

              ),

          ],

        ),

      ),

    );

  }

}

