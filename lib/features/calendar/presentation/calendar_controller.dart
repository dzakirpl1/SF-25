import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/task_controller.dart';
import '../data/calendar_repository.dart';
import '../domain/calendar_event.dart';

enum CalendarViewMode { month, week, day, agenda }

final calendarViewModeProvider =
    StateProvider<CalendarViewMode>((ref) => CalendarViewMode.month);

final selectedCalendarDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

/// Provider untuk mengambil semua acara kalender aktif dari Supabase
final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final repo = ref.watch(calendarRepositoryProvider);
  return repo.fetchEvents();
});

/// Item terpadu yang ditampilkan pada kalender (bisa berupa Event Occurrence atau Task Due Date)
class CalendarItem {
  final String id;
  final String title;
  final String? subtitle;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool allDay;
  final String color;
  final bool isTask;
  final bool isTimeBlock;
  final CalendarEvent? originalEvent;
  final TaskItem? originalTask;

  CalendarItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.startsAt,
    required this.endsAt,
    this.allDay = false,
    this.color = '#1976D2',
    this.isTask = false,
    this.isTimeBlock = false,
    this.originalEvent,
    this.originalTask,
  });
}

/// Provider yang menggabungkan ekspansi event kalender dan tugas ber-tenggat
final combinedCalendarItemsProvider = Provider<List<CalendarItem>>((ref) {
  final eventsAsync = ref.watch(calendarEventsProvider);
  final tasksAsync = ref.watch(taskListProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final viewMode = ref.watch(calendarViewModeProvider);

  final events = eventsAsync.value ?? [];
  final tasks = tasksAsync.value ?? [];

  // Tentukan rentang waktu aktif berdasarkan viewMode
  DateTime rangeStart;
  DateTime rangeEnd;

  switch (viewMode) {
    case CalendarViewMode.month:
      rangeStart = DateTime(selectedDate.year, selectedDate.month - 1, 20);
      rangeEnd = DateTime(selectedDate.year, selectedDate.month + 2, 10);
      break;
    case CalendarViewMode.week:
      final weekday = selectedDate.weekday; // 1 = Senin, 7 = Minggu
      rangeStart = DateTime(selectedDate.year, selectedDate.month,
          selectedDate.day - (weekday - 1));
      rangeEnd = rangeStart.add(const Duration(days: 7));
      break;
    case CalendarViewMode.day:
      rangeStart =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      rangeEnd = rangeStart.add(const Duration(days: 1));
      break;
    case CalendarViewMode.agenda:
      rangeStart =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      rangeEnd = rangeStart.add(const Duration(days: 30));
      break;
  }

  final items = <CalendarItem>[];

  // 1. Ekspansi Event Kalender
  for (final ev in events) {
    final occurrences = ev.expandForRange(rangeStart, rangeEnd);
    for (final occ in occurrences) {
      items.add(
        CalendarItem(
          id: '${occ.eventId}_${occ.startsAt.millisecondsSinceEpoch}',
          title: occ.title,
          subtitle: occ.location,
          startsAt: occ.startsAt,
          endsAt: occ.endsAt,
          allDay: occ.allDay,
          color: occ.color ?? '#1976D2',
          isTask: false,
          isTimeBlock: occ.isTimeBlock,
          originalEvent: ev,
        ),
      );
    }
  }

  // 2. Sertakan Tugas dengan tenggat waktu (F-CAL-03)
  for (final t in tasks) {
    if (t.dueDate != null) {
      final due = t.dueDate!;
      if (!due.isBefore(rangeStart) && !due.isAfter(rangeEnd)) {
        items.add(
          CalendarItem(
            id: 'task_${t.id}',
            title: '[Tugas] ${t.title}',
            subtitle: t.isCompleted ? 'Selesai' : 'Tenggat Tugas',
            startsAt: due,
            endsAt: due.add(const Duration(hours: 1)),
            allDay: false,
            color: t.isCompleted ? '#9E9E9E' : '#E65100',
            isTask: true,
            isTimeBlock: false,
            originalTask: t,
          ),
        );
      }
    }
  }

  // Urutkan berdasarkan waktu mulai
  items.sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return items;
});

/// Provider khusus untuk ringkasan jadwal hari ini (digunakan di Layar Beranda)
final todayScheduleProvider = Provider<List<CalendarItem>>((ref) {
  final allItems = ref.watch(combinedCalendarItemsProvider);
  final now = DateTime.now();
  final startToday = DateTime(now.year, now.month, now.day);
  final endToday = startToday.add(const Duration(days: 1));

  return allItems.where((it) {
    return !it.endsAt.isBefore(startToday) && !it.startsAt.isAfter(endToday);
  }).toList();
});

/// Notifier untuk aksi manipulasi event
class CalendarActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CalendarActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> createEvent(CalendarEvent event) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(calendarRepositoryProvider);
      await repo.createEvent(event);
      _ref.invalidate(calendarEventsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(calendarRepositoryProvider);
      await repo.updateEvent(event);
      _ref.invalidate(calendarEventsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(calendarRepositoryProvider);
      await repo.deleteEvent(id);
      _ref.invalidate(calendarEventsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final calendarActionsProvider =
    StateNotifierProvider<CalendarActionsNotifier, AsyncValue<void>>((ref) {
  return CalendarActionsNotifier(ref);
});
