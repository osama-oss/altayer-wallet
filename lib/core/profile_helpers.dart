/// Resolves the core-banking CIF from a cached user profile.
///
/// Prefer explicit core fields over [customerId]. Never treat the login
/// username / mobile as a CIF — that caused profile + balance search to use
/// the phone instead of the real core id (e.g. `000001778`).
String coreCustomerIdFromProfile(
  Map<String, dynamic> profile, {
  String? usernameFallback,
}) {
  final mobile = _firstNonEmpty(profile, const [
    'mobile',
    'mobileNo',
    'mobileNumber',
    'phone',
  ]);
  final username = usernameFallback?.trim();

  for (final key in ['coreCustomerId', 'customerCode', 'customerId']) {
    final value = profile[key]?.toString().trim();
    if (value == null || value.isEmpty) continue;
    if (_isLoginIdentity(value, mobile: mobile, username: username)) {
      continue;
    }
    return value;
  }
  return '';
}

/// Fields stored on the local profile for the core CIF (same value, three keys
/// so older and newer readers both work).
Map<String, String> coreCustomerIdProfileFields(String coreCustomerId) {
  final id = coreCustomerId.trim();
  if (id.isEmpty) return const {};
  return {
    'customerId': id,
    'coreCustomerId': id,
    'customerCode': id,
  };
}

String? _firstNonEmpty(Map<String, dynamic> profile, List<String> keys) {
  for (final key in keys) {
    final value = profile[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

bool _isLoginIdentity(
  String value, {
  String? mobile,
  String? username,
}) {
  if (username != null && username.isNotEmpty && value == username) {
    return true;
  }
  if (mobile != null && mobile.isNotEmpty && value == mobile) {
    return true;
  }
  return false;
}
