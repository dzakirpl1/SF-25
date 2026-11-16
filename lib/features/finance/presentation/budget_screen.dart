import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/budget.dart';
import 'budget_controller.dart';
import 'finance_controller.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final budgetsAsync = ref.watch(computedBudgetsProvider);
    final categoriesAsync = ref.watch(finCategoriesProvider);
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran Bulanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Anggaran',
            onPressed: () => _showBudgetDialog(context, ref, null),
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigasi Pemilih Bulan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Bulan Sebelumnya',
                  onPressed: () {
                    final prev = DateTime(
                      selectedMonth.year,
                      selectedMonth.month - 1,
                      1,
                    );
                    ref.read(selectedBudgetMonthProvider.notifier).state = prev;
                  },
                ),
                Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Bulan Berikutnya',
                  onPressed: () {
                    final next = DateTime(
                      selectedMonth.year,
                      selectedMonth.month + 1,
                      1,
                    );
                    ref.read(selectedBudgetMonthProvider.notifier).state = next;
                  },
                ),
              ],
            ),
          ),

          // Konten Anggaran
          Expanded(
            child: budgetsAsync.when(
              loading: () =>
                  const LoadingView(message: 'Memuat data anggaran...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(rawBudgetsProvider),
              ),
              data: (budgets) {
                if (budgets.isEmpty) {
                  return EmptyView(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'Belum Ada Anggaran',
                    subtitle:
                        'Tetapkan batas pengeluaran untuk bulan $monthLabel agar keuangan tetap sehat.',
                    action: FilledButton.icon(
                      onPressed: () => _showBudgetDialog(context, ref, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Anggaran Baru'),
                    ),
                  );
                }

                final categories = categoriesAsync.value ?? [];
                final catMap = {for (var c in categories) c.id: c};

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final b = budgets[index];
                    final cat = catMap[b.categoryId];
                    final catName = cat?.name ?? 'Kategori Tidak Dikenal';

                    // Penentuan Warna Sesuai Batasan Peringatan
                    Color progressColor = Colors.green;
                    if (b.isExceeded) {
                      progressColor = Colors.red;
                    } else if (b.isWarning) {
                      progressColor = Colors.orange;
                    }

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: b.isExceeded
                              ? Colors.red.withValues(alpha: 0.5)
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
                                  radius: 18,
                                  backgroundColor:
                                      progressColor.withValues(alpha: 0.15),
                                  child: Icon(
                                    b.isExceeded
                                        ? Icons.warning_rounded
                                        : Icons.shopping_bag_outlined,
                                    size: 20,
                                    color: progressColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        catName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Batas: ${CurrencyUtils.formatRupiah(b.limitAmount)}',
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
                                  onPressed: () {
                                    _showBudgetOptions(context, ref, b);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: b.progress > 1.0 ? 1.0 : b.progress,
                                minHeight: 8,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    progressColor),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Detail Info Pemakaian
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Terpakai: ${CurrencyUtils.formatRupiah(b.spentAmount)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  b.isExceeded
                                      ? 'Lebih ${CurrencyUtils.formatRupiah(b.overAmount)}!'
                                      : 'Sisa: ${CurrencyUtils.formatRupiah(b.remainingAmount)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: b.isExceeded
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
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

  void _showBudgetOptions(BuildContext context, WidgetRef ref, Budget b) {
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
                title: const Text('Ubah Anggaran'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBudgetDialog(context, ref, b);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Anggaran',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Hapus Anggaran',
                    message: 'Apakah Anda yakin ingin menghapus anggaran ini?',
                    confirmLabel: 'Hapus',
                    isDestructive: true,
                  );
                  if (confirmed) {
                    await ref
                        .read(budgetActionsProvider.notifier)
                        .deleteBudget(b.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    Budget? existing,
  ) {
    final selectedMonth = ref.read(selectedBudgetMonthProvider);
    final categories = ref.read(finCategoriesProvider).value ?? [];
    final expenseCategories = categories.where((c) => c.isExpense).toList();

    String? selectedCatId = existing?.categoryId ??
        (expenseCategories.isNotEmpty ? expenseCategories.first.id : null);
    final amountController = TextEditingController(
      text: existing != null ? existing.limitAmount.toString() : '',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Buat Anggaran' : 'Ubah Anggaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (expenseCategories.isEmpty)
                      const Text(
                        'Belum ada kategori pengeluaran. Buat kategori terlebih dahulu.',
                        style: TextStyle(color: Colors.red),
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: selectedCatId,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Pengeluaran',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: expenseCategories.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedCatId = val);
                        },
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Batas Nominal Anggaran (Rp) *',
                        prefixText: 'Rp ',
                        prefixIcon: Icon(Icons.attach_money_rounded),
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
                  onPressed: selectedCatId == null
                      ? null
                      : () async {
                          final amount =
                              CurrencyUtils.parseNominal(amountController.text);
                          if (amount <= BigInt.zero) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nominal harus lebih dari 0'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final now = DateTime.now().toUtc();
                          final budgetToSave = Budget(
                            id: existing?.id ?? '',
                            userId: '',
                            categoryId: selectedCatId!,
                            month: selectedMonth,
                            limitAmount: amount,
                            createdAt: existing?.createdAt ?? now,
                            updatedAt: now,
                          );

                          await ref
                              .read(budgetActionsProvider.notifier)
                              .upsertBudget(budgetToSave);

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
}
