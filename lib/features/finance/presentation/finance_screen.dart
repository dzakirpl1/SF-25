import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import 'finance_controller.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawWalletsAsync = ref.watch(rawWalletsProvider);
    final txAsync = ref.watch(allTransactionsProvider);
    final summary = ref.watch(financialSummaryProvider);
    final wallets = ref.watch(walletsWithBalanceProvider);
    final categoriesAsync = ref.watch(finCategoriesProvider);
    final theme = Theme.of(context);

    final catMap = <String, String>{};
    for (final c in (categoriesAsync.value ?? [])) {
      catMap[c.id] = c.name;
    }

    final walletMap = <String, String>{};
    for (final w in wallets) {
      walletMap[w.id] = w.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan (Money Tracker)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_rounded),
            tooltip: 'Tambah Dompet',
            onPressed: () => context.push('/finance/wallet/edit'),
          ),
        ],
      ),
      body: rawWalletsAsync.when(
        loading: () => const LoadingView(message: 'Memuat data keuangan...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () {
            ref.invalidate(rawWalletsProvider);
            ref.invalidate(allTransactionsProvider);
          },
        ),
        data: (_) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Kartu Ringkasan Total Saldo & Arus Kas
              Card(
                elevation: 0,
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Saldo Semua Dompet',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtils.formatRupiah(summary.totalBalance),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.arrow_downward,
                                        size: 14, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('Pemasukan',
                                        style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyUtils.formatRupiah(
                                      summary.monthlyIncome),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.arrow_upward,
                                        size: 14, color: Colors.red),
                                    SizedBox(width: 4),
                                    Text('Pengeluaran',
                                        style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyUtils.formatRupiah(
                                      summary.monthlyExpense),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Menu Cepat Keuangan Lanjutan (Fase 10)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.push('/finance/budgets'),
                      icon:
                          const Icon(Icons.pie_chart_outline_rounded, size: 18),
                      label: const Text('Anggaran',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.push('/finance/savings'),
                      icon: const Icon(Icons.savings_outlined, size: 18),
                      label: const Text('Tabungan',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.push('/finance/debts'),
                      icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                      label:
                          const Text('Utang', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Daftar Dompet (Horizontal Carousel)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dompet & Rekening',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/finance/wallet/edit'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Dompet Baru'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (wallets.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.wallet_outlined),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                              'Belum ada dompet. Buat dompet tunai atau rekening Anda.'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => context.push('/finance/wallet/edit'),
                          child: const Text('Buat'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final w = wallets[index];
                      Color wColor;
                      try {
                        wColor = Color(
                            int.parse(w.color.replaceAll('#', ''), radix: 16) +
                                0xFF000000);
                      } catch (_) {
                        wColor = theme.colorScheme.primary;
                      }

                      return InkWell(
                        onTap: () =>
                            context.push('/finance/wallet/edit', extra: w),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: wColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: wColor.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: wColor,
                                    child: const Icon(Icons.wallet,
                                        size: 14, color: Colors.white),
                                  ),
                                  Text(
                                    w.type.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: wColor,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyUtils.formatRupiah(
                                        w.currentBalance),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              // 3. Riwayat Transaksi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Transaksi Terakhir',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              txAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Text('Gagal memuat transaksi: $err'),
                data: (txs) {
                  if (txs.isEmpty) {
                    return const EmptyView(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum Ada Transaksi',
                      subtitle:
                          'Catat pengeluaran, pemasukan, atau transfer dengan tombol di bawah.',
                    );
                  }

                  return Column(
                    children: txs.map((tx) {
                      final isIncome = tx.isIncome;
                      final isExpense = tx.isExpense;
                      final isTransfer = tx.isTransfer;

                      Color amountColor;
                      String prefix;
                      IconData txIcon;

                      if (isIncome) {
                        amountColor = Colors.green;
                        prefix = '+';
                        txIcon = Icons.arrow_downward;
                      } else if (isExpense) {
                        amountColor = Colors.red;
                        prefix = '-';
                        txIcon = Icons.arrow_upward;
                      } else {
                        amountColor = Colors.blue;
                        prefix = '⇄ ';
                        txIcon = Icons.swap_horiz;
                      }

                      final catName = catMap[tx.categoryId] ?? 'Tanpa Kategori';
                      final wName = walletMap[tx.walletId] ?? 'Dompet';
                      final toWName =
                          isTransfer ? (walletMap[tx.toWalletId] ?? '') : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                amountColor.withValues(alpha: 0.15),
                            child: Icon(txIcon, color: amountColor, size: 20),
                          ),
                          title: Text(
                            isTransfer
                                ? 'Transfer: $wName → $toWName'
                                : (tx.note != null && tx.note!.isNotEmpty
                                    ? tx.note!
                                    : catName),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${DateFormat('d MMM, HH:mm', 'id_ID').format(tx.occurredAt.toLocal())} • ${isTransfer ? 'Transfer' : '$catName ($wName)'}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$prefix${CurrencyUtils.formatRupiah(tx.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                  fontSize: 13,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18),
                                onSelected: (val) async {
                                  if (val == 'delete') {
                                    final confirm = await ConfirmDialog.show(
                                      context,
                                      title: 'Hapus Transaksi',
                                      message:
                                          'Hapus catatan transaksi ${CurrencyUtils.formatRupiah(tx.amount)}?',
                                      confirmLabel: 'Hapus',
                                      isDestructive: true,
                                    );
                                    if (confirm) {
                                      await ref
                                          .read(financeActionsProvider.notifier)
                                          .deleteTransaction(tx.id);
                                    }
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Hapus',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/finance/transaction/edit'),
        icon: const Icon(Icons.add),
        label: const Text('Catat Transaksi'),
      ),
    );
  }
}
