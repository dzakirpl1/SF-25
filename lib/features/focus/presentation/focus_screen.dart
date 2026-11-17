import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../tasks/presentation/task_controller.dart';
import '../domain/pomodoro_state.dart';
import 'focus_controller.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoro = ref.watch(pomodoroTimerProvider);
    final stats = ref.watch(focusStatsProvider);
    final sessionsAsync = ref.watch(focusSessionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fokus & Pomodoro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Pelacak Waktu Aktivitas',
            onPressed: () => context.push('/time'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Kartu Ringkasan Statistik Hari Ini
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        stats.formattedTodayFocus,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fokus Hari Ini',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey.withValues(alpha: 0.3)),
                  Column(
                    children: [
                      Text(
                        '${stats.todayCompletedSessions}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sesi Selesai',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey.withValues(alpha: 0.3)),
                  Column(
                    children: [
                      Text(
                        stats.formattedWeekFocus,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Minggu Ini',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Pemilih Mode Pomodoro
          Center(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'pomodoro',
                  label: Text('Fokus (25m)'),
                  icon: Icon(Icons.psychology_rounded),
                ),
                ButtonSegment(
                  value: 'short_break',
                  label: Text('Rehat (5m)'),
                  icon: Icon(Icons.coffee_rounded),
                ),
                ButtonSegment(
                  value: 'long_break',
                  label: Text('Rehat (15m)'),
                  icon: Icon(Icons.weekend_rounded),
                ),
              ],
              selected: {pomodoro.mode},
              onSelectionChanged: (set) {
                ref.read(pomodoroTimerProvider.notifier).switchMode(set.first);
              },
            ),
          ),
          const SizedBox(height: 28),

          // 3. Tampilan Lingkaran Countdown Timer
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: pomodoro.progress,
                    strokeWidth: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pomodoro.mode == 'pomodoro'
                          ? theme.colorScheme.primary
                          : Colors.teal,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pomodoro.formattedTime,
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pomodoro.isRunning
                              ? (pomodoro.mode == 'pomodoro'
                                  ? 'Sedang Fokus...'
                                  : 'Waktu Istirahat')
                              : 'Siap Dimulai',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // 4. Tombol Kontrol Timer (Play, Pause, Reset, Complete)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                iconSize: 28,
                tooltip: 'Reset Timer',
                onPressed: () =>
                    ref.read(pomodoroTimerProvider.notifier).reset(),
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 20),
              FloatingActionButton.large(
                heroTag: 'pomodoro_play_btn',
                onPressed: () {
                  if (pomodoro.isRunning) {
                    ref.read(pomodoroTimerProvider.notifier).pause();
                  } else {
                    ref.read(pomodoroTimerProvider.notifier).start();
                  }
                },
                child: Icon(
                  pomodoro.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 40,
                ),
              ),
              const SizedBox(width: 20),
              IconButton.filledTonal(
                iconSize: 28,
                tooltip: 'Selesaikan Sesi',
                onPressed: () async {
                  await ref
                      .read(pomodoroTimerProvider.notifier)
                      .completeSession();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Sesi fokus berhasil dicatat!')),
                    );
                  }
                },
                icon: const Icon(Icons.done_all_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. Kaitkan ke Tugas / Proyek
          _buildLinkTaskProjectSection(context, ref, pomodoro),
          const SizedBox(height: 24),

          // 6. Header Riwayat Sesi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Sesi Terbaru',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/time'),
                child: const Text('Buka Timesheet'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 7. Daftar Sesi Fokus
          sessionsAsync.when(
            loading: () => const LoadingView(message: 'Memuat riwayat sesi...'),
            error: (err, _) => ErrorView(
              message: err.toString(),
              onRetry: () => ref.invalidate(focusSessionsProvider),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: EmptyView(
                    icon: Icons.timer_off_outlined,
                    title: 'Belum Ada Sesi Fokus',
                    subtitle:
                        'Mulai timer Pomodoro Anda sekarang untuk meningkatkan produktivitas.',
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.take(10).length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  final isBreak = s.isBreak;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          (isBreak ? Colors.teal : theme.colorScheme.primary)
                              .withValues(alpha: 0.15),
                      child: Icon(
                        isBreak
                            ? Icons.coffee_rounded
                            : Icons.psychology_rounded,
                        color:
                            isBreak ? Colors.teal : theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      s.isPomodoro ? 'Sesi Fokus' : 'Istirahat',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${DateFormat('d MMM, HH:mm', 'id_ID').format(s.startedAt)} • ${s.actualMinutes} menit',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.grey),
                      onPressed: () async {
                        final confirmed = await ConfirmDialog.show(
                          context,
                          title: 'Hapus Sesi Fokus',
                          message: 'Hapus catatan sesi fokus ini dari riwayat?',
                          confirmLabel: 'Hapus',
                          isDestructive: true,
                        );
                        if (confirmed) {
                          await ref
                              .read(focusActionsProvider.notifier)
                              .deleteSession(s.id);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTaskProjectSection(
    BuildContext context,
    WidgetRef ref,
    PomodoroState pomodoro,
  ) {
    final tasksAsync = ref.watch(taskListProvider);
    final tasks = tasksAsync.value ?? [];

    return ExpansionTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      leading: const Icon(Icons.link_rounded),
      title: Text(
        pomodoro.selectedTaskId != null
            ? 'Terhubung ke Tugas'
            : 'Hubungkan ke Tugas (Opsional)',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<String>(
            initialValue: pomodoro.selectedTaskId,
            decoration: const InputDecoration(
              labelText: 'Pilih Tugas yang Dikerjakan',
              prefixIcon: Icon(Icons.check_circle_outline_rounded),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Tanpa Tugas Terkait'),
              ),
              ...tasks.map(
                (t) => DropdownMenuItem<String>(
                  value: t.id,
                  child: Text(t.title, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (val) {
              ref
                  .read(pomodoroTimerProvider.notifier)
                  .setTaskAndProject(val, null);
            },
          ),
        ),
      ],
    );
  }
}
