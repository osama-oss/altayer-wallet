import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One package tier shown in the نوع الباقة dropdown (demo seed data — the
/// real list will come from the provider's offers API later).
class TelecomPackage {
  const TelecomPackage({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.nameZh,
    this.amount,
  });

  final String code;
  final String nameAr;
  final String nameEn;
  final String nameZh;
  final double? amount;

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr.isNotEmpty ? nameAr : nameEn;
      case 'zh':
        return nameZh.isNotEmpty ? nameZh : nameEn;
      default:
        return nameEn.isNotEmpty ? nameEn : nameAr;
    }
  }
}

/// One selectable service under a telecom operator (the نوع الخدمة tiles):
/// balance top-up vs prepaid / postpaid package lines.
class TelecomService {
  const TelecomService({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.nameZh,
    this.isPackages = false,
    this.packages = const [],
  });

  final String code;
  final String nameAr;
  final String nameEn;
  final String nameZh;

  /// A package line (باقات) rather than a direct-amount balance top-up.
  final bool isPackages;

  /// Options for the نوع الباقة dropdown (only meaningful when [isPackages]).
  final List<TelecomPackage> packages;

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr.isNotEmpty ? nameAr : nameEn;
      case 'zh':
        return nameZh.isNotEmpty ? nameZh : nameEn;
      default:
        return nameEn.isNotEmpty ? nameEn : nameAr;
    }
  }
}

/// Demo package tiers for the نوع الباقة dropdown (placeholder data for the
/// manager preview — real tiers come from the provider offers API later).
const List<TelecomPackage> _demoDataPackages = [
  TelecomPackage(code: 'D1', nameAr: 'باقة 1 جيجا', nameEn: '1 GB', nameZh: '1 GB', amount: 500),
  TelecomPackage(code: 'D3', nameAr: 'باقة 3 جيجا', nameEn: '3 GB', nameZh: '3 GB', amount: 1200),
  TelecomPackage(code: 'D5', nameAr: 'باقة 5 جيجا', nameEn: '5 GB', nameZh: '5 GB', amount: 1800),
  TelecomPackage(code: 'D10', nameAr: 'باقة 10 جيجا', nameEn: '10 GB', nameZh: '10 GB', amount: 3000),
];

const List<TelecomPackage> _demoVoicePackages = [
  TelecomPackage(code: 'V100', nameAr: 'باقة 100 دقيقة', nameEn: '100 minutes', nameZh: '100 分钟', amount: 600),
  TelecomPackage(code: 'V300', nameAr: 'باقة 300 دقيقة', nameEn: '300 minutes', nameZh: '300 分钟', amount: 1500),
  TelecomPackage(code: 'VM', nameAr: 'باقة مختلطة (دقائق + إنترنت)', nameEn: 'Mixed bundle', nameZh: '混合套餐', amount: 2500),
];

/// Yemen 4G LTE data tiers (mirrors the legacy app; demo prices until the
/// provider offers API is wired).
const List<TelecomPackage> _yemen4gPackages = [
  TelecomPackage(code: 'FG15', nameAr: '4G (15GB)', nameEn: '4G (15GB)', nameZh: '4G (15GB)', amount: 2500),
  TelecomPackage(code: 'FG25', nameAr: '4G (25GB)', nameEn: '4G (25GB)', nameZh: '4G (25GB)', amount: 4000),
  TelecomPackage(code: 'FG60', nameAr: '4G (60GB)', nameEn: '4G (60GB)', nameZh: '4G (60GB)', amount: 8000),
  TelecomPackage(code: 'FG130', nameAr: '4G (130GB)', nameEn: '4G (130GB)', nameZh: '4G (130GB)', amount: 15000),
  TelecomPackage(code: 'FG250', nameAr: '4G (250GB)', nameEn: '4G (250GB)', nameZh: '4G (250GB)', amount: 25000),
];

/// Aden Net subscription tiers with the network's published prices (legacy app).
const List<TelecomPackage> _adenNetPackages = [
  TelecomPackage(code: 'AN20', nameAr: 'باقة 20 جيجا', nameEn: '20 GB', nameZh: '20 GB', amount: 3000),
  TelecomPackage(code: 'AN40', nameAr: 'باقة 40 جيجا', nameEn: '40 GB', nameZh: '40 GB', amount: 6000),
  TelecomPackage(code: 'AN60', nameAr: 'باقة 60 جيجا', nameEn: '60 GB', nameZh: '60 GB', amount: 9000),
  TelecomPackage(code: 'AN80', nameAr: 'باقة 80 جيجا', nameEn: '80 GB', nameZh: '80 GB', amount: 12000),
  TelecomPackage(code: 'ANBIZ', nameAr: 'باقة تجارية', nameEn: 'Commercial package', nameZh: '商业套餐', amount: 30000),
];

