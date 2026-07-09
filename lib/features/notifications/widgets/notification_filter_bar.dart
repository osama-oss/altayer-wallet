import 'package:flutter/material.dart';
import 'package:banksync_app/core/theme/bank_sync_colors.dart';
import 'package:banksync_app/l10n/app_localizations.dart';

class NotificationFilterBar extends StatelessWidget {
  const NotificationFilterBar({
    required this.selectedType,
    required this.onSelected,
    super.key,
  });

  final String? selectedType;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;

    final filters = [
      _FilterOption(label: l10n.filterAll, value: null),
      _FilterOption(label: l10n.notificationsTransfers, value: 'TRANSFER'),
      _FilterOption(label: l10n.notificationsSecurityAlerts, value: 'SECURITY'),
      _FilterOption(label: l10n.navPayments, value: 'BILL'),
      _FilterOption(label: l10n.notificationsComingSoon, value: 'OFFER'), // Fallback to "Coming soon" as placeholder
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedType == filter.value;

          return ChoiceChip(
            label: Text(
              filter.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colors.onPrimary : colors.onSurface,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                onSelected(filter.value);
              }
            },
            selectedColor: colors.secondaryContainer,
            backgroundColor: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
              color: isSelected ? colors.secondary : colors.outlineVariant,
              width: 1,
            ),
          );
        },
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({required this.label, this.value});
  final String label;
  final String? value;
}
