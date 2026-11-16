import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/budget.dart';
import '../domain/debt.dart';
import '../domain/fin_category.dart';
import '../domain/savings_goal.dart';
import '../domain/transaction.dart';
import '../domain/wallet.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(Supabase.instance.client);
});

class FinanceRepository {
  final SupabaseClient _client;

  FinanceRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Mengambil semua dompet aktif
  Future<List<Wallet>> fetchWallets() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: true);

      return (data as List).map((json) => Wallet.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Mengambil semua kategori keuangan
  Future<List<FinCategory>> fetchCategories() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('fin_categories')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('name', ascending: true);

      return (data as List).map((json) => FinCategory.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Mengambil semua transaksi aktif
  Future<List<TransactionItem>> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? walletId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      var query = _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null);

      if (walletId != null) {
        query = query.or('wallet_id.eq.$walletId,to_wallet_id.eq.$walletId');
      }
      if (startDate != null) {
        query = query.gte('occurred_at', startDate.toUtc().toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('occurred_at', endDate.toUtc().toIso8601String());
      }

      final data = await query.order('occurred_at', ascending: false);
      return (data as List)
          .map((json) => TransactionItem.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Membuat dompet baru
  Future<Wallet> createWallet(Wallet wallet) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = wallet.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('wallets').insert(payload).select().single();
      return Wallet.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Memperbarui dompet dengan optimistic check
  Future<Wallet> updateWallet(Wallet wallet) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc();
      final payload = {
        'name': wallet.name,
        'type': wallet.type,
        'initial_balance': wallet.initialBalance.toInt(),
        'color': wallet.color,
        'icon': wallet.icon,
        'archived_at': wallet.archivedAt?.toUtc().toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final res = await _client
          .from('wallets')
          .update(payload)
          .eq('id', wallet.id)
          .eq('user_id', userId)
          .eq('updated_at', wallet.updatedAt.toUtc().toIso8601String())
          .select();

      if ((res as List).isEmpty) {
        throw const AppError(
          'Gagal memperbarui dompet: Data telah diubah dari perangkat lain.',
        );
      }

      return Wallet.fromJson(res.first);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(e.toString());
    }
  }

  /// Soft delete dompet
  Future<void> deleteWallet(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('wallets')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Membuat kategori keuangan baru
  Future<FinCategory> createCategory(FinCategory cat) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = cat.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res = await _client
          .from('fin_categories')
          .insert(payload)
          .select()
          .single();
      return FinCategory.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Mencatat transaksi baru (income, expense, transfer)
  Future<TransactionItem> createTransaction(TransactionItem tx) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = tx.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('transactions').insert(payload).select().single();
      return TransactionItem.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Soft delete transaksi
  Future<void> deleteTransaction(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('transactions')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  // ===========================================================================
  // FASE 10: BUDGETS (ANGGARAN BULANAN)
  // ===========================================================================

  /// Mengambil semua anggaran aktif untuk bulan tertentu
  Future<List<Budget>> fetchBudgets(DateTime month) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final monthStr =
          '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01';
      final data = await _client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .eq('month', monthStr)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: true);

      return (data as List).map((json) => Budget.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Membuat atau memperbarui anggaran kategori bulanan
  Future<Budget> upsertBudget(Budget budget) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = budget.toJson();
      if (budget.id.isEmpty) {
        payload.remove('id');
      }
      payload['user_id'] = userId;

      final res = await _client
          .from('budgets')
          .upsert(
            payload,
            onConflict: 'user_id, category_id, month',
          )
          .select()
          .single();
      return Budget.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Hapus anggaran (soft delete)
  Future<void> deleteBudget(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('budgets')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  // ===========================================================================
  // FASE 10: SAVINGS GOALS & CONTRIBUTIONS (TARGET TABUNGAN)
  // ===========================================================================

  /// Mengambil seluruh target tabungan aktif
  Future<List<SavingsGoal>> fetchSavingsGoals() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('savings_goals')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return (data as List).map((json) => SavingsGoal.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Mengambil semua kontribusi tabungan aktif
  Future<List<SavingsContribution>> fetchAllSavingsContributions() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('savings_contributions')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('contributed_at', ascending: false);

      return (data as List)
          .map((json) => SavingsContribution.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Membuat target tabungan baru
  Future<SavingsGoal> createSavingsGoal(SavingsGoal goal) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = goal.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('savings_goals').insert(payload).select().single();
      return SavingsGoal.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Memperbarui target tabungan
  Future<SavingsGoal> updateSavingsGoal(SavingsGoal goal) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = goal.toJson();
      payload['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final res = await _client
          .from('savings_goals')
          .update(payload)
          .eq('id', goal.id)
          .eq('user_id', userId)
          .select()
          .single();
      return SavingsGoal.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Soft delete target tabungan
  Future<void> deleteSavingsGoal(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('savings_goals')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Menambah setoran tabungan
  Future<SavingsContribution> addSavingsContribution(
      SavingsContribution contribution) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = contribution.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res = await _client
          .from('savings_contributions')
          .insert(payload)
          .select()
          .single();
      return SavingsContribution.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  // ===========================================================================
  // FASE 10: DEBTS & DEBT PAYMENTS (UTANG & PIUTANG)
  // ===========================================================================

  /// Mengambil semua catatan utang piutang aktif
  Future<List<Debt>> fetchDebts() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('debts')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return (data as List).map((json) => Debt.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Mengambil semua pembayaran cicilan aktif
  Future<List<DebtPayment>> fetchAllDebtPayments() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('debt_payments')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('paid_at', ascending: false);

      return (data as List).map((json) => DebtPayment.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Membuat catatan utang/piutang baru
  Future<Debt> createDebt(Debt debt) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = debt.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res = await _client.from('debts').insert(payload).select().single();
      return Debt.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Memperbarui catatan utang/piutang
  Future<Debt> updateDebt(Debt debt) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = debt.toJson();
      payload['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final res = await _client
          .from('debts')
          .update(payload)
          .eq('id', debt.id)
          .eq('user_id', userId)
          .select()
          .single();
      return Debt.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Tandai utang/piutang lunas
  Future<void> settleDebt(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('debts')
          .update({'settled_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Hapus utang/piutang (soft delete)
  Future<void> deleteDebt(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('debts')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Menambah pembayaran cicilan utang/piutang
  Future<DebtPayment> addDebtPayment(DebtPayment payment) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = payment.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('debt_payments').insert(payload).select().single();
      return DebtPayment.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }
}
