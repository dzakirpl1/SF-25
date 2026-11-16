import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notes/presentation/note_controller.dart';
import '../../notes/presentation/quick_capture_dialog.dart';
import '../../settings/data/settings_repository.dart';
import '../../tasks/presentation/task_controller.dart';
import '../../calendar/presentation/calendar_controller.dart';
import '../../habits/presentation/habit_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final settingsAsync = ref.watch(userSettingsProvider);
    final recentNotesAsync = ref.watch(recentNotesProvider);
    final todayTasksAsync = ref.watch(todayTasksSummaryProvider);
    final todaySchedule = ref.watch(todayScheduleProvider);
    final habitsWithStreak = ref.watch(habitsWithStreakProvider);
    final theme = Theme.of(context);

    final dayStartHour = settingsAsync.value?.dayStartHour ?? 4;
    final logicalToday = AppDateUtils.getLogicalDate(DateTime.now().toUtc(),
        dayStartHour: dayStartHour);
    final tanggalStr = AppDateUtils.formatHariTanggal(logicalToday);

    final nama = profileAsync.value?.displayName ?? 'Pemilik';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, $nama',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              tanggalStr,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentNotesProvider);
          ref.invalidate(todayTasksSummaryProvider);
          ref.invalidate(calendarEventsProvider);
          ref.invalidate(habitListProvider);
          ref.invalidate(habitLogsProvider);
          ref.invalidate(userProfileProvider);
          ref.invalidate(userSettingsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Quick Capture Banner
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.bolt_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Quick Capture',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                    const Text('Simpan ide atau catatan dengan satu ketukan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => QuickCaptureDialog.show(context),
              ),
            ),
            const SizedBox(height: 20),

            // Bagian: Jadwal Hari Ini (Fase 6 Integrasi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jadwal Hari Ini',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/calendar'),
                  child: const Text('Buka Kalender'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (todaySchedule.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                            'Tidak ada acara atau blok waktu terjadwal hari ini.'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: todaySchedule.take(3).map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        item.isTask
                            ? Icons.check_circle_outline
                            : (item.isTimeBlock
                                ? Icons.timelapse
                                : Icons.event),
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        item.allDay
                            ? 'Seharian'
                            : '${item.startsAt.hour.toString().padLeft(2, '0')}:${item.startsAt.minute.toString().padLeft(2, '0')} - ${item.endsAt.hour.toString().padLeft(2, '0')}:${item.endsAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => context.go('/calendar'),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // Bagian: Tugas Hari Ini & Terlambat (Fase 4 Integrasi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tugas Hari Ini',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(taskFilterProvider.notifier).state = ref
                        .read(taskFilterProvider)
                        .copyWith(tab: TaskTabFilter.today);
                    context.go('/tasks');
                  },
                  child: const Text('Buka Tugas'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            todayTasksAsync.when(
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator())),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Gagal memuat tugas: $err'),
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                                'Tidak ada tugas mendesak hari ini. Kerja bagus!'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: tasks.take(3).map((t) {
                    final isOverdue = t.isOverdue(logicalToday);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: Checkbox(
                          value: t.isCompleted,
                          onChanged: (_) {
                            ref
                                .read(taskActionsProvider.notifier)
                                .toggleComplete(t);
                          },
                        ),
                        title: Text(
                          t.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isOverdue ? theme.colorScheme.error : null,
                          ),
                        ),
                        subtitle: t.dueDate != null
                            ? Text(
                                isOverdue
                                    ? 'Terlambat!'
                                    : 'Jatuh tempo hari ini',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.outline,
                                  fontWeight: isOverdue
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => context.push('/tasks/edit', extra: t),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // Bagian: Kebiasaan Hari Ini (Fase 7 Integrasi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kebiasaan Hari Ini',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.push('/habits'),
                  child: const Text('Buka Kebiasaan'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (habitsWithStreak.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.repeat_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                            'Belum ada kebiasaan aktif. Mulai bangun kebiasaan baik!'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: habitsWithStreak.take(4).map((item) {
                  final h = item.habit;
                  final s = item.streakResult;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: IconButton(
                        icon: Icon(
                          s.isCompletedToday
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: s.isCompletedToday ? Colors.green : null,
                        ),
                        onPressed: () {
                          ref
                              .read(habitActionsProvider.notifier)
                              .toggleHabitToday(h.id);
                        },
                      ),
                      title: Text(
                        h.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: s.isCompletedToday
                              ? TextDecoration.lineThrough
                              : null,
                          color: s.isCompletedToday ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Text(
                        '🔥 ${s.currentStreak} hari beruntun',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => context.push('/habits/edit', extra: h),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // Bagian: Catatan Terbaru
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Catatan Terbaru',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/notes'),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            recentNotesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Gagal memuat catatan terbaru: $err'),
                ),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.note_add_outlined,
                            size: 36,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text('Belum ada catatan yang tersimpan.'),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () => context.push('/notes/edit'),
                            child: const Text('Buat Catatan Sekarang'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: notes.map((n) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(
                          n.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          n.content.isNotEmpty
                              ? n.content.replaceAll('\n', ' ')
                              : 'Catatan kosong',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          AppDateUtils.formatRelatif(n.updatedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        onTap: () => context.push('/notes/edit', extra: n),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => QuickCaptureDialog.show(context),
        tooltip: 'Quick Capture',
        child: const Icon(Icons.bolt_rounded),
      ),
    );
  }
}
