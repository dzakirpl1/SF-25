import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/note.dart';
import '../../../core/errors/app_error.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(Supabase.instance.client);
});

class NoteRepository {
  final SupabaseClient _client;

  NoteRepository(this._client);

  Future<List<Note>> fetchNotes({
    String? categoryId,
    String? searchQuery,
    bool includeArchived = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      var query = _client.from('notes').select().eq('user_id', user.id).isFilter('deleted_at', null);

      if (!includeArchived) {
        query = query.isFilter('archived_at', null);
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = searchQuery.trim();
        query = query.or('title.ilike.%$term%,content.ilike.%$term%');
      }

      final data = await query.order('is_pinned', ascending: false).order('updated_at', ascending: false);

      return (data as List).map((e) => Note.fromJson(e)).toList();
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<Note> createNote({
    String? title,
    required String content,
    String? categoryId,
    bool isPinned = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw AppError('Pengguna tidak terautentikasi');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final res = await _client
          .from('notes')
          .insert({
            'user_id': user.id,
            'title': title?.trim(),
            'content': content.trim(),
            'category_id': categoryId,
            'is_pinned': isPinned,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      return Note.fromJson(res);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<Note> updateNote({
    required String id,
    String? title,
    required String content,
    String? categoryId,
    bool? isPinned,
    required DateTime lastKnownUpdatedAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw AppError('Pengguna tidak terautentikasi');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final updates = <String, dynamic>{
        'title': title?.trim(),
        'content': content.trim(),
        'category_id': categoryId,
        'updated_at': now,
      };
      if (isPinned != null) {
        updates['is_pinned'] = isPinned;
      }

      final res = await _client
          .from('notes')
          .update(updates)
          .eq('id', id)
          .eq('user_id', user.id)
          .select()
          .single();

      return Note.fromJson(res);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> togglePin(String id, bool currentPin) async {
    try {
      await _client.from('notes').update({
        'is_pinned': !currentPin,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> toggleArchive(String id, bool currentlyArchived) async {
    try {
      await _client.from('notes').update({
        'archived_at': currentlyArchived ? null : DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await _client.from('notes').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }
}
