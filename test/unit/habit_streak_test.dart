import 'package:test/test.dart';
import 'package:personal_os/core/habits/habit_streak_calculator.dart';
import 'package:personal_os/features/habits/domain/habit.dart';
import 'package:personal_os/features/habits/domain/habit_log.dart';
import 'package:personal_os/features/habits/domain/routine.dart';
import 'package:personal_os/features/habits/domain/routine_step.dart';

void main() {
  group('Habit Streak Calculator Tests', () {
    final logicalToday = DateTime(2026, 11, 16);

    test('Streak harian beruntun dihitung tepat jika hari ini sudah dikerjakan',
        () {
      final completedDates = {
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 15),
        DateTime(2026, 11, 14),
      };

      final res = HabitStreakCalculator.calculate(
        frequencyType: 'daily',
        frequencyConfig: const {},
        completedDates: completedDates,
        logicalToday: logicalToday,
      );

      expect(res.currentStreak, 3);
      expect(res.longestStreak, 3);
      expect(res.isCompletedToday, true);
    });

    test('Streak tetap berlanjut dari kemarin jika hari ini belum selesai', () {
      final completedDates = {
        DateTime(2026, 11, 15),
        DateTime(2026, 11, 14),
        DateTime(2026, 11, 13),
      };

      final res = HabitStreakCalculator.calculate(
        frequencyType: 'daily',
        frequencyConfig: const {},
        completedDates: completedDates,
        logicalToday: logicalToday, // 16 Nov
      );

      // Hari ini (16 Nov) belum dikerjakan, tetapi kemarin (15 Nov) selesai -> streak tetap 3
      expect(res.currentStreak, 3);
      expect(res.isCompletedToday, false);
    });

    test(
        'Streak patah (0) jika kemarin tidak dikerjakan dan hari ini belum dikerjakan',
        () {
      final completedDates = {
        DateTime(2026, 11, 14), // 15 Nov bolos
      };

      final res = HabitStreakCalculator.calculate(
        frequencyType: 'daily',
        frequencyConfig: const {},
        completedDates: completedDates,
        logicalToday: logicalToday, // 16 Nov
      );

      expect(res.currentStreak, 0);
      expect(res.isCompletedToday, false);
    });

    test(
        'Streak specific_days (hari kerja Sen-Jum) tidak patah saat akhir pekan',
        () {
      // Misal logicalToday adalah Senin 16 Nov 2026
      // Jumat kemarin adalah 13 Nov 2026. Sabtu (14) & Minggu (15) bukan hari aktif.
      final completedDates = {
        DateTime(2026, 11, 16), // Senin
        DateTime(2026, 11, 13), // Jumat
        DateTime(2026, 11, 12), // Kamis
      };

      final res = HabitStreakCalculator.calculate(
        frequencyType: 'specific_days',
        frequencyConfig: {
          'days': [1, 2, 3, 4, 5], // Senin s.d. Jumat
        },
        completedDates: completedDates,
        logicalToday: logicalToday,
      );

      // Sabtu dan Minggu dilewati, streak tetap 3 hari kerja beruntun!
      expect(res.currentStreak, 3);
      expect(res.isCompletedToday, true);
    });

    test('Tingkat penyelesaian 30 hari dihitung proporsional', () {
      final completedDates = <DateTime>{};
      // Dikerjakan 15 hari dari 30 hari
      for (int i = 0; i < 15; i++) {
        completedDates.add(logicalToday.subtract(Duration(days: i)));
      }

      final res = HabitStreakCalculator.calculate(
        frequencyType: 'daily',
        frequencyConfig: const {},
        completedDates: completedDates,
        logicalToday: logicalToday,
      );

      expect(res.completionRate30Days, 0.5);
    });
  });

  group('Habit & Routine Domain Model Tests', () {
    test('Habit JSON Serialization bolak-balik', () {
      final now = DateTime.now().toUtc();
      final habit = Habit(
        id: 'h-100',
        userId: 'u-1',
        name: 'Membaca 10 Menit',
        description: 'Buku pengembangan diri',
        color: '#4CAF50',
        frequencyType: 'daily',
        frequencyConfig: const {'target': 1},
        createdAt: now,
        updatedAt: now,
      );

      final json = habit.toJson();
      final revived = Habit.fromJson(json);

      expect(revived.id, habit.id);
      expect(revived.name, habit.name);
      expect(revived.frequencyType, 'daily');
      expect(revived.isDeleted, false);
      expect(revived.isArchived, false);
    });

    test('HabitLog format log_date yyyy-MM-dd valid', () {
      final now = DateTime.now().toUtc();
      final log = HabitLog(
        id: 'hl-1',
        userId: 'u-1',
        habitId: 'h-100',
        logDate: DateTime(2026, 11, 16),
        done: true,
        note: 'Selesai bab 2',
        createdAt: now,
        updatedAt: now,
      );

      final json = log.toJson();
      expect(json['log_date'], '2026-11-16');
      expect(json['done'], true);
    });

    test('Routine dan RoutineStep serialisasi lengkap', () {
      final now = DateTime.now().toUtc();
      final step = RoutineStep(
        id: 's-1',
        userId: 'u-1',
        routineId: 'r-1',
        title: 'Minum 2 gelas air',
        position: 0,
        createdAt: now,
        updatedAt: now,
      );

      final routine = Routine(
        id: 'r-1',
        userId: 'u-1',
        name: 'Rutinitas Pagi',
        timeOfDay: 'morning',
        steps: [step],
        createdAt: now,
        updatedAt: now,
      );

      final json = routine.toJson();
      final revived = Routine.fromJson(json, steps: [step]);

      expect(revived.id, 'r-1');
      expect(revived.timeOfDay, 'morning');
      expect(revived.steps.length, 1);
      expect(revived.steps.first.title, 'Minum 2 gelas air');
    });
  });
}
