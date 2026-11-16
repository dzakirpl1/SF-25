import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_repository.dart';
import '../domain/debt.dart';

/// Provider data mentah utang piutang
final rawDebtsProvider = FutureProvider<List<Debt>>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  return repo.fetchDebts();
});

/// Provider seluruh pembayaran cicilan utang
final rawDebtPaymentsProvider = FutureProvider<List<DebtPayment>>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  return repo.fetchAllDebtPayments();
});

/// Menggabungkan utang/piutang dengan mutasi cicilan yang telah terbayar
final computedDebtsProvider = Provider<AsyncValue<List<Debt>>>((ref) {
  final debtsAsync = ref.watch(rawDebtsProvider);
  final paymentsAsync = ref.watch(rawDebtPaymentsProvider);

  if (debtsAsync is AsyncLoading || paymentsAsync is AsyncLoading) {
    return const AsyncLoading();
  }

  if (debtsAsync is AsyncError) {
    return AsyncError(debtsAsync.error!, debtsAsync.stackTrace!);
  }

  final debts = debtsAsync.value ?? [];
  final payments = paymentsAsync.value ?? [];

  final paidPerDebt = <String, BigInt>{};
  for (final p in payments) {
    final cur = paidPerDebt[p.debtId] ?? BigInt.zero;
    paidPerDebt[p.debtId] = cur + p.amount;
  }

  final computedList = debts.map((d) {
    final paid = paidPerDebt[d.id] ?? BigInt.zero;
    return d.copyWith(paidAmount: paid);
  }).toList();

  return AsyncData(computedList);
});

final debtActionsProvider =
    StateNotifierProvider<DebtActionsNotifier, AsyncValue<void>>((ref) {
  return DebtActionsNotifier(ref.watch(financeRepositoryProvider), ref);
});

class DebtActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final FinanceRepository _repo;
  final Ref _ref;

  DebtActionsNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> createDebt(Debt debt) async {
    state = const AsyncLoading();
    try {
      await _repo.createDebt(debt);
      _ref.invalidate(rawDebtsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateDebt(Debt debt) async {
    state = const AsyncLoading();
    try {
      await _repo.updateDebt(debt);
      _ref.invalidate(rawDebtsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteDebt(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteDebt(id);
      _ref.invalidate(rawDebtsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> settleDebt(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.settleDebt(id);
      _ref.invalidate(rawDebtsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> addPayment(DebtPayment payment) async {
    state = const AsyncLoading();
    try {
      await _repo.addDebtPayment(payment);
      _ref.invalidate(rawDebtPaymentsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
