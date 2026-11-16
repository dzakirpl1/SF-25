import 'package:test/test.dart';
import 'package:personal_os/core/recurrence/recurrence_engine.dart';
import 'package:personal_os/features/calendar/domain/calendar_event.dart';

void main() {
  group('Calendar & RecurrenceEngine Expansion Tests', () {
    test('Ekspansi event tunggal tanpa aturan pengulangan', () {
      final start = DateTime(2026, 11, 15, 10, 0);
      final end = DateTime(2026, 11, 15, 11, 0);

      final instances = RecurrenceEngine.expandEventOccurrences(
        id: 'ev-1',
        title: 'Interview',
        startsAt: start,
        endsAt: end,
        recurrenceRule: null,
        rangeStart: DateTime(2026, 11, 1, 0, 0),
        rangeEnd: DateTime(2026, 11, 30, 23, 59),
      );

      expect(instances.length, 1);
      expect(instances.first.title, 'Interview');
      expect(instances.first.startsAt, start);
      expect(instances.first.endsAt, end);
      expect(instances.first.isCrossMidnight, false);
    });

    test('Ekspansi event harian (FREQ=DAILY;INTERVAL=1)', () {
      final start = DateTime(2026, 11, 1, 8, 0);
      final end = DateTime(2026, 11, 1, 8, 30);

      // Rentang 7 hari (1 Nov s.d. 7 Nov)
      final instances = RecurrenceEngine.expandEventOccurrences(
        id: 'ev-daily',
        title: 'Olahraga Pagi',
        startsAt: start,
        endsAt: end,
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
        rangeStart: DateTime(2026, 11, 1, 0, 0),
        rangeEnd: DateTime(2026, 11, 7, 23, 59),
      );

      expect(instances.length, 7);
      expect(instances[0].startsAt, DateTime(2026, 11, 1, 8, 0));
      expect(instances[1].startsAt, DateTime(2026, 11, 2, 8, 0));
      expect(instances[6].startsAt, DateTime(2026, 11, 7, 8, 0));
    });

    test('Ekspansi event mingguan (FREQ=WEEKLY;INTERVAL=1)', () {
      final start = DateTime(2026, 11, 2, 14, 0); // Senin
      final end = DateTime(2026, 11, 2, 15, 0);

      // Rentang 1 bulan (November 2026)
      final instances = RecurrenceEngine.expandEventOccurrences(
        id: 'ev-weekly',
        title: 'Sprint Planning',
        startsAt: start,
        endsAt: end,
        recurrenceRule: 'FREQ=WEEKLY;INTERVAL=1',
        rangeStart: DateTime(2026, 11, 1, 0, 0),
        rangeEnd: DateTime(2026, 11, 30, 23, 59),
      );

      // Senin di November 2026: 2, 9, 16, 23, 30 (5 kali)
      expect(instances.length, 5);
      expect(instances[0].startsAt.day, 2);
      expect(instances[1].startsAt.day, 9);
      expect(instances[2].startsAt.day, 16);
      expect(instances[3].startsAt.day, 23);
      expect(instances[4].startsAt.day, 30);
    });

    test(
        'Ekspansi event bulanan (FREQ=MONTHLY;INTERVAL=1) dengan tanggal akhir bulan',
        () {
      final start = DateTime(2026, 1, 31, 19, 0);
      final end = DateTime(2026, 1, 31, 20, 0);

      // Rentang 3 bulan: Jan s.d. Maret
      final instances = RecurrenceEngine.expandEventOccurrences(
        id: 'ev-monthly',
        title: 'Review Bulanan',
        startsAt: start,
        endsAt: end,
        recurrenceRule: 'FREQ=MONTHLY;INTERVAL=1',
        rangeStart: DateTime(2026, 1, 1, 0, 0),
        rangeEnd: DateTime(2026, 3, 31, 23, 59),
      );

      expect(instances.length, 3);
      expect(instances[0].startsAt, DateTime(2026, 1, 31, 19, 0));
      // Februari 2026 bukan kabisat -> tanggal 28
      expect(instances[1].startsAt, DateTime(2026, 2, 28, 19, 0));
      // Maret -> tanggal 28 atau 31 tergantung penyesuaian (28 Feb -> 28 Mar)
      expect(instances[2].startsAt.month, 3);
    });

    test('Ekspansi event tahunan (FREQ=YEARLY;INTERVAL=1)', () {
      final start = DateTime(2024, 2, 29, 10, 0); // Kabisat
      final end = DateTime(2024, 2, 29, 11, 0);

      // Rentang 2 tahun: 2024 s.d. 2025
      final instances = RecurrenceEngine.expandEventOccurrences(
        id: 'ev-yearly',
        title: 'Ulang Tahun Langka',
        startsAt: start,
        endsAt: end,
        recurrenceRule: 'FREQ=YEARLY;INTERVAL=1',
        rangeStart: DateTime(2024, 1, 1, 0, 0),
        rangeEnd: DateTime(2025, 12, 31, 23, 59),
      );

      expect(instances.length, 2);
      expect(instances[0].startsAt, DateTime(2024, 2, 29, 10, 0));
      // 2025 bukan kabisat -> otomatis 28 Feb
      expect(instances[1].startsAt, DateTime(2025, 2, 28, 10, 0));
    });

    test('Deteksi event seharian (All-Day) dan Lintas Tengah Malam', () {
      final allDayEvent = CalendarEvent(
        id: 'all-day-1',
        userId: 'u1',
        title: 'Hari Libur Nasional',
        startsAt: DateTime(2026, 11, 20, 0, 0),
        endsAt: DateTime(2026, 11, 20, 23, 59),
        allDay: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(allDayEvent.allDay, true);

      final midnightEvent = CalendarEvent(
        id: 'cross-1',
        userId: 'u1',
        title: 'Shift Malam',
        startsAt: DateTime(2026, 11, 20, 22, 0),
        endsAt: DateTime(2026, 11, 21, 6, 0),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final occurrences = midnightEvent.expandForRange(
        DateTime(2026, 11, 20, 0, 0),
        DateTime(2026, 11, 22, 0, 0),
      );

      expect(occurrences.length, 1);
      expect(occurrences.first.isCrossMidnight, true);
      expect(occurrences.first.duration.inHours, 8);
    });

    test('Model CalendarEvent JSON Serialization bolak-balik', () {
      final now = DateTime.now().toUtc();
      final event = CalendarEvent(
        id: 'test-event-123',
        userId: 'user-abc',
        title: 'Blok Deep Work',
        description: 'Mengerjakan Fase 6',
        startsAt: now,
        endsAt: now.add(const Duration(hours: 2)),
        allDay: false,
        location: 'Ruang Belajar',
        color: '#388E3C',
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
        linkedTaskId: 'task-999',
        isTimeBlock: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = event.toJson();
      final revived = CalendarEvent.fromJson(json);

      expect(revived.id, event.id);
      expect(revived.userId, event.userId);
      expect(revived.title, event.title);
      expect(revived.isTimeBlock, true);
      expect(revived.linkedTaskId, 'task-999');
      expect(revived.color, '#388E3C');
      expect(revived.hasRecurrence, true);
    });
  });
}
