/// Backend error from MOBILE_API envelope (`success: false`).
class ApiException implements Exception {
  const ApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class KeycloakAuthException implements Exception {
  const KeycloakAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Keycloak blocked token until permanent password is set (MOBILE_API flow A).
class FirstLoginPasswordChangeRequired implements Exception {
  const FirstLoginPasswordChangeRequired({this.message});

  final String? message;
}
