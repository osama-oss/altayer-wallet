import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../kyc_document.dart';
import '../kyc_form_data.dart';
import '../kyc_providers.dart';
import '../kyc_repository.dart';
import '../kyc_status.dart';
import 'kyc_camera_screen.dart';
import 'kyc_document_card.dart';
import 'kyc_id_type_selector.dart';

/// The document-capture step: capture each document with the bespoke in-app
/// camera, review the set and submit for verification. Used for the unverified
/// / incomplete / rejected states.
///
/// Driven by [KycFlow] as the final step ([onBack] + [initialIdType] +
/// [formData] all supplied): the identity type is chosen on the preceding data
/// form, so the in-view type selector is hidden and the collected [formData] is
/// sent with the submit. When used standalone (none supplied) it shows its own
/// identity-type selector and behaves as a self-contained capture flow.
/// Where a document photo comes from: the bespoke in-app camera or the gallery.
enum _CaptureSource { camera, gallery }

class KycCaptureView extends ConsumerStatefulWidget {
  const KycCaptureView({
    super.key,
    required this.profile,
    required this.onSubmitted,
    this.initialIdType,
    this.formData,
    this.onBack,
  });

  final KycProfile profile;
  final ValueChanged<KycProfile> onSubmitted;

  /// Identity type chosen upstream. When null the view shows its own selector.
  final KycIdType? initialIdType;

  /// Identity + residence details collected on the data form, sent with submit.
  final KycFormData? formData;

  /// When provided, the view is a step in a larger flow: a "back" affordance
  /// returns to the previous step and the primary button confirms the account.
  final VoidCallback? onBack;

  @override
  ConsumerState<KycCaptureView> createState() => _KycCaptureViewState();
}

class _KycCaptureViewState extends ConsumerState<KycCaptureView> {
  late KycIdType _idType;
  late Map<KycDocType, KycDocument> _docs;
  bool _submitting = false;
  bool _submitted = false;

  /// True when this view is a step inside [KycFlow] rather than standalone.
  bool get _inFlow => widget.onBack != null;

  @override
  void initState() {
    super.initState();
    _idType = widget.initialIdType ?? KycIdType.nationalId;
    _docs = _freshDocs(_idType);
  }

  static Map<KycDocType, KycDocument> _freshDocs(KycIdType type) => {
        for (final t in type.documents) t: KycDocument(type: t),
      };

  List<KycDocType> get _types => _idType.documents;
  int get _capturedCount => _docs.values.where((d) => d.isCaptured).length;
  bool get _ready => _capturedCount == _types.length;

  @override
  void dispose() {
    // Drop any captured-but-not-submitted temp files so KYC images never
    // linger on disk after the user leaves.
    if (!_submitted) {
      for (final doc in _docs.values) {
        if (doc.file != null) _safeDelete(doc.file!.path);
      }
    }
    super.dispose();
  }

  // ── Identity type ───────────────────────────────────────────────────────
  void _selectIdType(KycIdType type) {
    if (type == _idType || _submitting) return;
    // Discard captures from the previous document set.
    for (final doc in _docs.values) {
      if (doc.file != null) _safeDelete(doc.file!.path);
    }
    setState(() {
      _idType = type;
      _docs = _freshDocs(type);
    });
  }

  // ── Capture ─────────────────────────────────────────────────────────────
  /// Lets the customer capture a document with the in-app camera or pick an
  /// existing photo from the gallery, then stores it in the [type] slot.
  Future<void> _addDocument(KycDocType type) async {
    final source = await _chooseSource();
    if (source == null || !mounted) return;

    final index = _types.indexOf(type);
    final file = source == _CaptureSource.camera
        ? await openKycCamera(
            context,
            docType: type,
            stepIndex: index + 1,
            stepCount: _types.length,
          )
        : await _pickFromGallery();
    if (file == null || !mounted) return;
    // Replace any prior capture for this slot.
    final previous = _docs[type]?.file;
    if (previous != null && previous.path != file.path) {
      _safeDelete(previous.path);
    }
    setState(() {
      _docs[type] = KycDocument(
        type: type,
        file: file,
        uploadState: KycDocUploadState.captured,
      );
    });
  }

