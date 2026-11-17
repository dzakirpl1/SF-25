import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/workout.dart';
import 'health_controller.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Olahraga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Catat Olahraga',
            onPressed: () => _showAddWorkoutDialog(context, ref),
          ),
        ],
      ),
      body: workoutsAsync.when(
        loading: () => const LoadingView(message: 'Memuat riwayat olahraga...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(workoutsProvider),
        ),
        data: (workouts) {
          if (workouts.isEmpty) {
            return EmptyView(
              icon: Icons.fitness_center_rounded,
              title: 'Belum Ada Catatan Olahraga',
              subtitle:
                  'Aktivitas fisik teratur menjaga tubuh tetap berenergi dan bugar.',
              action: FilledButton.icon(
                onPressed: () => _showAddWorkoutDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Catat Olahraga Pertama'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final w = workouts[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x1AFF9800),
                    child: Icon(Icons.directions_run_rounded,
                        color: Colors.orange),
                  ),
                  title: Text(w.type,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID')
                        .format(w.startedAt),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${w.durationMinutes} menit',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddWorkoutDialog(BuildContext context, WidgetRef ref) {
    final typeController = TextEditingController();
    final minutesController = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Catat Olahraga'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Jenis Olahraga *',
                  hintText: 'Lari, Gym, Renang, Yoga',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Durasi (Menit) *',
                  suffixText: 'menit',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final type = typeController.text.trim();
                final min = int.tryParse(minutesController.text.trim()) ?? 0;
                if (type.isEmpty || min <= 0) return;

                final now = DateTime.now().toUtc();
                final workout = Workout(
                  id: '',
                  userId: '',
                  type: type,
                  startedAt: now,
                  durationMinutes: min,
                  createdAt: now,
                  updatedAt: now,
                );
                await ref
                    .read(healthActionsProvider.notifier)
                    .logWorkout(workout);
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
