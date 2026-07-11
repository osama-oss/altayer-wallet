import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/report_filter.dart';
import 'data/report_models.dart';

/// Currently-selected direction tab (All / Sent / Received / Fees).
final reportDirectionProvider =
    StateProvider<ReportDirection>((ref) => ReportDirection.all);

/// Active filter-sheet criteria. Reset to [ReportFilter.initial] on demand.
final reportFilterProvider =
    StateProvider<ReportFilter>((ref) => ReportFilter.initial());

/// Raw ledger source. Backed by mock data today; swap for a `FutureProvider`
/// bound to the reports API when it becomes available — nothing downstream
/// needs to change beyond awaiting the result.
final reportEntriesProvider =
    Provider<List<ReportEntry>>((ref) => mockReportEntries());

/// The ledger after applying both the direction tab and the filter sheet,
/// sorted newest-first.
final filteredReportEntriesProvider = Provider<List<ReportEntry>>((ref) {
  final entries = ref.watch(reportEntriesProvider);
  final direction = ref.watch(reportDirectionProvider);
  final filter = ref.watch(reportFilterProvider);

  final result = entries.where((e) {
    if (direction != ReportDirection.all && e.direction != direction) {
      return false;
    }
    return filter.matches(e);
  }).toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  return result;
});
