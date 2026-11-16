import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/task.dart';
import 'task_controller.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    final filter = ref.watch(taskFilterProvider);

    final now = DateTime.now();
    final logicalToday = AppDateUtils.getLogicalDate(now.toUtc());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_special_outlined),
            tooltip: 'Kelola Proyek',
            onPressed: () => context.push('/projects'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip(
                    context, ref, 'Semua', TaskTabFilter.all, filter.tab),
                _buildFilterChip(
                    context, ref, 'Hari Ini', TaskTabFilter.today, filter.tab),
                _buildFilterChip(context, ref, 'Mendatang',
                    TaskTabFilter.upcoming, filter.tab),
                _buildFilterChip(context, ref, 'Terlambat',
                    TaskTabFilter.overdue, filter.tab),
                _buildFilterChip(context, ref, 'Selesai',
                    TaskTabFilter.completed, filter.tab),
                _buildFilterChip(context, ref, 'Eisenhower',
                    TaskTabFilter.eisenhower, filter.tab),
              ],
            ),
          ),
        ),
      ),
      body: tasksAsync.when(
        loading: () => const LoadingView(message: 'Memuat tugas...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(taskListProvider),
        ),
        data: (allTasks) {
          // Terapkan filtering sisi klien untuk tab tanggal & Eisenhower
          List<TaskItem> filteredTasks = allTasks;

          if (filter.tab == TaskTabFilter.today) {
            filteredTasks = allTasks
                .where((t) => !t.isCompleted && t.isDueToday(logicalToday))
                .toList();
          } else if (filter.tab == TaskTabFilter.upcoming) {
            final tomorrow = logicalToday.add(const Duration(days: 1));
            filteredTasks = allTasks.where((t) {
              if (t.isCompleted || t.dueDate == null) return false;
              final d =
                  DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
              return d.isAfter(tomorrow) || d.isAtSameMomentAs(tomorrow);
            }).toList();
          } else if (filter.tab == TaskTabFilter.overdue) {
            filteredTasks =
                allTasks.where((t) => t.isOverdue(logicalToday)).toList();
          } else if (filter.tab == TaskTabFilter.completed) {
            filteredTasks = allTasks.where((t) => t.isCompleted).toList();
          }

          if (filter.tab == TaskTabFilter.eisenhower) {
            return _buildEisenhowerView(
                context, ref, allTasks.where((t) => !t.isCompleted).toList());
          }

          if (filteredTasks.isEmpty) {
            return EmptyView(
              icon: Icons.task_alt_rounded,
              title: 'Tidak Ada Tugas',
              subtitle:
                  'Semua tugas telah selesai atau belum ada tugas dalam filter ini.',
              action: FilledButton.icon(
                onPressed: () => context.push('/tasks/edit'),
                icon: const Icon(Icons.add),
                label: const Text('Buat Tugas'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(taskListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: filteredTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return _TaskCard(task: task, logicalToday: logicalToday);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/edit'),
        tooltip: 'Tambah Tugas',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    TaskTabFilter tab,
    TaskTabFilter currentTab,
  ) {
    final isSelected = tab == currentTab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(taskFilterProvider.notifier).state =
              ref.read(taskFilterProvider).copyWith(tab: tab);
        },
      ),
    );
  }

  Widget _buildEisenhowerView(
      BuildContext context, WidgetRef ref, List<TaskItem> activeTasks) {
    final q1 = activeTasks
        .where(
            (t) => t.eisenhowerQuadrant == EisenhowerQuadrant.q1UrgentImportant)
        .toList();
    final q2 = activeTasks
        .where((t) =>
            t.eisenhowerQuadrant == EisenhowerQuadrant.q2ImportantNotUrgent)
        .toList();
    final q3 = activeTasks
        .where((t) =>
            t.eisenhowerQuadrant == EisenhowerQuadrant.q3UrgentNotImportant)
        .toList();
    final q4 = activeTasks
        .where((t) =>
            t.eisenhowerQuadrant == EisenhowerQuadrant.q4NotUrgentNotImportant)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildQuadrantCard(context, ref,
            'I: Mendesak & Penting (Kerjakan Segera)', q1, Colors.red.shade700),
        const SizedBox(height: 12),
        _buildQuadrantCard(
            context,
            ref,
            'II: Penting & Tidak Mendesak (Jadwalkan)',
            q2,
            Colors.teal.shade700),
        const SizedBox(height: 12),
        _buildQuadrantCard(
            context,
            ref,
            'III: Mendesak & Tidak Penting (Tinjau/Delegasi)',
            q3,
            Colors.amber.shade800),
        const SizedBox(height: 12),
        _buildQuadrantCard(
            context,
            ref,
            'IV: Tidak Mendesak & Tidak Penting (Eliminasi)',
            q4,
            Colors.grey.shade700),
      ],
    );
  }

  Widget _buildQuadrantCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<TaskItem> tasks,
    Color color,
  ) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          radius: 12,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            '${tasks.length}',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        children: tasks.isEmpty
            ? [
                const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Tidak ada tugas di kuadran ini.'))
              ]
            : tasks
                .map((t) => ListTile(
                      dense: true,
                      title: Text(t.title),
                      leading: Checkbox(
                        value: t.isCompleted,
                        onChanged: (_) => ref
                            .read(taskActionsProvider.notifier)
                            .toggleComplete(t),
                      ),
                      onTap: () => context.push('/tasks/edit', extra: t),
                    ))
                .toList(),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final TaskItem task;
  final DateTime logicalToday;

  const _TaskCard({required this.task, required this.logicalToday});

  Color _getPriorityColor(int priority, ThemeData theme) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOverdue = task.isOverdue(logicalToday);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/tasks/edit', extra: task),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) {
                      ref
                          .read(taskActionsProvider.notifier)
                          .toggleComplete(task);
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? theme.colorScheme.outline
                                : null,
                          ),
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      final confirmed = await ConfirmDialog.show(
                        context,
                        title: 'Hapus Tugas',
                        message:
                            'Pindahkan tugas "${task.title}" ke tempat sampah?',
                        confirmLabel: 'Hapus',
                        isDestructive: true,
                      );
                      if (confirmed) {
                        ref
                            .read(taskActionsProvider.notifier)
                            .deleteTask(task.id);
                      }
                    },
                  ),
                ],
              ),

              // Subtasks List Inline
              if (task.subtasks.isNotEmpty) ...[
                const Divider(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Column(
                    children: task.subtasks.map((st) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: st.isDone,
                              onChanged: (val) {
                                if (val != null) {
                                  ref
                                      .read(taskActionsProvider.notifier)
                                      .toggleSubtask(st.id, val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              st.title,
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: st.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: st.isDone
                                    ? theme.colorScheme.outline
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Badges: Due Date, Priority, Recurrence
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (task.dueDate != null)
                      Chip(
                        avatar: Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: isOverdue
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        label: Text(
                          AppDateUtils.formatRelatif(task.dueDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue ? theme.colorScheme.error : null,
                            fontWeight:
                                isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (task.priority < 4)
                      Chip(
                        avatar: Icon(Icons.flag_rounded,
                            size: 14,
                            color: _getPriorityColor(task.priority, theme)),
                        label: Text(
                          task.priority == 1
                              ? 'Tinggi'
                              : (task.priority == 2 ? 'Sedang' : 'Rendah'),
                          style: const TextStyle(fontSize: 11),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (task.hasRecurrence)
                      const Chip(
                        avatar: Icon(Icons.repeat_rounded, size: 14),
                        label: Text('Berulang', style: TextStyle(fontSize: 11)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
