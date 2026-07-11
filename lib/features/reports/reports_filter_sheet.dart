import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bank_sync_colors.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'data/report_filter.dart';
import 'data/report_models.dart';
import 'reports_providers.dart';
import 'widgets/report_segmented_tabs.dart';

/// Opens the reports filter sheet. On confirm it writes the edited criteria into
/// [reportFilterProvider]; export actions are stubbed until the backend lands.
Future<void> showReportsFilterSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context,
    isScrollControlled: true,
    title: context.l10n.reportsFilterTitle,
    icon: Icons.tune_rounded,
    child: const _ReportsFilterSheet(),
  );
}

class _ReportsFilterSheet extends ConsumerStatefulWidget {
  const _ReportsFilterSheet();

  @override
  ConsumerState<_ReportsFilterSheet> createState() =>
      _ReportsFilterSheetState();
}

class _ReportsFilterSheetState extends ConsumerState<_ReportsFilterSheet> {
  late Set<ReportCurrency> _currencies;
  late ReportOperationType _operationType;
  late DateTime _fromDate;
  late DateTime _toDate;
  final _phoneCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final f = ref.read(reportFilterProvider);
    _currencies = {...f.currencies};
    _operationType = f.operationType;
    _fromDate = f.fromDate;
    _toDate = f.toDate;
    _phoneCtrl.text = f.phone;
    _purposeCtrl.text = f.purpose;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  void _toggleCurrency(ReportCurrency c) {
    setState(() {
      if (!_currencies.remove(c)) _currencies.add(c);
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
      } else {
        _toDate = picked;
        if (_fromDate.isAfter(_toDate)) _fromDate = _toDate;
      }
    });
  }

  void _reset() {
    final initial = ReportFilter.initial();
    setState(() {
      _currencies = {...initial.currencies};
      _operationType = initial.operationType;
      _fromDate = initial.fromDate;
      _toDate = initial.toDate;
      _phoneCtrl.text = initial.phone;
      _purposeCtrl.text = initial.purpose;
    });
  }

  void _confirm() {
    ref.read(reportFilterProvider.notifier).state = ReportFilter(
      currencies: {..._currencies},
      phone: _phoneCtrl.text.trim(),
      operationType: _operationType,
      fromDate: _fromDate,
      toDate: _toDate,
      purpose: _purposeCtrl.text.trim(),
    );
    Navigator.of(context).pop();
  }

  void _export(String format) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.reportsExportComingSoon)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reset action.
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.reportsReset),
                ),
              ),
              const SizedBox(height: 4),

              // ── Currency chips ──
              _FieldLabel(l10n.reportsFilterCurrency),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in ReportCurrency.values)
                    ReportChoiceChip(
                      label: c.label(l10n),
                      selected: _currencies.contains(c),
                      onTap: () => _toggleCurrency(c),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Operation type + phone (side-by-side, stacks when narrow) ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final typeField = _OperationTypeField(
                    value: _operationType,
                    onChanged: (v) => setState(() => _operationType = v),
                  );
                  final phoneField = TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.reportsFilterPhoneHint,
                      prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                    ),
                  );
                  if (constraints.maxWidth >= 340) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: typeField),
                        const SizedBox(width: 12),
                        Expanded(child: phoneField),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      typeField,
                      const SizedBox(height: 12),
                      phoneField,
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              _OrDivider(label: l10n.reportsFilterOr),
              const SizedBox(height: 18),

              // ── Date range ──
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: l10n.reportsFilterFromDate,
                      value: _fromDate,
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: l10n.reportsFilterToDate,
                      value: _toDate,
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Purpose ──
              TextField(
                controller: _purposeCtrl,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.reportsFilterPurposeHint,
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 24),

              // ── Actions ──
              FilledButton(
                onPressed: _confirm,
                child: Text(l10n.reportsApply),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ExportButton(
                      label: 'EXCEL',
                      color: colors.success,
                      onTap: () => _export('EXCEL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ExportButton(
                      label: 'PDF',
                      color: colors.error,
                      onTap: () => _export('PDF'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    return Text(
      text,
      style: AppTextStyles.labelSm(color: colors.onSurface, languageCode: lang)
          .copyWith(fontWeight: FontWeight.w700),
    );
  }
}

/// A themed dropdown for the operation-type selector, matching the app's input
/// fields (floating label, brand focus border, wallet prefix icon).
class _OperationTypeField extends StatelessWidget {
  const _OperationTypeField({required this.value, required this.onChanged});

  final ReportOperationType value;
  final ValueChanged<ReportOperationType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    return DropdownButtonFormField<ReportOperationType>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.secondary),
      decoration: InputDecoration(
        labelText: l10n.reportsFilterOperationType,
        prefixIcon:
            const Icon(Icons.account_balance_wallet_rounded, size: 20),
      ),
      items: [
        for (final t in ReportOperationType.values)
          DropdownMenuItem(value: t, child: Text(t.label(l10n))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// A read-only, tap-to-open date field styled like the app's text inputs.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusField),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon:
              Icon(Icons.calendar_today_rounded, size: 18, color: colors.secondary),
        ),
        child: Text(
          DateFormat('yyyy-MM-dd').format(value),
          textDirection: TextDirection.ltr,
          style: AppTextStyles.bodyMd(color: colors.onSurface, languageCode: lang)
              .copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

/// Centred "or" divider (أو) matching the reference sheet's separator line.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final lang = Localizations.localeOf(context).languageCode;
    final line = Expanded(
      child: Divider(color: colors.outlineVariant, thickness: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: AppTextStyles.labelSm(
              color: colors.onSurfaceVariant,
              languageCode: lang,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        line,
      ],
    );
  }
}

/// Outlined export button (EXCEL / PDF) with a download glyph in the given
/// accent colour.
class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.download_rounded, size: 18, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
