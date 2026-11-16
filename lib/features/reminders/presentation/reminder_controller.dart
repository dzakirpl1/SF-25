import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reminder_repository.dart';
import '../domain/reminder.dart';

final reminderListProvider = FutureProvider<List<Reminder>>((ref) async {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.fetchReminders(activeOnly: false);
});

class ReminderActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ReminderActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> createReminder(Reminder reminder) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(reminderRepositoryProvider);
      await repo.createReminder(reminder);
      _ref.invalidate(reminderListProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> snooze(String id, {int minutes = 10}) async {
    try {
      final repo = _ref.read(reminderRepositoryProvider);
      await repo.snoozeReminder(id, minutes: minutes);
      _ref.invalidate(reminderListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> dismiss(String id) async {
    try {
      final repo = _ref.read(reminderRepositoryProvider);
      await repo.dismissReminder(id);
      _ref.invalidate(reminderListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String id) async {
    try {
      final repo = _ref.read(reminderRepositoryProvider);
      await repo.deleteReminder(id);
      _ref.invalidate(reminderListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final reminderActionsProvider =
    StateNotifierProvider<ReminderActionsNotifier, AsyncValue<void>>((ref) {
  return ReminderActionsNotifier(ref);
});
