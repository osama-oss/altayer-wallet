import 'package:flutter/foundation.dart';

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
    this.issuingAuthority = '',
    this.issueDate,
    this.expiryDate,
    this.placeOfBirth = '',
    this.dateOfBirth,
    this.gender = '',
    this.country = '',
    this.city = '',
    this.district = '',
    this.region = '',
    this.address = '',
  });

  // ── Identity ──────────────────────────────────────────────────────────────
  /// National-ID or passport number, depending on the chosen identity type.
  final String documentNumber;
  final String issuingAuthority;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String placeOfBirth;
  final DateTime? dateOfBirth;

  /// 'male' | 'female' | '' — collected in this step. Keycloak has no attribute
  /// for gender, so registration no longer captures it; the customer confirms it
  /// here where it is submitted with the rest of the identity.
  final String gender;

  // ── Residence ─────────────────────────────────────────────────────────────
  final String country;
  final String city;
  final String district;
  final String region;
  final String address;

  KycFormData copyWith({
    String? documentNumber,
    String? issuingAuthority,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? placeOfBirth,
    DateTime? dateOfBirth,
    String? gender,
    String? country,
    String? city,
    String? district,
    String? region,
    String? address,
  }) =>
      KycFormData(
        documentNumber: documentNumber ?? this.documentNumber,
        issuingAuthority: issuingAuthority ?? this.issuingAuthority,
        issueDate: issueDate ?? this.issueDate,
        expiryDate: expiryDate ?? this.expiryDate,
        placeOfBirth: placeOfBirth ?? this.placeOfBirth,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        country: country ?? this.country,
        city: city ?? this.city,
        district: district ?? this.district,
        region: region ?? this.region,
        address: address ?? this.address,
      );

  /// Serialises this form into the `profile` object sent with `POST /kyc/submit`,
  /// shaped to line up with the wallet core's `WALLET_CUSTOMER_CREATE` contract so
  /// mobile-service can fold it into the customer-create call with minimal
  /// translation — see `mobile-service-scaffold/KYC_BACKEND_PLAN.md` §11.
  ///
  /// Only the identity-document + birth fields this form owns are emitted. The
  /// customer's name / mobile come from registration; gender is confirmed here
  /// (Keycloak has no attribute for it) and emitted as a single-letter `M`/`F`.
  /// The compliance and extra birth/nationality fields (peps, sector, motherName,
  /// nationality, birthCountry/Zone, …) are not collected yet — they are tracked
  /// as gaps in the plan. `documents[].legalIdType` is derived server-side from
  /// the separately-sent `idType`. Dates are ISO-8601 date-only (`yyyy-MM-dd`);
  /// empty text is omitted so the server only ever sees what the customer entered.
  Map<String, dynamic> toWire() {
    String? text(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    // documents[] — the legal-ID block of WALLET_CUSTOMER_CREATE.
    final document = <String, dynamic>{};
    void putDoc(String key, String? value) {
      if (value != null) document[key] = value;
    }

    putDoc('legalIdNumber', text(documentNumber));
    putDoc('issueAuthority', text(issuingAuthority));
    if (issueDate != null) document['legalIdIssueDate'] = _isoDate(issueDate!);
    if (expiryDate != null) {
      document['legalIdExpirationDate'] = _isoDate(expiryDate!);
    }

    final map = <String, dynamic>{};
    if (dateOfBirth != null) map['dateOfBirth'] = _isoDate(dateOfBirth!);
    // Provisional core mapping: WALLET_CUSTOMER_CREATE expects a single-letter
    // gender. Confirm the exact key/enum against the core contract when the KYC
    // backend lands (see KYC_BACKEND_PLAN §11).
    final genderCode = switch (gender.trim().toLowerCase()) {
      'male' => 'M',
      'female' => 'F',
      _ => null,
    };
    if (genderCode != null) map['gender'] = genderCode;
    // Provisional: the form's single "place of birth" seeds birthCity; the core
    // also wants birthCountry + birthZone, which aren't collected yet (§11).
    final birthCity = text(placeOfBirth);
    if (birthCity != null) map['birthCity'] = birthCity;
    if (document.isNotEmpty) map['documents'] = [document];

    // Residence is collected here but is NOT part of WALLET_CUSTOMER_CREATE; the
    // KYC service keeps it on the local verification record. Nested so it can
    // never leak into the core customer body.
    final residence = <String, dynamic>{};
    void putRes(String key, String? value) {
      if (value != null) residence[key] = value;
    }

    putRes('country', text(country));
    putRes('city', text(city));
    putRes('district', text(district));
    putRes('region', text(region));
    putRes('address', text(address));
    if (residence.isNotEmpty) map['residence'] = residence;

    return map;
  }

  static String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
