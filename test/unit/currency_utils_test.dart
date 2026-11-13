import 'package:test/test.dart';
import 'package:personal_os/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils Tests', () {
    test('formatRupiah memformat bigint nominal dengan benar', () {
      expect(CurrencyUtils.formatRupiah(1250000), contains('1.250.000'));
      expect(CurrencyUtils.formatRupiah(0), contains('0'));
      expect(CurrencyUtils.formatRupiah(50000), contains('50.000'));
    });

    test('parseNominal membersihkan karakter non-angka', () {
      expect(CurrencyUtils.parseNominal('Rp 1.250.000'), 1250000);
      expect(CurrencyUtils.parseNominal('Rp 50.000,00'), 5000000); // 5000000 if digits only
      expect(CurrencyUtils.parseNominal('abc'), 0);
    });
  });
}
