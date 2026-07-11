import 'package:camera/camera.dart' show XFile;
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The identity document the customer verifies with. A national ID needs both
/// sides; a passport needs only its data page. Both add a selfie.
enum KycIdType { nationalId, passport }

extension KycIdTypeX on KycIdType {
  /// Ordered documents required for this identity type (selfie always last).
  List<KycDocType> get documents => switch (this) {
        KycIdType.nationalId => const [
            KycDocType.idFront,
            KycDocType.idBack,
            KycDocType.selfie,
          ],
        KycIdType.passport => const [
            KycDocType.passport,
            KycDocType.selfie,
          ],
      };

  String get wireCode =>
      this == KycIdType.passport ? 'PASSPORT' : 'NATIONAL_ID';

  IconData get icon => this == KycIdType.passport
      ? Icons.book_outlined
      : Icons.badge_outlined;

  String label(AppLocalizations l10n) => this == KycIdType.passport
      ? l10n.kycIdTypePassport
      : l10n.kycIdTypeNationalId;
}

/// The capture-frame geometry drawn over the live camera for a document.
enum KycFrameShape {
  /// ID-1 card ratio (~1.585:1, landscape).
  card,

  /// Passport data page (~1.42:1, landscape).
  passport,

  /// Portrait oval for a face selfie.
  faceOval,
}

/// A single capture within a verification session.
enum KycDocType { idFront, idBack, passport, selfie }

extension KycDocTypeX on KycDocType {
  /// Wire value expected by the upload endpoint (`type` multipart field).
  String get wireCode => switch (this) {
        KycDocType.idFront => 'ID_FRONT',
        KycDocType.idBack => 'ID_BACK',
        KycDocType.passport => 'PASSPORT',
        KycDocType.selfie => 'SELFIE',
      };

  /// Selfies use the front camera; every document uses the rear camera.
  bool get useFrontCamera => this == KycDocType.selfie;

  KycFrameShape get frameShape => switch (this) {
        KycDocType.idFront => KycFrameShape.card,
        KycDocType.idBack => KycFrameShape.card,
        KycDocType.passport => KycFrameShape.passport,
        KycDocType.selfie => KycFrameShape.faceOval,
      };

  IconData get icon => switch (this) {
        KycDocType.idFront => Icons.badge_outlined,
        KycDocType.idBack => Icons.badge_outlined,
        KycDocType.passport => Icons.book_outlined,
        KycDocType.selfie => Icons.face_retouching_natural_outlined,
      };

  String label(AppLocalizations l10n) => switch (this) {
        KycDocType.idFront => l10n.kycIdFront,
        KycDocType.idBack => l10n.kycIdBack,
        KycDocType.passport => l10n.kycPassport,
        KycDocType.selfie => l10n.kycSelfie,
      };

  String guide(AppLocalizations l10n) => switch (this) {
        KycDocType.idFront => l10n.kycIdFrontGuide,
        KycDocType.idBack => l10n.kycIdBackGuide,
        KycDocType.passport => l10n.kycPassportGuide,
        KycDocType.selfie => l10n.kycSelfieGuide,
      };
}

/// Per-document upload lifecycle within a capture session.
enum KycDocUploadState { captured, uploading, uploaded, failed }

/// A captured document plus its upload state. Immutable — the controller
/// replaces the instance on every transition.
@immutable
class KycDocument {
  const KycDocument({
    required this.type,
    this.file,
    this.uploadState,
    this.documentId,
  });

  final KycDocType type;

  /// The captured image on disk (from the in-app camera). Null until captured.
  final XFile? file;

  /// Null when not captured; otherwise the current upload lifecycle state.
  final KycDocUploadState? uploadState;

  /// Server-assigned id once the upload succeeds.
  final String? documentId;

  bool get isCaptured => file != null;
  bool get isUploaded => uploadState == KycDocUploadState.uploaded;
  bool get isUploading => uploadState == KycDocUploadState.uploading;
  bool get hasFailed => uploadState == KycDocUploadState.failed;

  KycDocument copyWith({
    XFile? file,
    KycDocUploadState? uploadState,
    String? documentId,
  }) =>
      KycDocument(
        type: type,
        file: file ?? this.file,
        uploadState: uploadState ?? this.uploadState,
        documentId: documentId ?? this.documentId,
      );
}
