import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_repository.dart';
import '../domain/fin_category.dart';
import '../domain/financial_summary.dart';
import '../domain/transaction.dart';
import '../domain/wallet.dart';

final rawWalletsProvider = FutureProvider<List<Wallet>>((ref) async {
  return ref.watch(financeRepositoryProvider).fetchWallets();
});

final finCategoriesProvider = FutureProvider<List<FinCategory>>((ref) async {
  return ref.watch(financeRepositoryProvider).fetchCategories();
});

final allTransactionsProvider =
    FutureProvider<List<TransactionItem>>((ref) async {
  return ref.watch(financeRepositoryProvider).fetchTransactions();
});

/// Provider dompet dengan saldo terkini yang dihitung dari saldo awal + seluruh transaksi
final walletsWithBalanceProvider = Provider<List<Wallet>>((ref) {
  final walletsAsync = ref.watch(rawWalletsProvider);
  final txAsync = ref.watch(allTransactionsProvider);

  final wallets = walletsAsync.value ?? [];
  final txs = txAsync.value ?? [];

  // Hitung mutasi per dompet
  final mutationMap = <String, BigInt>{};
  for (final tx in txs) {
    if (tx.isIncome) {
      mutationMap[tx.walletId] =
          (mutationMap[tx.walletId] ?? BigInt.zero) + tx.amount;
    } else if (tx.isExpense) {
      mutationMap[tx.walletId] =
          (mutationMap[tx.walletId] ?? BigInt.zero) - tx.amount;
    } else if (tx.isTransfer) {
      // Keluar dari walletId
      mutationMap[tx.walletId] =
          (mutationMap[tx.walletId] ?? BigInt.zero) - tx.amount;
      // Masuk ke toWalletId
      if (tx.toWalletId != null) {
        mutationMap[tx.toWalletId!] =
            (mutationMap[tx.toWalletId!] ?? BigInt.zero) + tx.amount;
      }
    }
  }

  return wallets.map((w) {
    final mutation = mutationMap[w.id] ?? BigInt.zero;
    return w.copyWith(currentBalance: w.initialBalance + mutation);
  }).toList();
});

/// Ringkasan Keuangan (Total Saldo, Pemasukan Bulan Ini, Pengeluaran Bulan Ini)
final financialSummaryProvider = Provider<FinancialSummary>((ref) {
  final wallets = ref.watch(walletsWithBalanceProvider);
  final txs = ref.watch(allTransactionsProvider).value ?? [];

  BigInt totalBal = BigInt.zero;
  for (final w in wallets) {
    totalBal += w.currentBalance;
  }

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  BigInt monthIncome = BigInt.zero;
  BigInt monthExpense = BigInt.zero;

  for (final t in txs) {
    if (!t.occurredAt.isBefore(startOfMonth)) {
      if (t.isIncome) {
        monthIncome += t.amount;
      } else if (t.isExpense) {
        monthExpense += t.amount;
      }
    }
  }

  return FinancialSummary(
    totalBalance: totalBal,
    monthlyIncome: monthIncome,
    monthlyExpense: monthExpense,
  );
});

class FinanceActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  FinanceActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> createWallet(Wallet wallet) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(financeRepositoryProvider);
      await repo.createWallet(wallet);
      _ref.invalidate(rawWalletsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateWallet(Wallet wallet) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(financeRepositoryProvider);
      await repo.updateWallet(wallet);
      _ref.invalidate(rawWalletsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteWallet(String id) async {
    try {
      final repo = _ref.read(financeRepositoryProvider);
      await repo.deleteWallet(id);
      _ref.invalidate(rawWalletsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createTransaction(TransactionItem tx) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(financeRepositoryProvider);
      await repo.createTransaction(tx);
      _ref.invalidate(allTransactionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final repo = _ref.read(financeRepositoryProvider);
      await repo.deleteTransaction(id);
      _ref.invalidate(allTransactionsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final financeActionsProvider =
    StateNotifierProvider<FinanceActionsNotifier, AsyncValue<void>>((ref) {
  return FinanceActionsNotifier(ref);
});
