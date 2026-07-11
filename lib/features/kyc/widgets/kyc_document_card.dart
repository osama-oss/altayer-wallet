import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/bank_sync_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../kyc_document.dart';

/// One document row in the capture flow. Shows an empty "tap to capture" state
/// or, once captured, a thumbnail with the upload lifecycle indicator.
class KycDocumentCard extends StatelessWidget {
  const KycDocumentCard({
    super.key,
    required this.document,
    required this.onTap,
  });

  final KycDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final captured = document.isCaptured;
    final accent = document.hasFailed ? colors.error : colors.secondary;

    return InkWell(
      onTap: document.isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: captured
              ? accent.withValues(alpha: 0.06)
              : colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: captured ? accent : colors.outlineVariant,
            width: 1.3,
          ),
        ),
        child: Row(
          children: [
            _Leading(document: document, accent: accent, colors: colors),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.type.label(l10n),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _Subtitle(document: document, colors: colors),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _Trailing(document: document, accent: accent, colors: colors),
          ],
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({
    required this.document,
    required this.accent,
    required this.colors,
  });

  final KycDocument document;
  final Color accent;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    final file = document.file;
    if (file != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(file.path),
          width: 54,
          height: 54,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(document.type.icon, color: colors.secondary, size: 26),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.document, required this.colors});

  final KycDocument document;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (String text, Color color) = switch (document.uploadState) {
      KycDocUploadState.uploaded => (l10n.kycUploaded, colors.accentGreen),
      KycDocUploadState.uploading => (l10n.kycUploading, colors.onSurfaceVariant),
      KycDocUploadState.failed => (l10n.kycUploadFailed, colors.error),
      KycDocUploadState.captured => (l10n.kycRetake, colors.onSurfaceVariant),
      null => (document.type.guide(l10n), colors.onSurfaceVariant),
    };
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.document,
    required this.accent,
    required this.colors,
  });

  final KycDocument document;
  final Color accent;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    switch (document.uploadState) {
      case KycDocUploadState.uploading:
        return SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: accent),
        );
      case KycDocUploadState.uploaded:
        return Icon(Icons.check_circle_rounded,
            color: colors.accentGreen, size: 24);
      case KycDocUploadState.failed:
        return Icon(Icons.error_rounded, color: colors.error, size: 24);
      case KycDocUploadState.captured:
        return Icon(Icons.edit_rounded, color: accent, size: 20);
      case null:
        return Icon(Icons.add_a_photo_outlined,
            color: colors.onSurfaceVariant, size: 22);
    }
  }
}
