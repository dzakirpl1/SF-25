import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/savings_goal.dart';
import 'savings_controller.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(computedSavingsGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Tabungan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Target',
            onPressed: () => _showGoalDialog(context, ref, null),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const LoadingView(message: 'Memuat target tabungan...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(rawSavingsGoalsProvider),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyView(
              icon: Icons.savings_outlined,
              title: 'Belum Ada Target Tabungan',
              subtitle:
                  'Mulai rencanakan impian finansial Anda seperti dana darurat, liburan, atau gadget.',
              action: FilledButton.icon(
                onPressed: () => _showGoalDialog(context, ref, null),
                icon: const Icon(Icons.add),
                label: const Text('Buat Target Tabungan'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final g = goals[index];
              final percent = (g.progress * 100).toInt();

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: g.isCompleted
                        ? Colors.green.withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.outlineVariant,
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
                            backgroundColor:
                                (g.isCompleted ? Colors.green : Colors.teal)
                                    .withValues(alpha: 0.15),
                            child: Icon(
                              g.isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.savings_rounded,
                              color: g.isCompleted ? Colors.green : Colors.teal,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (g.targetDate != null)
                                  Text(
                                    'Tenggat: ${DateFormat('d MMMM yyyy', 'id_ID').format(g.targetDate!)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
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
                      const SizedBox(height: 12),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: g.progress,
                          minHeight: 8,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            g.isCompleted ? Colors.green : Colors.teal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Detail Angka & Persen
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${CurrencyUtils.formatRupiah(g.currentAmount)} / ${CurrencyUtils.formatRupiah(g.targetAmount)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          Text(
                            g.isCompleted ? 'Tercapai! (100%)' : '$percent%',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: g.isCompleted
                                          ? Colors.green
                                          : Colors.teal,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tombol Setor Tabungan
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showContributionDialog(context, ref, g),
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text('Setor Tabungan'),
                        ),
                      ),
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

  void _showGoalOptions(BuildContext context, WidgetRef ref, SavingsGoal goal) {
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
                title: const Text('Ubah Target'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showGoalDialog(context, ref, goal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Target',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Hapus Target Tabungan',
                    message:
                        'Apakah Anda yakin ingin menghapus target "${goal.name}"?',
                    confirmLabel: 'Hapus',
                    isDestructive: true,
                  );
                  if (confirmed) {
                    await ref
                        .read(savingsActionsProvider.notifier)
                        .deleteSavingsGoal(goal.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGoalDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal? existing,
  ) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.targetAmount.toString() : '',
    );
    DateTime? selectedDate = existing?.targetDate;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null
                  ? 'Buat Target Tabungan'
                  : 'Ubah Target Tabungan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Target *',
                        hintText: 'Misal: Dana Darurat, iPhone 16',
                        prefixIcon: Icon(Icons.drive_file_rename_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Nominal (Rp) *',
                        prefixText: 'Rp ',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: Text(
                        selectedDate == null
                            ? 'Pilih Tenggat Waktu (Opsional)'
                            : DateFormat('d MMMM yyyy', 'id_ID')
                                .format(selectedDate!),
                      ),
                      trailing: selectedDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setDialogState(() => selectedDate = null),
                            )
                          : null,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ??
                              DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
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
                    final name = nameController.text.trim();
                    final amount =
                        CurrencyUtils.parseNominal(amountController.text);

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nama target tidak boleh kosong'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (amount <= BigInt.zero) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Target nominal harus lebih dari 0'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final now = DateTime.now().toUtc();
                    if (existing == null) {
                      final newGoal = SavingsGoal(
                        id: '',
                        userId: '',
                        name: name,
                        targetAmount: amount,
                        targetDate: selectedDate,
                        createdAt: now,
                        updatedAt: now,
                      );
                      await ref
                          .read(savingsActionsProvider.notifier)
                          .createSavingsGoal(newGoal);
                    } else {
                      final updated = existing.copyWith(
                        name: name,
                        targetAmount: amount,
                        targetDate: selectedDate,
                      );
                      await ref
                          .read(savingsActionsProvider.notifier)
                          .updateSavingsGoal(updated);
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

  void _showContributionDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Setor ke "${goal.name}"'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nominal Setoran (Rp) *',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Setoran (Opsional)',
                    hintText: 'Misal: Sisa gaji, bonus',
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
                final amount =
                    CurrencyUtils.parseNominal(amountController.text);
                if (amount <= BigInt.zero) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nominal setoran harus lebih dari 0'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final now = DateTime.now().toUtc();
                final contrib = SavingsContribution(
                  id: '',
                  userId: '',
                  goalId: goal.id,
                  amount: amount,
                  contributedAt: now,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                );

                await ref
                    .read(savingsActionsProvider.notifier)
                    .addContribution(contrib);

                if (context.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Setor'),
            ),
          ],
        );
      },
    );
  }
}
