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
        country: country ?? this.country,
        city: city ?? this.city,
        district: district ?? this.district,
        region: region ?? this.region,
        address: address ?? this.address,
      );

  /// Serialises the provided fields for the `POST /kyc/submit` payload. Dates
  /// use ISO-8601 date-only (`yyyy-MM-dd`); empty text fields are omitted so the
  /// server only ever sees what the customer actually entered.
  Map<String, dynamic> toWire() {
    final map = <String, dynamic>{};
    void putText(String key, String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) map[key] = trimmed;
    }

    void putDate(String key, DateTime? value) {
      if (value != null) map[key] = _isoDate(value);
    }

    putText('documentNumber', documentNumber);
    putText('issuingAuthority', issuingAuthority);
    putDate('issueDate', issueDate);
    putDate('expiryDate', expiryDate);
    putText('placeOfBirth', placeOfBirth);
    putDate('dateOfBirth', dateOfBirth);
    putText('country', country);
    putText('city', city);
    putText('district', district);
    putText('region', region);
    putText('address', address);
    return map;
  }

  static String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
