import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/sleep_log.dart';
import '../domain/workout.dart';
import 'health_controller.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(healthSummaryProvider);
    final medicationsAsync = ref.watch(medicationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesehatan & Kebugaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center_rounded),
            tooltip: 'Riwayat Olahraga',
            onPressed: () => context.push('/health/workouts'),
          ),
          IconButton(
            icon: const Icon(Icons.medication_outlined),
            tooltip: 'Daftar Obat',
            onPressed: () => context.push('/health/medications'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Kartu Pelacak Air Minum
          Card(
            elevation: 0,
            color: Colors.blue.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.water_drop_rounded,
                              color: Colors.blue, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Air Minum Hari Ini',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Text(
                        '${summary.todayWaterMl} / ${summary.targetWaterMl} ml',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: summary.waterProgress,
                      minHeight: 10,
                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            await ref
                                .read(healthActionsProvider.notifier)
                                .addWater(250);
                          },
                          icon: const Icon(Icons.local_cafe_outlined, size: 16),
                          label: const Text('+250 ml (Gelas)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            await ref
                                .read(healthActionsProvider.notifier)
                                .addWater(500);
                          },
                          icon: const Icon(Icons.sports_bar_outlined, size: 16),
                          label: const Text('+500 ml (Botol)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Kartu Tidur Semalam
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bedtime_outlined,
                              color: Colors.indigo, size: 24),
                          SizedBox(width: 8),
                          Text('Tidur Semalam',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _showSleepLogDialog(context, ref),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Catat Tidur'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (summary.lastSleepDuration != null) ...[
                    Text(
                      '${summary.lastSleepDuration!.inHours} jam ${summary.lastSleepDuration!.inMinutes % 60} menit',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Kualitas: ${_qualityText(summary.lastSleepQuality ?? 3)}',
                      style:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ] else ...[
                    Text(
                      'Belum ada catatan tidur untuk hari ini.',
                      style:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Kartu Olahraga Minggu Ini
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.orange.withValues(alpha: 0.15),
                    child: const Icon(Icons.fitness_center_rounded,
                        color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Olahraga 7 Hari Terakhir',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${summary.weekWorkoutsCount} sesi diselesaikan'),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _showWorkoutDialog(context, ref),
                    child: const Text('Catat'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Jadwal Obat & Suplemen Hari Ini
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Obat & Suplemen',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.push('/health/medications'),
                child: const Text('Kelola Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          medicationsAsync.when(
            data: (meds) {
              final activeMeds = meds.where((m) => m.active).toList();
              if (activeMeds.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Tidak ada obat atau suplemen aktif saat ini.'),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeMeds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final med = activeMeds[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0x1AE91E63),
                        child: Icon(Icons.medication_rounded,
                            color: Colors.pink, size: 20),
                      ),
                      title: Text(med.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${med.dosage} • Jadwal: ${med.schedule.join(", ")}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        tooltip: 'Tandai Sudah Diminum',
                        onPressed: () async {
                          await ref
                              .read(healthActionsProvider.notifier)
                              .markMedicationTaken(med.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${med.name} ditandai sudah diminum!')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Gagal memuat obat: $err'),
          ),
        ],
      ),
    );
  }

  String _qualityText(int q) {
    switch (q) {
      case 5:
        return 'Sangat Nyenyak ⭐⭐⭐⭐⭐';
      case 4:
        return 'Nyenyak ⭐⭐⭐⭐';
      case 3:
        return 'Cukup ⭐⭐⭐';
      case 2:
        return 'Kurang ⭐⭐';
      default:
        return 'Buruk ⭐';
    }
  }

  void _showSleepLogDialog(BuildContext context, WidgetRef ref) {
    DateTime sleepTime = DateTime.now().subtract(const Duration(hours: 7));
    DateTime wakeTime = DateTime.now();
    int quality = 4;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Catat Jam Tidur'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Jam Bangun'),
                    subtitle: Text(DateFormat('HH:mm').format(wakeTime)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(wakeTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          wakeTime = DateTime(
                            wakeTime.year,
                            wakeTime.month,
                            wakeTime.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Kualitas Tidur (1-5):',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: quality.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: quality.toString(),
                    onChanged: (val) {
                      setDialogState(() => quality = val.toInt());
                    },
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
                    final now = DateTime.now().toUtc();
                    final sleepLog = SleepLog(
                      id: '',
                      userId: '',
                      sleepAt: sleepTime.toUtc(),
                      wakeAt: wakeTime.toUtc(),
                      quality: quality,
                      createdAt: now,
                      updatedAt: now,
                    );
                    await ref
                        .read(healthActionsProvider.notifier)
                        .logSleep(sleepLog);
                    if (context.mounted) Navigator.pop(dialogCtx);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWorkoutDialog(BuildContext context, WidgetRef ref) {
    final typeController = TextEditingController(text: 'Lari Santai');
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
                decoration: const InputDecoration(
                  labelText: 'Jenis Olahraga *',
                  hintText: 'Lari, Gym, Renang, Sepeda',
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
