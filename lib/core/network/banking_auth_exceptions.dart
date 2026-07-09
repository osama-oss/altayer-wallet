/// MOBILE_API error codes for device / biometric flows.
class DeviceAlreadyBoundException implements Exception {
  const DeviceAlreadyBoundException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'This account is registered on another device.';
}

class DeviceNotRegisteredException implements Exception {
  const DeviceNotRegisteredException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'This device is not registered. Sign in with password.';
}

class BiometricNotEnrolledException implements Exception {
  const BiometricNotEnrolledException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'Biometric login is not enabled for this device.';
}

class BiometricLockedException implements Exception {
  const BiometricLockedException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'Biometric login locked. Sign in with password and enroll again.';
}

class PinInvalidException implements Exception {
  const PinInvalidException(this.message);

  final String message;

  @override
  String toString() => message;
}

// ─── Notification errors ────────────────────────────────────────────────

/// FCM token was empty, malformed, or rejected by backend.
class PushTokenInvalidException implements Exception {
  const PushTokenInvalidException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'Push token is invalid or malformed.';
}

/// Notification ID does not exist or does not belong to this customer.
class NotificationNotFoundException implements Exception {
  const NotificationNotFoundException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'Notification not found.';
}

/// Attempted to toggle a non-toggleable category (e.g. SECURITY).
class CategoryNotToggleableException implements Exception {
  const CategoryNotToggleableException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'This notification category cannot be disabled.';
}
