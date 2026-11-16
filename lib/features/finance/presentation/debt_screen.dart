import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/debt.dart';
import 'debt_controller.dart';

class DebtScreen extends ConsumerStatefulWidget {
  const DebtScreen({super.key});

  @override
  ConsumerState<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends ConsumerState<DebtScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(computedDebtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utang & Piutang'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
                text: 'Utang Saya (Pinjaman)',
                icon: Icon(Icons.arrow_upward_rounded)),
            Tab(
                text: 'Piutang Saya (Dipinjam)',
                icon: Icon(Icons.arrow_downward_rounded)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Catatan',
            onPressed: () => _showDebtDialog(context, ref, null),
          ),
        ],
      ),
      body: debtsAsync.when(
        loading: () =>
            const LoadingView(message: 'Memuat data utang piutang...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(rawDebtsProvider),
        ),
        data: (allDebts) {
          final myDebts = allDebts.where((d) => d.isOwedByMe).toList();
          final myReceivables = allDebts.where((d) => d.isOwedToMe).toList();

          // Total sisa utang dan total sisa piutang aktif
          var totalOwedByMe = BigInt.zero;
          for (final d in myDebts) {
            if (!d.isSettled) totalOwedByMe += d.remainingAmount;
          }

          var totalOwedToMe = BigInt.zero;
          for (final d in myReceivables) {
            if (!d.isSettled) totalOwedToMe += d.remainingAmount;
          }

          return Column(
            children: [
              // Ringkasan Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Utang Belum Lunas',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyUtils.formatRupiah(totalOwedByMe),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.withValues(alpha: 0.3)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Piutang Belum Diterima',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyUtils.formatRupiah(totalOwedToMe),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab View Isi Daftar
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDebtList(context, ref, myDebts, isOwedByMe: true),
                    _buildDebtList(context, ref, myReceivables,
                        isOwedByMe: false),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDebtList(
    BuildContext context,
    WidgetRef ref,
    List<Debt> debts, {
    required bool isOwedByMe,
  }) {
    if (debts.isEmpty) {
      return EmptyView(
        icon: isOwedByMe ? Icons.money_off_rounded : Icons.attach_money_rounded,
        title: isOwedByMe ? 'Tidak Ada Utang' : 'Tidak Ada Piutang',
        subtitle: isOwedByMe
            ? 'Hebat! Anda tidak memiliki catatan utang ke orang lain.'
            : 'Belum ada pihak lain yang memiliki pinjaman ke Anda.',
        action: FilledButton.icon(
          onPressed: () => _showDebtDialog(
            context,
            ref,
            null,
            defaultDirection: isOwedByMe ? 'owed_by_me' : 'owed_to_me',
          ),
          icon: const Icon(Icons.add),
          label: const Text('Catat Baru'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: debts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final d = debts[index];
        final percent = (d.progress * 100).toInt();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: d.isSettled
                  ? Colors.green.withValues(alpha: 0.5)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: (d.isSettled
                              ? Colors.green
                              : (isOwedByMe ? Colors.red : Colors.blue))
                          .withValues(alpha: 0.15),
                      child: Icon(
                        d.isSettled
                            ? Icons.check_circle_rounded
                            : (isOwedByMe
                                ? Icons.call_made_rounded
                                : Icons.call_received_rounded),
                        color: d.isSettled
                            ? Colors.green
                            : (isOwedByMe ? Colors.red : Colors.blue),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.personName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (d.dueDate != null)
                            Text(
                              'Jatuh Tempo: ${DateFormat('d MMMM yyyy', 'id_ID').format(d.dueDate!)}',
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
                    if (d.isSettled)
                      const Chip(
                        label: Text('Lunas',
                            style:
                                TextStyle(color: Colors.green, fontSize: 11)),
                        backgroundColor: Color(0x1A4CAF50),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: () => _showDebtOptions(context, ref, d),
                      ),
                  ],
                ),
                if (d.note != null && d.note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    d.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: d.progress,
                    minHeight: 8,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      d.isSettled
                          ? Colors.green
                          : (isOwedByMe ? Colors.red : Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Detail Sisa
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dibayar: ${CurrencyUtils.formatRupiah(d.paidAmount)} / ${CurrencyUtils.formatRupiah(d.principal)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      d.isSettled
                          ? 'Lunas (100%)'
                          : 'Sisa: ${CurrencyUtils.formatRupiah(d.remainingAmount)} ($percent%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: d.isSettled
                                ? Colors.green
                                : (isOwedByMe ? Colors.red : Colors.blue),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),

                if (!d.isSettled) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final confirmed = await ConfirmDialog.show(
                            context,
                            title: 'Tandai Lunas Penuh',
                            message:
                                'Tandai catatan "${d.personName}" sebesar ${CurrencyUtils.formatRupiah(d.principal)} sebagai lunas?',
                            confirmLabel: 'Lunas',
                          );
                          if (confirmed) {
                            await ref
                                .read(debtActionsProvider.notifier)
                                .settleDebt(d.id);
                          }
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Tandai Lunas'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => _showPaymentDialog(context, ref, d),
                        icon: const Icon(Icons.payment_rounded, size: 16),
                        label: const Text('Cicil / Bayar'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDebtOptions(BuildContext context, WidgetRef ref, Debt d) {
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
                title: const Text('Ubah Catatan'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDebtDialog(context, ref, d);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Catatan',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Hapus Catatan Utang/Piutang',
                    message:
                        'Apakah Anda yakin ingin menghapus catatan untuk "${d.personName}"?',
                    confirmLabel: 'Hapus',
                    isDestructive: true,
                  );
                  if (confirmed) {
                    await ref
                        .read(debtActionsProvider.notifier)
                        .deleteDebt(d.id);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDebtDialog(
    BuildContext context,
    WidgetRef ref,
    Debt? existing, {
    String defaultDirection = 'owed_by_me',
  }) {
    final personController =
        TextEditingController(text: existing?.personName ?? '');
    final principalController = TextEditingController(
      text: existing != null ? existing.principal.toString() : '',
    );
    final noteController = TextEditingController(text: existing?.note ?? '');
    String direction = existing?.direction ?? defaultDirection;
    DateTime? selectedDueDate = existing?.dueDate;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                  existing == null ? 'Catat Utang / Piutang' : 'Ubah Catatan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pilihan Arah Utang/Piutang
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'owed_by_me',
                          label: Text('Utang Saya'),
                          icon: Icon(Icons.arrow_upward_rounded),
                        ),
                        ButtonSegment(
                          value: 'owed_to_me',
                          label: Text('Piutang Saya'),
                          icon: Icon(Icons.arrow_downward_rounded),
                        ),
                      ],
                      selected: {direction},
                      onSelectionChanged: (set) {
                        setDialogState(() => direction = set.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: personController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pihak / Orang *',
                        hintText: 'Misal: Budi Santoso, Toko Makmur',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: principalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Pokok (Rp) *',
                        prefixText: 'Rp ',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: Text(
                        selectedDueDate == null
                            ? 'Pilih Jatuh Tempo (Opsional)'
                            : DateFormat('d MMMM yyyy', 'id_ID')
                                .format(selectedDueDate!),
                      ),
                      trailing: selectedDueDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setDialogState(() => selectedDueDate = null),
                            )
                          : null,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ??
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDueDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        hintText: 'Misal: Keperluan sewa, modal usaha',
                        prefixIcon: Icon(Icons.note_alt_outlined),
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
                    final person = personController.text.trim();
                    final principal =
                        CurrencyUtils.parseNominal(principalController.text);

                    if (person.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nama pihak/orang wajib diisi'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (principal <= BigInt.zero) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nominal pokok harus lebih dari 0'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final now = DateTime.now().toUtc();
                    if (existing == null) {
                      final newDebt = Debt(
                        id: '',
                        userId: '',
                        personName: person,
                        direction: direction,
                        principal: principal,
                        dueDate: selectedDueDate,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                        createdAt: now,
                        updatedAt: now,
                      );
                      await ref
                          .read(debtActionsProvider.notifier)
                          .createDebt(newDebt);
                    } else {
                      final updated = existing.copyWith(
                        personName: person,
                        direction: direction,
                        principal: principal,
                        dueDate: selectedDueDate,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                      await ref
                          .read(debtActionsProvider.notifier)
                          .updateDebt(updated);
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

  void _showPaymentDialog(BuildContext context, WidgetRef ref, Debt debt) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Bayar Cicilan "${debt.personName}"'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sisa yang harus diselesaikan: ${CurrencyUtils.formatRupiah(debt.remainingAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nominal Pembayaran (Rp) *',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Pembayaran (Opsional)',
                    hintText: 'Misal: Cicilan ke-1, transfer BCA',
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
                      content: Text('Nominal pembayaran harus lebih dari 0'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final now = DateTime.now().toUtc();
                final payment = DebtPayment(
                  id: '',
                  userId: '',
                  debtId: debt.id,
                  amount: amount,
                  paidAt: now,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                );

                await ref
                    .read(debtActionsProvider.notifier)
                    .addPayment(payment);

                // Jika cicilan ini melunasi utang, perbarui status otomatis
                if (amount >= debt.remainingAmount) {
                  await ref
                      .read(debtActionsProvider.notifier)
                      .settleDebt(debt.id);
                }

                if (context.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Catat Pembayaran'),
            ),
          ],
        );
      },
    );
  }
}
