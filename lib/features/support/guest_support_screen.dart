import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/uff_loader.dart';

class GuestSupportScreen extends ConsumerStatefulWidget {
  const GuestSupportScreen({super.key});

  @override
  ConsumerState<GuestSupportScreen> createState() => _GuestSupportScreenState();
}

class _GuestSupportScreenState extends ConsumerState<GuestSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _name = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _mobile.dispose();
    _name.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await ref.read(apiClientProvider).createGuestSupportCase(
            mobile: _mobile.text.trim(),
            guestName: _name.text.trim(),
            subject: _subject.text.trim(),
            message: _message.text.trim(),
          );
      if (!mounted) return;
      final caseNumber = result['caseNumber']?.toString() ?? '';
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.supportCreatedTitle),
          content: Text(context.l10n.supportCreatedBody(caseNumber)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(
                  '/guest-support/lookup?caseNumber=$caseNumber&mobile=${Uri.encodeComponent(_mobile.text.trim())}',
                );
              },
              child: Text(context.l10n.supportTitle),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.continueLabel),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.needHelp)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(
                onPressed: () => context.push('/guest-support/lookup'),
                child: Text(l10n.trackExistingCase),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mobile,
                decoration: InputDecoration(labelText: l10n.guestMobile),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.guestName),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subject,
                decoration: InputDecoration(labelText: l10n.supportSubject),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _message,
                maxLines: 5,
                decoration: InputDecoration(labelText: l10n.supportMessage),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: UffLoader(),
                      )
                    : Text(l10n.supportSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
