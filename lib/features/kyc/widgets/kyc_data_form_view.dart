import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/bank_sync_colors.dart';
import '../../../core/widgets/uff_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../kyc_document.dart';
import '../kyc_form_data.dart';
import '../kyc_providers.dart';
import '../kyc_reference_data.dart';
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
  late final TextEditingController _fullNameAr;
  late final TextEditingController _fullNameEn;
  late final TextEditingController _motherNameAr;
  late final TextEditingController _motherNameEn;
  late final TextEditingController _placeOfBirth;
  late final TextEditingController _birthZone;
  late final TextEditingController _country;
  late final TextEditingController _city;
  late final TextEditingController _district;
  late final TextEditingController _region;
  late final TextEditingController _address;

  DateTime? _issueDate;
  DateTime? _expiryDate;
  DateTime? _dateOfBirth;

  // Country / sector selections are stored as codes; the display object is
  // resolved from the live (or fallback) list in build, so an async reload of
  // the reference lists never invalidates the selection.
  String? _issueCountryCode;
  String? _nationalityCode;
  String? _birthCountryCode;
  String? _sectorCode;
  KycMaritalStatus? _maritalStatus;
  bool _otherNationalities = false;
  bool _peps = false;

  /// 'male' | 'female' | null. Collected here (registration no longer captures
  /// gender because Keycloak has no attribute for it).
  String? _gender;

  /// Inline validation message shown under the gender selector, since it is not
  /// a [TextFormField] and so is not covered by [Form.validate].
  String? _genderError;

  /// Inline validation message shown under the names card (the four bilingual
  /// name fields live in a bottom sheet, so they aren't covered by [Form.validate]).
  String? _namesError;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _idType = widget.initialIdType;
    _documentNumber = TextEditingController(text: d.documentNumber);
    _issuingAuthority = TextEditingController(text: d.issuingAuthority);
    _fullNameAr = TextEditingController(text: d.fullNameAr);
    _fullNameEn = TextEditingController(text: d.fullNameEn);
    _motherNameAr = TextEditingController(text: d.motherNameAr);
    _motherNameEn = TextEditingController(text: d.motherNameEn);
    _placeOfBirth = TextEditingController(text: d.placeOfBirth);
    _birthZone = TextEditingController(text: d.birthZone);
    _country = TextEditingController(text: d.country);
    _city = TextEditingController(text: d.city);
    _district = TextEditingController(text: d.district);
    _region = TextEditingController(text: d.region);
    _address = TextEditingController(text: d.address);
    _issueDate = d.issueDate;
    _expiryDate = d.expiryDate;
    _dateOfBirth = d.dateOfBirth;
    _issueCountryCode = d.issueCountry.isEmpty ? null : d.issueCountry;
    _nationalityCode = d.nationality.isEmpty ? null : d.nationality;
    _birthCountryCode = d.birthCountry.isEmpty ? null : d.birthCountry;
    _sectorCode = d.sector.isEmpty ? null : d.sector;
    _maritalStatus = d.maritalStatus;
    _otherNationalities = d.otherNationalities;
    _peps = d.peps;
    _gender = d.gender.isEmpty ? null : d.gender;
  }

  /// Resolves a stored code to its option instance in the current (live or
  /// fallback) list, so the dropdown value always matches an item.
  KycCountry? _findCountry(List<KycCountry> list, String? code) {
    if (code == null || code.isEmpty) return null;
    for (final c in list) {
      if (c.code == code) return c;
    }
    return null;
  }

  KycSector? _findSector(List<KycSector> list, String? code) {
    if (code == null || code.isEmpty) return null;
    for (final s in list) {
      if (s.code == code) return s;
    }
    return null;
  }

  @override
  void dispose() {
    _documentNumber.dispose();
    _issuingAuthority.dispose();
    _fullNameAr.dispose();
    _fullNameEn.dispose();
    _motherNameAr.dispose();
    _motherNameEn.dispose();
    _placeOfBirth.dispose();
    _birthZone.dispose();
    _country.dispose();
    _city.dispose();
    _district.dispose();
    _region.dispose();
    _address.dispose();
    super.dispose();
  }

  KycFormData _collect() => KycFormData(
        documentNumber: _documentNumber.text,
        // Name-on-ID mirrors the full name (Arabic preferred) — no separate input.
        nameOnId: _fullNameAr.text.trim().isNotEmpty
            ? _fullNameAr.text
            : _fullNameEn.text,
        issuingAuthority: _issuingAuthority.text,
        issueCountry: _issueCountryCode ?? '',
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        fullNameAr: _fullNameAr.text,
        fullNameEn: _fullNameEn.text,
        motherNameAr: _motherNameAr.text,
        motherNameEn: _motherNameEn.text,
        gender: _gender ?? '',
        maritalStatus: _maritalStatus,
        nationality: _nationalityCode ?? '',
        otherNationalities: _otherNationalities,
        sector: _sectorCode ?? '1001',
        placeOfBirth: _placeOfBirth.text,
        birthCountry: _birthCountryCode ?? '',
        birthZone: _birthZone.text,
        dateOfBirth: _dateOfBirth,
        country: _country.text,
        city: _city.text,
        district: _district.text,
        region: _region.text,
        address: _address.text,
        peps: _peps,
      );

  bool get _namesComplete =>
      _fullNameAr.text.trim().isNotEmpty &&
      _fullNameEn.text.trim().isNotEmpty &&
      _motherNameAr.text.trim().isNotEmpty &&
      _motherNameEn.text.trim().isNotEmpty;

  void _onContinue() {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState?.validate() ?? false;
    // The gender selector and the bilingual names card aren't form fields, so
    // validate them manually.
    final genderMissing = _gender == null;
    if (genderMissing) {
      setState(() => _genderError = context.l10n.kycFieldRequired);
    }
    final namesMissing = !_namesComplete;
    if (namesMissing) {
      setState(() => _namesError = context.l10n.kycNamesRequired);
    }
    if (!formOk || genderMissing || namesMissing) return;
    widget.onContinue(_idType, _collect());
  }

  /// Opens the bilingual names sheet (Arabic / English tabs, Full name + Mother's
  /// name each). Edits the shared controllers, so values persist on close.
  Future<void> _openNamesSheet() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NamesSheet(
        fullNameAr: _fullNameAr,
        fullNameEn: _fullNameEn,
        motherNameAr: _motherNameAr,
        motherNameEn: _motherNameEn,
      ),
    );
    if (mounted) {
      setState(() {
        if (_namesComplete) _namesError = null;
      });
    }
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

  void _fillMockData() {
    setState(() {
      _documentNumber.text = '1012345678';
      _issuingAuthority.text = 'مصلحة الأحوال المدنية';
      _fullNameAr.text = 'سمير شاهر عبدالكافي';
      _fullNameEn.text = 'Sameer Shaher Abdulkhafi';
      _motherNameAr.text = 'فاطمة أحمد محمد';
      _motherNameEn.text = 'Fatima Ahmed Mohamed';
      _placeOfBirth.text = 'صنعاء';
      _birthZone.text = 'الأمانة';
      _country.text = 'اليمن';
      _city.text = 'صنعاء';
      _district.text = 'معين';
      _region.text = 'الدائري';
      _address.text = 'شارع الدائري الغربي';
      _issueDate = DateTime(2023, 5, 12);
      _expiryDate = DateTime(2029, 5, 12);
      _dateOfBirth = DateTime(1995, 8, 20);
      _issueCountryCode = 'YE';
      _nationalityCode = 'YE';
      _birthCountryCode = 'YE';
      _sectorCode = '1001';
      _maritalStatus = KycMaritalStatus.single;
      _otherNationalities = false;
      _peps = false;
      _gender = 'male';
      _genderError = null;
      _namesError = null;
    });
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    // Live reference lists (WALLET_COUNTRY / WALLET_SECTOR); fall back to the
    // local lists while loading / on error so the pickers always have options.
    final countries = ref.watch(kycCountriesProvider).valueOrNull ?? kycCountries;
    final sectors =
        ref.watch(kycSectorsProvider).valueOrNull ?? kycSectorsFallback;

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
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _fillMockData,
                      icon: Icon(Icons.auto_awesome_rounded, color: colors.secondary),
                      label: Text(
                        'تعبئة بيانات تجريبية (Mock)',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w800,
                          color: colors.secondary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.secondary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _NamesCard(
                    fullNameArabic: _fullNameAr.text,
                    motherNameArabic: _motherNameAr.text,
                    complete: _namesComplete,
                    errorText: _namesError,
                    onTap: _openNamesSheet,
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
                  // "Name as printed on ID" (nameOnID) is not a separate input —
                  // it is the same as the full name, so it's auto-filled from the
                  // Arabic full name on submit (see _collect).
                  _TextField(
                    controller: _issuingAuthority,
                    label: l10n.kycFieldIssuingAuthority,
                  ),
                  _DropdownField<KycCountry>(
                    label: l10n.kycFieldIssueCountry,
                    value: _findCountry(countries, _issueCountryCode),
                    items: countries,
                    labelBuilder: (c) => c.label(isArabic),
                    prefixIcon: Icons.public_rounded,
                    onChanged: (c) =>
                        setState(() => _issueCountryCode = c.code),
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
                  const SizedBox(height: 8),
                  UffSectionLabel(label: l10n.kycSectionPersonalInfo),
                  const SizedBox(height: 14),
                  _GenderSelector(
                    value: _gender,
                    errorText: _genderError,
                    onChanged: (g) => setState(() {
                      _gender = g;
                      _genderError = null;
                    }),
                  ),
                  _DropdownField<KycMaritalStatus>(
                    label: l10n.kycFieldMaritalStatus,
                    value: _maritalStatus,
                    items: KycMaritalStatus.values,
                    labelBuilder: (m) => m.label(l10n),
                    prefixIcon: Icons.favorite_outline_rounded,
                    onChanged: (m) => setState(() => _maritalStatus = m),
                  ),
                  _DropdownField<KycCountry>(
                    label: l10n.kycFieldNationality,
                    value: _findCountry(countries, _nationalityCode),
                    items: countries,
                    labelBuilder: (c) => c.label(isArabic),
                    prefixIcon: Icons.flag_outlined,
                    onChanged: (c) =>
                        setState(() => _nationalityCode = c.code),
                  ),
                  _DropdownField<KycSector>(
                    label: l10n.kycFieldSector,
                    value: _findSector(sectors, _sectorCode),
                    items: sectors,
                    labelBuilder: (s) => s.label(isArabic),
                    prefixIcon: Icons.work_outline_rounded,
                    onChanged: (s) => setState(() => _sectorCode = s.code),
                  ),
                  _YesNoField(
                    label: l10n.kycFieldOtherNationalities,
                    value: _otherNationalities,
                    onChanged: (v) => setState(() => _otherNationalities = v),
                  ),
                  const SizedBox(height: 8),
                  UffSectionLabel(label: l10n.kycSectionBirth),
                  const SizedBox(height: 14),
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
                  _TextField(
                    controller: _placeOfBirth,
                    label: l10n.kycFieldPlaceOfBirth,
                    required: false,
                  ),
                  _DropdownField<KycCountry>(
                    label: l10n.kycFieldBirthCountry,
                    value: _findCountry(countries, _birthCountryCode),
                    items: countries,
                    labelBuilder: (c) => c.label(isArabic),
                    prefixIcon: Icons.public_rounded,
                    onChanged: (c) =>
                        setState(() => _birthCountryCode = c.code),
                  ),
                  _TextField(
                    controller: _birthZone,
                    label: l10n.kycFieldBirthZone,
                    required: false,
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
                  const SizedBox(height: 8),
                  UffSectionLabel(label: l10n.kycSectionCompliance),
                  const SizedBox(height: 14),
                  _YesNoField(
                    label: l10n.kycFieldPeps,
                    value: _peps,
                    onChanged: (v) => setState(() => _peps = v),
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

/// A required dropdown wearing the shared floating-label decoration, matching
/// [_TextField]'s constant-height error slot. Shows a "Select" hint until the
/// customer picks a value; validates inline with the rest of the [Form].
class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.prefixIcon,
    this.required = true,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  final IconData? prefixIcon;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.outline),
        dropdownColor: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        style: AppTextStyles.bodyMd(color: colors.onSurface)
            .copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        hint: Text(
          l10n.kycSelectHint,
          style: AppTextStyles.bodyMd(color: colors.onSurfaceVariant),
        ),
        decoration: uffInputDecoration(
          context,
          label: label,
          reserveErrorSpace: true,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: colors.outline, size: 20)
              : null,
        ),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item, child: Text(labelBuilder(item))),
        ],
        validator: required
            ? (v) => v == null ? l10n.kycFieldRequired : null
            : null,
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }
}

