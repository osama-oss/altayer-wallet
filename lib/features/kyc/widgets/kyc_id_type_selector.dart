import 'package:flutter/material.dart';

import '../../../core/theme/bank_sync_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../kyc_document.dart';

/// Two-option identity-type segmented control (national ID / passport). Drives
/// which document set the customer must capture, and which number label the
/// data-entry form shows. Shared by the KYC data form and the standalone
/// capture view so both read as one control.
class KycIdTypeSelector extends StatelessWidget {
  const KycIdTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final KycIdType value;
  final ValueChanged<KycIdType> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kycIdType,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              for (final type in KycIdType.values)
                Expanded(
                  child: _SegmentButton(
                    selected: value == type,
                    icon: type.icon,
                    label: type.label(l10n),
                    colors: colors,
                    onTap: () => onChanged(type),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final BankSyncColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? colors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? colors.onSecondary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color:
                      selected ? colors.onSecondary : colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
