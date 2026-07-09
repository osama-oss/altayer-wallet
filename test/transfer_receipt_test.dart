import 'package:banksync_app/features/transfer/transfer_helpers.dart';
import 'package:banksync_app/features/transfer/transfer_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maskAccount keeps only the last 4 digits', () {
    expect(maskAccount('SA1234567890123456'), '**** 3456');
    expect(maskAccount('00012347045'), '**** 7045');
    expect(maskAccount('7045'), '7045'); // too short to mask
    expect(maskAccount('12'), '12');
  });

  test('transferCounterpartyName finds the beneficiary name in common keys', () {
    expect(
      transferCounterpartyName({'beneficiaryName': 'فاطمه العمري'}),
      'فاطمه العمري',
    );
    // nested + bilingual map → prefers Arabic
    expect(
      transferCounterpartyName({
        'data': {
          'creditCustomerName': {'ar': 'نورة الجبير', 'en': 'Noura'}
        }
      }),
      'نورة الجبير',
    );
    expect(transferCounterpartyName({'unrelated': 'x'}), isNull);
    expect(transferCounterpartyName(null), isNull);
    expect(transferCounterpartyName(const {}), isNull);
  });
}
