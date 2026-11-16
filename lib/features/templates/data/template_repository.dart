import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/template_item.dart';
import '../../../core/errors/app_error.dart';

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository(Supabase.instance.client);
});

class TemplateRepository {
  final SupabaseClient _client;

  TemplateRepository(this._client);

  Future<List<TemplateItem>> fetchTemplates({String? type}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      var query = _client.from('templates').select().eq('user_id', user.id);
      if (type != null) {
        query = query.eq('type', type);
      }
      final data = await query.order('name', ascending: true);
      return (data as List).map((e) => TemplateItem.fromJson(e)).toList();
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<TemplateItem> createTemplate({
    required String name,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppError('Pengguna tidak terautentikasi');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final res = await _client
          .from('templates')
          .insert({
            'user_id': user.id,
            'name': name.trim(),
            'type': type,
            'payload': payload,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      return TemplateItem.fromJson(res);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _client.from('templates').delete().eq('id', id);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }
}
