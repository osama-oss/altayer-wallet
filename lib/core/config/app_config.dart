import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  static late AppConfig instance;

  final String apiBaseUrl;
  final KeycloakConfig keycloak;
  final KeycloakConfig? merchantKeycloak;
  final SecurityConfig security;

  /// Fixed idle-timeout for all users (minutes). During development ≥ 10;
  /// before go-live lower to 5–7. Keycloak SSO Session Idle is authoritative;
  /// this is the client-side UX fallback.
  final int sessionIdleMinutes;

  /// TEMPORARY fixed OTP code (no SMS provider yet). See [OtpService].
  final String otpStaticCode;

  AppConfig({
    required this.apiBaseUrl,
    required this.keycloak,
    this.merchantKeycloak,
    required this.security,
    this.sessionIdleMinutes = 10,
    this.otpStaticCode = '1234',
  });

  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/config/app_config.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final kc = json['keycloak'] as Map<String, dynamic>;
    final merchantKc = json['merchantKeycloak'] as Map<String, dynamic>?;
    instance = AppConfig(
      apiBaseUrl: json['apiBaseUrl'] as String,
      keycloak: KeycloakConfig.fromJson(kc),
      merchantKeycloak:
          merchantKc != null ? KeycloakConfig.fromJson(merchantKc) : null,
      security: SecurityConfig.fromJson(json['security'] as Map<String, dynamic>?),
      sessionIdleMinutes: json['sessionIdleMinutes'] as int? ?? 10,
      otpStaticCode:
          (json['otp'] as Map<String, dynamic>?)?['staticCode']?.toString() ??
              '1234',
    );
  }
}

class KeycloakConfig {
  const KeycloakConfig({
    required this.issuer,
    required this.clientId,
    required this.scopes,
    this.trustSelfSignedCerts = false,
  });

  final String issuer;
  final String clientId;
  final List<String> scopes;
  final bool trustSelfSignedCerts;

  String get tokenEndpoint => '$issuer/protocol/openid-connect/token';

  factory KeycloakConfig.fromJson(Map<String, dynamic> json) {
    return KeycloakConfig(
      issuer: json['issuer'] as String,
      clientId: json['clientId'] as String,
      scopes: (json['scopes'] as List<dynamic>).cast<String>(),
      trustSelfSignedCerts: json['trustSelfSignedCerts'] as bool? ?? false,
    );
  }
}

/// freeRASP / threat-response configuration. All fields default safely so a
/// missing `security` block never breaks startup; secrets (signing-cert hash,
/// Apple Team ID) are supplied per environment, not committed.
class SecurityConfig {
  const SecurityConfig({
    this.threatPolicy = 'monitor',
    this.watcherMail = 'security@uff.example',
    this.androidSigningCertHashes = const [],
    this.iosTeamId = '',
    this.iosBundleIds = const ['com.banksync.banksyncApp'],
  });

  /// monitor | warn | enforce — see [ThreatPolicy].
  final String threatPolicy;
  final String watcherMail;
  final List<String> androidSigningCertHashes;
  final String iosTeamId;
  final List<String> iosBundleIds;

  factory SecurityConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SecurityConfig();
    return SecurityConfig(
      threatPolicy: json['threatPolicy'] as String? ?? 'monitor',
      watcherMail: json['watcherMail'] as String? ?? 'security@uff.example',
      androidSigningCertHashes:
          (json['androidSigningCertHashes'] as List<dynamic>?)?.cast<String>() ??
              const [],
      iosTeamId: json['iosTeamId'] as String? ?? '',
      iosBundleIds: (json['iosBundleIds'] as List<dynamic>?)?.cast<String>() ??
          const ['com.banksync.banksyncApp'],
    );
  }
}
