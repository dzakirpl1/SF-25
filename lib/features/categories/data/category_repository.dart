import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/note_category.dart';
import '../../../core/errors/app_error.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(Supabase.instance.client);
});

class CategoryRepository {
  final SupabaseClient _client;

  CategoryRepository(this._client);

  Future<List<NoteCategory>> fetchCategories() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await _client
          .from('note_categories')
          .select()
          .order('name', ascending: true);

      return (data as List).map((e) => NoteCategory.fromJson(e)).toList();
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<NoteCategory> createCategory({
    required String name,
    String? color,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppError('Pengguna tidak terautentikasi');

    try {
      final res = await _client
          .from('note_categories')
          .insert({
            'user_id': user.id,
            'name': name.trim(),
            'color': color ?? '#00796B',
          })
          .select()
          .single();

      return NoteCategory.fromJson(res);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    String? color,
  }) async {
    try {
      await _client.from('note_categories').update({
        'name': name.trim(),
        if (color != null) 'color': color,
      }).eq('id', id);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      // Memanggil fungsi database yang memvalidasi apakah ada catatan aktif
      await _client.rpc('delete_note_category', params: {
        'category_uuid': id,
      });
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }
}
