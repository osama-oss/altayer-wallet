import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:banksync_app/core/network/api_exception.dart';

import 'package:banksync_app/core/providers/app_providers.dart';

import 'package:banksync_app/core/widgets/banksync_auth_header.dart';

import 'package:banksync_app/core/widgets/db_error_banner.dart';

import 'package:banksync_app/core/widgets/db_primary_button.dart';

import 'package:banksync_app/core/auth/auth_service.dart';

import 'package:banksync_app/l10n/app_localizations.dart';

import 'package:banksync_app/router/app_router.dart';



/// MOBILE_API flow A — step 2: set permanent Keycloak password.

class SetInitialPasswordScreen extends ConsumerStatefulWidget {

  const SetInitialPasswordScreen({

    super.key,

    required this.username,

    this.keycloakUsername,

    required this.currentPassword,

  });



  final String username;

  final String? keycloakUsername;

  final String currentPassword;



  @override

  ConsumerState<SetInitialPasswordScreen> createState() =>

      _SetInitialPasswordScreenState();

}



class _SetInitialPasswordScreenState extends ConsumerState<SetInitialPasswordScreen> {

  final _formKey = GlobalKey<FormState>();

  final _newPassword = TextEditingController();

  final _confirm = TextEditingController();

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

    setState(() {

      _loading = true;

      _error = null;

    });

    try {

      final result = await ref.read(authServiceProvider).completeInitialPasswordAndLogin(

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



    return Scaffold(

      appBar: AppBar(title: Text(l10n.setPasswordTitle)),

      body: SingleChildScrollView(

        child: Column(

          children: [

            BankSyncAuthHeader(

              title: l10n.createYourPassword,

              subtitle: l10n.setPasswordSubtitle,

            ),

            Padding(

              padding: const EdgeInsets.all(24),

              child: Form(

                key: _formKey,

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    Text(

                      l10n.usernameLabel(widget.username),

                      style: Theme.of(context).textTheme.bodyMedium,

                    ),

                    const SizedBox(height: 16),

                    TextFormField(

                      controller: _newPassword,

                      obscureText: true,

                      decoration: InputDecoration(

                        labelText: l10n.newPassword,

                        helperText: l10n.passwordLengthHint,

                      ),

                      validator: (v) {

                        if (v == null || v.length < 8) return l10n.atLeast8Characters;

                        return null;

                      },

                    ),

                    const SizedBox(height: 16),

                    TextFormField(

                      controller: _confirm,

                      obscureText: true,

                      decoration: InputDecoration(labelText: l10n.confirmPassword),

                      validator: (v) {

                        if (v != _newPassword.text) return l10n.passwordsDoNotMatch;

                        return null;

                      },

                    ),

                    if (_error != null) ...[

                      const SizedBox(height: 16),

                      DbErrorBanner(message: _error!),

                    ],

                    const SizedBox(height: 24),

                    DbPrimaryButton(

                      label: l10n.saveAndContinue,

                      loading: _loading,

                      onPressed: _submit,

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

