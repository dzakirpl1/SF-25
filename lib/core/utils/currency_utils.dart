import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka BigInt, int, num, atau String ke format rupiah: Rp 1.250.000
  static String formatRupiah(Object amount) {
    if (amount is BigInt) {
      if (amount.isValidInt) {
        return _formatter.format(amount.toInt());
      }
      return 'Rp ${amount.toString()}';
    } else if (amount is num) {
      return _formatter.format(amount);
    } else if (amount is String) {
      final parsed = BigInt.tryParse(amount);
      if (parsed != null) return formatRupiah(parsed);
      return amount;
    }
    return _formatter.format(0);
  }

  /// Parse string input nominal ke BigInt
  static BigInt parseNominal(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    return BigInt.tryParse(cleaned) ?? BigInt.zero;
  }
}
