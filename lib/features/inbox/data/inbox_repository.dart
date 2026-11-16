import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/inbox_item.dart';
import '../../notes/data/note_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../../core/errors/app_error.dart';

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository(
    Supabase.instance.client,
    ref.read(noteRepositoryProvider),
    ref.read(taskRepositoryProvider),
    ref.read(calendarRepositoryProvider),
  );
});

class InboxRepository {
  final SupabaseClient _client;
  final NoteRepository _noteRepo;
  final TaskRepository _taskRepo;
  final CalendarRepository _calendarRepo;

  InboxRepository(
    this._client,
    this._noteRepo,
    this._taskRepo,
    this._calendarRepo,
  );

  Future<List<InboxItem>> fetchUnprocessed() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _client
          .from('inbox_items')
          .select()
          .eq('user_id', user.id)
          .isFilter('deleted_at', null)
          .isFilter('processed_at', null)
          .order('created_at', ascending: false);

      return (data as List).map((e) => InboxItem.fromJson(e)).toList();
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<InboxItem> addInboxItem(String content,
      {String source = 'manual'}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppError('Pengguna tidak terautentikasi');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final res = await _client
          .from('inbox_items')
          .insert({
            'user_id': user.id,
            'content': content.trim(),
            'source': source,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      return InboxItem.fromJson(res);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> convertToNote(String inboxId, String content,
      {String? categoryId}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final note = await _noteRepo.createNote(
        content: content,
        categoryId: categoryId,
      );

      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('inbox_items').update({
        'processed_at': now,
        'converted_type': 'note',
        'converted_id': note.id,
        'updated_at': now,
      }).eq('id', inboxId);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> convertToTask(String inboxId, String title,
      {String? projectId, DateTime? dueDate}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final task = await _taskRepo.createTask(
        title: title,
        projectId: projectId,
        dueDate: dueDate,
      );

      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('inbox_items').update({
        'processed_at': now,
        'converted_type': 'task',
        'converted_id': task.id,
        'updated_at': now,
      }).eq('id', inboxId);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> convertToEvent(
    String inboxId,
    String title, {
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now().toUtc();
      final start = startsAt ?? now;
      final end = endsAt ?? start.add(const Duration(hours: 1));

      final event = await _calendarRepo.createEvent(
        CalendarEvent(
          id: '',
          userId: user.id,
          title: title,
          startsAt: start,
          endsAt: end,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final nowStr = now.toIso8601String();
      await _client.from('inbox_items').update({
        'processed_at': nowStr,
        'converted_type': 'event',
        'converted_id': event.id,
        'updated_at': nowStr,
      }).eq('id', inboxId);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> deleteInboxItem(String id) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('inbox_items').update({
        'deleted_at': now,
        'updated_at': now,
      }).eq('id', id);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }
}
