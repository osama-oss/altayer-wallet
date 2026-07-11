import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';

/// Reusable equal-width segmented control used for the Reports direction tabs.
///
/// Renders each label as a rounded pill; the selected pill fills with the brand
/// secondary colour while the rest stay quiet outlined surfaces. Segments share
/// the row width equally and shrink their text gracefully, so it stays intact
/// from small phones to tablets in both LTR and RTL.
class ReportSegmentedTabs extends StatelessWidget {
  const ReportSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Segment(
              label: labels[i],
              selected: i == selectedIndex,
              onTap: () => onChanged(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? colors.secondary : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colors.secondary
                  : colors.secondary.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.secondary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyles.labelSm(
                color: selected ? colors.onSecondary : colors.secondary,
                languageCode: lang,
              ).copyWith(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded outlined chip used for the currency selectors in the filter sheet.
/// Selected chips fill with the brand secondary and show a check glyph, exactly
/// like the reference sheet's currency toggles.
class ReportChoiceChip extends StatelessWidget {
  const ReportChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppColors.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.secondary : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
            border: Border.all(
              color: selected
                  ? colors.secondary
                  : colors.secondary.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 16, color: colors.onSecondary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.labelSm(
                  color: selected ? colors.onSecondary : colors.secondary,
                  languageCode: lang,
                ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
