import 'package:test/test.dart';
import 'package:personal_os/features/focus/domain/focus_session.dart';
import 'package:personal_os/features/focus/domain/focus_statistics.dart';
import 'package:personal_os/features/focus/domain/pomodoro_state.dart';
import 'package:personal_os/features/focus/domain/time_entry.dart';

void main() {
  group('Focus & Time Tracking Tests (Fase 11)', () {
    test('FocusSession serialization dan getter tipe sesi valid', () {
      final now = DateTime.now().toUtc();
      final session = FocusSession(
        id: 'foc-1',
        userId: 'usr-1',
        taskId: 'task-10',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 25)),
        plannedMinutes: 25,
        actualMinutes: 25,
        completed: true,
        sessionType: 'pomodoro',
        note: 'Sesi koding algoritma',
        createdAt: now,
        updatedAt: now,
      );

      expect(session.isPomodoro, true);
      expect(session.isBreak, false);

      final json = session.toJson();
      expect(json['task_id'], 'task-10');
      expect(json['planned_minutes'], 25);
      expect(json['session_type'], 'pomodoro');

      final revived = FocusSession.fromJson(json);
      expect(revived.id, 'foc-1');
      expect(revived.actualMinutes, 25);
      expect(revived.completed, true);
    });

    test('TimeEntry serialization dan format durasi teks tepat', () {
      final now = DateTime.now().toUtc();
      final entry1 = TimeEntry(
        id: 'time-1',
        userId: 'usr-1',
        activity: 'Riset Desain UI',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 45)),
        durationSeconds: 45 * 60,
        createdAt: now,
        updatedAt: now,
      );

      expect(entry1.durationMinutes, 45);
      expect(entry1.formattedDuration, '45m');

      final entry2 = entry1.copyWith(
        durationSeconds: 90 * 60, // 1 jam 30 menit
      );
      expect(entry2.formattedDuration, '1j 30m');

      final json = entry2.toJson();
      expect(json['activity'], 'Riset Desain UI');
      expect(json['duration_seconds'], 5400);

      final revived = TimeEntry.fromJson(json);
      expect(revived.id, 'time-1');
      expect(revived.durationSeconds, 5400);
    });

    test('FocusStatistics format ringkasan jam dan menit', () {
      const stats = FocusStatistics(
        todayFocusMinutes: 125, // 2j 5m
        todayCompletedSessions: 5,
        weekFocusMinutes: 650, // 10j 50m
        weekTotalTimeMinutes: 45,
      );

      expect(stats.formattedTodayFocus, '2j 5m');
      expect(stats.formattedWeekFocus, '10j 50m');
      expect(stats.formattedWeekTotalTime, '45m');
      expect(stats.todayCompletedSessions, 5);
    });

    test('PomodoroState perhitungan progres dan format waktu MM:SS', () {
      const state = PomodoroState(
        mode: 'pomodoro',
        totalSeconds: 25 * 60,
        remainingSeconds: 15 * 60, // 10 menit berlalu
      );

      expect(state.formattedTime, '15:00');
      expect(state.progress, closeTo(0.4, 0.01));
    });
  });
}
