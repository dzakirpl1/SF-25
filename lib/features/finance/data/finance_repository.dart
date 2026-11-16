import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/fin_category.dart';
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
}
