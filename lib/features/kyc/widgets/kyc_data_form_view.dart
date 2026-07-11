import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/uff_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../kyc_document.dart';
import '../kyc_form_data.dart';
import '../kyc_providers.dart';
import 'kyc_id_scan_screen.dart';
import 'kyc_id_type_selector.dart';

/// Step 1 of account verification: the customer confirms the details printed on
/// their identity document plus their residence, then continues to the document
/// capture step. Nothing is submitted here — the collected [KycFormData] is
/// handed back through [onContinue]; the parent [KycFlow] carries it to submit.
class KycDataFormView extends ConsumerStatefulWidget {
  const KycDataFormView({
    super.key,
    required this.initialIdType,
    required this.initialData,
    required this.onContinue,
  });

  final KycIdType initialIdType;
  final KycFormData initialData;
  final void Function(KycIdType idType, KycFormData data) onContinue;

  @override
  ConsumerState<KycDataFormView> createState() => _KycDataFormViewState();
}

class _KycDataFormViewState extends ConsumerState<KycDataFormView> {
  final _formKey = GlobalKey<FormState>();

  late KycIdType _idType;
  late final TextEditingController _documentNumber;
  late final TextEditingController _issuingAuthority;
  late final TextEditingController _placeOfBirth;
  late final TextEditingController _country;
  late final TextEditingController _city;
  late final TextEditingController _district;
  late final TextEditingController _region;
  late final TextEditingController _address;

  DateTime? _issueDate;
  DateTime? _expiryDate;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _idType = widget.initialIdType;
    _documentNumber = TextEditingController(text: d.documentNumber);
    _issuingAuthority = TextEditingController(text: d.issuingAuthority);
    _placeOfBirth = TextEditingController(text: d.placeOfBirth);
    _country = TextEditingController(text: d.country);
    _city = TextEditingController(text: d.city);
    _district = TextEditingController(text: d.district);
    _region = TextEditingController(text: d.region);
    _address = TextEditingController(text: d.address);
    _issueDate = d.issueDate;
    _expiryDate = d.expiryDate;
    _dateOfBirth = d.dateOfBirth;
  }

  @override
  void dispose() {
    _documentNumber.dispose();
    _issuingAuthority.dispose();
    _placeOfBirth.dispose();
    _country.dispose();
    _city.dispose();
    _district.dispose();
    _region.dispose();
    _address.dispose();
    super.dispose();
  }

  KycFormData _collect() => KycFormData(
        documentNumber: _documentNumber.text,
        issuingAuthority: _issuingAuthority.text,
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        placeOfBirth: _placeOfBirth.text,
        dateOfBirth: _dateOfBirth,
        country: _country.text,
        city: _city.text,
        district: _district.text,
        region: _region.text,
        address: _address.text,
      );

  void _onContinue() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onContinue(_idType, _collect());
  }

  /// Opens the ID-barcode scanner and, on a successful read, fills the document
  /// number. The field stays fully editable so a failed scan never blocks manual
  /// entry.
  Future<void> _scanId() async {
    FocusScope.of(context).unfocus();
    final number = await openIdBarcodeScanScreen(context);
    if (!mounted || number == null || number.isEmpty) return;
    setState(() => _documentNumber.text = number);
  }

  Future<DateTime?> _pick({
    required DateTime? current,
    required DateTime first,
    required DateTime last,
    required DateTime fallback,
  }) {
    FocusScope.of(context).unfocus();
    final init = current ?? fallback;
    final clamped = init.isBefore(first)
        ? first
        : (init.isAfter(last) ? last : init);
    return showDatePicker(
      context: context,
      initialDate: clamped,
      firstDate: first,
      lastDate: last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPassport = _idType == KycIdType.passport;
    // Name + gender captured at sign-up — shown read-only (never editable here).
    final identity = ref.watch(registrationIdentityProvider).valueOrNull;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.kycDataIntro,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  KycIdTypeSelector(
                    value: _idType,
                    onChanged: (t) => setState(() => _idType = t),
                  ),
                  const SizedBox(height: 20),
                  UffSectionLabel(label: l10n.kycSectionIdentity),
                  const SizedBox(height: 14),
                  _TextField(
                    controller: _documentNumber,
                    label: isPassport
                        ? l10n.kycFieldPassportNumber
                        : l10n.kycFieldIdNumber,
                    keyboardType:
                        isPassport ? TextInputType.text : TextInputType.number,
                    onScan: _scanId,
                  ),
                  _TextField(
                    controller: _issuingAuthority,
                    label: l10n.kycFieldIssuingAuthority,
                  ),
                  _DateField(
                    label: l10n.kycFieldIssueDate,
                    initialValue: _issueDate,
                    pick: () => _pick(
                      current: _issueDate,
                      first: DateTime(1950),
                      last: today,
                      fallback: today,
                    ),
                    onChanged: (d) => setState(() => _issueDate = d),
                    validator: (v) => v == null ? l10n.kycFieldRequired : null,
                  ),
                  _DateField(
                    label: l10n.kycFieldExpiryDate,
                    initialValue: _expiryDate,
                    pick: () => _pick(
                      current: _expiryDate,
                      first: DateTime(1950),
                      last: DateTime(today.year + 30, today.month, today.day),
                      fallback: today,
                    ),
                    onChanged: (d) => setState(() => _expiryDate = d),
                    validator: (v) {
                      if (v == null) return l10n.kycFieldRequired;
                      if (_issueDate != null && !v.isAfter(_issueDate!)) {
                        return l10n.kycFieldExpiryBeforeIssue;
                      }
                      return null;
                    },
                  ),
                  _TextField(
                    controller: _placeOfBirth,
                    label: l10n.kycFieldPlaceOfBirth,
                    required: false,
                  ),
                  _DateField(
                    label: l10n.kycFieldDateOfBirth,
                    initialValue: _dateOfBirth,
                    pick: () => _pick(
                      current: _dateOfBirth,
                      first: DateTime(1900),
                      last: today,
                      fallback: DateTime(2000),
                    ),
                    onChanged: (d) => setState(() => _dateOfBirth = d),
                    validator: (v) => v == null ? l10n.kycFieldRequired : null,
                  ),
                  const SizedBox(height: 8),
                  UffSectionLabel(label: l10n.kycSectionResidence),
                  const SizedBox(height: 14),
                  // Free-text for now; these become backend-driven cascading
                  // dropdowns (country → city → district → region) once the
                  // location reference endpoint is wired — see KYC_BACKEND_PLAN.
                  _TextField(
                    controller: _country,
                    label: l10n.kycFieldCountry,
                    prefixIcon: Icons.public_rounded,
                  ),
                  _TextField(
                    controller: _city,
                    label: l10n.kycFieldCity,
                  ),
                  _TextField(
                    controller: _district,
                    label: l10n.kycFieldDistrict,
                    required: false,
                  ),
                  _TextField(
                    controller: _region,
                    label: l10n.kycFieldRegion,
                    required: false,
                  ),
                  _TextField(
                    controller: _address,
                    label: l10n.kycFieldAddress,
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: UffPrimaryButton(
                label: l10n.kycContinue,
                onPressed: _onContinue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Validated text field wearing the shared floating-label decoration, with a
/// constant-height error slot so a `required` message never nudges the field
/// below it.
class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.prefixIcon,
    this.required = true,
    this.maxLines = 1,
    this.onScan,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool required;
  final int maxLines;

  /// When set, a barcode-scan button is shown at the trailing edge; tapping it
  /// runs the ID scanner to fill this field.
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        style: AppTextStyles.bodyMd(color: colors.onSurface)
            .copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        decoration: uffInputDecoration(
          context,
          label: label,
          reserveErrorSpace: true,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: colors.outline, size: 20)
              : null,
          suffixIcon: onScan == null ? null : _ScanButton(onTap: onScan!),
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? l10n.kycFieldRequired : null
            : null,
      ),
    );
  }
}

