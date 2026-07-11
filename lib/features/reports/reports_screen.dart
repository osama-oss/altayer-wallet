import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../l10n/app_localizations.dart';
import 'data/report_models.dart';
import 'reports_filter_sheet.dart';
import 'reports_providers.dart';
import 'widgets/report_entry_tile.dart';
import 'widgets/report_segmented_tabs.dart';
import 'widgets/reports_empty_state.dart';

/// Transaction-reports tab. Mirrors the reference design — a direction
/// segmented control, a scrollable ledger (or an empty state), and a floating
/// filter action that opens [showReportsFilterSheet] — all in the Ultimate
/// Wallet identity. Data is mock-backed today (see [reportEntriesProvider]) and
/// ready to bind to the reports API without UI changes.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final direction = ref.watch(reportDirectionProvider);
    final entries = ref.watch(filteredReportEntriesProvider);
    final hasActiveFilter =
        ref.watch(reportFilterProvider).hasActiveConstraints;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: ReportSegmentedTabs(
                labels: [
                  for (final d in ReportDirection.values) d.label(l10n),
                ],
                selectedIndex: direction.index,
                onChanged: (i) => ref
                    .read(reportDirectionProvider.notifier)
                    .state = ReportDirection.values[i],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: entries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: ReportsEmptyState(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) =>
                          ReportEntryTile(entry: entries[i]),
                    ),
            ),
          ],
        ),
        PositionedDirectional(
          end: 20,
          bottom: 20,
          child: _FilterFab(
            active: hasActiveFilter,
            onTap: () => showReportsFilterSheet(context),
          ),
        ),
      ],
    );
  }
}

/// Floating filter action — brand-gradient circle with a sliders glyph and a
/// small dot when a filter is active.
class _FilterFab extends StatelessWidget {
  const _FilterFab({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;

    return Semantics(
      button: true,
      label: context.l10n.reportsFilterTitle,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                  boxShadow: [
                    BoxShadow(
                      color: colors.secondary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              if (active)
                PositionedDirectional(
                  top: 2,
                  end: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors.accentGreen,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: colors.surfaceContainerLowest, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
