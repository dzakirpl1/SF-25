import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/focus_repository.dart';
import '../domain/focus_session.dart';
import '../domain/focus_statistics.dart';
import '../domain/pomodoro_state.dart';
import '../domain/time_entry.dart';

final focusSessionsProvider = FutureProvider<List<FocusSession>>((ref) async {
  final repo = ref.watch(focusRepositoryProvider);
  return repo.fetchFocusSessions();
});

final timeEntriesProvider = FutureProvider<List<TimeEntry>>((ref) async {
  final repo = ref.watch(focusRepositoryProvider);
  return repo.fetchTimeEntries();
});

/// Provider agregasi statistik fokus dan waktu
final focusStatsProvider = Provider<FocusStatistics>((ref) {
  final sessionsAsync = ref.watch(focusSessionsProvider);
  final timeEntriesAsync = ref.watch(timeEntriesProvider);

  final sessions = sessionsAsync.value ?? [];
  final entries = timeEntriesAsync.value ?? [];

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final sevenDaysAgo = startOfToday.subtract(const Duration(days: 7));

  int todayFocusMinutes = 0;
  int todayCompletedSessions = 0;
  int weekFocusMinutes = 0;

  for (final s in sessions) {
    if (s.startedAt.isAfter(startOfToday)) {
      todayFocusMinutes += s.actualMinutes;
      if (s.completed) todayCompletedSessions++;
    }
    if (s.startedAt.isAfter(sevenDaysAgo)) {
      weekFocusMinutes += s.actualMinutes;
    }
  }

  int weekTotalTimeSeconds = 0;
  for (final e in entries) {
    if (e.startedAt.isAfter(sevenDaysAgo)) {
      weekTotalTimeSeconds += e.durationSeconds;
    }
  }

  return FocusStatistics(
    todayFocusMinutes: todayFocusMinutes,
    todayCompletedSessions: todayCompletedSessions,
    weekFocusMinutes: weekFocusMinutes,
    weekTotalTimeMinutes: weekTotalTimeSeconds ~/ 60,
  );
});

final pomodoroTimerProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier(ref);
});

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  final Ref _ref;
  Timer? _timer;

  PomodoroNotifier(this._ref)
      : super(const PomodoroState(
          mode: 'pomodoro',
          totalSeconds: 25 * 60,
          remainingSeconds: 25 * 60,
        ));

  void switchMode(String mode) {
    _timer?.cancel();
    int seconds = 25 * 60;
    if (mode == 'short_break') seconds = 5 * 60;
    if (mode == 'long_break') seconds = 15 * 60;

    state = state.copyWith(
      mode: mode,
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: false,
    );
  }

  void setTaskAndProject(String? taskId, String? projectId) {
    state = state.copyWith(
      selectedTaskId: taskId,
      selectedProjectId: projectId,
      clearTask: taskId == null,
      clearProject: projectId == null,
    );
  }

  void start() {
    if (state.isRunning) return;

    final now = DateTime.now().toUtc();
    state = state.copyWith(
      isRunning: true,
      startedAt: state.startedAt ?? now,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _timer?.cancel();
        completeSession();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: state.totalSeconds,
      isRunning: false,
    );
  }

  Future<void> completeSession() async {
    _timer?.cancel();
    final started = state.startedAt ?? DateTime.now().toUtc();
    final ended = DateTime.now().toUtc();
    final plannedMin = state.totalSeconds ~/ 60;
    final actualMin = (state.totalSeconds - state.remainingSeconds) ~/ 60;

    final session = FocusSession(
      id: '',
      userId: '',
      taskId: state.selectedTaskId,
      projectId: state.selectedProjectId,
      startedAt: started,
      endedAt: ended,
      plannedMinutes: plannedMin,
      actualMinutes: actualMin > 0 ? actualMin : plannedMin,
      completed: state.remainingSeconds == 0,
      sessionType: state.mode,
      createdAt: ended,
      updatedAt: ended,
    );

    await _ref.read(focusActionsProvider.notifier).createSession(session);

    // Reset timer
    state = state.copyWith(
      remainingSeconds: state.totalSeconds,
      isRunning: false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusActionsProvider =
    StateNotifierProvider<FocusActionsNotifier, AsyncValue<void>>((ref) {
  return FocusActionsNotifier(ref.watch(focusRepositoryProvider), ref);
});

class FocusActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final FocusRepository _repo;
  final Ref _ref;

  FocusActionsNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> createSession(FocusSession session) async {
    state = const AsyncLoading();
    try {
      await _repo.createFocusSession(session);
      _ref.invalidate(focusSessionsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteSession(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteFocusSession(id);
      _ref.invalidate(focusSessionsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> createTimeEntry(TimeEntry entry) async {
    state = const AsyncLoading();
    try {
      await _repo.createTimeEntry(entry);
      _ref.invalidate(timeEntriesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteTimeEntry(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteTimeEntry(id);
      _ref.invalidate(timeEntriesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
