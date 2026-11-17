import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/time_entry.dart';
import 'focus_controller.dart';

class TimeTrackerScreen extends ConsumerWidget {
  const TimeTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(timeEntriesProvider);
    final stats = ref.watch(focusStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelacak Waktu Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Catat Waktu Baru',
            onPressed: () => _showAddEntryDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Total Waktu Minggu Ini
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(Icons.av_timer_rounded,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Waktu Minggu Ini',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        stats.formattedWeekTotalTime,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _showAddEntryDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Catat Waktu'),
                ),
              ],
            ),
          ),

          // Daftar Time Entries
          Expanded(
            child: entriesAsync.when(
              loading: () =>
                  const LoadingView(message: 'Memuat catatan waktu...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(timeEntriesProvider),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return EmptyView(
                    icon: Icons.access_time_rounded,
                    title: 'Belum Ada Catatan Waktu',
                    subtitle:
                        'Lacak berapa banyak waktu yang Anda luangkan untuk proyek atau aktivitas penting.',
                    action: FilledButton.icon(
                      onPressed: () => _showAddEntryDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Catat Aktivitas Pertama'),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final e = entries[index];

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withValues(alpha: 0.15),
                          child: const Icon(Icons.timelapse_rounded,
                              color: Colors.blue, size: 20),
                        ),
                        title: Text(
                          e.activity,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(e.startedAt)}'
                          '${e.note != null && e.note!.isNotEmpty ? ' • ${e.note}' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                e.formattedDuration,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.grey),
                              onPressed: () async {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'Hapus Catatan Waktu',
                                  message:
                                      'Hapus entri waktu untuk "${e.activity}"?',
                                  confirmLabel: 'Hapus',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  await ref
                                      .read(focusActionsProvider.notifier)
                                      .deleteTimeEntry(e.id);
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
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context, WidgetRef ref) {
    final activityController = TextEditingController();
    final minutesController = TextEditingController(text: '30');
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Catat Waktu Aktivitas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: activityController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama Aktivitas / Pekerjaan *',
                    hintText: 'Misal: Review PR, Rapat Klien, Riset API',
                    prefixIcon: Icon(Icons.work_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durasi (Menit) *',
                    suffixText: 'menit',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    hintText: 'Detail pekerjaan',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final activity = activityController.text.trim();
                final minutes =
                    int.tryParse(minutesController.text.trim()) ?? 0;

                if (activity.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama aktivitas tidak boleh kosong'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (minutes <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Durasi harus lebih dari 0 menit'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final now = DateTime.now().toUtc();
                final entry = TimeEntry(
                  id: '',
                  userId: '',
                  activity: activity,
                  startedAt: now.subtract(Duration(minutes: minutes)),
                  endedAt: now,
                  durationSeconds: minutes * 60,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                );

                await ref
                    .read(focusActionsProvider.notifier)
                    .createTimeEntry(entry);
                if (context.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
