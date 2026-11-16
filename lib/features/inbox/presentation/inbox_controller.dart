import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inbox_repository.dart';
import '../domain/inbox_item.dart';
import '../../notes/presentation/note_controller.dart';
import '../../tasks/presentation/task_controller.dart';
import '../../calendar/presentation/calendar_controller.dart';

final inboxListProvider = FutureProvider<List<InboxItem>>((ref) async {
  return ref.watch(inboxRepositoryProvider).fetchUnprocessed();
});

class InboxActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final InboxRepository _repo;
  final Ref _ref;

  InboxActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> addItem(String content, {String source = 'manual'}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addInboxItem(content, source: source);
      state = const AsyncValue.data(null);
      _ref.invalidate(inboxListProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> convertToNote(String inboxId, String content,
      {String? categoryId}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.convertToNote(inboxId, content, categoryId: categoryId);
      state = const AsyncValue.data(null);
      _ref.invalidate(inboxListProvider);
      _ref.invalidate(noteListProvider);
      _ref.invalidate(recentNotesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> convertToTask(String inboxId, String title,
      {String? projectId, DateTime? dueDate}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.convertToTask(inboxId, title,
          projectId: projectId, dueDate: dueDate);
      state = const AsyncValue.data(null);
      _ref.invalidate(inboxListProvider);
      _ref.invalidate(taskListProvider);
      _ref.invalidate(todayTasksSummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> convertToEvent(String inboxId, String title,
      {DateTime? startsAt, DateTime? endsAt}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.convertToEvent(inboxId, title,
          startsAt: startsAt, endsAt: endsAt);
      state = const AsyncValue.data(null);
      _ref.invalidate(inboxListProvider);
      _ref.invalidate(calendarEventsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _repo.deleteInboxItem(id);
      _ref.invalidate(inboxListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final inboxActionsProvider =
    StateNotifierProvider<InboxActionsNotifier, AsyncValue<void>>((ref) {
  return InboxActionsNotifier(ref.watch(inboxRepositoryProvider), ref);
});
