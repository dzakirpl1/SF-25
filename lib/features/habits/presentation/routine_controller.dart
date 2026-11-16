import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../settings/data/settings_repository.dart';
import '../data/routine_repository.dart';
import '../domain/routine.dart';
import '../domain/routine_log.dart';

final routineListProvider = FutureProvider<List<Routine>>((ref) async {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.fetchRoutines();
});

final routineLogsTodayProvider = FutureProvider<List<RoutineLog>>((ref) async {
  final repo = ref.watch(routineRepositoryProvider);
  final settingsAsync = ref.watch(userSettingsProvider);
  final dayStartHour = settingsAsync.value?.dayStartHour ?? 4;
  final logicalToday = AppDateUtils.getLogicalDate(DateTime.now().toUtc(),
      dayStartHour: dayStartHour);

  return repo.fetchRoutineLogs(logicalToday);
});

class RoutineActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  RoutineActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> createRoutine(Routine routine, List<String> steps) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(routineRepositoryProvider);
      await repo.createRoutine(routine, steps);
      _ref.invalidate(routineListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateRoutine(Routine routine, List<String> steps) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(routineRepositoryProvider);
      await repo.updateRoutine(routine, steps);
      _ref.invalidate(routineListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleStepToday(String routineId, String stepId) async {
    final settings = _ref.read(userSettingsProvider).value;
    final dayStartHour = settings?.dayStartHour ?? 4;
    final logicalToday = AppDateUtils.getLogicalDate(DateTime.now().toUtc(),
        dayStartHour: dayStartHour);

    try {
      final repo = _ref.read(routineRepositoryProvider);
      await repo.toggleStepCompletion(routineId, stepId, logicalToday);
      _ref.invalidate(routineLogsTodayProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteRoutine(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(routineRepositoryProvider);
      await repo.deleteRoutine(id);
      _ref.invalidate(routineListProvider);
      _ref.invalidate(routineLogsTodayProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final routineActionsProvider =
    StateNotifierProvider<RoutineActionsNotifier, AsyncValue<void>>((ref) {
  return RoutineActionsNotifier(ref);
});
