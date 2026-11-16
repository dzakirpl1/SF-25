import 'package:personal_os/core/recurrence/recurrence_engine.dart';
import 'package:personal_os/features/tasks/domain/task.dart';
import 'package:test/test.dart';

void main() {
  group('RecurrenceEngine Tests', () {
    test('Pengulangan harian (FREQ=DAILY;INTERVAL=1)', () {
      final base = DateTime(2026, 11, 13, 9, 0);
      final next =
          RecurrenceEngine.computeNextDueDate('FREQ=DAILY;INTERVAL=1', base);

      expect(next, isNotNull);
      expect(next!.day, 14);
      expect(next.month, 11);
    });

    test('Pengulangan harian interval 2 (FREQ=DAILY;INTERVAL=2)', () {
      final base = DateTime(2026, 11, 13, 9, 0);
      final next =
          RecurrenceEngine.computeNextDueDate('FREQ=DAILY;INTERVAL=2', base);

      expect(next, isNotNull);
      expect(next!.day, 15);
    });

    test('Pengulangan mingguan (FREQ=WEEKLY;INTERVAL=1)', () {
      final base = DateTime(2026, 11, 13, 9, 0);
      final next =
          RecurrenceEngine.computeNextDueDate('FREQ=WEEKLY;INTERVAL=1', base);

      expect(next, isNotNull);
      expect(next!.day, 20);
      expect(next.month, 11);
    });

    test(
        'Pengulangan bulanan (FREQ=MONTHLY;INTERVAL=1) dengan penyesuaian akhir bulan',
        () {
      // 31 Januari ke Februari (bukan tahun kabisat -> tanggal 28)
      final jan31 = DateTime(2027, 1, 31, 9, 0);
      final nextFeb =
          RecurrenceEngine.computeNextDueDate('FREQ=MONTHLY;INTERVAL=1', jan31);

      expect(nextFeb, isNotNull);
      expect(nextFeb!.month, 2);
      expect(nextFeb.day, 28);

      // 31 Mei ke Juni (Juni 30 hari)
      final may31 = DateTime(2026, 5, 31, 9, 0);
      final nextJun =
          RecurrenceEngine.computeNextDueDate('FREQ=MONTHLY;INTERVAL=1', may31);

      expect(nextJun, isNotNull);
      expect(nextJun!.month, 6);
      expect(nextJun.day, 30);
    });

    test('Format deskripsi ramah Bahasa Indonesia', () {
      expect(RecurrenceEngine.formatRuleToText('FREQ=DAILY;INTERVAL=1'),
          'Setiap hari');
      expect(RecurrenceEngine.formatRuleToText('FREQ=WEEKLY;INTERVAL=1'),
          'Setiap minggu');
      expect(RecurrenceEngine.formatRuleToText('FREQ=MONTHLY;INTERVAL=1'),
          'Setiap bulan');
      expect(RecurrenceEngine.formatRuleToText(null), 'Tidak berulang');
    });
  });

  group('Eisenhower Quadrant Tests', () {
    test('Perhitungan kuadran tepat', () {
      final t1 = TaskItem(
        id: '1',
        userId: 'u1',
        title: 'Mendesak & Penting',
        isImportant: true,
        isUrgent: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(t1.eisenhowerQuadrant, EisenhowerQuadrant.q1UrgentImportant);

      final t2 = TaskItem(
        id: '2',
        userId: 'u1',
        title: 'Penting Tidak Mendesak',
        isImportant: true,
        isUrgent: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(t2.eisenhowerQuadrant, EisenhowerQuadrant.q2ImportantNotUrgent);

      final t3 = TaskItem(
        id: '3',
        userId: 'u1',
        title: 'Mendesak Tidak Penting',
        isImportant: false,
        isUrgent: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(t3.eisenhowerQuadrant, EisenhowerQuadrant.q3UrgentNotImportant);

      final t4 = TaskItem(
        id: '4',
        userId: 'u1',
        title: 'Tidak Mendesak Tidak Penting',
        isImportant: false,
        isUrgent: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(t4.eisenhowerQuadrant, EisenhowerQuadrant.q4NotUrgentNotImportant);
    });
  });
}
