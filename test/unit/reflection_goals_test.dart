import 'package:test/test.dart';
import 'package:personal_os/features/reflection/domain/goal.dart';
import 'package:personal_os/features/reflection/domain/journal_entry.dart';
import 'package:personal_os/features/reflection/domain/mood_log.dart';
import 'package:personal_os/features/reflection/domain/periodic_review.dart';

void main() {
  group('Reflection, Journal, Mood & Goals Tests (Fase 12)', () {
    test('JournalEntry serialization dan format tanggal valid', () {
      final now = DateTime.now().toUtc();
      final entry = JournalEntry(
        id: 'jrn-1',
        userId: 'usr-1',
        entryDate: DateTime(2026, 3, 15),
        prompt: 'Apa yang Anda syukuri?',
        content: 'Hari ini berhasil menyelesaikan fitur penting.',
        createdAt: now,
        updatedAt: now,
      );

      final json = entry.toJson();
      expect(json['entry_date'], '2026-03-15');
      expect(json['prompt'], 'Apa yang Anda syukuri?');
      expect(json['content'], 'Hari ini berhasil menyelesaikan fitur penting.');

      final revived = JournalEntry.fromJson(json);
      expect(revived.id, 'jrn-1');
      expect(revived.entryDate.year, 2026);
    });

    test('MoodLog label dan emoji tepat sesuai skor', () {
      final now = DateTime.now().toUtc();
      final mood5 = MoodLog(
        id: 'm-1',
        userId: 'usr-1',
        logDate: DateTime(2026, 3, 15),
        score: 5,
        tags: const ['Senang', 'Produktif'],
        note: 'Hari yang sangat produktif!',
        createdAt: now,
        updatedAt: now,
      );

      expect(mood5.moodLabel, 'Luar Biasa');
      expect(mood5.moodEmoji, '😄');

      final mood1 = mood5.copyWith(score: 1);
      expect(mood1.moodLabel, 'Sangat Buruk');
      expect(mood1.moodEmoji, '😢');

      final json = mood5.toJson();
      expect(json['score'], 5);
      expect(json['tags'], contains('Produktif'));

      final revived = MoodLog.fromJson(json);
      expect(revived.tags.length, 2);
    });

    test('PeriodicReview serialization dan label periode', () {
      final now = DateTime.now().toUtc();
      final review = PeriodicReview(
        id: 'rev-1',
        userId: 'usr-1',
        period: 'weekly',
        periodStart: DateTime(2026, 3, 9),
        answers: const {
          'highlight': 'Menyelesaikan modul fokus',
          'improvement': 'Tidur lebih awal',
        },
        createdAt: now,
        updatedAt: now,
      );

      expect(review.periodLabel, 'Review Mingguan');
      final json = review.toJson();
      expect(json['period'], 'weekly');
      expect(json['answers']['highlight'], 'Menyelesaikan modul fokus');

      final revived = PeriodicReview.fromJson(json);
      expect(revived.answers['improvement'], 'Tidur lebih awal');
    });

    test('Goal dan KeyResult kalkulasi overallProgress dan status selesai', () {
      final now = DateTime.now().toUtc();
      final kr1 = KeyResult(
        id: 'kr-1',
        userId: 'usr-1',
        goalId: 'g-1',
        title: 'Membaca 10 Buku',
        targetValue: 10,
        currentValue: 5, // 50%
        unit: 'buku',
        createdAt: now,
        updatedAt: now,
      );

      final kr2 = KeyResult(
        id: 'kr-2',
        userId: 'usr-1',
        goalId: 'g-1',
        title: 'Menulis 5 Artikel',
        targetValue: 5,
        currentValue: 5, // 100%
        unit: 'artikel',
        createdAt: now,
        updatedAt: now,
      );

      expect(kr1.progress, 0.5);
      expect(kr1.isAchieved, false);
      expect(kr2.progress, 1.0);
      expect(kr2.isAchieved, true);

      final goal = Goal(
        id: 'g-1',
        userId: 'usr-1',
        title: 'Pengembangan Diri 2026',
        createdAt: now,
        updatedAt: now,
        keyResults: [kr1, kr2],
      );

      // Rata-rata progress: (0.5 + 1.0) / 2 = 0.75 (75%)
      expect(goal.overallProgress, closeTo(0.75, 0.01));
      expect(goal.isCompleted, false);

      final json = goal.toJson();
      expect(json['title'], 'Pengembangan Diri 2026');

      final revived = Goal.fromJson(json, keyResults: [kr1, kr2]);
      expect(revived.keyResults.length, 2);
    });
  });
}
