import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/reminder.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(Supabase.instance.client);
});

class ReminderRepository {
  final SupabaseClient _client;

  ReminderRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Mengambil daftar pengingat pengguna
  Future<List<Reminder>> fetchReminders({bool activeOnly = true}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      var query = _client
          .from('reminders')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null);

      if (activeOnly) {
        query = query.inFilter('status', ['scheduled', 'snoozed']);
      }

      final data = await query.order('remind_at', ascending: true);
      return (data as List).map((json) => Reminder.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Membuat pengingat baru
  Future<Reminder> createReminder(Reminder reminder) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = reminder.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('reminders').insert(payload).select().single();
      return Reminder.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Menunda pengingat
  Future<void> snoozeReminder(String id, {int minutes = 10}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    final snoozeTime =
        DateTime.now().toUtc().add(Duration(minutes: minutes)).toIso8601String();

    try {
      await _client.from('reminders').update({
        'status': 'snoozed',
        'snoozed_until': snoozeTime,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id).eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Menandai pengingat selesai/diabaikan
  Future<void> dismissReminder(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      await _client.from('reminders').update({
        'status': 'dismissed',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id).eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Soft delete pengingat
  Future<void> deleteReminder(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('reminders')
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
