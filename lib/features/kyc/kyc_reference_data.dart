import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../l10n/app_localizations.dart';

/// Reference data for the KYC form's dropdown pickers.
///
/// Countries and sectors are fetched live from mobile-service (WALLET_COUNTRY /
/// WALLET_SECTOR) via `KycRepository.fetchCountries()` / `fetchSectors()`, with
/// the local lists below as a fallback while loading / on error. The submitted
/// value is always the reference **code** the core expects (countries as ISO
/// 3166-1 alpha-2 like `"YE"`; sectors as their id like `"1001"`; marital status
/// as the English enum like `"Single"`).
@immutable
class KycCountry {
  const KycCountry(this.code, this.en, this.ar);

  /// ISO 3166-1 alpha-2 code, sent to the core (e.g. `YE`).
  final String code;
  final String en;
  final String ar;

  /// Arabic name when available, else English (the live WALLET_COUNTRY list
  /// carries English names only — the Arabic name is enriched from the local map).
  String label(bool isArabic) => (isArabic && ar.isNotEmpty) ? ar : en;

  /// Parses a WALLET_COUNTRY row `{ ID, countryCode, countryName, currency }`.
  factory KycCountry.fromWallet(Map<String, dynamic> row) {
    final code = (row['ID'] ?? row['id'] ?? '').toString().trim();
    final en =
        (row['countryName'] ?? row['name'] ?? code).toString().trim();
    return KycCountry(code, en, _arCountryNameByCode[code] ?? '');
  }
}

/// Arabic country names keyed by code — enriches the live (English-only)
/// WALLET_COUNTRY list for the common countries.
final Map<String, String> _arCountryNameByCode = {
  for (final c in kycCountries) c.code: c.ar,
};

/// A KYC business sector (WALLET_SECTOR). [code] is the id sent to the core
/// (e.g. `"1001"`); the label is bilingual, parsed from the row's `description`.
@immutable
class KycSector {
  const KycSector(this.code, this.ar, this.en);

  final String code;
  final String ar;
  final String en;

  String label(bool isArabic) => (isArabic && ar.isNotEmpty)
      ? ar
      : (en.isNotEmpty ? en : code);

  /// Parses a WALLET_SECTOR row `{ ID, description: "{\"ar\":..,\"en\":..}", shortName }`.
  factory KycSector.fromWallet(Map<String, dynamic> row) {
    final code = (row['ID'] ?? row['id'] ?? '').toString().trim();
    var ar = '';
    var en = '';
    final desc = row['description'];
    if (desc is String && desc.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(desc);
        if (parsed is Map) {
          ar = (parsed['ar'] ?? '').toString().trim();
          en = (parsed['en'] ?? '').toString().trim();
        }
      } catch (_) {
        // description isn't JSON — fall back to shortName below.
      }
    }
    if (en.isEmpty) en = (row['shortName'] ?? code).toString().trim();
    return KycSector(code, ar, en);
  }
}

/// Fallback sector list (personal-wallet default) used until WALLET_SECTOR loads.
const List<KycSector> kycSectorsFallback = <KycSector>[
  KycSector('1001', 'قطاع خاص', 'Private sector'),
];

/// A curated, region-first country list. Yemen leads (the app's primary market),
/// followed by the GCC / wider Arab world, then a handful of common others.
/// Extend or replace with the backend reference list once it is available.
const List<KycCountry> kycCountries = <KycCountry>[
  KycCountry('YE', 'Yemen', 'اليمن'),
  KycCountry('SA', 'Saudi Arabia', 'السعودية'),
  KycCountry('AE', 'United Arab Emirates', 'الإمارات'),
  KycCountry('OM', 'Oman', 'عُمان'),
  KycCountry('QA', 'Qatar', 'قطر'),
  KycCountry('KW', 'Kuwait', 'الكويت'),
  KycCountry('BH', 'Bahrain', 'البحرين'),
  KycCountry('JO', 'Jordan', 'الأردن'),
  KycCountry('EG', 'Egypt', 'مصر'),
  KycCountry('SD', 'Sudan', 'السودان'),
  KycCountry('SY', 'Syria', 'سوريا'),
  KycCountry('LB', 'Lebanon', 'لبنان'),
  KycCountry('IQ', 'Iraq', 'العراق'),
  KycCountry('PS', 'Palestine', 'فلسطين'),
  KycCountry('DJ', 'Djibouti', 'جيبوتي'),
  KycCountry('SO', 'Somalia', 'الصومال'),
  KycCountry('MA', 'Morocco', 'المغرب'),
  KycCountry('DZ', 'Algeria', 'الجزائر'),
  KycCountry('TN', 'Tunisia', 'تونس'),
  KycCountry('LY', 'Libya', 'ليبيا'),
  KycCountry('TR', 'Türkiye', 'تركيا'),
  KycCountry('IN', 'India', 'الهند'),
  KycCountry('PK', 'Pakistan', 'باكستان'),
  KycCountry('ID', 'Indonesia', 'إندونيسيا'),
  KycCountry('MY', 'Malaysia', 'ماليزيا'),
  KycCountry('GB', 'United Kingdom', 'المملكة المتحدة'),
  KycCountry('US', 'United States', 'الولايات المتحدة'),
  KycCountry('DE', 'Germany', 'ألمانيا'),
  KycCountry('FR', 'France', 'فرنسا'),
];

/// Marital-status options for the KYC form. The [code] is the English enum the
/// wallet core expects on `maritalStatus` (e.g. `"Single"`); the label is
/// localised via [AppLocalizations].
enum KycMaritalStatus {
  single('Single'),
  married('Married'),
  divorced('Divorced'),
  widowed('Widowed');

  const KycMaritalStatus(this.code);

  /// Value sent to the core.
  final String code;

  String label(AppLocalizations l10n) => switch (this) {
        KycMaritalStatus.single => l10n.kycMaritalSingle,
        KycMaritalStatus.married => l10n.kycMaritalMarried,
        KycMaritalStatus.divorced => l10n.kycMaritalDivorced,
        KycMaritalStatus.widowed => l10n.kycMaritalWidowed,
      };
}
