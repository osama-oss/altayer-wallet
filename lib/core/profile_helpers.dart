String coreCustomerIdFromProfile(
  Map<String, dynamic> profile, {
  String? usernameFallback,
}) {
  for (final key in ['coreCustomerId', 'customerCode']) {
    final value = profile[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  final fallback = usernameFallback?.trim();
  return fallback != null && fallback.isNotEmpty ? fallback : '';
}
