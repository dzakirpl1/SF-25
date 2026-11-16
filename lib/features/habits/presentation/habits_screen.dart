import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import 'habit_controller.dart';
import 'routine_controller.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kebiasaan & Rutinitas'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.repeat_rounded),
                text: 'Kebiasaan',
              ),
              Tab(
                icon: Icon(Icons.wb_sunny_outlined),
                text: 'Rutinitas Harian',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HabitsTab(),
            _RoutinesTab(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () {
                final tabIndex = DefaultTabController.of(context).index;
                if (tabIndex == 0) {
                  context.push('/habits/edit');
                } else {
                  context.push('/routines/edit');
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Baru'),
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: DAFTAR KEBIASAAN (HABITS TAB)
// -----------------------------------------------------------------------------
class _HabitsTab extends ConsumerWidget {
  const _HabitsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final habitsWithStreak = ref.watch(habitsWithStreakProvider);
    final theme = Theme.of(context);

    return habitsAsync.when(
      loading: () => const LoadingView(message: 'Memuat kebiasaan...'),
      error: (err, _) => ErrorView(
        message: err.toString(),
        onRetry: () {
          ref.invalidate(habitListProvider);
          ref.invalidate(habitLogsProvider);
        },
      ),
      data: (_) {
        if (habitsWithStreak.isEmpty) {
          return const EmptyView(
            icon: Icons.repeat_on_rounded,
            title: 'Belum Ada Kebiasaan',
            subtitle:
                'Bangun rutinitas positif dengan mencatat kebiasaan harian Anda.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: habitsWithStreak.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = habitsWithStreak[index];
            final habit = item.habit;
            final streak = item.streakResult;

            Color habitColor;
            try {
              habitColor = Color(
                  int.parse(habit.color.replaceAll('#', ''), radix: 16) +
                      0xFF000000);
            } catch (_) {
              habitColor = theme.colorScheme.primary;
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: habitColor.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: habitColor.withValues(alpha: 0.15),
                          child: Icon(Icons.check_circle_outline,
                              color: habitColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (habit.description != null &&
                                  habit.description!.isNotEmpty)
                                Text(
                                  habit.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Tombol Check-in Hari Ini
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: streak.isCompletedToday
                                ? habitColor
                                : habitColor.withValues(alpha: 0.1),
                            foregroundColor: streak.isCompletedToday
                                ? Colors.white
                                : habitColor,
                          ),
                          icon: Icon(
                            streak.isCompletedToday
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                          ),
                          tooltip: streak.isCompletedToday
                              ? 'Selesai hari ini'
                              : 'Tandai selesai hari ini',
                          onPressed: () {
                            ref
                                .read(habitActionsProvider.notifier)
                                .toggleHabitToday(habit.id);
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) async {
                            if (val == 'edit') {
                              context.push('/habits/edit', extra: habit);
                            } else if (val == 'delete') {
                              final confirm = await ConfirmDialog.show(
                                context,
                                title: 'Hapus Kebiasaan',
                                message:
                                    'Pindahkan kebiasaan "${habit.name}" ke tempat sampah?',
                                confirmLabel: 'Hapus',
                                isDestructive: true,
                              );
                              if (confirm) {
                                await ref
                                    .read(habitActionsProvider.notifier)
                                    .deleteHabit(habit.id);
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
                                  Text('Hapus',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Baris Statistik Streak
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${streak.currentStreak} hari beruntun',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Rekor: ${streak.longestStreak} hari',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          '30 Hari: ${(streak.completionRate30Days * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: streak.completionRate30Days,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: habitColor,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: DAFTAR RUTINITAS (ROUTINES TAB)
// -----------------------------------------------------------------------------
class _RoutinesTab extends ConsumerWidget {
  const _RoutinesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineListProvider);
    final logsAsync = ref.watch(routineLogsTodayProvider);
    final theme = Theme.of(context);

    return routinesAsync.when(
      loading: () => const LoadingView(message: 'Memuat rutinitas...'),
      error: (err, _) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.refresh(routineListProvider),
      ),
      data: (routines) {
        if (routines.isEmpty) {
          return const EmptyView(
            icon: Icons.checklist_rtl_rounded,
            title: 'Belum Ada Rutinitas',
            subtitle:
                'Buat checklist rutinitas pagi atau malam untuk memulai dan mengakhiri hari dengan rapi.',
          );
        }

        final logs = logsAsync.value ?? [];
        final logsByRoutine = <String, Set<String>>{};
        for (final l in logs) {
          logsByRoutine[l.routineId] = l.completedStepIds.toSet();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: routines.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final routine = routines[index];
            final completedSteps = logsByRoutine[routine.id] ?? {};
            final totalSteps = routine.steps.length;
            final progress =
                totalSteps == 0 ? 0.0 : (completedSteps.length / totalSteps);

            IconData timeIcon;
            if (routine.timeOfDay == 'morning') {
              timeIcon = Icons.wb_sunny_rounded;
            } else if (routine.timeOfDay == 'evening') {
              timeIcon = Icons.nights_stay_rounded;
            } else {
              timeIcon = Icons.schedule_rounded;
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(timeIcon, color: theme.colorScheme.primary),
                ),
                title: Text(
                  routine.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${completedSteps.length}/$totalSteps langkah selesai',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          context.push('/routines/edit', extra: routine);
                        } else if (val == 'delete') {
                          final confirm = await ConfirmDialog.show(
                            context,
                            title: 'Hapus Rutinitas',
                            message:
                                'Pindahkan rutinitas "${routine.name}" ke tempat sampah?',
                            confirmLabel: 'Hapus',
                            isDestructive: true,
                          );
                          if (confirm) {
                            await ref
                                .read(routineActionsProvider.notifier)
                                .deleteRoutine(routine.id);
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
                              Text('Hapus',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (routine.steps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Belum ada langkah dalam rutinitas ini.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  else
                    ...routine.steps.map((step) {
                      final isDone = completedSteps.contains(step.id);
                      return CheckboxListTile(
                        dense: true,
                        value: isDone,
                        title: Text(
                          step.title,
                          style: TextStyle(
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? Colors.grey : null,
                          ),
                        ),
                        onChanged: (_) {
                          ref
                              .read(routineActionsProvider.notifier)
                              .toggleStepToday(routine.id, step.id);
                        },
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
