import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/medication.dart';
import 'health_controller.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obat & Suplemen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Obat',
            onPressed: () => _showAddMedDialog(context, ref),
          ),
        ],
      ),
      body: medsAsync.when(
        loading: () => const LoadingView(message: 'Memuat daftar obat...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(medicationsProvider),
        ),
        data: (meds) {
          if (meds.isEmpty) {
            return EmptyView(
              icon: Icons.medication_outlined,
              title: 'Belum Ada Obat Terdaftar',
              subtitle:
                  'Catat resep obat, vitamin, atau suplemen harian Anda dengan jadwal teratur.',
              action: FilledButton.icon(
                onPressed: () => _showAddMedDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Obat / Suplemen'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: meds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final m = meds[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.pink.withValues(alpha: 0.15),
                    child: const Icon(Icons.medication_rounded,
                        color: Colors.pink, size: 22),
                  ),
                  title: Text(m.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Dosis: ${m.dosage} • Jadwal: ${m.schedule.join(", ")}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.grey),
                    onPressed: () async {
                      final confirmed = await ConfirmDialog.show(
                        context,
                        title: 'Hapus Obat',
                        message: 'Hapus "${m.name}" dari daftar?',
                        confirmLabel: 'Hapus',
                        isDestructive: true,
                      );
                      if (confirmed) {
                        await ref
                            .read(healthActionsProvider.notifier)
                            .deleteMedication(m.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddMedDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final dosageController = TextEditingController(text: '1 Tablet');
    final timeController = TextEditingController(text: '08:00, 20:00');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Tambah Obat / Suplemen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nama Obat / Suplemen *',
                  hintText: 'Misal: Vitamin C, Paracetamol',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosis / Aturan Minum *',
                  hintText: '1 Tablet, 500mg, 1 Sendok',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Jadwal Jam Minum (Pisahkan koma)',
                  hintText: '08:00, 20:00',
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
                final name = nameController.text.trim();
                final dosage = dosageController.text.trim();
                final schedule = timeController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                if (name.isEmpty) return;

                final now = DateTime.now().toUtc();
                final med = Medication(
                  id: '',
                  userId: '',
                  name: name,
                  dosage: dosage.isEmpty ? '1 Tablet' : dosage,
                  schedule: schedule,
                  createdAt: now,
                  updatedAt: now,
                );

                await ref
                    .read(healthActionsProvider.notifier)
                    .createMedication(med);
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
