import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/routine.dart';
import '../domain/routine_log.dart';
import '../domain/routine_step.dart';

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(Supabase.instance.client);
});

class RoutineRepository {
  final SupabaseClient _client;

  RoutineRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Mengambil semua rutinitas aktif beserta langkah-langkahnya
  Future<List<Routine>> fetchRoutines() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final routineData = await _client
          .from('routines')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: true);

      final stepsData = await _client
          .from('routine_steps')
          .select()
          .eq('user_id', userId)
          .order('position', ascending: true);

      final stepsMap = <String, List<RoutineStep>>{};
      for (final s in (stepsData as List)) {
        final step = RoutineStep.fromJson(s);
        stepsMap.putIfAbsent(step.routineId, () => []).add(step);
      }

      return (routineData as List).map((r) {
        final rId = r['id'] as String;
        return Routine.fromJson(r, steps: stepsMap[rId] ?? []);
      }).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Mengambil log penyelesaian rutinitas untuk tanggal tertentu
  Future<List<RoutineLog>> fetchRoutineLogs(DateTime logDate) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    final dateStr =
        '${logDate.year.toString().padLeft(4, '0')}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';

    try {
      final data = await _client
          .from('routine_logs')
          .select()
          .eq('user_id', userId)
          .eq('log_date', dateStr);

      return (data as List).map((json) => RoutineLog.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Membuat rutinitas baru beserta langkah-langkah awalnya
  Future<Routine> createRoutine(
      Routine routine, List<String> stepTitles) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = routine.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('routines').insert(payload).select().single();
      final newRoutine = Routine.fromJson(res);

      final createdSteps = <RoutineStep>[];
      for (int i = 0; i < stepTitles.length; i++) {
        final title = stepTitles[i].trim();
        if (title.isEmpty) continue;

        final stepRes = await _client
            .from('routine_steps')
            .insert({
              'user_id': userId,
              'routine_id': newRoutine.id,
              'title': title,
              'position': i,
            })
            .select()
            .single();

        createdSteps.add(RoutineStep.fromJson(stepRes));
      }

      return newRoutine.copyWith(steps: createdSteps);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Memperbarui rutinitas
  Future<Routine> updateRoutine(
      Routine routine, List<String> stepTitles) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc();
      final payload = {
        'name': routine.name,
        'description': routine.description,
        'time_of_day': routine.timeOfDay,
        'active_days': routine.activeDays,
        'archived_at': routine.archivedAt?.toUtc().toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final res = await _client
          .from('routines')
          .update(payload)
          .eq('id', routine.id)
          .eq('user_id', userId)
          .eq('updated_at', routine.updatedAt.toUtc().toIso8601String())
          .select();

      if ((res as List).isEmpty) {
        throw const AppError(
          'Gagal memperbarui: Rutinitas telah diubah dari sesi lain.',
        );
      }

      // Perbarui langkah: hapus langkah lama dan tambahkan yang baru
      await _client
          .from('routine_steps')
          .delete()
          .eq('routine_id', routine.id)
          .eq('user_id', userId);

      final createdSteps = <RoutineStep>[];
      for (int i = 0; i < stepTitles.length; i++) {
        final title = stepTitles[i].trim();
        if (title.isEmpty) continue;

        final stepRes = await _client
            .from('routine_steps')
            .insert({
              'user_id': userId,
              'routine_id': routine.id,
              'title': title,
              'position': i,
            })
            .select()
            .single();

        createdSteps.add(RoutineStep.fromJson(stepRes));
      }

      return Routine.fromJson(res.first, steps: createdSteps);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      if (e is AppError) rethrow;
      throw AppError(e.toString());
    }
  }

  /// Menandai satu langkah rutinitas selesai / belum selesai pada tanggal tertentu
  Future<void> toggleStepCompletion(
    String routineId,
    String stepId,
    DateTime logDate,
  ) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    final dateStr =
        '${logDate.year.toString().padLeft(4, '0')}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';

    try {
      final existing = await _client
          .from('routine_logs')
          .select()
          .eq('user_id', userId)
          .eq('routine_id', routineId)
          .eq('log_date', dateStr);

      final now = DateTime.now().toUtc().toIso8601String();

      if ((existing as List).isNotEmpty) {
        final row = existing.first;
        final list =
            List<String>.from(row['completed_step_ids'] as List? ?? []);
        if (list.contains(stepId)) {
          list.remove(stepId);
        } else {
          list.add(stepId);
        }

        await _client
            .from('routine_logs')
            .update({'completed_step_ids': list, 'updated_at': now})
            .eq('id', row['id'])
            .eq('user_id', userId);
      } else {
        await _client.from('routine_logs').insert({
          'user_id': userId,
          'routine_id': routineId,
          'log_date': dateStr,
          'completed_step_ids': [stepId],
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

  /// Soft delete rutinitas
  Future<void> deleteRoutine(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('routines')
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
