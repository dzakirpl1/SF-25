import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/item_link.dart';
import '../../../core/errors/app_error.dart';

final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  return LinkRepository(Supabase.instance.client);
});

class LinkRepository {
  final SupabaseClient _client;

  LinkRepository(this._client);

  Future<List<ItemLink>> fetchLinksFor(String type, String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _client.from('links').select().eq('user_id', user.id).or(
          'and(source_type.eq.$type,source_id.eq.$id),and(target_type.eq.$type,target_id.eq.$id)');

      return (data as List).map((e) => ItemLink.fromJson(e)).toList();
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> createLink({
    required String sourceType,
    required String sourceId,
    required String targetType,
    required String targetId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('links').insert({
        'user_id': user.id,
        'source_type': sourceType,
        'source_id': sourceId,
        'target_type': targetType,
        'target_id': targetId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> deleteLink(String linkId) async {
    try {
      await _client.from('links').delete().eq('id', linkId);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }
}
