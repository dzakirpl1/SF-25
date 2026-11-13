import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka BigInt atau int ke format rupiah: Rp 1.250.000
  static String formatRupiah(num amount) {
    return _formatter.format(amount);
  }

  /// Parse string input nominal ke bigint
  static int parseNominal(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}
