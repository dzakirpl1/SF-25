import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/subtask.dart';
import '../domain/task.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/recurrence/recurrence_engine.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(Supabase.instance.client);
});

class TaskRepository {
  final SupabaseClient _client;

  TaskRepository(this._client);

  Future<List<TaskItem>> fetchTasks({
    String? projectId,
    String? statusFilter, // 'active', 'completed', 'all'
    bool includeArchived = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      var query = _client
          .from('tasks')
          .select('*, subtasks(*)')
          .eq('user_id', user.id)
          .isFilter('deleted_at', null);

      if (!includeArchived) {
        query = query.isFilter('archived_at', null);
      }

      if (projectId != null && projectId.isNotEmpty) {
        query = query.eq('project_id', projectId);
      }

      if (statusFilter == 'active') {
        query = query.neq('status', 'completed');
      } else if (statusFilter == 'completed') {
        query = query.eq('status', 'completed');
      }

      final data = await query
          .order('priority', ascending: true)
          .order('due_date', ascending: true);

      return (data as List).map((row) {
        final subtasksData = (row['subtasks'] as List? ?? [])
            .map((s) => Subtask.fromJson(s as Map<String, dynamic>))
            .toList();
        return TaskItem.fromJson(row as Map<String, dynamic>,
            subtasks: subtasksData);
      }).toList();
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<TaskItem> createTask({
    String? projectId,
    required String title,
    String? description,
    int priority = 4,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    String? recurrenceRule,
    List<String> initialSubtasks = const [],
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AppError('Pengguna tidak terautentikasi');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final res = await _client
          .from('tasks')
          .insert({
            'user_id': user.id,
            'project_id': projectId,
            'title': title.trim(),
            'description': description?.trim(),
            'priority': priority,
            'is_important': isImportant,
            'is_urgent': isUrgent,
            'due_date': dueDate?.toIso8601String(),
            'recurrence_rule': recurrenceRule,
            'status': 'todo',
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      final createdTask = TaskItem.fromJson(res);

      if (initialSubtasks.isNotEmpty) {
        final subtaskPayloads = initialSubtasks.asMap().entries.map((entry) {
          return {
            'user_id': user.id,
            'task_id': createdTask.id,
            'title': entry.value.trim(),
            'is_done': false,
            'position': entry.key,
            'created_at': now,
            'updated_at': now,
          };
        }).toList();

        await _client.from('subtasks').insert(subtaskPayloads);
      }

      return createdTask;
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> updateTask({
    required String id,
    String? projectId,
    required String title,
    String? description,
    int? priority,
    bool? isImportant,
    bool? isUrgent,
    DateTime? dueDate,
    String? recurrenceRule,
    required DateTime lastKnownUpdatedAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final updates = <String, dynamic>{
        'project_id': projectId,
        'title': title.trim(),
        'description': description?.trim(),
        'updated_at': now,
      };
      if (priority != null) updates['priority'] = priority;
      if (isImportant != null) updates['is_important'] = isImportant;
      if (isUrgent != null) updates['is_urgent'] = isUrgent;
      updates['due_date'] = dueDate?.toIso8601String();
      updates['recurrence_rule'] = recurrenceRule;

      await _client
          .from('tasks')
          .update(updates)
          .eq('id', id)
          .eq('user_id', user.id)
          .lte('updated_at', lastKnownUpdatedAt.toIso8601String());
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> toggleTaskComplete(TaskItem task) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now().toUtc();
      final willComplete = !task.isCompleted;

      await _client.from('tasks').update({
        'status': willComplete ? 'completed' : 'todo',
        'completed_at': willComplete ? now.toIso8601String() : null,
        'updated_at': now.toIso8601String(),
      }).eq('id', task.id);

      // Aturan Khusus Tugas Berulang: Saat tugas diselesaikan, sistem otomatis membuat instance tugas berikutnya!
      if (willComplete && task.hasRecurrence) {
        final baseDate = task.dueDate ?? now;
        final nextDue =
            RecurrenceEngine.computeNextDueDate(task.recurrenceRule, baseDate);

        if (nextDue != null) {
          await _client.from('tasks').insert({
            'user_id': user.id,
            'project_id': task.projectId,
            'title': task.title,
            'description': task.description,
            'priority': task.priority,
            'is_important': task.isImportant,
            'is_urgent': task.isUrgent,
            'due_date': nextDue.toIso8601String(),
            'recurrence_rule': task.recurrenceRule,
            'status': 'todo',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
        }
      }
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> toggleSubtask(String subtaskId, bool isDone) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('subtasks').update({
        'is_done': isDone,
        'updated_at': now,
      }).eq('id', subtaskId);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> addSubtask(String taskId, String title, int position) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('subtasks').insert({
        'user_id': user.id,
        'task_id': taskId,
        'title': title.trim(),
        'is_done': false,
        'position': position,
        'created_at': now,
        'updated_at': now,
      });
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> deleteSubtask(String subtaskId) async {
    try {
      await _client.from('subtasks').delete().eq('id', subtaskId);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> softDeleteTask(String id) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('tasks').update({
        'deleted_at': now,
        'updated_at': now,
      }).eq('id', id);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }
}