/// One provider row from the server-side `BILLER_CATALOG` (db_mobile.billers).
/// Routing internals (network/service numbers, integration codes) deliberately
/// stay on the server — the app addresses a biller by [code] only.
class Biller {
  const Biller({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.nameZh,
    required this.category,
    this.inputLabel = 'PHONE',
    this.inputRegex,
    this.prefixes = const [],
    this.services = const [],
    this.supportsOffers = false,
    this.supportsAmount = true,
    this.currency = 'YER',
    this.iconKey,
    this.assetIcon,
  });

  final String code;
  final String nameAr;
  final String nameEn;
  final String nameZh;

  /// TELECOM | INTERNET | MONEY_TRANSFER | ENTERTAINMENT
  final String category;

  /// PHONE | SUBSCRIBER_NO | ACCOUNT_NO — picks the input keyboard and label.
  final String inputLabel;
  final String? inputRegex;

  /// Mobile number prefixes that route to this operator (e.g. `77`, `78`).
  /// Used to auto-detect the operator as the user types on the telecom screen.
  final List<String> prefixes;

  /// نوع الخدمة tiles shown once this operator is detected (top-up / packages).
  final List<TelecomService> services;

  final bool supportsOffers;
  final bool supportsAmount;
  final String currency;
  final String? iconKey;

  /// Brand logo asset (PNG under assets/telecom/), preferred over [icon].
  final String? assetIcon;

  /// Codes of the two Yemen Telecom fixed-line services; the dedicated سداد
  /// الهاتف الثابت / سداد الانترنت screens resolve their biller by these.
  static const String landlineBillerCode = 'YEMEN-LANDLINE';
  static const String internetBillerCode = 'YEMEN-NET';

  factory Biller.fromMap(Map<String, dynamic> map) {
    return Biller(
      code: map['code']?.toString() ?? '',
      nameAr: map['nameAr']?.toString() ?? '',
      nameEn: map['nameEn']?.toString() ?? '',
      nameZh: map['nameZh']?.toString() ?? '',
      category: map['category']?.toString() ?? 'TELECOM',
      inputLabel: map['inputLabel']?.toString() ?? 'PHONE',
      inputRegex: _optional(map['inputRegex']),
      prefixes: _stringList(map['prefixes']),
      supportsOffers: map['supportsOffers'] == true,
      supportsAmount: map['supportsAmount'] != false,
      currency: map['currency']?.toString() ?? 'YER',
      iconKey: _optional(map['iconKey']),
      assetIcon: _optional(map['assetIcon']),
    );
  }

