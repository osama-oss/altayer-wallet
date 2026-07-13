import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/merchant_providers.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/db_error_banner.dart';
import '../../core/widgets/uff_loader.dart';
import '../../core/widgets/uff_ui.dart';

class _UploadedDocument {
  const _UploadedDocument({required this.fileName, required this.uploadString});

  final String fileName;
  final String uploadString;
}

/// Merchant owner registration completion (core banking activation).
///
/// Uses `/api/merchant/onboarding/*` — not the customer KYC flow.
class PosOnboardingScreen extends ConsumerStatefulWidget {
  const PosOnboardingScreen({super.key});

  @override
  ConsumerState<PosOnboardingScreen> createState() => _PosOnboardingScreenState();
}

class _PosOnboardingScreenState extends ConsumerState<PosOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _givenName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _idNumber = TextEditingController();

  String _idType = 'NATIONAL_ID';
  bool _loadingStatus = true;
  bool _uploading = false;
  bool _submitting = false;
  bool _alreadyComplete = false;
  String? _error;
  final List<_UploadedDocument> _uploadedDocs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatus();
      _prefillProfile();
    });
  }

  @override
  void dispose() {
    _givenName.dispose();
    _lastName.dispose();
    _email.dispose();
    _mobile.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  Future<void> _prefillProfile() async {
    final profile = await ref.read(merchantAuthServiceProvider).readProfile();
    if (!mounted) return;
    _givenName.text = profile['givenName']?.toString() ?? '';
    _lastName.text = profile['lastName']?.toString() ?? '';
    _email.text = profile['email']?.toString() ?? '';
    _mobile.text = profile['username']?.toString() ?? '';
    setState(() {});
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loadingStatus = true;
      _error = null;
    });
    try {
      final auth = ref.read(merchantAuthServiceProvider);
      final token = await auth.readToken();
      if (token == null || token.isEmpty) {
        throw const ApiException('Not signed in');
      }
      final status = await ref.read(merchantApiClientProvider).onboardingStatus(token);
      if (!mounted) return;
      final simulation = status['simulationMode'] == true;
      setState(() {
        _alreadyComplete = !simulation;
        _loadingStatus = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingStatus = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingStatus = false;
      });
    }
  }

  Future<void> _pickAndUploadDocuments() async {
    final auth = ref.read(merchantAuthServiceProvider);
    final api = ref.read(merchantApiClientProvider);
    final token = await auth.readToken();
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Not signed in');
      return;
    }

    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        final uploaded = await api.uploadOnboardingDocument(token, base64Encode(bytes));
        final uploadString = uploaded['uploadString']?.toString().trim();
        if (uploadString == null || uploadString.isEmpty) {
          throw const ApiException('Upload returned no reference');
        }
        _uploadedDocs.add(_UploadedDocument(
          fileName: file.name,
          uploadString: uploadString,
        ));
      }
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedDocs.isEmpty) {
      setState(() => _error = 'Upload at least one document image');
      return;
    }

    final auth = ref.read(merchantAuthServiceProvider);
    final api = ref.read(merchantApiClientProvider);
    final token = await auth.readToken();
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Not signed in');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final profile = <String, dynamic>{
        if (_givenName.text.trim().isNotEmpty) 'givenName': _givenName.text.trim(),
        if (_lastName.text.trim().isNotEmpty) 'lastName': _lastName.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        if (_mobile.text.trim().isNotEmpty) 'mobileNo': _mobile.text.trim(),
        if (_idType == 'NATIONAL_ID' && _idNumber.text.trim().isNotEmpty)
          'nationalID': _idNumber.text.trim(),
        if (_idType == 'PASSPORT' && _idNumber.text.trim().isNotEmpty)
          'passportNo': _idNumber.text.trim(),
      };

      await api.completeOnboarding(
        token,
        idType: _idType,
        profile: profile,
        uploadRefs: _uploadedDocs.map((d) => d.uploadString).toList(),
      );
      await auth.refreshProfile();
      ref.invalidate(merchantProfileProvider);
      ref.invalidate(merchantCatalogProvider);
      if (!mounted) return;
      context.go('/pos/home');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          'Complete registration',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
        ),
      ),
      body: _loadingStatus
          ? const Center(child: UffLoader())
          : _alreadyComplete
              ? _AlreadyCompleteBody(colors: colors)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Submit your business identity and documents to activate your merchant account.',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _idType,
                          decoration: uffInputDecoration(context, label: 'ID type'),
                          items: const [
                            DropdownMenuItem(value: 'NATIONAL_ID', child: Text('National ID')),
                            DropdownMenuItem(value: 'PASSPORT', child: Text('Passport')),
                          ],
                          onChanged: _submitting || _uploading
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() => _idType = value);
                                },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _givenName,
                          textInputAction: TextInputAction.next,
                          decoration: uffInputDecoration(context, label: 'First name'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _lastName,
                          textInputAction: TextInputAction.next,
                          decoration: uffInputDecoration(context, label: 'Last name'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: uffInputDecoration(context, label: 'Email'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _mobile,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: uffInputDecoration(
                            context,
                            label: 'Mobile number',
                            placeholder: 'Defaults to your login phone if empty',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _idNumber,
                          textInputAction: TextInputAction.done,
                          decoration: uffInputDecoration(
                            context,
                            label: _idType == 'PASSPORT' ? 'Passport number' : 'National ID',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Document images',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'National ID: front, back, selfie. Passport: passport page, selfie.',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12.5,
                            height: 1.4,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: (_submitting || _uploading) ? null : _pickAndUploadDocuments,
                          icon: _uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: UffLoader(size: 16),
                                )
                              : const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(_uploading ? 'Uploading…' : 'Add document photos'),
                        ),
                        if (_uploadedDocs.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ..._uploadedDocs.map(
                            (doc) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 18, color: colors.secondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${doc.fileName} — ${doc.uploadString}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 12,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          DbErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: (_submitting || _uploading) ? null : _submit,
                          child: _submitting
                              ? const UffLoader(size: 22, color: Colors.white)
                              : const Text(
                                  'Submit and activate',
                                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _AlreadyCompleteBody extends StatelessWidget {
  const _AlreadyCompleteBody({required this.colors});

  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: 48, color: colors.secondary),
            const SizedBox(height: 16),
            Text(
              'Your merchant account is already activated.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/pos/home'),
              child: const Text('Back to POS', style: TextStyle(fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }
}