  /// Bottom sheet to pick where the photo comes from. Returns null if dismissed.
  Future<_CaptureSource?> _chooseSource() {
    final colors = context.bankColors;
    final l10n = context.l10n;
    return showModalBottomSheet<_CaptureSource>(
      context: context,
      backgroundColor: colors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Widget option(IconData icon, String label, _CaptureSource value) =>
            ListTile(
              leading: Icon(icon, color: colors.secondary),
              title: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop(value),
            );
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.kycChooseSource,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
              option(Icons.photo_camera_outlined, l10n.kycCamera,
                  _CaptureSource.camera),
              option(Icons.photo_library_outlined, l10n.kycGallery,
                  _CaptureSource.gallery),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Picks an image from the gallery, downscaled and re-encoded so the base64
  /// payload stays small (the onboard call sends all photos inline in one JSON
  /// body — full-resolution originals would make it too large to upload).
  Future<XFile?> _pickFromGallery() async {
    try {
      return await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 72,
      );
    } catch (_) {
      if (mounted) _snack(context.l10n.kycSubmitFailed);
      return null;
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_ready || _submitting) return;
    final l10n = context.l10n;
    setState(() => _submitting = true);
    final repo = ref.read(kycRepositoryProvider);
    try {
      // Mark the captured set as in-flight: upload each photo for uploadString,
      // then submit profile + refs for WALLET_CUSTOMER_VALIDATE → CREATE.
      for (final type in _types) {
        setState(() => _docs[type] =
            _docs[type]!.copyWith(uploadState: KycDocUploadState.uploading));
      }
      final orderedDocuments = [for (final type in _types) _docs[type]!];
      final result = await repo.createCustomer(
        idType: _idType,
        formData: widget.formData ?? const KycFormData(),
        orderedDocuments: orderedDocuments,
      );
      _submitted = true;
      for (final type in _types) {
        setState(() => _docs[type] =
            _docs[type]!.copyWith(uploadState: KycDocUploadState.uploaded));
      }
      // Submitted successfully — remove the local temp copies.
      for (final doc in _docs.values) {
        if (doc.file != null) _safeDelete(doc.file!.path);
      }
      ref.read(kycStatusProvider.notifier).applyLocal(result);
      if (mounted) widget.onSubmitted(result);
    } on KycUnavailableException {
      if (mounted) _snack(l10n.kycServiceUnavailable);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack(l10n.kycSubmitFailed);
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          // On failure the whole submission is retried as one call, so clear the
          // in-flight state from the captured docs (nothing was persisted).
          if (!_submitted) {
            for (final type in _types) {
              if (_docs[type]!.isUploading) {
                _docs[type] = _docs[type]!
                    .copyWith(uploadState: KycDocUploadState.captured);
              }
            }
          }
        });
      }
    }
  }

  Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final total = _types.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.profile.status.hasReviewNote)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ReviewNoteBanner(
                        profile: widget.profile, colors: colors),
                  ),
                if (_inFlow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _FinalStepHeader(colors: colors),
                  )
                else ...[
                  Text(
                    l10n.kycDocsIntro,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  KycIdTypeSelector(
                    value: _idType,
                    onChanged: _selectIdType,
                  ),
                  const SizedBox(height: 18),
                ],
                _ProgressHeader(
                  captured: _capturedCount,
                  total: total,
                  colors: colors,
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _types.length; i++) ...[
                  KycDocumentCard(
                    document: _docs[_types[i]]!,
                    onTap: () => _addDocument(_types[i]),
                  ),
                  if (i != _types.length - 1) const SizedBox(height: 12),
                ],
                const SizedBox(height: 18),
                if (_ready)
                  Row(
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 16, color: colors.accentGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.kycAllReadyHint,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: colors.accentGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        _SubmitBar(
          enabled: _ready && !_submitting,
          submitting: _submitting,
          onSubmit: _submit,
          colors: colors,
          label: _inFlow ? l10n.kycConfirmAccount : l10n.kycSubmit,
          onBack: _submitting ? null : widget.onBack,
          backLabel: l10n.kycBack,
        ),
      ],
    );
  }
}

/// Header shown when the capture view runs as the final step of [KycFlow]: a
/// "final step" title over a short "attach your documents" subtitle, mirroring
/// the reference account-confirmation design.
class _FinalStepHeader extends StatelessWidget {
  const _FinalStepHeader({required this.colors});

  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kycFinalStepTitle,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.kycFinalStepSubtitle,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.captured,
    required this.total,
    required this.colors,
  });

  final int captured;
  final int total;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kycStepProgress(captured, total),
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : captured / total,
            minHeight: 6,
            backgroundColor: colors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation(colors.secondary),
          ),
        ),
      ],
    );
  }
}

class _ReviewNoteBanner extends StatelessWidget {
  const _ReviewNoteBanner({required this.profile, required this.colors});

  final KycProfile profile;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = profile.status;
    final color = status.color(colors);
    final headline =
        status.isReturned ? l10n.kycReturnedHeadline : l10n.kycRejectedHeadline;
    final fallbackBody = status.isReturned
        ? l10n.kycReturnedBody
        : l10n.kycStatusRejectedDesc;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(status.icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.rejectionReason ?? fallbackBody,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.enabled,
    required this.submitting,
    required this.onSubmit,
    required this.colors,
    required this.label,
    this.onBack,
    this.backLabel,
  });

  final bool enabled;
  final bool submitting;
  final VoidCallback onSubmit;
  final BankSyncColors colors;
  final String label;

  /// When provided (flow mode), an outlined "back" button is shown beneath the
  /// primary so the customer can return to edit their details.
  final VoidCallback? onBack;
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton(
                onPressed: enabled ? onSubmit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.secondary,
                  foregroundColor: colors.onSecondary,
                  disabledBackgroundColor:
                      colors.secondary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: submitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: colors.onSecondary,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            if (onBack != null && backLabel != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurface,
                    side: BorderSide(color: colors.outlineVariant, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    backLabel!,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