  /// The single operator whose prefix matches [phone] (longest prefix wins),
  /// or null when nothing matches yet. Drives the auto-reveal of نوع الخدمة.
  static Biller? detectOperator(List<Biller> catalog, String phone) {
    final value = phone.trim();
    if (value.isEmpty) return null;
    Biller? best;
    var bestLen = 0;
    for (final biller in catalog) {
      for (final prefix in biller.prefixes) {
        if (prefix.length > bestLen && value.startsWith(prefix)) {
          best = biller;
          bestLen = prefix.length;
        }
      }
    }
    return best;
  }

  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  static List<Biller> listFrom(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => Biller.fromMap(Map<String, dynamic>.from(e)))
        .where((b) => b.code.isNotEmpty)
        .toList();
  }

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr.isNotEmpty ? nameAr : nameEn;
      case 'zh':
        return nameZh.isNotEmpty ? nameZh : nameEn;
      default:
        return nameEn.isNotEmpty ? nameEn : nameAr;
    }
  }

  bool matchesInput(String value) {
    final regex = inputRegex;
    if (regex == null || regex.isEmpty) return value.trim().isNotEmpty;
    return RegExp(regex).hasMatch(value.trim());
  }

  String? getThemeAssetIcon(BuildContext context) {
    if (assetIcon == null) return null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (assetIcon!.endsWith('.svg')) {
      final base = assetIcon!.substring(0, assetIcon!.length - 4);
      return isDark ? '${base}_dark.svg' : '${base}_light.svg';
    }
    return assetIcon;
  }

  IconData get icon {
    switch (iconKey) {
      case 'yemen_mobile':
        return Icons.smartphone_rounded;
      case 'sabafon':
        return Icons.sim_card_outlined;
      case 'y_telecom':
        return Icons.cell_tower_rounded;
      case 'you':
        return Icons.sim_card_rounded;
      case 'yemen_4g':
        return Icons.router_outlined;
      case 'landline':
        return Icons.phone_outlined;
      case 'adsl':
        return Icons.wifi_rounded;
      case 'adennet':
        return Icons.language_rounded;
      case 'starlink':
        return Icons.satellite_alt_outlined;
      case 'unmoney':
        return Icons.currency_exchange_rounded;
      case 'games':
        return Icons.sports_esports_outlined;
    }
    switch (category) {
      case 'INTERNET':
        return Icons.wifi_rounded;
      case 'MONEY_TRANSFER':
        return Icons.currency_exchange_rounded;
      case 'ENTERTAINMENT':
        return Icons.sports_esports_outlined;
      default:
        return Icons.smartphone_rounded;
    }
  }

  Color get accentColor {
    // Per-provider brand colours first so the tiles read like the real
    // operators; falls back to a category colour for anything unbranded.
    switch (iconKey) {
      case 'yemen_mobile':
        return const Color(0xFF00A651); // Yemen Mobile green
      case 'sabafon':
        return const Color(0xFFED1C24); // Sabafon red
      case 'you':
        return const Color(0xFF6A1B9A); // YOU purple
      case 'y_telecom':
        return const Color(0xFF0057B8); // Y (واي) blue
      case 'yemen_4g':
        return const Color(0xFFEA7A00); // Yemen 4G orange
      case 'adennet':
        return const Color(0xFF1B7F79); // Aden Net teal
      case 'starlink':
        return const Color(0xFF1A2A4F); // Starlink deep navy
      case 'landline':
      case 'adsl':
        return const Color(0xFF0B62A4); // Yemen Telecom blue
    }
    switch (category) {
      case 'INTERNET':
        return const Color(0xFF12B5E5);
      case 'MONEY_TRANSFER':
        return const Color(0xFF16B89B);
      case 'ENTERTAINMENT':
        return const Color(0xFF9B51E0);
      default:
        return AppColors.brandIndigo;
    }
  }

  /// Client-side seed of the provider catalogue, mirroring the real free-sadad
  /// network matrix (PLAN_BILL_PAYMENTS §2.2 / §4.2). Used as a fallback until
  /// the server `BILLER_CATALOG` is seeded (plan phase 1) — once the server
  /// returns rows, those win. `inputRegex` is what reveals the matching نوع
  /// الخدمة tiles as the user types a number.
  static const List<Biller> fallbackCatalog = [
    // ── Mobile operators (auto-detected by prefix) ───────────────────────
    Biller(
      code: 'YEMEN-MOBILE',
      nameAr: 'يمن موبايل',
      nameEn: 'Yemen Mobile',
      nameZh: '也门移动',
      category: 'TELECOM',
      inputRegex: r'^7\d{8}$',
      prefixes: ['77', '78'],
      supportsOffers: true,
      iconKey: 'yemen_mobile',
      assetIcon: 'assets/telecom/yemen_mobile.png',
      services: [
        TelecomService(
          code: 'TOPUP',
          nameAr: 'يمن موبايل',
          nameEn: 'Yemen Mobile',
          nameZh: '也门移动',
        ),
        TelecomService(
          code: 'PREPAID_PKG',
          nameAr: 'باقات دفع مسبق',
          nameEn: 'Prepaid packages',
          nameZh: '预付套餐',
          isPackages: true,
          packages: _demoDataPackages,
        ),
        TelecomService(
          code: 'POSTPAID_PKG',
          nameAr: 'باقات فوترة',
          nameEn: 'Postpaid packages',
          nameZh: '后付套餐',
          isPackages: true,
          packages: _demoVoicePackages,
        ),
      ],
    ),
    Biller(
      code: 'SABAFON',
      nameAr: 'سبأفون',
      nameEn: 'Sabafon',
      nameZh: '萨巴丰',
      category: 'TELECOM',
      inputRegex: r'^7\d{8}$',
      prefixes: ['71'],
      supportsOffers: true,
      iconKey: 'sabafon',
      assetIcon: 'assets/telecom/sabafon.png',
      services: [
        TelecomService(code: 'TOPUP', nameAr: 'سبأفون', nameEn: 'Sabafon', nameZh: '萨巴丰'),
        TelecomService(
          code: 'PKG',
          nameAr: 'الباقات',
          nameEn: 'Packages',
          nameZh: '套餐',
          isPackages: true,
          packages: _demoDataPackages,
        ),
      ],
    ),
    Biller(
      code: 'YOU',
      nameAr: 'يو',
      nameEn: 'YOU',
      nameZh: 'YOU',
      category: 'TELECOM',
      inputRegex: r'^7\d{8}$',
      prefixes: ['73'],
      supportsOffers: true,
      iconKey: 'you',
      assetIcon: 'assets/telecom/you.png',
      services: [
        TelecomService(code: 'TOPUP', nameAr: 'يو', nameEn: 'YOU', nameZh: 'YOU'),
        TelecomService(
          code: 'PKG',
          nameAr: 'الباقات',
          nameEn: 'Packages',
          nameZh: '套餐',
          isPackages: true,
          packages: _demoDataPackages,
        ),
      ],
    ),
    Biller(
      code: 'Y-TELECOM',
      nameAr: 'واي',
      nameEn: 'Y',
      nameZh: 'Y',
      category: 'TELECOM',
      inputRegex: r'^7\d{8}$',
      prefixes: ['70'],
      supportsOffers: true,
      iconKey: 'y_telecom',
      assetIcon: 'assets/telecom/way.png',
      services: [
        TelecomService(code: 'TOPUP', nameAr: 'واي', nameEn: 'Y', nameZh: 'Y'),
        TelecomService(
          code: 'PKG',
          nameAr: 'الباقات',
          nameEn: 'Packages',
          nameZh: '套餐',
          isPackages: true,
          packages: _demoDataPackages,
        ),
      ],
    ),
    Biller(
      code: 'YEMEN-4G',
      nameAr: 'يمن فورجي',
      nameEn: 'Yemen 4G',
      nameZh: '也门4G',
      category: 'INTERNET',
      inputLabel: 'SUBSCRIBER_NO',
      inputRegex: r'^\d{4,}$',
      supportsOffers: true,
      iconKey: 'yemen_4g',
      assetIcon: 'assets/pay/4g.png',
      services: [
        TelecomService(
          code: 'PKG',
          nameAr: 'الباقات',
          nameEn: 'Packages',
          nameZh: '套餐',
          isPackages: true,
          packages: _yemen4gPackages,
        ),
      ],
    ),
    // ── Fixed line / internet (account-based, dedicated سداد screens) ─────
    // Yemen Telecom splits into two free-sadad networks: landline (network 6)
    // and ADSL / يمن نت (network 5, supports balance inquiry) — PLAN §2.2.
    Biller(
      code: landlineBillerCode,
      nameAr: 'الهاتف الثابت',
      nameEn: 'Landline',
      nameZh: '固定电话',
      category: 'TELECOM',
      inputLabel: 'SUBSCRIBER_NO',
      inputRegex: r'^0?\d{6,8}$',
      iconKey: 'landline',
      assetIcon: 'assets/pay/yemenTel.png',
    ),
    Biller(
      code: internetBillerCode,
      nameAr: 'يمن نت (ADSL)',
      nameEn: 'Yemen Net (ADSL)',
      nameZh: '也门网络 (ADSL)',
      category: 'INTERNET',
      inputLabel: 'SUBSCRIBER_NO',
      inputRegex: r'^0?\d{6,8}$',
      iconKey: 'adsl',
      assetIcon: 'assets/pay/yemen net.jpg',
    ),
    Biller(
      code: 'ADENNET',
      nameAr: 'عدن نت',
      nameEn: 'Aden Net',
      nameZh: '亚丁网络',
      category: 'INTERNET',
      inputLabel: 'ACCOUNT_NO',
      inputRegex: r'^\d{4,}$',
      supportsOffers: true,
      iconKey: 'adennet',
      assetIcon: 'assets/pay/adenNet.png',
      services: [
        TelecomService(
          code: 'PKG',
          nameAr: 'الباقات',
          nameEn: 'Packages',
          nameZh: '套餐',
          isPackages: true,
          packages: _adenNetPackages,
        ),
      ],
    ),
    Biller(
      code: 'STARLINK',
      nameAr: 'ستارلينك',
      nameEn: 'Starlink',
      nameZh: '星链',
      category: 'INTERNET',
      inputLabel: 'ACCOUNT_NO',
      inputRegex: r'^\d{4,}$',
      iconKey: 'starlink',
      assetIcon: 'assets/pay/Starlink_Logo.svg',
    ),
    // ── Unified money-transfer network ───────────────────────────────────
    Biller(
      code: 'UNMONEY',
      nameAr: 'الشبكة الموحّدة UN Money',
      nameEn: 'UN Money',
      nameZh: 'UN Money',
      category: 'MONEY_TRANSFER',
      inputLabel: 'PHONE',
      inputRegex: r'^7\d{8}$',
      supportsAmount: true,
      iconKey: 'unmoney',
      assetIcon: 'assets/telecom/unmoney.png',
    ),
  ];

  static String? _optional(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}
