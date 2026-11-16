/// Model representasi satu kejadian (occurrence) dari suatu event kalender,
/// baik kejadian asli tunggal maupun kejadian hasil ekspansi aturan pengulangan di sisi klien.
class EventOccurrence {
  final String eventId;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool allDay;
  final String? location;
  final String? color;
  final bool isTimeBlock;
  final String? linkedTaskId;
  final bool isOriginal;

  const EventOccurrence({
    required this.eventId,
    required this.title,
    this.description,
    required this.startsAt,
    required this.endsAt,
    this.allDay = false,
    this.location,
    this.color,
    this.isTimeBlock = false,
    this.linkedTaskId,
    this.isOriginal = true,
  });

  Duration get duration => endsAt.difference(startsAt);

  /// Menandakan apakah event membentang melintasi tengah malam (beda hari kalender)
  bool get isCrossMidnight =>
      startsAt.year != endsAt.year ||
      startsAt.month != endsAt.month ||
      startsAt.day != endsAt.day;
}

class RecurrenceEngine {
  /// Menghitung tanggal jatuh tempo berikutnya dari aturan recurrence_rule
  /// Format standar:
  /// - FREQ=DAILY;INTERVAL=1
  /// - FREQ=WEEKLY;INTERVAL=1
  /// - FREQ=MONTHLY;INTERVAL=1
  /// - FREQ=YEARLY;INTERVAL=1
  static DateTime? computeNextDueDate(String? rule, DateTime baseDate) {
    if (rule == null || rule.trim().isEmpty) return null;

    final parts = rule.toUpperCase().split(';');
    String? freq;
    int interval = 1;

    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length == 2) {
        if (kv[0] == 'FREQ') freq = kv[1];
        if (kv[0] == 'INTERVAL') interval = int.tryParse(kv[1]) ?? 1;
      }
    }

    if (freq == null || interval <= 0) return null;

    switch (freq) {
      case 'DAILY':
        return baseDate.add(Duration(days: interval));

      case 'WEEKLY':
        return baseDate.add(Duration(days: 7 * interval));

      case 'MONTHLY':
        // Menjaga penanganan tanggal akhir bulan (misal tgl 31 pada bulan yg ada 30 hari atau 28/29 Februari)
        int targetYear = baseDate.year;
        int targetMonth = baseDate.month + interval;

        while (targetMonth > 12) {
          targetYear += 1;
          targetMonth -= 12;
        }

        final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final targetDay =
            baseDate.day > daysInTargetMonth ? daysInTargetMonth : baseDate.day;

        return DateTime(
          targetYear,
          targetMonth,
          targetDay,
          baseDate.hour,
          baseDate.minute,
          baseDate.second,
        );

      case 'YEARLY':
        int targetYear = baseDate.year + interval;
        final isLeapTarget = (targetYear % 4 == 0 && targetYear % 100 != 0) ||
            (targetYear % 400 == 0);
        int targetDay = baseDate.day;
        if (baseDate.month == 2 && baseDate.day == 29 && !isLeapTarget) {
          targetDay = 28;
        }
        return DateTime(
          targetYear,
          baseDate.month,
          targetDay,
          baseDate.hour,
          baseDate.minute,
          baseDate.second,
        );

      default:
        return null;
    }
  }

  /// Mengekspansi event (terutama event berulang) ke dalam daftar kemunculan (instances)
  /// pada rentang tanggal aktif [rangeStart] s.d. [rangeEnd] di sisi klien.
  static List<EventOccurrence> expandEventOccurrences({
    required String id,
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
    bool allDay = false,
    String? location,
    String? color,
    String? recurrenceRule,
    bool isTimeBlock = false,
    String? linkedTaskId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    int maxOccurrences = 500,
  }) {
    final duration = endsAt.difference(startsAt);
    final results = <EventOccurrence>[];

    // Jika tidak memiliki aturan pengulangan, cukup periksa apakah event tunggal ini beririsan dengan rentang
    if (recurrenceRule == null || recurrenceRule.trim().isEmpty) {
      if (_isOverlapping(startsAt, endsAt, rangeStart, rangeEnd)) {
        results.add(
          EventOccurrence(
            eventId: id,
            title: title,
            description: description,
            startsAt: startsAt,
            endsAt: endsAt,
            allDay: allDay,
            location: location,
            color: color,
            isTimeBlock: isTimeBlock,
            linkedTaskId: linkedTaskId,
            isOriginal: true,
          ),
        );
      }
      return results;
    }

    // Parse parameter RRULE
    final parts = recurrenceRule.toUpperCase().split(';');
    String? freq;
    int interval = 1;
    DateTime? untilDate;
    int? maxCount;

    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length == 2) {
        if (kv[0] == 'FREQ') freq = kv[1];
        if (kv[0] == 'INTERVAL') interval = int.tryParse(kv[1]) ?? 1;
        if (kv[0] == 'COUNT') maxCount = int.tryParse(kv[1]);
        if (kv[0] == 'UNTIL') {
          untilDate = DateTime.tryParse(kv[1]);
        }
      }
    }

    if (freq == null || interval <= 0) return results;

    DateTime curStart = startsAt;
    DateTime curEnd = endsAt;
    int count = 0;

    while (count < maxOccurrences) {
      // Periksa batas UNTIL
      if (untilDate != null && curStart.isAfter(untilDate)) {
        break;
      }

      // Periksa batas COUNT
      if (maxCount != null && count >= maxCount) {
        break;
      }

      // Jika kejadian saat ini sudah melampaui rangeEnd dan bukan all-day atau cross-midnight, kita bisa berhenti
      if (curStart.isAfter(rangeEnd)) {
        break;
      }

      // Jika bersinggungan dengan rentang yang diminta pengguna
      if (_isOverlapping(curStart, curEnd, rangeStart, rangeEnd)) {
        results.add(
          EventOccurrence(
            eventId: id,
            title: title,
            description: description,
            startsAt: curStart,
            endsAt: curEnd,
            allDay: allDay,
            location: location,
            color: color,
            isTimeBlock: isTimeBlock,
            linkedTaskId: linkedTaskId,
            isOriginal: count == 0,
          ),
        );
      }

      count++;

      // Hitung jadwal kejadian berikutnya
      final nextStart =
          computeNextDueDate('FREQ=$freq;INTERVAL=$interval', curStart);
      if (nextStart == null) break;

      curStart = nextStart;
      curEnd = curStart.add(duration);
    }

    return results;
  }

  /// Memeriksa apakah interval waktu [aStart, aEnd] beririsan dengan [bStart, bEnd]
  static bool _isOverlapping(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return !aEnd.isBefore(bStart) && !aStart.isAfter(bEnd);
  }

  /// Menghasilkan deskripsi teks ramah Bahasa Indonesia dari aturan RRULE
  static String formatRuleToText(String? rule) {
    if (rule == null || rule.trim().isEmpty) return 'Tidak berulang';

    final upper = rule.toUpperCase();
    if (upper.contains('FREQ=DAILY')) {
      if (upper.contains('INTERVAL=2')) return 'Setiap 2 hari';
      return 'Setiap hari';
    }
    if (upper.contains('FREQ=WEEKLY')) {
      if (upper.contains('INTERVAL=2')) return 'Setiap 2 minggu';
      return 'Setiap minggu';
    }
    if (upper.contains('FREQ=MONTHLY')) {
      return 'Setiap bulan';
    }
    if (upper.contains('FREQ=YEARLY')) {
      return 'Setiap tahun';
    }
    return 'Berulang ($rule)';
  }
}
