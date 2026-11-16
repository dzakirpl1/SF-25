import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_repository.dart';
import '../domain/savings_goal.dart';

/// Provider data mentah seluruh target tabungan
final rawSavingsGoalsProvider = FutureProvider<List<SavingsGoal>>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  return repo.fetchSavingsGoals();
});

/// Provider seluruh setoran tabungan
final rawSavingsContributionsProvider =
    FutureProvider<List<SavingsContribution>>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  return repo.fetchAllSavingsContributions();
});

/// Menggabungkan target tabungan dengan total setoran yang sudah masuk
final computedSavingsGoalsProvider =
    Provider<AsyncValue<List<SavingsGoal>>>((ref) {
  final goalsAsync = ref.watch(rawSavingsGoalsProvider);
  final contribsAsync = ref.watch(rawSavingsContributionsProvider);

  if (goalsAsync is AsyncLoading || contribsAsync is AsyncLoading) {
    return const AsyncLoading();
  }

  if (goalsAsync is AsyncError) {
    return AsyncError(goalsAsync.error!, goalsAsync.stackTrace!);
  }

  final goals = goalsAsync.value ?? [];
  final contribs = contribsAsync.value ?? [];

  final sumPerGoal = <String, BigInt>{};
  for (final c in contribs) {
    final cur = sumPerGoal[c.goalId] ?? BigInt.zero;
    sumPerGoal[c.goalId] = cur + c.amount;
  }

  final computedList = goals.map((g) {
    final collected = sumPerGoal[g.id] ?? BigInt.zero;
    return g.copyWith(currentAmount: collected);
  }).toList();

  return AsyncData(computedList);
});

final savingsActionsProvider =
    StateNotifierProvider<SavingsActionsNotifier, AsyncValue<void>>((ref) {
  return SavingsActionsNotifier(ref.watch(financeRepositoryProvider), ref);
});

class SavingsActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final FinanceRepository _repo;
  final Ref _ref;

  SavingsActionsNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> createSavingsGoal(SavingsGoal goal) async {
    state = const AsyncLoading();
    try {
      await _repo.createSavingsGoal(goal);
      _ref.invalidate(rawSavingsGoalsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    state = const AsyncLoading();
    try {
      await _repo.updateSavingsGoal(goal);
      _ref.invalidate(rawSavingsGoalsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteSavingsGoal(id);
      _ref.invalidate(rawSavingsGoalsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> addContribution(SavingsContribution contrib) async {
    state = const AsyncLoading();
    try {
      await _repo.addSavingsContribution(contrib);
      _ref.invalidate(rawSavingsContributionsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
