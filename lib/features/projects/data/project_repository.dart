import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/project.dart';
import '../../../core/errors/app_error.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(Supabase.instance.client);
});

class ProjectRepository {
  final SupabaseClient _client;

  ProjectRepository(this._client);

  Future<List<Project>> fetchProjects({bool includeCompleted = true}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      var query = _client
          .from('projects')
          .select()
          .eq('user_id', user.id)
          .isFilter('deleted_at', null);

      if (!includeCompleted) {
        query = query.eq('status', 'active');
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => Project.fromJson(e)).toList();
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<Project> createProject({
    required String name,
    String? description,
    String? color,
    DateTime? targetDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppError('Pengguna tidak terautentikasi');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final res = await _client
          .from('projects')
          .insert({
            'user_id': user.id,
            'name': name.trim(),
            'description': description?.trim(),
            'color': color ?? '#00796B',
            'target_date': targetDate?.toIso8601String().split('T').first,
            'status': 'active',
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      return Project.fromJson(res);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> updateProject({
    required String id,
    required String name,
    String? description,
    String? status,
    String? color,
    DateTime? targetDate,
    required DateTime lastKnownUpdatedAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final updates = <String, dynamic>{
        'name': name.trim(),
        'description': description?.trim(),
        'updated_at': now,
      };
      if (status != null) updates['status'] = status;
      if (color != null) updates['color'] = color;
      if (targetDate != null) {
        updates['target_date'] = targetDate.toIso8601String().split('T').first;
      }

      await _client
          .from('projects')
          .update(updates)
          .eq('id', id)
          .eq('user_id', user.id)
          .lte('updated_at', lastKnownUpdatedAt.toIso8601String());
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> softDeleteProject(String id) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('projects').update({
        'deleted_at': now,
        'updated_at': now,
      }).eq('id', id);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }
}
