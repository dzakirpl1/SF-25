import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import 'trash_controller.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashNotesAsync = ref.watch(trashNotesProvider);
    final trashTasksAsync = ref.watch(trashTasksProvider);
    final trashEventsAsync = ref.watch(trashEventsProvider);
    final trashHabitsAsync = ref.watch(trashHabitsProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tempat Sampah'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded),
              tooltip: 'Kosongkan Tempat Sampah',
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Kosongkan Tempat Sampah',
                  message:
                      'Seluruh catatan, tugas, acara, dan kebiasaan di tempat sampah akan dihapus secara PERMANEN dan tidak dapat dipulihkan kembali.',
                  confirmLabel: 'Hapus Semua',
                  isDestructive: true,
                );
                if (confirmed) {
                  await ref.read(trashActionsProvider.notifier).emptyTrash();
                }
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Catatan'),
              Tab(text: 'Tugas'),
              Tab(text: 'Acara'),
              Tab(text: 'Kebiasaan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab Catatan Terhapus
            trashNotesAsync.when(
              loading: () =>
                  const LoadingView(message: 'Memuat catatan terhapus...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(trashNotesProvider),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return const EmptyView(
                    icon: Icons.delete_outline_rounded,
                    title: 'Tempat Sampah Catatan Kosong',
                    subtitle:
                        'Tidak ada catatan yang sedang berada di tempat sampah.',
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      child: ListTile(
                        title: Text(note.displayTitle,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Dihapus ${note.deletedAt != null ? AppDateUtils.formatRelatif(note.deletedAt!) : ''}',
                          style: TextStyle(
                              fontSize: 11, color: theme.colorScheme.outline),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore_from_trash_rounded,
                                  color: Colors.teal),
                              tooltip: 'Pulihkan',
                              onPressed: () => ref
                                  .read(trashActionsProvider.notifier)
                                  .restoreNote(note.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded,
                                  color: Colors.red),
                              tooltip: 'Hapus Permanen',
                              onPressed: () async {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'Hapus Permanen',
                                  message:
                                      'Hapus permanen catatan "${note.displayTitle}"?',
                                  confirmLabel: 'Hapus Permanen',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  ref
                                      .read(trashActionsProvider.notifier)
                                      .permanentDeleteNote(note.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Tab Tugas Terhapus
            trashTasksAsync.when(
              loading: () =>
                  const LoadingView(message: 'Memuat tugas terhapus...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(trashTasksProvider),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const EmptyView(
                    icon: Icons.delete_outline_rounded,
                    title: 'Tempat Sampah Tugas Kosong',
                    subtitle:
                        'Tidak ada tugas yang sedang berada di tempat sampah.',
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      child: ListTile(
                        title: Text(task.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Dihapus ${task.deletedAt != null ? AppDateUtils.formatRelatif(task.deletedAt!) : ''}',
                          style: TextStyle(
                              fontSize: 11, color: theme.colorScheme.outline),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore_from_trash_rounded,
                                  color: Colors.teal),
                              tooltip: 'Pulihkan',
                              onPressed: () => ref
                                  .read(trashActionsProvider.notifier)
                                  .restoreTask(task.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded,
                                  color: Colors.red),
                              tooltip: 'Hapus Permanen',
                              onPressed: () async {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'Hapus Permanen',
                                  message:
                                      'Hapus permanen tugas "${task.title}"?',
                                  confirmLabel: 'Hapus Permanen',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  ref
                                      .read(trashActionsProvider.notifier)
                                      .permanentDeleteTask(task.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Tab Acara Terhapus (Fase 6 Integrasi)
            trashEventsAsync.when(
              loading: () =>
                  const LoadingView(message: 'Memuat acara terhapus...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(trashEventsProvider),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return const EmptyView(
                    icon: Icons.event_available_outlined,
                    title: 'Tempat Sampah Acara Kosong',
                    subtitle: 'Tidak ada acara kalender yang dihapus.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      child: ListTile(
                        title: Text(event.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Dihapus ${event.deletedAt != null ? AppDateUtils.formatRelatif(event.deletedAt!) : ''}',
                          style: TextStyle(
                              fontSize: 11, color: theme.colorScheme.outline),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore_from_trash_rounded,
                                  color: Colors.teal),
                              tooltip: 'Pulihkan',
                              onPressed: () => ref
                                  .read(trashActionsProvider.notifier)
                                  .restoreEvent(event.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded,
                                  color: Colors.red),
                              tooltip: 'Hapus Permanen',
                              onPressed: () async {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'Hapus Permanen',
                                  message:
                                      'Hapus permanen acara "${event.title}"?',
                                  confirmLabel: 'Hapus Permanen',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  ref
                                      .read(trashActionsProvider.notifier)
                                      .permanentDeleteEvent(event.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Tab Kebiasaan Terhapus (Fase 7 Integrasi)
            trashHabitsAsync.when(
              loading: () =>
                  const LoadingView(message: 'Memuat kebiasaan terhapus...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(trashHabitsProvider),
              ),
              data: (habits) {
                if (habits.isEmpty) {
                  return const EmptyView(
                    icon: Icons.repeat_rounded,
                    title: 'Tempat Sampah Kebiasaan Kosong',
                    subtitle: 'Tidak ada kebiasaan yang dihapus.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    return Card(
                      child: ListTile(
                        title: Text(habit.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Dihapus ${habit.deletedAt != null ? AppDateUtils.formatRelatif(habit.deletedAt!) : ''}',
                          style: TextStyle(
                              fontSize: 11, color: theme.colorScheme.outline),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore_from_trash_rounded,
                                  color: Colors.teal),
                              tooltip: 'Pulihkan',
                              onPressed: () => ref
                                  .read(trashActionsProvider.notifier)
                                  .restoreHabit(habit.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded,
                                  color: Colors.red),
                              tooltip: 'Hapus Permanen',
                              onPressed: () async {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'Hapus Permanen',
                                  message:
                                      'Hapus permanen kebiasaan "${habit.name}"?',
                                  confirmLabel: 'Hapus Permanen',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  ref
                                      .read(trashActionsProvider.notifier)
                                      .permanentDeleteHabit(habit.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
