import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/habits/habit_streak_calculator.dart';
import '../../../core/utils/date_utils.dart';
import '../../settings/data/settings_repository.dart';
import '../data/habit_repository.dart';
import '../domain/habit.dart';
import '../domain/habit_log.dart';

final habitListProvider = FutureProvider<List<Habit>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.fetchHabits();
});

final habitLogsProvider = FutureProvider<List<HabitLog>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.fetchHabitLogs();
});

/// Model gabungan kebiasaan dengan status streak dan penyelesaian hari ini
class HabitWithStreak {
  final Habit habit;
  final HabitStreakResult streakResult;

  HabitWithStreak({required this.habit, required this.streakResult});
}

/// Provider yang menghitung streak untuk setiap kebiasaan menggunakan tanggal logis pengguna
final habitsWithStreakProvider = Provider<List<HabitWithStreak>>((ref) {
  final habitsAsync = ref.watch(habitListProvider);
  final logsAsync = ref.watch(habitLogsProvider);
  final settingsAsync = ref.watch(userSettingsProvider);

  final habits = habitsAsync.value ?? [];
  final logs = logsAsync.value ?? [];
  final dayStartHour = settingsAsync.value?.dayStartHour ?? 4;
  final logicalToday = AppDateUtils.getLogicalDate(DateTime.now().toUtc(),
      dayStartHour: dayStartHour);

  // Petakan logs per habitId
  final logsByHabit = <String, Set<DateTime>>{};
  for (final l in logs) {
    if (l.done) {
      logsByHabit.putIfAbsent(l.habitId, () => {}).add(l.logDate);
    }
  }

  return habits.map((h) {
    final completedSet = logsByHabit[h.id] ?? {};
    final streak = HabitStreakCalculator.calculate(
      frequencyType: h.frequencyType,
      frequencyConfig: h.frequencyConfig,
      completedDates: completedSet,
      logicalToday: logicalToday,
    );

    return HabitWithStreak(habit: h, streakResult: streak);
  }).toList();
});

class HabitActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  HabitActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> createHabit(Habit habit) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(habitRepositoryProvider);
      await repo.createHabit(habit);
      _ref.invalidate(habitListProvider);
      _ref.invalidate(habitLogsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateHabit(Habit habit) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(habitRepositoryProvider);
      await repo.updateHabit(habit);
      _ref.invalidate(habitListProvider);
      _ref.invalidate(habitLogsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleHabitToday(String habitId) async {
    final settings = _ref.read(userSettingsProvider).value;
    final dayStartHour = settings?.dayStartHour ?? 4;
    final logicalToday = AppDateUtils.getLogicalDate(DateTime.now().toUtc(),
        dayStartHour: dayStartHour);

    try {
      final repo = _ref.read(habitRepositoryProvider);
      await repo.toggleHabitLog(habitId, logicalToday);
      _ref.invalidate(habitLogsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteHabit(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(habitRepositoryProvider);
      await repo.deleteHabit(id);
      _ref.invalidate(habitListProvider);
      _ref.invalidate(habitLogsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final habitActionsProvider =
    StateNotifierProvider<HabitActionsNotifier, AsyncValue<void>>((ref) {
  return HabitActionsNotifier(ref);
});