/// The trailing barcode-scan affordance shown inside the ID-number field, in
/// the brand accent so it clearly reads as a tappable scan action.
class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return IconButton(
      onPressed: onTap,
      // AR-hardcoded to match the (Arabic-only) scanner screen; the surrounding
      // form is Arabic-first. Move to l10n if an English scanner is ever needed.
      tooltip: 'امسح الباركود',
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.qr_code_scanner_rounded,
          color: colors.secondary, size: 22),
    );
  }
}

/// A read-only, tappable field that opens a date picker. Backed by a
/// [FormField] so it validates inline with the rest of the [Form] and reserves
/// the same constant-height error slot as [_TextField].
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.initialValue,
    required this.pick,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final DateTime? initialValue;
  final Future<DateTime?> Function() pick;
  final ValueChanged<DateTime> onChanged;
  final FormFieldValidator<DateTime>? validator;

  static String _format(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FormField<DateTime>(
        initialValue: initialValue,
        validator: validator,
        builder: (state) {
          final value = state.value;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final picked = await pick();
              if (picked != null) {
                state.didChange(picked);
                onChanged(picked);
              }
            },
            child: InputDecorator(
              isEmpty: value == null,
              decoration: uffInputDecoration(
                context,
                label: label,
                placeholder: l10n.kycFieldSelectDate,
                errorText: state.errorText,
                reserveErrorSpace: true,
                prefixIcon: Icon(Icons.calendar_today_rounded,
                    color: colors.outline, size: 20),
              ),
              child: value == null
                  ? null
                  : Text(
                      _format(value),
                      style: AppTextStyles.bodyMd(color: colors.onSurface)
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
            ),
          );
        },
      ),
    );
  }
}
