import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';

enum TaskTabFilter {
  all,
  today,
  upcoming,
  overdue,
  completed,
  eisenhower,
}

class TaskFilterState {
  final TaskTabFilter tab;
  final String? projectId;
  final int? priority;
  final EisenhowerQuadrant? quadrant;

  const TaskFilterState({
    this.tab = TaskTabFilter.all,
    this.projectId,
    this.priority,
    this.quadrant,
  });

  TaskFilterState copyWith({
    TaskTabFilter? tab,
    String? projectId,
    int? priority,
    EisenhowerQuadrant? quadrant,
    bool clearProject = false,
    bool clearPriority = false,
    bool clearQuadrant = false,
  }) {
    return TaskFilterState(
      tab: tab ?? this.tab,
      projectId: clearProject ? null : (projectId ?? this.projectId),
      priority: clearPriority ? null : (priority ?? this.priority),
      quadrant: clearQuadrant ? null : (quadrant ?? this.quadrant),
    );
  }
}

final taskFilterProvider = StateProvider<TaskFilterState>((ref) {
  return const TaskFilterState();
});

final taskListProvider = FutureProvider<List<TaskItem>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final filter = ref.watch(taskFilterProvider);

  final tasks = await repo.fetchTasks(
    projectId: filter.projectId,
    statusFilter: filter.tab == TaskTabFilter.completed
        ? 'completed'
        : (filter.tab == TaskTabFilter.all ? 'all' : 'active'),
  );

  return tasks;
});

final todayTasksSummaryProvider = FutureProvider<List<TaskItem>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final allActive = await repo.fetchTasks(statusFilter: 'active');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return allActive.where((t) {
    if (t.dueDate == null) return false;
    final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
    return due.isBefore(today) || due.isAtSameMomentAs(today);
  }).toList();
});

class TaskActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repo;
  final Ref _ref;

  TaskActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> createTask({
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
    state = const AsyncValue.loading();
    try {
      await _repo.createTask(
        projectId: projectId,
        title: title,
        description: description,
        priority: priority,
        isImportant: isImportant,
        isUrgent: isUrgent,
        dueDate: dueDate,
        recurrenceRule: recurrenceRule,
        initialSubtasks: initialSubtasks,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(taskListProvider);
      _ref.invalidate(todayTasksSummaryProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateTask({
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
    state = const AsyncValue.loading();
    try {
      await _repo.updateTask(
        id: id,
        projectId: projectId,
        title: title,
        description: description,
        priority: priority,
        isImportant: isImportant,
        isUrgent: isUrgent,
        dueDate: dueDate,
        recurrenceRule: recurrenceRule,
        lastKnownUpdatedAt: lastKnownUpdatedAt,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(taskListProvider);
      _ref.invalidate(todayTasksSummaryProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> toggleComplete(TaskItem task) async {
    try {
      await _repo.toggleTaskComplete(task);
      _ref.invalidate(taskListProvider);
      _ref.invalidate(todayTasksSummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSubtask(String subtaskId, bool isDone) async {
    try {
      await _repo.toggleSubtask(subtaskId, isDone);
      _ref.invalidate(taskListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSubtask(String taskId, String title, int position) async {
    try {
      await _repo.addSubtask(taskId, title, position);
      _ref.invalidate(taskListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSubtask(String subtaskId) async {
    try {
      await _repo.deleteSubtask(subtaskId);
      _ref.invalidate(taskListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repo.softDeleteTask(id);
      _ref.invalidate(taskListProvider);
      _ref.invalidate(todayTasksSummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final taskActionsProvider =
    StateNotifierProvider<TaskActionsNotifier, AsyncValue<void>>((ref) {
  return TaskActionsNotifier(ref.watch(taskRepositoryProvider), ref);
});
