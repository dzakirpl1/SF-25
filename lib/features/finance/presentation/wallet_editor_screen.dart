import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../domain/wallet.dart';
import 'finance_controller.dart';

class WalletEditorScreen extends ConsumerStatefulWidget {
  final Wallet? initialWallet;

  const WalletEditorScreen({super.key, this.initialWallet});

  @override
  ConsumerState<WalletEditorScreen> createState() => _WalletEditorScreenState();
}

class _WalletEditorScreenState extends ConsumerState<WalletEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  late String _type;
  late String _color;
  bool _isLoading = false;

  final List<String> _colorOptions = [
    '#00796B', // Teal
    '#1976D2', // Biru
    '#388E3C', // Hijau
    '#D32F2F', // Merah
    '#7B1FA2', // Ungu
    '#E65100', // Oranye Tua
  ];

  @override
  void initState() {
    super.initState();
    final w = widget.initialWallet;
    _nameController = TextEditingController(text: w?.name ?? '');
    _balanceController = TextEditingController(
      text: w != null ? w.initialBalance.toString() : '0',
    );
    _type = w?.type ?? 'cash';
    _color = w?.color ?? '#00796B';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final balanceBigInt = CurrencyUtils.parseNominal(_balanceController.text);
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now().toUtc();
      if (widget.initialWallet == null) {
        // Buat baru
        final newWallet = Wallet(
          id: '',
          userId: '',
          name: _nameController.text.trim(),
          type: _type,
          initialBalance: balanceBigInt,
          color: _color,
          currentBalance: balanceBigInt,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(financeActionsProvider.notifier).createWallet(newWallet);
      } else {
        // Update
        final updated = widget.initialWallet!.copyWith(
          name: _nameController.text.trim(),
          type: _type,
          initialBalance: balanceBigInt,
          color: _color,
        );
        await ref.read(financeActionsProvider.notifier).updateWallet(updated);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan dompet: $e'),
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
    final isEditing = widget.initialWallet != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Dompet' : 'Dompet Baru'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Hapus Dompet',
                  message:
                      'Pindahkan dompet "${widget.initialWallet!.name}" ke tempat sampah?',
                  confirmLabel: 'Hapus',
                  isDestructive: true,
                );
                if (confirm && mounted) {
                  await ref
                      .read(financeActionsProvider.notifier)
                      .deleteWallet(widget.initialWallet!.id);
                  if (mounted) context.pop();
                }
              },
            ),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Dompet / Rekening *',
                hintText: 'Misal: Dompet Utama, Bank BCA, GoPay',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama dompet wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tipe Dompet
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipe Dompet',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'cash', child: Text('Uang Tunai (Cash)')),
                DropdownMenuItem(value: 'bank', child: Text('Rekening Bank')),
                DropdownMenuItem(
                    value: 'ewallet', child: Text('E-Wallet / Dompet Digital')),
                DropdownMenuItem(value: 'other', child: Text('Lainnya')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _type = val);
              },
            ),
            const SizedBox(height: 16),

            // Saldo Awal
            TextFormField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Saldo Awal (Rp)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 20),

            // Warna
            const Text(
              'Warna Label',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: _colorOptions.map((c) {
                final isSelected = _color == c;
                final col = Color(
                    int.parse(c.replaceAll('#', ''), radix: 16) + 0xFF000000);
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.onSurface, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
