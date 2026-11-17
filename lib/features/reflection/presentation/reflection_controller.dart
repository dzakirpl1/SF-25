import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reflection_repository.dart';
import '../domain/goal.dart';
import '../domain/journal_entry.dart';
import '../domain/mood_log.dart';
import '../domain/periodic_review.dart';

final journalEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final repo = ref.watch(reflectionRepositoryProvider);
  return repo.fetchJournalEntries();
});

/// Jurnal kilas balik "1 Tahun Lalu Hari Ini" (On this day)
final onThisDayJournalProvider = FutureProvider<JournalEntry?>((ref) async {
  final repo = ref.watch(reflectionRepositoryProvider);
  final now = DateTime.now();
  final lastYearDate = DateTime(now.year - 1, now.month, now.day);
  return repo.fetchJournalEntryByDate(lastYearDate);
});

final moodLogsProvider = FutureProvider<List<MoodLog>>((ref) async {
  final repo = ref.watch(reflectionRepositoryProvider);
  return repo.fetchMoodLogs();
});

final reviewsProvider = FutureProvider<List<PeriodicReview>>((ref) async {
  final repo = ref.watch(reflectionRepositoryProvider);
  return repo.fetchReviews();
});

final rawGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repo = ref.watch(reflectionRepositoryProvider);
  return repo.fetchGoals();
});

final rawKeyResultsProvider = FutureProvider<List<KeyResult>>((ref) async {
  final repo = ref.watch(reflectionRepositoryProvider);
  return repo.fetchAllKeyResults();
});

/// Menggabungkan Goal dengan Key Results terdaftar
final computedGoalsProvider = Provider<AsyncValue<List<Goal>>>((ref) {
  final goalsAsync = ref.watch(rawGoalsProvider);
  final krsAsync = ref.watch(rawKeyResultsProvider);

  if (goalsAsync is AsyncLoading || krsAsync is AsyncLoading) {
    return const AsyncLoading();
  }
  if (goalsAsync is AsyncError) {
    return AsyncError(goalsAsync.error!, goalsAsync.stackTrace!);
  }

  final goals = goalsAsync.value ?? [];
  final krs = krsAsync.value ?? [];

  final krMap = <String, List<KeyResult>>{};
  for (final kr in krs) {
    krMap.putIfAbsent(kr.goalId, () => []).add(kr);
  }

  final result = goals.map((g) {
    final relatedKrs = krMap[g.id] ?? [];
    return g.copyWith(keyResults: relatedKrs);
  }).toList();

  return AsyncData(result);
});

final reflectionActionsProvider =
    StateNotifierProvider<ReflectionActionsNotifier, AsyncValue<void>>((ref) {
  return ReflectionActionsNotifier(
      ref.watch(reflectionRepositoryProvider), ref);
});

class ReflectionActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ReflectionRepository _repo;
  final Ref _ref;

  ReflectionActionsNotifier(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> saveJournal(JournalEntry entry) async {
    state = const AsyncLoading();
    try {
      await _repo.upsertJournalEntry(entry);
      _ref.invalidate(journalEntriesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteJournal(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteJournalEntry(id);
      _ref.invalidate(journalEntriesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logMood(MoodLog mood) async {
    state = const AsyncLoading();
    try {
      await _repo.upsertMoodLog(mood);
      _ref.invalidate(moodLogsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> saveReview(PeriodicReview review) async {
    state = const AsyncLoading();
    try {
      await _repo.upsertReview(review);
      _ref.invalidate(reviewsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> createGoal(Goal goal) async {
    state = const AsyncLoading();
    try {
      await _repo.createGoal(goal);
      _ref.invalidate(rawGoalsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    state = const AsyncLoading();
    try {
      await _repo.updateGoal(goal);
      _ref.invalidate(rawGoalsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteGoal(id);
      _ref.invalidate(rawGoalsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> upsertKeyResult(KeyResult kr) async {
    state = const AsyncLoading();
    try {
      await _repo.upsertKeyResult(kr);
      _ref.invalidate(rawKeyResultsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteKeyResult(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteKeyResult(id);
      _ref.invalidate(rawKeyResultsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
