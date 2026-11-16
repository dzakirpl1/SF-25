import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/note_controller.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_controller.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../calendar/presentation/calendar_controller.dart';
import '../../habits/domain/habit.dart';
import '../../habits/presentation/habit_controller.dart';

final trashNotesProvider = FutureProvider<List<Note>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('notes')
      .select()
      .eq('user_id', user.id)
      .not('deleted_at', 'is', null)
      .order('deleted_at', ascending: false);

  return (data as List).map((e) => Note.fromJson(e)).toList();
});

final trashTasksProvider = FutureProvider<List<TaskItem>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('tasks')
      .select()
      .eq('user_id', user.id)
      .not('deleted_at', 'is', null)
      .order('deleted_at', ascending: false);

  return (data as List).map((e) => TaskItem.fromJson(e)).toList();
});

final trashEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('events')
      .select()
      .eq('user_id', user.id)
      .not('deleted_at', 'is', null)
      .order('deleted_at', ascending: false);

  return (data as List).map((e) => CalendarEvent.fromJson(e)).toList();
});

final trashHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('habits')
      .select()
      .eq('user_id', user.id)
      .not('deleted_at', 'is', null)
      .order('deleted_at', ascending: false);

  return (data as List).map((e) => Habit.fromJson(e)).toList();
});

class TrashActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  TrashActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> restoreNote(String id) async {
    final client = Supabase.instance.client;
    await client.from('notes').update({
      'deleted_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    _ref.invalidate(trashNotesProvider);
    _ref.invalidate(noteListProvider);
    _ref.invalidate(recentNotesProvider);
  }

  Future<void> permanentDeleteNote(String id) async {
    final client = Supabase.instance.client;
    await client.from('notes').delete().eq('id', id);
    _ref.invalidate(trashNotesProvider);
  }

  Future<void> restoreTask(String id) async {
    final client = Supabase.instance.client;
    await client.from('tasks').update({
      'deleted_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    _ref.invalidate(trashTasksProvider);
    _ref.invalidate(taskListProvider);
    _ref.invalidate(todayTasksSummaryProvider);
  }

  Future<void> permanentDeleteTask(String id) async {
    final client = Supabase.instance.client;
    await client.from('tasks').delete().eq('id', id);
    _ref.invalidate(trashTasksProvider);
  }

  Future<void> restoreEvent(String id) async {
    final client = Supabase.instance.client;
    await client.from('events').update({
      'deleted_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    _ref.invalidate(trashEventsProvider);
    _ref.invalidate(calendarEventsProvider);
  }

  Future<void> permanentDeleteEvent(String id) async {
    final client = Supabase.instance.client;
    await client.from('events').delete().eq('id', id);
    _ref.invalidate(trashEventsProvider);
  }

  Future<void> restoreHabit(String id) async {
    final client = Supabase.instance.client;
    await client.from('habits').update({
      'deleted_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    _ref.invalidate(trashHabitsProvider);
    _ref.invalidate(habitListProvider);
  }

  Future<void> permanentDeleteHabit(String id) async {
    final client = Supabase.instance.client;
    await client.from('habits').delete().eq('id', id);
    _ref.invalidate(trashHabitsProvider);
  }

  Future<void> emptyTrash() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    await client
        .from('notes')
        .delete()
        .eq('user_id', user.id)
        .not('deleted_at', 'is', null);
    await client
        .from('tasks')
        .delete()
        .eq('user_id', user.id)
        .not('deleted_at', 'is', null);
    await client
        .from('events')
        .delete()
        .eq('user_id', user.id)
        .not('deleted_at', 'is', null);
    await client
        .from('habits')
        .delete()
        .eq('user_id', user.id)
        .not('deleted_at', 'is', null);

    _ref.invalidate(trashNotesProvider);
    _ref.invalidate(trashTasksProvider);
    _ref.invalidate(trashEventsProvider);
    _ref.invalidate(trashHabitsProvider);
  }
}

final trashActionsProvider =
    StateNotifierProvider<TrashActionsNotifier, AsyncValue<void>>((ref) {
  return TrashActionsNotifier(ref);
});
