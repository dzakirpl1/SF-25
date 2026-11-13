import 'package:intl/intl.dart';

class AppDateUtils {
  /// Menghitung tanggal logis berdasarkan day_start_hour (misal jam 4 pagi)
  static DateTime getLogicalDate(DateTime nowUtc, {int dayStartHour = 4}) {
    final localTime = nowUtc.toLocal();
    if (localTime.hour < dayStartHour) {
      final prevDay = localTime.subtract(const Duration(days: 1));
      return DateTime(prevDay.year, prevDay.month, prevDay.day);
    }
    return DateTime(localTime.year, localTime.month, localTime.day);
  }

  /// Format tanggal ramah Bahasa Indonesia: "Kamis, 12 November 2026"
  static String formatHariTanggal(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  /// Format jam: "19:30"
  static String formatJam(DateTime date) {
    return DateFormat('HH:mm').format(date.toLocal());
  }

  /// Format relatif ringkas untuk kartu catatan
  static String formatRelatif(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} mnt lalu';
    } else if (diff.inDays < 1 && now.day == dateTime.day) {
      return 'Hari ini ${formatJam(dateTime)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return DateFormat('d MMM yyyy', 'id_ID').format(dateTime.toLocal());
    }
  }
}
