import 'package:banksync_app/core/config/app_config.dart';

/// OTP verification.
///
/// TEMPORARY: the project has no SMS provider yet, so — per the team decision —
/// the OTP flow stays *functional* (it genuinely checks the code the customer
/// types) but validates it against a **fixed** code from config that does not
/// rotate. No Firebase / no SMS round-trip for now.
///
/// When an SMS gateway / backend verify endpoint is available, swap the body of
/// [verify] (and implement [request]) for the real server round-trip — the
/// screen contract (a `Future<bool>` per entered code) stays identical.
class OtpService {
  OtpService({String? staticCode})
      : _staticCode = staticCode ?? AppConfig.instance.otpStaticCode;

  final String _staticCode;

  /// Returns true when [code] matches the configured fixed OTP.
  Future<bool> verify(String code) async {
    // Small delay to mimic a network verify so the UX matches the future
    // real implementation.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return code.trim() == _staticCode.trim();
  }

  /// Placeholder for sending an OTP. No-op until an SMS provider exists; the
  /// fixed code is always accepted by [verify].
  Future<void> request(String mobile) async {/* no SMS provider yet */}
}
