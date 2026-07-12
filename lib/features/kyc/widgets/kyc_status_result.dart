import 'package:flutter/material.dart';

import '../../../core/theme/bank_sync_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../kyc_status.dart';

/// Centered result screen shown for the terminal / waiting states
/// (verified, pending, rejected). The capture flow is rendered elsewhere.
class KycStatusResultView extends StatelessWidget {
  const KycStatusResultView({
    super.key,
    required this.profile,
    this.onPrimary,
    this.primaryLabel,
    this.onSecondary,
    this.secondaryLabel,
  });

  final KycProfile profile;
  final VoidCallback? onPrimary;
  final String? primaryLabel;
  final VoidCallback? onSecondary;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final status = profile.status;
    final color = status.color(colors);

    final (String headline, String body) = switch (status) {
      KycStatus.verified => (l10n.kycVerifiedHeadline, l10n.kycVerifiedBody),
      KycStatus.pending => (l10n.kycPendingHeadline, l10n.kycPendingBody),
      KycStatus.rejected =>
        (l10n.kycRejectedHeadline, status.description(l10n)),
      KycStatus.returned => (l10n.kycReturnedHeadline, l10n.kycReturnedBody),
      _ => (status.title(l10n), status.description(l10n)),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 108,
              height: 108,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(status.icon, size: 56, color: color),
            ),
            const SizedBox(height: 28),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14.5,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
            if (status.hasReviewNote && profile.rejectionReason != null) ...[
              const SizedBox(height: 20),
              _ReviewNote(
                reason: profile.rejectionReason!,
                status: status,
                colors: colors,
              ),
            ],
            const Spacer(),
            if (onPrimary != null && primaryLabel != null)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.secondary,
                    foregroundColor: colors.onSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    primaryLabel!,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            if (onSecondary != null && secondaryLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSecondary,
                child: Text(
                  secondaryLabel!,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
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

class _ReviewNote extends StatelessWidget {
  const _ReviewNote({
    required this.reason,
    required this.status,
    required this.colors,
  });

  final String reason;
  final KycStatus status;
  final BankSyncColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = status.color(colors);
    final label = status.isReturned
        ? l10n.kycReturnedReasonLabel
        : l10n.kycRejectionReasonLabel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