/// A yes/no question rendered as two pills, mirroring [_GenderSelector]. Used
/// for the compliance toggles (other nationalities, PEP) which always carry a
/// value, so no inline validation is needed.
class _YesNoField extends StatelessWidget {
  const _YesNoField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.bankColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GenderOption(
                selected: value,
                label: l10n.kycYes,
                icon: Icons.check_rounded,
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderOption(
                selected: !value,
                label: l10n.kycNo,
                icon: Icons.close_rounded,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
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

/// Tappable card that opens the bilingual names sheet. Shows the Arabic full
/// name + mother's name once entered (English is kept in the background), or a
/// prompt to enter them. [errorText] surfaces the "required" message since the
/// fields live in a sheet, not the [Form].
class _NamesCard extends StatelessWidget {
  const _NamesCard({
    required this.fullNameArabic,
    required this.motherNameArabic,
    required this.complete,
    required this.onTap,
    this.errorText,
  });

  final String fullNameArabic;
  final String motherNameArabic;
  final bool complete;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    final hasError = errorText != null;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError ? colors.error : colors.outlineVariant,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.badge_outlined,
                      color: colors.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.kycNamesCardTitle,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        complete
                            ? '${fullNameArabic.trim()} · ${motherNameArabic.trim()}'
                            : l10n.kycNamesCardHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: complete
                              ? colors.onSurfaceVariant
                              : colors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (complete)
                  Icon(Icons.check_circle_rounded,
                      color: colors.accentGreen, size: 20)
                else
                  Text(
                    l10n.kycNamesCardAction,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: colors.secondary,
                    ),
                  ),
                Icon(
                  isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: colors.outline,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet with Arabic / English tabs; each tab has Full name + Mother's
/// name fields. Edits the shared controllers passed in, so the values persist
/// after the sheet closes.
class _NamesSheet extends StatefulWidget {
  const _NamesSheet({
    required this.fullNameAr,
    required this.fullNameEn,
    required this.motherNameAr,
    required this.motherNameEn,
  });

  final TextEditingController fullNameAr;
  final TextEditingController fullNameEn;
  final TextEditingController motherNameAr;
  final TextEditingController motherNameEn;

  @override
  State<_NamesSheet> createState() => _NamesSheetState();
}

class _NamesSheetState extends State<_NamesSheet> {
  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.kycNamesSheetTitle,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TabBar(
                labelColor: colors.secondary,
                unselectedLabelColor: colors.onSurfaceVariant,
                indicatorColor: colors.secondary,
                labelStyle: const TextStyle(
                    fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
                tabs: [
                  Tab(text: l10n.kycLangArabic),
                  Tab(text: l10n.kycLangEnglish),
                ],
              ),
              SizedBox(
                height: 210,
                child: TabBarView(
                  children: [
                    _tab(isArabic: true),
                    _tab(isArabic: false),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: UffPrimaryButton(
                    label: l10n.kycNamesSave,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab({required bool isArabic}) {
    final l10n = context.l10n;
    final dir = isArabic ? TextDirection.rtl : TextDirection.ltr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        children: [
          _field(
            controller: isArabic ? widget.fullNameAr : widget.fullNameEn,
            label: l10n.fullName,
            dir: dir,
          ),
          const SizedBox(height: 14),
          _field(
            controller: isArabic ? widget.motherNameAr : widget.motherNameEn,
            label: l10n.kycFieldMotherName,
            dir: dir,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required TextDirection dir,
  }) {
    final colors = context.bankColors;
    return TextField(
      controller: controller,
      textDirection: dir,
      textInputAction: TextInputAction.next,
      onChanged: (_) => setState(() {}),
      style: AppTextStyles.bodyMd(color: colors.onSurface)
          .copyWith(fontWeight: FontWeight.w600, fontSize: 16),
      decoration: uffInputDecoration(context, label: label),
    );
  }
}

/// Male/female selector for the KYC form. Registration no longer captures
/// gender (Keycloak has no attribute for it), so the customer chooses it here.
/// Mirrors the two-button style used elsewhere; [errorText] surfaces the
/// "required" message since this is not a [TextFormField].
class _GenderSelector extends StatelessWidget {
  const _GenderSelector({
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  /// 'male' | 'female' | null.
  final String? value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UffSectionLabel(label: l10n.gender),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GenderOption(
                selected: value == 'male',
                label: l10n.genderMale,
                icon: Icons.male_rounded,
                onTap: () => onChanged('male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderOption(
                selected: value == 'female',
                label: l10n.genderFemale,
                icon: Icons.female_rounded,
                onTap: () => onChanged('female'),
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.error,
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

/// A single male/female pill inside [_GenderSelector].
class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bankColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: selected ? colors.secondary : colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.secondary : colors.outlineVariant,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? colors.onSecondary : colors.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon,
                size: 20,
                color: selected ? colors.onSecondary : colors.onSurfaceVariant),
          ],
        ),
      ),
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
