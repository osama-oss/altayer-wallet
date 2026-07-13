import 'package:flutter/foundation.dart';

import 'kyc_reference_data.dart';

/// The identity + residence details a customer confirms before the document
/// capture step of account verification.
///
/// This is purely a client-side draft: it is collected on the data-entry form
/// ([KycDataFormView]) and handed to [KycRepository.submit] via [toWire] so the
/// backend can persist it alongside the uploaded documents. The verification
/// backend is still pending — see
/// `mobile-service-scaffold/KYC_BACKEND_PLAN.md`. No business logic lives here;
/// the core validates and stores the values.
@immutable
class KycFormData {
  const KycFormData({
    this.documentNumber = '',
    this.nameOnId = '',
    this.issuingAuthority = '',
    this.issueCountry = '',
    this.issueDate,
    this.expiryDate,
    this.fullNameAr = '',
    this.fullNameEn = '',
    this.motherNameAr = '',
    this.motherNameEn = '',
    this.gender = '',
    this.maritalStatus,
    this.nationality = '',
    this.otherNationalities = false,
    this.sector = '1001',
    this.placeOfBirth = '',
    this.birthCountry = '',
    this.birthZone = '',
    this.dateOfBirth,
    this.country = '',
    this.city = '',
    this.district = '',
    this.region = '',
    this.address = '',
    this.peps = false,
  });

  // ── Identity document ───────────────────────────────────────────────────────
  /// National-ID or passport number, depending on the chosen identity type.
  final String documentNumber;

  /// The holder's name exactly as printed on the identity document
  /// (`documents[].nameOnID`). May differ from the registration name.
  final String nameOnId;
  final String issuingAuthority;

  /// ISO alpha-2 code of the country that issued the document
  /// (`documents[].legalIdIssueCountry`) — not necessarily the residence country.
  final String issueCountry;
  final DateTime? issueDate;
  final DateTime? expiryDate;

  // ── Personal ────────────────────────────────────────────────────────────────
  /// Full name in Arabic / English. The core requires both (`fullName.{ar,en}`).
  /// Collected via the bilingual names sheet on the KYC form.
  final String fullNameAr;
  final String fullNameEn;

  /// Mother's name in Arabic / English (`motherName.{ar,en}`), both required.
  final String motherNameAr;
  final String motherNameEn;

  /// 'male' | 'female' | '' — collected in this step. Keycloak has no attribute
  /// for gender, so registration no longer captures it; the customer confirms it
  /// here where it is submitted with the rest of the identity.
  final String gender;

  /// Marital status (`maritalStatus`); null until the customer picks one.
  final KycMaritalStatus? maritalStatus;

  /// ISO alpha-2 code of the primary nationality (`basicNationality`).
  final String nationality;

  /// Whether the customer holds any other nationalities (`otherNationalities`,
  /// emitted as `"Yes"`/`"No"`).
  final bool otherNationalities;

  /// Business sector id (WALLET_SECTOR, e.g. `"1001"`). Defaults to the
  /// personal-wallet sector; `subSector`/`industry` stay backend defaults.
  final String sector;

  // ── Birth ─────────────────────────────────────────────────────────────────
  /// City of birth (`birthCity`).
  final String placeOfBirth;

  /// ISO alpha-2 code of the country of birth (`birthCountry`).
  final String birthCountry;

  /// Governorate / zone of birth (`birthZone`).
  final String birthZone;
  final DateTime? dateOfBirth;

  // ── Residence ─────────────────────────────────────────────────────────────
  final String country;
  final String city;
  final String district;
  final String region;
  final String address;

  // ── Compliance ──────────────────────────────────────────────────────────────
  /// Politically-exposed-person flag (`peps`, emitted as `"Yes"`/`"No"`).
  /// `sector` / `subSector` / `industry` are not collected here — mobile-service
  /// supplies fixed personal-wallet defaults (see KYC_BACKEND_PLAN §11.5).
  final bool peps;

  KycFormData copyWith({
    String? documentNumber,
    String? nameOnId,
    String? issuingAuthority,
    String? issueCountry,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? fullNameAr,
    String? fullNameEn,
    String? motherNameAr,
    String? motherNameEn,
    String? gender,
    KycMaritalStatus? maritalStatus,
    String? nationality,
    bool? otherNationalities,
    String? sector,
    String? placeOfBirth,
    String? birthCountry,
    String? birthZone,
    DateTime? dateOfBirth,
    String? country,
    String? city,
    String? district,
    String? region,
    String? address,
    bool? peps,
  }) =>
      KycFormData(
        documentNumber: documentNumber ?? this.documentNumber,
        nameOnId: nameOnId ?? this.nameOnId,
        issuingAuthority: issuingAuthority ?? this.issuingAuthority,
        issueCountry: issueCountry ?? this.issueCountry,
        issueDate: issueDate ?? this.issueDate,
        expiryDate: expiryDate ?? this.expiryDate,
        fullNameAr: fullNameAr ?? this.fullNameAr,
        fullNameEn: fullNameEn ?? this.fullNameEn,
        motherNameAr: motherNameAr ?? this.motherNameAr,
        motherNameEn: motherNameEn ?? this.motherNameEn,
        gender: gender ?? this.gender,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        nationality: nationality ?? this.nationality,
        otherNationalities: otherNationalities ?? this.otherNationalities,
        sector: sector ?? this.sector,
        placeOfBirth: placeOfBirth ?? this.placeOfBirth,
        birthCountry: birthCountry ?? this.birthCountry,
        birthZone: birthZone ?? this.birthZone,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        country: country ?? this.country,
        city: city ?? this.city,
        district: district ?? this.district,
        region: region ?? this.region,
        address: address ?? this.address,
        peps: peps ?? this.peps,
      );

