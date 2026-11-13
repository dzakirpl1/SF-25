import 'package:test/test.dart';
import 'package:personal_os/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils Tests', () {
    test('getLogicalDate mengembalikan hari sebelumnya jika jam sebelum dayStartHour', () {
      // 03:00 pagi lokal -> harus dianggap masih tanggal kemarin
      final earlyMorning = DateTime(2026, 11, 12, 3, 0);
      final logicalDate = AppDateUtils.getLogicalDate(earlyMorning.toUtc(), dayStartHour: 4);

      expect(logicalDate.day, 11);
    });

    test('getLogicalDate mengembalikan hari yang sama jika jam setelah dayStartHour', () {
      // 05:00 pagi lokal -> hari ini
      final morning = DateTime(2026, 11, 12, 5, 0);
      final logicalDate = AppDateUtils.getLogicalDate(morning.toUtc(), dayStartHour: 4);

      expect(logicalDate.day, 12);
    });
  });
}
