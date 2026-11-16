import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_utils.dart';
import '../domain/transaction.dart';
import 'finance_controller.dart';

class TransactionEditorScreen extends ConsumerStatefulWidget {
  const TransactionEditorScreen({super.key});

  @override
  ConsumerState<TransactionEditorScreen> createState() =>
      _TransactionEditorScreenState();
}

class _TransactionEditorScreenState
    extends ConsumerState<TransactionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense'; // income, expense, transfer
  String? _selectedWalletId;
  String? _selectedToWalletId;
  String? _selectedCategoryId;
  DateTime _occurredAt = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amountBigInt = CurrencyUtils.parseNominal(_amountController.text);
    if (amountBigInt <= BigInt.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal harus lebih dari 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih dompet yang digunakan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_type == 'transfer') {
      if (_selectedToWalletId == null ||
          _selectedToWalletId == _selectedWalletId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih dompet tujuan transfer yang berbeda'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now().toUtc();
      final tx = TransactionItem(
        id: '',
        userId: '',
        walletId: _selectedWalletId!,
        toWalletId: _type == 'transfer' ? _selectedToWalletId : null,
        categoryId: _type != 'transfer' ? _selectedCategoryId : null,
        type: _type,
        amount: amountBigInt,
        occurredAt: _occurredAt.toUtc(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(financeActionsProvider.notifier).createTransaction(tx);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsWithBalanceProvider);
    final categoriesAsync = ref.watch(finCategoriesProvider);
    final categories = (categoriesAsync.value ?? [])
        .where((c) => _type == 'income' ? c.isIncome : c.isExpense)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Transaksi'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _isLoading ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Pemilih Jenis Transaksi
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  label: Text('Pengeluaran'),
                  icon: Icon(Icons.arrow_upward, color: Colors.red),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Pemasukan'),
                  icon: Icon(Icons.arrow_downward, color: Colors.green),
                ),
                ButtonSegment(
                  value: 'transfer',
                  label: Text('Transfer'),
                  icon: Icon(Icons.swap_horiz, color: Colors.blue),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (val) {
                setState(() {
                  _type = val.first;
                  _selectedCategoryId = null;
                });
              },
            ),
            const SizedBox(height: 20),

            // Nominal Uang (Rupiah BigInt)
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: 'Nominal Transaksi (Rp) *',
                prefixText: 'Rp ',
                hintText: '0',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nominal wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Pemilih Dompet Asal
            DropdownButtonFormField<String>(
              initialValue: _selectedWalletId,
              decoration: InputDecoration(
                labelText: _type == 'transfer' ? 'Dompet Asal *' : 'Dompet *',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              ),
              items: wallets.map((w) {
                return DropdownMenuItem(
                  value: w.id,
                  child: Text(
                      '${w.name} (${CurrencyUtils.formatRupiah(w.currentBalance)})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedWalletId = val),
            ),
            const SizedBox(height: 16),

            // Jika Transfer: Pemilih Dompet Tujuan
            if (_type == 'transfer') ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedToWalletId,
                decoration: const InputDecoration(
                  labelText: 'Dompet Tujuan *',
                  prefixIcon: Icon(Icons.move_down_rounded),
                ),
                items: wallets
                    .where((w) => w.id != _selectedWalletId)
                    .map((w) => DropdownMenuItem(
                          value: w.id,
                          child: Text(w.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedToWalletId = val),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Jika Bukan Transfer: Pemilih Kategori Keuangan
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori Keuangan',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Tanpa Kategori')),
                  ...categories.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),
            ],

            // Pemilih Tanggal & Waktu Transaksi
            ListTile(
              title: const Text('Waktu Transaksi'),
              subtitle: Text(
                DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID')
                    .format(_occurredAt),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _occurredAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (d != null) {
                    setState(() {
                      _occurredAt = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        _occurredAt.hour,
                        _occurredAt.minute,
                      );
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Catatan
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan Transaksi',
                hintText: 'Misal: Makan siang bersama tim',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