  /// Serialises this form into the **nested** `profile` object for the
  /// single-call `POST /api/mobile/kyc/onboard` endpoint.
  ///
  /// The backend's onboard orchestrator expects the profile structured as:
  /// ```json
  /// {
  ///   "fullName": { "ar": "...", "en": "..." },
  ///   "motherName": { "ar": "...", "en": "..." },
  ///   "documents": [{ "nameOnID": "...", "legalIdNumber": "...", ... }],
  ///   "gender": "male",
  ///   ...
  /// }
  /// ```
  ///
  /// The identity-document fields are nested inside `documents[0]`. Personal,
  /// birth, and compliance fields are top-level. FK pickers submit their resolved
  /// codes (countries as ISO alpha-2, marital status as the English enum).
  /// `sector`/`subSector`/`industry`/`residencyStatus` are mandatory in the core,
  /// so they are sent as personal-wallet defaults. `legalIdType` and
  /// registration-sourced `givenName`/`familyName`/`mobileNo`/`privateCode` are
  /// folded in by [KycRepository.createCustomer]. Dates are ISO-8601 date-only;
  /// empty text / unselected pickers are omitted.
  Map<String, dynamic> toWire() {
    final map = <String, dynamic>{};
    String? text(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    void put(String key, String? value) {
      if (value != null) map[key] = value;
    }

    // ── Identity document — nested inside `documents[0]` ──────────────────
    final doc = <String, dynamic>{};
    final nameOnID = text(nameOnId);
    if (nameOnID != null) doc['nameOnID'] = nameOnID;
    final legalIdNumber = text(documentNumber);
    if (legalIdNumber != null) doc['legalIdNumber'] = legalIdNumber;
    final authority = text(issuingAuthority);
    if (authority != null) doc['issueAuthority'] = authority;
    final issueCtry = text(issueCountry);
    if (issueCtry != null) doc['legalIdIssueCountry'] = issueCtry;
    if (issueDate != null) doc['legalIdIssuedDate'] = _isoDate(issueDate!);
    if (expiryDate != null) {
      doc['legalIdExpirationDate'] = _isoDate(expiryDate!);
    }
    // legalIdStatus: the core requires it; hardcoded to VALID for new submits.
    doc['legalIdStatus'] = 'VALID';
    if (doc.isNotEmpty) map['documents'] = [doc];

    // ── Personal ──────────────────────────────────────────────────────────
    final g = gender.trim().toLowerCase();
    if (g == 'male' || g == 'female') map['gender'] = g;

    // fullName / motherName as nested {ar, en} objects.
    final fnAr = text(fullNameAr);
    final fnEn = text(fullNameEn);
    if (fnAr != null || fnEn != null) {
      map['fullName'] = <String, dynamic>{
        if (fnAr != null) 'ar': fnAr,
        if (fnEn != null) 'en': fnEn,
      };
    }
    final mnAr = text(motherNameAr);
    final mnEn = text(motherNameEn);
    if (mnAr != null || mnEn != null) {
      map['motherName'] = <String, dynamic>{
        if (mnAr != null) 'ar': mnAr,
        if (mnEn != null) 'en': mnEn,
      };
    }

    if (maritalStatus != null) map['maritalStatus'] = maritalStatus!.code;
    put('basicNationality', text(nationality));
    // Booleans go to the core as "Yes"/"No" strings, matching the template.
    map['otherNationalities'] = otherNationalities ? 'Yes' : 'No';
    map['peps'] = peps ? 'Yes' : 'No';

    // ── Birth ─────────────────────────────────────────────────────────────
    if (dateOfBirth != null) map['dateOfBirth'] = _isoDate(dateOfBirth!);
    put('birthCity', text(placeOfBirth));
    put('birthCountry', text(birthCountry));
    put('birthZone', text(birthZone));

    // Mandatory group fields the core requires. `sector` is now picked from the
    // live WALLET_SECTOR list (defaults to Private "1001"); subSector/industry/
    // residencyStatus stay personal-wallet defaults until they get pickers too.
    map['sector'] = sector.trim().isEmpty ? '1001' : sector.trim();
    map['subSector'] = '1001';
    map['industry'] = '1001';
    map['residencyStatus'] = 'resident';

    return map;
  }

  static String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
