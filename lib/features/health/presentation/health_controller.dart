import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/health_repository.dart';
import '../domain/health_summary.dart';
import '../domain/medication.dart';
import '../domain/sleep_log.dart';
import '../domain/water_log.dart';
import '../domain/workout.dart';

final workoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return repo.fetchWorkouts();
});

final sleepLogsProvider = FutureProvider<List<SleepLog>>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return repo.fetchSleepLogs();
});

final waterLogsProvider = FutureProvider<List<WaterLog>>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return repo.fetchWaterLogs();
});

final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return repo.fetchMedications();
});

/// Provider ringkasan dashboard kesehatan harian
final healthSummaryProvider = Provider<HealthSummary>((ref) {
  final waterAsync = ref.watch(waterLogsProvider);
  final sleepAsync = ref.watch(sleepLogsProvider);
  final workoutsAsync = ref.watch(workoutsProvider);

  final waterLogs = waterAsync.value ?? [];
  final sleepLogs = sleepAsync.value ?? [];
  final workouts = workoutsAsync.value ?? [];

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final sevenDaysAgo = startOfToday.subtract(const Duration(days: 7));

  // Hitung total air hari ini
  int todayWater = 0;
  for (final w in waterLogs) {
    if (w.loggedAt.isAfter(startOfToday)) {
      todayWater += w.amountMl;
    }
  }

  // Tidur terakhir
  final latestSleep = sleepLogs.isNotEmpty ? sleepLogs.first : null;

  // Olahraga minggu ini
  int weekWorkouts = 0;
  for (final w in workouts) {
    if (w.startedAt.isAfter(sevenDaysAgo)) {
      weekWorkouts++;
    }
  }

  return HealthSummary(
    todayWaterMl: todayWater,
    targetWaterMl: 2000,
    lastSleepDuration: latestSleep?.duration,
    lastSleepQuality: latestSleep?.quality,
    weekWorkoutsCount: weekWorkouts,
  );
});

final healthActionsProvider =
    StateNotifierProvider<HealthActionsNotifier, AsyncValue<void>>((ref) {
  return HealthActionsNotifier(ref.watch(healthRepositoryProvider), ref);
});

class HealthActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final HealthRepository _repo;
  final Ref _ref;

  HealthActionsNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> addWater(int ml) async {
    state = const AsyncLoading();
    try {
      await _repo.addWaterLog(ml);
      _ref.invalidate(waterLogsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logWorkout(Workout workout) async {
    state = const AsyncLoading();
    try {
      await _repo.createWorkout(workout);
      _ref.invalidate(workoutsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logSleep(SleepLog sleep) async {
    state = const AsyncLoading();
    try {
      await _repo.createSleepLog(sleep);
      _ref.invalidate(sleepLogsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> createMedication(Medication med) async {
    state = const AsyncLoading();
    try {
      await _repo.createMedication(med);
      _ref.invalidate(medicationsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteMedication(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteMedication(id);
      _ref.invalidate(medicationsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> markMedicationTaken(String medId) async {
    state = const AsyncLoading();
    try {
      await _repo.logMedicationTaken(medId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
