import 'package:flutter/material.dart';

import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';

/// Identity-verification (KYC) lifecycle for a wallet customer.
///
/// The authoritative value comes from the backend (`kycStatus` on the user
/// profile / `GET /api/mobile/kyc/status`). When the backend has not yet been
/// wired the app degrades to [unverified] — it never fabricates a verified or
/// pending state. See [KycStatusX.parse] for the string mapping.
enum KycStatus {
  /// No documents provided yet.
  unverified,

  /// The customer started but has not submitted all required documents.
  incomplete,

  /// Documents submitted and awaiting back-office review.
  pending,

  /// Identity confirmed — all wallet features active.
  verified,

  /// Review rejected — the customer must fix and resubmit.
  rejected,

  /// Reviewed and sent back for edits — the submission wasn't rejected, but the
  /// customer must correct specific details and resubmit.
  returned,
}

extension KycStatusX on KycStatus {
  /// Maps a backend status string (any casing / common synonyms) to a
  /// [KycStatus]. Unknown or empty values fall back to [KycStatus.unverified]
  /// so the UI fails safe (never shows "verified" for an unknown value).
  static KycStatus parse(Object? raw) {
    final value = raw?.toString().trim().toUpperCase();
    if (value == null || value.isEmpty) return KycStatus.unverified;
    switch (value) {
      case 'VERIFIED':
      case 'APPROVED':
      case 'ACTIVE':
        return KycStatus.verified;
      case 'PENDING':
      case 'SUBMITTED':
      case 'IN_REVIEW':
      case 'UNDER_REVIEW':
      case 'REVIEWING':
        return KycStatus.pending;
      case 'REJECTED':
      case 'DECLINED':
      case 'FAILED':
        return KycStatus.rejected;
      case 'RETURNED':
      case 'NEEDS_INFO':
      case 'NEEDS_EDIT':
      case 'MORE_INFO':
      case 'RESUBMIT':
      case 'ACTION_REQUIRED':
      case 'CHANGES_REQUESTED':
        return KycStatus.returned;
      case 'INCOMPLETE':
      case 'DRAFT':
      case 'STARTED':
        return KycStatus.incomplete;
      case 'UNVERIFIED':
      case 'NONE':
      case 'NOT_VERIFIED':
      case 'NEW':
        return KycStatus.unverified;
      default:
        return KycStatus.unverified;
    }
  }

  /// Wire value sent back to / stored by the backend.
  String get wireValue => switch (this) {
        KycStatus.unverified => 'UNVERIFIED',
        KycStatus.incomplete => 'INCOMPLETE',
        KycStatus.pending => 'PENDING',
        KycStatus.verified => 'VERIFIED',
        KycStatus.rejected => 'REJECTED',
        KycStatus.returned => 'RETURNED',
      };

  /// True when the customer can (re)start the capture flow.
  bool get canSubmit =>
      this == KycStatus.unverified ||
      this == KycStatus.incomplete ||
      this == KycStatus.rejected ||
      this == KycStatus.returned;

  bool get isVerified => this == KycStatus.verified;
  bool get isPending => this == KycStatus.pending;
  bool get isRejected => this == KycStatus.rejected;
  bool get isReturned => this == KycStatus.returned;

  /// Review states that carry a back-office note the customer should read
  /// (a rejection reason or a list of edits requested).
  bool get hasReviewNote =>
      this == KycStatus.rejected || this == KycStatus.returned;

  String title(AppLocalizations l10n) => switch (this) {
        KycStatus.unverified => l10n.kycStatusUnverifiedTitle,
        KycStatus.incomplete => l10n.kycStatusIncompleteTitle,
        KycStatus.pending => l10n.kycStatusPendingTitle,
        KycStatus.verified => l10n.kycStatusVerifiedTitle,
        KycStatus.rejected => l10n.kycStatusRejectedTitle,
        KycStatus.returned => l10n.kycStatusReturnedTitle,
      };

  String description(AppLocalizations l10n) => switch (this) {
        KycStatus.unverified => l10n.kycStatusUnverifiedDesc,
        KycStatus.incomplete => l10n.kycStatusIncompleteDesc,
        KycStatus.pending => l10n.kycStatusPendingDesc,
        KycStatus.verified => l10n.kycStatusVerifiedDesc,
        KycStatus.rejected => l10n.kycStatusRejectedDesc,
        KycStatus.returned => l10n.kycStatusReturnedDesc,
      };

  IconData get icon => switch (this) {
        KycStatus.unverified => Icons.gpp_maybe_outlined,
        KycStatus.incomplete => Icons.pending_actions_outlined,
        KycStatus.pending => Icons.hourglass_top_rounded,
        KycStatus.verified => Icons.verified_rounded,
        KycStatus.rejected => Icons.gpp_bad_outlined,
        KycStatus.returned => Icons.assignment_late_outlined,
      };

  /// Accent color for the status, drawn from the theme so it adapts to
  /// light/dark and stays on-brand.
  Color color(BankSyncColors colors) => switch (this) {
        KycStatus.unverified => colors.onSurfaceVariant,
        KycStatus.incomplete => colors.secondary,
        KycStatus.pending => colors.secondary,
        KycStatus.verified => colors.accentGreen,
        KycStatus.rejected => colors.error,
        KycStatus.returned => colors.warning,
      };
}

/// Full KYC snapshot returned by the backend. All fields except [status] are
/// optional metadata used by the result screens.
@immutable
class KycProfile {
  const KycProfile({
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });

  final KycStatus status;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  static const unverified = KycProfile(status: KycStatus.unverified);

  factory KycProfile.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(Object? v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString())?.toLocal();
    }

    final reason = map['rejectionReason']?.toString().trim();
    return KycProfile(
      status: KycStatusX.parse(map['status'] ?? map['kycStatus']),
      rejectionReason: (reason == null || reason.isEmpty) ? null : reason,
      submittedAt: parseDate(map['submittedAt']),
      reviewedAt: parseDate(map['reviewedAt']),
    );
  }

  /// Derives a KYC snapshot from the cached user profile (`userDetail`). This is
  /// the real source once the backend adds `kycStatus` to the profile payload;
  /// until then it resolves to [KycStatus.unverified].
  factory KycProfile.fromUserProfile(Map<String, dynamic>? profile) {
    if (profile == null) return unverified;
    return KycProfile(
      status: KycStatusX.parse(profile['kycStatus'] ?? profile['kyc_status']),
      rejectionReason:
          profile['kycRejectionReason']?.toString().trim().isEmpty ?? true
              ? null
              : profile['kycRejectionReason'].toString().trim(),
    );
  }

  KycProfile copyWith({KycStatus? status, String? rejectionReason}) => KycProfile(
        status: status ?? this.status,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        submittedAt: submittedAt,
        reviewedAt: reviewedAt,
      );
}
