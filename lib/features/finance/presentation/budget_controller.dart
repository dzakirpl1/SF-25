import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_repository.dart';
import '../domain/budget.dart';
import 'finance_controller.dart';

/// State bulan yang sedang dilihat untuk anggaran (default tanggal 1 bulan berjalan)
final selectedBudgetMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// Mengambil data anggaran mentah dari Supabase berdasarkan bulan terpilih
final rawBudgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final month = ref.watch(selectedBudgetMonthProvider);
  final repo = ref.watch(financeRepositoryProvider);
  return repo.fetchBudgets(month);
});

/// Menggabungkan anggaran dengan mutasi pengeluaran transaksi untuk kalkulasi spent & alert
final computedBudgetsProvider = Provider<AsyncValue<List<Budget>>>((ref) {
  final budgetsAsync = ref.watch(rawBudgetsProvider);
  final transactionsAsync = ref.watch(allTransactionsProvider);
  final selectedMonth = ref.watch(selectedBudgetMonthProvider);

  if (budgetsAsync is AsyncLoading || transactionsAsync is AsyncLoading) {
    return const AsyncLoading();
  }

  if (budgetsAsync is AsyncError) {
    return AsyncError(budgetsAsync.error!, budgetsAsync.stackTrace!);
  }

  final budgets = budgetsAsync.value ?? [];
  final transactions = transactionsAsync.value ?? [];

  // Hitung pengeluaran per kategori di bulan terpilih
  final spentPerCategory = <String, BigInt>{};
  for (final tx in transactions) {
    if (tx.isExpense && tx.categoryId != null) {
      if (tx.occurredAt.year == selectedMonth.year &&
          tx.occurredAt.month == selectedMonth.month) {
        final current = spentPerCategory[tx.categoryId!] ?? BigInt.zero;
        spentPerCategory[tx.categoryId!] = current + tx.amount;
      }
    }
  }

  final computedList = budgets.map((b) {
    final spent = spentPerCategory[b.categoryId] ?? BigInt.zero;
    return b.copyWith(spentAmount: spent);
  }).toList();

  return AsyncData(computedList);
});

final budgetActionsProvider =
    StateNotifierProvider<BudgetActionsNotifier, AsyncValue<void>>((ref) {
  return BudgetActionsNotifier(ref.watch(financeRepositoryProvider), ref);
});

class BudgetActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final FinanceRepository _repo;
  final Ref _ref;

  BudgetActionsNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> upsertBudget(Budget budget) async {
    state = const AsyncLoading();
    try {
      await _repo.upsertBudget(budget);
      _ref.invalidate(rawBudgetsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteBudget(id);
      _ref.invalidate(rawBudgetsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
