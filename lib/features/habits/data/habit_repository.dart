import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/habit.dart';
import '../domain/habit_log.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(Supabase.instance.client);
});

class HabitRepository {
  final SupabaseClient _client;

  HabitRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Mengambil semua kebiasaan aktif
  Future<List<Habit>> fetchHabits({bool includeArchived = false}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      var query = _client
          .from('habits')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null);

      if (!includeArchived) {
        query = query.filter('archived_at', 'is', null);
      }

      final data = await query.order('created_at', ascending: true);
      return (data as List).map((json) => Habit.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Mengambil log kebiasaan (default: 90 hari terakhir)
  Future<List<HabitLog>> fetchHabitLogs({DateTime? fromDate}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final from =
          fromDate ?? DateTime.now().subtract(const Duration(days: 90));
      final dateStr =
          '${from.year.toString().padLeft(4, '0')}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';

      final data = await _client
          .from('habit_logs')
          .select()
          .eq('user_id', userId)
          .gte('log_date', dateStr)
          .order('log_date', ascending: true);

      return (data as List).map((json) => HabitLog.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Membuat kebiasaan baru
  Future<Habit> createHabit(Habit habit) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = habit.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('habits').insert(payload).select().single();
      return Habit.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Memperbarui kebiasaan dengan pengecekan optimistic concurrency
  Future<Habit> updateHabit(Habit habit) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc();
      final payload = {
        'name': habit.name,
        'description': habit.description,
        'color': habit.color,
        'icon': habit.icon,
        'frequency_type': habit.frequencyType,
        'frequency_config': habit.frequencyConfig,
        'target_per_period': habit.targetPerPeriod,
        'archived_at': habit.archivedAt?.toUtc().toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final res = await _client
          .from('habits')
          .update(payload)
          .eq('id', habit.id)
          .eq('user_id', userId)
          .eq('updated_at', habit.updatedAt.toUtc().toIso8601String())
          .select();

      if ((res as List).isEmpty) {
        throw const AppError(
          'Gagal memperbarui: Data kebiasaan telah diubah dari sesi lain.',
        );
      }

      return Habit.fromJson(res.first);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(e.toString());
    }
  }

  /// Menandai / mencabut centang log kebiasaan pada tanggal logis tertentu
  Future<void> toggleHabitLog(
    String habitId,
    DateTime logDate, {
    String? note,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    final dateStr =
        '${logDate.year.toString().padLeft(4, '0')}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';

    try {
      // Cek apakah sudah ada log untuk tanggal ini
      final existing = await _client
          .from('habit_logs')
          .select()
          .eq('user_id', userId)
          .eq('habit_id', habitId)
          .eq('log_date', dateStr);

      final now = DateTime.now().toUtc().toIso8601String();

      if ((existing as List).isNotEmpty) {
        final currentDone = existing.first['done'] as bool? ?? false;
        if (currentDone) {
          // Jika sudah dicentang, hapus centang (delete log)
          await _client
              .from('habit_logs')
              .delete()
              .eq('id', existing.first['id'])
              .eq('user_id', userId);
        } else {
          // Ubah jadi done
          await _client
              .from('habit_logs')
              .update({'done': true, 'updated_at': now})
              .eq('id', existing.first['id'])
              .eq('user_id', userId);
        }
      } else {
        // Buat log baru (done = true)
        await _client.from('habit_logs').insert({
          'user_id': userId,
          'habit_id': habitId,
          'log_date': dateStr,
          'done': true,
          'note': note,
          'created_at': now,
          'updated_at': now,
        });
      }
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Soft delete kebiasaan
  Future<void> deleteHabit(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('habits')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Memulihkan kebiasaan dari tempat sampah
  Future<void> restoreHabit(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('habits')
          .update({'deleted_at': null, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Menghapus kebiasaan secara permanen
  Future<void> permanentDeleteHabit(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      await _client.from('habits').delete().eq('id', id).eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }
}
