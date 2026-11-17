import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/goal.dart';
import 'reflection_controller.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(computedGoalsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sasaran & OKR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Sasaran',
            onPressed: () => _showGoalDialog(context, ref, null),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const LoadingView(message: 'Memuat sasaran...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(rawGoalsProvider),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyView(
              icon: Icons.flag_outlined,
              title: 'Belum Ada Sasaran Jangka Panjang',
              subtitle:
                  'Tetapkan tujuan bermakna dan ukur hasil kunci (Key Results) untuk meraih impian Anda.',
              action: FilledButton.icon(
                onPressed: () => _showGoalDialog(context, ref, null),
                icon: const Icon(Icons.add),
                label: const Text('Buat Sasaran Baru'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final g = goals[index];
              final percent = (g.overallProgress * 100).toInt();

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: g.isCompleted
                        ? Colors.green.withValues(alpha: 0.5)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: (g.isCompleted
                                    ? Colors.green
                                    : theme.colorScheme.primary)
                                .withValues(alpha: 0.15),
                            child: Icon(
                              g.isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.flag_rounded,
                              color: g.isCompleted
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (g.targetDate != null)
                                  Text(
                                    'Tenggat: ${DateFormat('d MMMM yyyy', 'id_ID').format(g.targetDate!)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onPressed: () => _showGoalOptions(context, ref, g),
                          ),
                        ],
                      ),
                      if (g.description != null &&
                          g.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          g.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Overall Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: g.overallProgress,
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            g.isCompleted
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$percent% Tercapai',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: g.isCompleted
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const Divider(height: 20),

                      // Daftar Key Results
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hasil Kunci (Key Results)',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _showAddKeyResultDialog(context, ref, g.id),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Tambah KR',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      if (g.keyResults.isEmpty)
                        Text(
                          'Belum ada hasil kunci terukur. Tambahkan Key Result untuk memantau progres.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        ...g.keyResults.map((kr) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  kr.isAchieved
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: kr.isAchieved
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${kr.title} (${kr.currentValue.toStringAsFixed(0)}/${kr.targetValue.toStringAsFixed(0)} ${kr.unit})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      decoration: kr.isAchieved
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 16),
                                  tooltip: 'Update Nilai',
                                  onPressed: () =>
                                      _showUpdateKRDialog(context, ref, kr),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showGoalOptions(BuildContext context, WidgetRef ref, Goal goal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Ubah Sasaran'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showGoalDialog(context, ref, goal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Sasaran',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Hapus Sasaran',
                    message:
                        'Apakah Anda yakin ingin menghapus sasaran "${goal.title}"?',
                    confirmLabel: 'Hapus',
                    isDestructive: true,
                  );
                  if (confirmed) {
                    await ref
                        .read(reflectionActionsProvider.notifier)
                        .deleteGoal(goal.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, Goal? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    DateTime? targetDate = existing?.targetDate;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title:
                  Text(existing == null ? 'Buat Sasaran Baru' : 'Ubah Sasaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Sasaran *',
                        hintText: 'Misal: Menulis Buku, Mandiri Finansial',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Sasaran',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: Text(
                        targetDate == null
                            ? 'Pilih Target Tanggal (Opsional)'
                            : DateFormat('d MMMM yyyy', 'id_ID')
                                .format(targetDate!),
                      ),
                      trailing: targetDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setDialogState(() => targetDate = null),
                            )
                          : null,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: targetDate ??
                              DateTime.now().add(const Duration(days: 180)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setDialogState(() => targetDate = picked);
                        }
                      },
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
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Judul sasaran wajib diisi')),
                      );
                      return;
                    }

                    final now = DateTime.now().toUtc();
                    if (existing == null) {
                      final newGoal = Goal(
                        id: '',
                        userId: '',
                        title: title,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        targetDate: targetDate,
                        createdAt: now,
                        updatedAt: now,
                      );
                      await ref
                          .read(reflectionActionsProvider.notifier)
                          .createGoal(newGoal);
                    } else {
                      final updated = existing.copyWith(
                        title: title,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        targetDate: targetDate,
                      );
                      await ref
                          .read(reflectionActionsProvider.notifier)
                          .updateGoal(updated);
                    }

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

  void _showAddKeyResultDialog(
      BuildContext context, WidgetRef ref, String goalId) {
    final titleController = TextEditingController();
    final targetController = TextEditingController(text: '100');
    final unitController = TextEditingController(text: '%');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Tambah Hasil Kunci (Key Result)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Hasil Kunci *',
                    hintText: 'Misal: Selesaikan 10 bab draf',
                    prefixIcon: Icon(Icons.check_circle_outline),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: targetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target Angka *',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan',
                          hintText: '%, bab, km, buku',
                        ),
                      ),
                    ),
                  ],
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
                final title = titleController.text.trim();
                final target =
                    double.tryParse(targetController.text.trim()) ?? 0;
                final unit = unitController.text.trim().isEmpty
                    ? '%'
                    : unitController.text.trim();

                if (title.isEmpty || target <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Judul dan target harus valid')),
                  );
                  return;
                }

                final now = DateTime.now().toUtc();
                final kr = KeyResult(
                  id: '',
                  userId: '',
                  goalId: goalId,
                  title: title,
                  targetValue: target,
                  currentValue: 0,
                  unit: unit,
                  createdAt: now,
                  updatedAt: now,
                );

                await ref
                    .read(reflectionActionsProvider.notifier)
                    .upsertKeyResult(kr);
                if (context.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateKRDialog(BuildContext context, WidgetRef ref, KeyResult kr) {
    final currentController =
        TextEditingController(text: kr.currentValue.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Update Nilai "${kr.title}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nilai Progres Saat Ini',
                  suffixText: kr.unit,
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
                final val = double.tryParse(currentController.text.trim()) ??
                    kr.currentValue;
                final updated = kr.copyWith(currentValue: val);
                await ref
                    .read(reflectionActionsProvider.notifier)
                    .upsertKeyResult(updated);
                if (context.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Perbarui'),
            ),
          ],
        );
      },
    );
  }
}
