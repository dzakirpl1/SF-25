import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/reminder.dart';
import 'reminder_controller.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  void _showAddReminderDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    DateTime pickedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay pickedTime = TimeOfDay.fromDateTime(pickedDate);
    String targetType = 'custom';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Buat Pengingat Baru',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Pengingat *',
                  prefixIcon: Icon(Icons.alarm),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Catatan Tambahan (Opsional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Waktu Pengingat'),
                subtitle: Text(
                  '${DateFormat('EEEE, d MMM yyyy', 'id_ID').format(pickedDate)} jam ${pickedTime.format(context)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: pickedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) {
                          setModalState(() => pickedDate = d);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: pickedTime,
                        );
                        if (t != null) {
                          setModalState(() => pickedTime = t);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final text = titleController.text.trim();
                  if (text.isEmpty) return;

                  final remindAt = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  Navigator.pop(ctx);
                  final now = DateTime.now().toUtc();
                  await ref
                      .read(reminderActionsProvider.notifier)
                      .createReminder(
                        Reminder(
                          id: '',
                          userId: '',
                          title: text,
                          body: bodyController.text.trim().isEmpty
                              ? null
                              : bodyController.text.trim(),
                          targetType: targetType,
                          remindAt: remindAt.toUtc(),
                          createdAt: now,
                          updatedAt: now,
                        ),
                      );
                },
                child: const Text('Jadwalkan Pengingat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(reminderListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat & Notifikasi'),
      ),
      body: remindersAsync.when(
        loading: () => const LoadingView(message: 'Memuat pengingat...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(reminderListProvider),
        ),
        data: (reminders) {
          if (reminders.isEmpty) {
            return const EmptyView(
              icon: Icons.notifications_none_rounded,
              title: 'Belum Ada Pengingat',
              subtitle:
                  'Jadwalkan pengingat untuk tugas, obat, dokumen penting, atau acara Anda.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = reminders[index];
              final isOverdue =
                  r.isScheduled && r.remindAt.isBefore(DateTime.now());

              Color statusColor = theme.colorScheme.primary;
              String statusText = 'Terjadwal';
              if (r.isSnoozed) {
                statusColor = Colors.orange;
                statusText = 'Ditunda';
              } else if (r.isDismissed) {
                statusColor = Colors.grey;
                statusText = 'Selesai';
              } else if (isOverdue) {
                statusColor = Colors.red;
                statusText = 'Waktunya Lewat';
              }

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: statusColor.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    child: Icon(Icons.alarm, color: statusColor),
                  ),
                  title: Text(
                    r.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration:
                          r.isDismissed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.body != null && r.body!.isNotEmpty)
                        Text(r.body!, style: const TextStyle(fontSize: 12)),
                      Text(
                        '${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(r.remindAt.toLocal())} • $statusText',
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!r.isDismissed) ...[
                        // Tombol Tunda 10 Menit
                        IconButton(
                          icon: const Icon(Icons.snooze_rounded, size: 20),
                          tooltip: 'Tunda 10 Menit',
                          onPressed: () {
                            ref
                                .read(reminderActionsProvider.notifier)
                                .snooze(r.id, minutes: 10);
                          },
                        ),
                        // Tombol Selesai
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 20),
                          tooltip: 'Tandai Selesai',
                          onPressed: () {
                            ref
                                .read(reminderActionsProvider.notifier)
                                .dismiss(r.id);
                          },
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        tooltip: 'Hapus',
                        onPressed: () async {
                          final confirm = await ConfirmDialog.show(
                            context,
                            title: 'Hapus Pengingat',
                            message: 'Hapus pengingat "${r.title}"?',
                            confirmLabel: 'Hapus',
                            isDestructive: true,
                          );
                          if (confirm) {
                            await ref
                                .read(reminderActionsProvider.notifier)
                                .delete(r.id);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        icon: const Icon(Icons.add_alarm),
        label: const Text('Buat Pengingat'),
      ),
    );
  }
}
