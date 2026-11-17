import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/focus_session.dart';
import '../domain/time_entry.dart';

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  return FocusRepository(Supabase.instance.client);
});

class FocusRepository {
  final SupabaseClient _client;

  FocusRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Mengambil riwayat sesi fokus
  Future<List<FocusSession>> fetchFocusSessions({int limit = 50}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('focus_sessions')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('started_at', ascending: false)
          .limit(limit);

      return (data as List).map((j) => FocusSession.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Mencatat sesi fokus baru
  Future<FocusSession> createFocusSession(FocusSession session) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = session.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res = await _client
          .from('focus_sessions')
          .insert(payload)
          .select()
          .single();
      return FocusSession.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Hapus sesi fokus (soft delete)
  Future<void> deleteFocusSession(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('focus_sessions')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Mengambil riwayat time entries
  Future<List<TimeEntry>> fetchTimeEntries({int limit = 50}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('time_entries')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('started_at', ascending: false)
          .limit(limit);

      return (data as List).map((j) => TimeEntry.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Mencatat time entry baru
  Future<TimeEntry> createTimeEntry(TimeEntry entry) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = entry.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('time_entries').insert(payload).select().single();
      return TimeEntry.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Hapus time entry (soft delete)
  Future<void> deleteTimeEntry(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('time_entries')
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
