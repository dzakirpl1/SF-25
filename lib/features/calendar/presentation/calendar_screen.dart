import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import 'calendar_controller.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);
    final combinedItems = ref.watch(combinedCalendarItemsProvider);
    final theme = Theme.of(context);

    final titleFormat = DateFormat('MMMM yyyy', 'id_ID');
    final monthTitle = titleFormat.format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(monthTitle),
        actions: [
          // Navigasi ke Hari Ini
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Hari Ini',
            onPressed: () {
              ref.read(selectedCalendarDateProvider.notifier).state =
                  DateTime.now();
            },
          ),
          // Pemilih Tampilan
          PopupMenuButton<CalendarViewMode>(
            icon: const Icon(Icons.view_agenda_outlined),
            tooltip: 'Mode Tampilan',
            onSelected: (mode) {
              ref.read(calendarViewModeProvider.notifier).state = mode;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarViewMode.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month_rounded),
                    SizedBox(width: 8),
                    Text('Bulan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarViewMode.week,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week_rounded),
                    SizedBox(width: 8),
                    Text('Minggu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarViewMode.day,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_day_rounded),
                    SizedBox(width: 8),
                    Text('Hari'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: CalendarViewMode.agenda,
                child: Row(
                  children: [
                    Icon(Icons.view_agenda_rounded),
                    SizedBox(width: 8),
                    Text('Agenda'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const LoadingView(message: 'Memuat kalender...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(calendarEventsProvider),
        ),
        data: (_) {
          return Column(
            children: [
              // Header Navigasi Tanggal (< >)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        _navigateDate(ref, selectedDate, viewMode, -1);
                      },
                    ),
                    Text(
                      _getHeaderLabel(selectedDate, viewMode),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        _navigateDate(ref, selectedDate, viewMode, 1);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Konten Utama berdasarkan Mode Tampilan
              Expanded(
                child: _buildViewContent(
                  context,
                  ref,
                  viewMode,
                  selectedDate,
                  combinedItems,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/calendar/event/edit'),
        icon: const Icon(Icons.add),
        label: const Text('Acara / Blok Waktu'),
      ),
    );
  }

  void _navigateDate(
      WidgetRef ref, DateTime current, CalendarViewMode mode, int step) {
    DateTime next;
    switch (mode) {
      case CalendarViewMode.month:
        next = DateTime(current.year, current.month + step, current.day);
        break;
      case CalendarViewMode.week:
        next = current.add(Duration(days: 7 * step));
        break;
      case CalendarViewMode.day:
        next = current.add(Duration(days: step));
        break;
      case CalendarViewMode.agenda:
        next = current.add(Duration(days: 14 * step));
        break;
    }
    ref.read(selectedCalendarDateProvider.notifier).state = next;
  }

  String _getHeaderLabel(DateTime current, CalendarViewMode mode) {
    final format = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
    switch (mode) {
      case CalendarViewMode.month:
        return DateFormat('MMMM yyyy', 'id_ID').format(current);
      case CalendarViewMode.week:
        final start = current.subtract(Duration(days: current.weekday - 1));
        final end = start.add(const Duration(days: 6));
        final f = DateFormat('d MMM', 'id_ID');
        return '${f.format(start)} - ${f.format(end)} ${end.year}';
      case CalendarViewMode.day:
        return format.format(current);
      case CalendarViewMode.agenda:
        return 'Agenda 30 Hari ke Depan';
    }
  }

  Widget _buildViewContent(
    BuildContext context,
    WidgetRef ref,
    CalendarViewMode mode,
    DateTime selectedDate,
    List<CalendarItem> items,
  ) {
    switch (mode) {
      case CalendarViewMode.month:
        return _MonthView(selectedDate: selectedDate, allItems: items);
      case CalendarViewMode.week:
        return _WeekView(selectedDate: selectedDate, allItems: items);
      case CalendarViewMode.day:
        return _DayView(selectedDate: selectedDate, allItems: items);
      case CalendarViewMode.agenda:
        return _AgendaView(allItems: items);
    }
  }
}

// -----------------------------------------------------------------------------
// TAMPILAN BULAN (MONTH VIEW)
// -----------------------------------------------------------------------------
class _MonthView extends ConsumerWidget {
  final DateTime selectedDate;
  final List<CalendarItem> allItems;

  const _MonthView({required this.selectedDate, required this.allItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Sen, 7 = Min

    // Filter item yang terjadi di hari yang dipilih
    final dayItems = allItems.where((it) {
      final itemDay =
          DateTime(it.startsAt.year, it.startsAt.month, it.startsAt.day);
      final selDay =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      return itemDay.isAtSameMomentAs(selDay);
    }).toList();

    return Column(
      children: [
        // Baris Nama Hari
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Sen', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Sel', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Rab', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Kam', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Jum', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Sab', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Min', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Divider(height: 1),

        // Grid Kalender Bulan
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.2,
          ),
          itemCount: 42, // 6 baris x 7 hari
          itemBuilder: (context, index) {
            final dayOffset = index - (startingWeekday - 1);
            if (dayOffset < 0 || dayOffset >= daysInMonth) {
              return const SizedBox.shrink();
            }

            final dayNumber = dayOffset + 1;
            final dateOfCell =
                DateTime(selectedDate.year, selectedDate.month, dayNumber);
            final isSelected = selectedDate.day == dayNumber;
            final isToday = _isSameDay(dateOfCell, DateTime.now());

            // Cari apakah ada event di tanggal ini
            final hasEvents = allItems.any((it) =>
                it.startsAt.year == dateOfCell.year &&
                it.startsAt.month == dateOfCell.month &&
                it.startsAt.day == dateOfCell.day);

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                ref.read(selectedCalendarDateProvider.notifier).state =
                    dateOfCell;
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : (isToday
                          ? theme.colorScheme.surfaceContainerHighest
                          : null),
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    if (hasEvents)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(height: 1),

        // Daftar Agenda untuk Hari Terpilih
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jadwal ${DateFormat('d MMMM', 'id_ID').format(selectedDate)}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${dayItems.length} agenda',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),

        Expanded(
          child: dayItems.isEmpty
              ? const EmptyView(
                  icon: Icons.event_available_outlined,
                  title: 'Tidak Ada Agenda',
                  subtitle:
                      'Tidak ada acara, blok waktu, atau tugas ber-tenggat pada tanggal ini.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  itemCount: dayItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _CalendarItemCard(item: dayItems[index]);
                  },
                ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// -----------------------------------------------------------------------------
// TAMPILAN MINGGU (WEEK VIEW)
// -----------------------------------------------------------------------------
class _WeekView extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarItem> allItems;

  const _WeekView({required this.selectedDate, required this.allItems});

  @override
  Widget build(BuildContext context) {
    final startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 7,
      itemBuilder: (context, index) {
        final currentDay = startOfWeek.add(Duration(days: index));
        final dayItems = allItems.where((it) {
          return it.startsAt.year == currentDay.year &&
              it.startsAt.month == currentDay.month &&
              it.startsAt.day == currentDay.day;
        }).toList();

        final isToday = DateTime.now().year == currentDay.year &&
            DateTime.now().month == currentDay.month &&
            DateTime.now().day == currentDay.day;

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMM', 'id_ID').format(currentDay),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Hari Ini',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (dayItems.isEmpty)
                  const Text(
                    'Tidak ada agenda',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  )
                else
                  ...dayItems.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _CalendarItemCard(item: it),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAMPILAN HARI (DAY VIEW)
// -----------------------------------------------------------------------------
class _DayView extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarItem> allItems;

  const _DayView({required this.selectedDate, required this.allItems});

  @override
  Widget build(BuildContext context) {
    final dayItems = allItems.where((it) {
      return it.startsAt.year == selectedDate.year &&
          it.startsAt.month == selectedDate.month &&
          it.startsAt.day == selectedDate.day;
    }).toList();

    if (dayItems.isEmpty) {
      return const EmptyView(
        icon: Icons.calendar_today_outlined,
        title: 'Hari Ini Tenang',
        subtitle:
            'Tidak ada acara kalender atau tugas yang harus diselesaikan.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: dayItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _CalendarItemCard(item: dayItems[index]);
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAMPILAN AGENDA (AGENDA VIEW)
// -----------------------------------------------------------------------------
class _AgendaView extends StatelessWidget {
  final List<CalendarItem> allItems;

  const _AgendaView({required this.allItems});

  @override
  Widget build(BuildContext context) {
    if (allItems.isEmpty) {
      return const EmptyView(
        icon: Icons.view_agenda_outlined,
        title: 'Agenda Kosong',
        subtitle: 'Tidak ada acara mendatang dalam 30 hari ke depan.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: allItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _CalendarItemCard(item: allItems[index]);
      },
    );
  }
}

// -----------------------------------------------------------------------------
// KARTU ITEM KALENDER (EVENT / TIME BLOCK / TASK DUE)
// -----------------------------------------------------------------------------
class _CalendarItemCard extends ConsumerWidget {
  final CalendarItem item;

  const _CalendarItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = item.allDay
        ? 'Seharian'
        : '${DateFormat('HH:mm').format(item.startsAt)} - ${DateFormat('HH:mm').format(item.endsAt)}';

    Color cardColor;
    try {
      cardColor = Color(
          int.parse(item.color.replaceAll('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      cardColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      elevation: 0,
      color: cardColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cardColor.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cardColor,
          child: Icon(
            item.isTask
                ? Icons.check_circle_outline
                : (item.isTimeBlock ? Icons.timelapse : Icons.event),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$timeStr${item.subtitle != null && item.subtitle!.isNotEmpty ? ' • ${item.subtitle}' : ''}',
        ),
        trailing: item.originalEvent != null
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) async {
                  if (val == 'edit') {
                    context.push('/calendar/event/edit',
                        extra: item.originalEvent);
                  } else if (val == 'delete') {
                    final confirm = await ConfirmDialog.show(
                      context,
                      title: 'Hapus Acara',
                      message:
                          'Pindahkan acara "${item.title}" ke tempat sampah?',
                      confirmLabel: 'Hapus',
                      isDestructive: true,
                    );
                    if (confirm) {
                      await ref
                          .read(calendarActionsProvider.notifier)
                          .deleteEvent(item.originalEvent!.id);
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
