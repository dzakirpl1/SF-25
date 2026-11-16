import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/calendar_event.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(Supabase.instance.client);
});

class CalendarRepository {
  final SupabaseClient _client;

  CalendarRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Mengambil semua acara kalender aktif (non-deleted).
  /// Untuk event berulang, ekspansi dilakukan di sisi klien menggunakan RecurrenceEngine.
  Future<List<CalendarEvent>> fetchEvents({
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      var query = _client
          .from('events')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null);

      final data = await query.order('starts_at', ascending: true);
      return (data as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Membuat event atau blok waktu baru
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = event.toJson();
      payload.remove('id'); // Gunakan gen_random_uuid() di Supabase
      payload['user_id'] = userId;

      final res =
          await _client.from('events').insert(payload).select().single();
      return CalendarEvent.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Memperbarui event dengan pengecekan optimistic concurrency pada updated_at
  Future<CalendarEvent> updateEvent(CalendarEvent event) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc();
      final payload = {
        'title': event.title,
        'description': event.description,
        'starts_at': event.startsAt.toUtc().toIso8601String(),
        'ends_at': event.endsAt.toUtc().toIso8601String(),
        'all_day': event.allDay,
        'location': event.location,
        'color': event.color,
        'recurrence_rule': event.recurrenceRule,
        'linked_task_id': event.linkedTaskId,
        'is_time_block': event.isTimeBlock,
        'updated_at': now.toIso8601String(),
      };

      // Optimistic concurrency check
      final res = await _client
          .from('events')
          .update(payload)
          .eq('id', event.id)
          .eq('user_id', userId)
          .eq('updated_at', event.updatedAt.toUtc().toIso8601String())
          .select();

      if ((res as List).isEmpty) {
        throw const AppError(
          'Gagal memperbarui: Acara telah diubah dari perangkat lain atau tidak ditemukan.',
        );
      }

      return CalendarEvent.fromJson(res.first);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(e.toString());
    }
  }

  /// Soft delete event (pindahkan ke tempat sampah)
  Future<void> deleteEvent(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('events')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Memulihkan event dari tempat sampah
  Future<void> restoreEvent(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('events')
          .update({'deleted_at': null, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Menghapus event secara permanen
  Future<void> permanentDeleteEvent(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      await _client.from('events').delete().eq('id', id).eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }
}
