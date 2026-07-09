import 'package:banksync_app/core/auth/otp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verify accepts the matching fixed code (and trims)', () async {
    final otp = OtpService(staticCode: '1234');
    expect(await otp.verify('1234'), isTrue);
    expect(await otp.verify('  1234 '), isTrue);
  });

  test('verify rejects a wrong / incomplete / empty code', () async {
    final otp = OtpService(staticCode: '1234');
    expect(await otp.verify('0000'), isFalse);
    expect(await otp.verify('12'), isFalse);
    expect(await otp.verify(''), isFalse);
  });
}
