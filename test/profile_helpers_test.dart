import 'package:banksync_app/core/profile_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prefers coreCustomerId over customerId', () {
    final id = coreCustomerIdFromProfile({
      'customerId': '000001111',
      'coreCustomerId': '000001778',
      'mobile': '789456123',
    });
    expect(id, '000001778');
  });

  test('reads customerId when only that key is present', () {
    final id = coreCustomerIdFromProfile({
      'customerId': '000001778',
      'mobile': '789456123',
    }, usernameFallback: '789456123');
    expect(id, '000001778');
  });

  test('does not treat mobile/username as a core CIF', () {
    final id = coreCustomerIdFromProfile({
      'customerId': '789456123',
      'mobile': '789456123',
    }, usernameFallback: '789456123');
    expect(id, '');
  });

  test('does not fall back to username when core fields are missing', () {
    final id = coreCustomerIdFromProfile({
      'mobile': '789456123',
    }, usernameFallback: '789456123');
    expect(id, '');
  });

  test('coreCustomerIdProfileFields writes all three keys', () {
    expect(coreCustomerIdProfileFields('000001778'), {
      'customerId': '000001778',
      'coreCustomerId': '000001778',
      'customerCode': '000001778',
    });
  });
}
