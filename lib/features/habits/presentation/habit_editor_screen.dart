import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../domain/habit.dart';
import 'habit_controller.dart';

class HabitEditorScreen extends ConsumerStatefulWidget {
  final Habit? initialHabit;

  const HabitEditorScreen({super.key, this.initialHabit});

  @override
  ConsumerState<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends ConsumerState<HabitEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  late String _color;
  late String _frequencyType;
  late List<int> _selectedDays;
  bool _isLoading = false;

  final List<String> _colorOptions = [
    '#4CAF50', // Hijau
    '#2196F3', // Biru
    '#FF9800', // Oranye
    '#E91E63', // Pink
    '#9C27B0', // Ungu
    '#00BCD4', // Cyan
  ];

  final Map<int, String> _weekdayLabels = {
    1: 'Sen',
    2: 'Sel',
    3: 'Rab',
    4: 'Kam',
    5: 'Jum',
    6: 'Sab',
    7: 'Min',
  };

  @override
  void initState() {
    super.initState();
    final h = widget.initialHabit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descController = TextEditingController(text: h?.description ?? '');
    _color = h?.color ?? '#4CAF50';
    _frequencyType = h?.frequencyType ?? 'daily';

    if (h != null && h.frequencyConfig['days'] != null) {
      _selectedDays = (h.frequencyConfig['days'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 1)
          .toList();
    } else {
      _selectedDays = [1, 2, 3, 4, 5, 6, 7];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_frequencyType == 'specific_days' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu hari aktif untuk kebiasaan ini'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now().toUtc();
      final config = _frequencyType == 'specific_days'
          ? {'days': _selectedDays}
          : <String, dynamic>{};

      if (widget.initialHabit == null) {
        // Buat baru
        final newHabit = Habit(
          id: '',
          userId: '',
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          color: _color,
          frequencyType: _frequencyType,
          frequencyConfig: config,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(habitActionsProvider.notifier).createHabit(newHabit);
      } else {
        // Update
        final updated = widget.initialHabit!.copyWith(
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          color: _color,
          frequencyType: _frequencyType,
          frequencyConfig: config,
        );
        await ref.read(habitActionsProvider.notifier).updateHabit(updated);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
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
    final isEditing = widget.initialHabit != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Kebiasaan' : 'Kebiasaan Baru'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Hapus',
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Hapus Kebiasaan',
                  message: 'Pindahkan kebiasaan ini ke tempat sampah?',
                  confirmLabel: 'Hapus',
                  isDestructive: true,
                );
                if (confirm && mounted) {
                  await ref
                      .read(habitActionsProvider.notifier)
                      .deleteHabit(widget.initialHabit!.id);
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
            tooltip: 'Simpan',
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
                labelText: 'Nama Kebiasaan *',
                hintText: 'Misal: Olahraga 20 Menit, Membaca Buku',
                prefixIcon: Icon(Icons.fitness_center_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama kebiasaan wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Frekuensi
            DropdownButtonFormField<String>(
              initialValue: _frequencyType,
              decoration: const InputDecoration(
                labelText: 'Target Frekuensi',
                prefixIcon: Icon(Icons.repeat_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'daily',
                  child: Text('Setiap Hari'),
                ),
                DropdownMenuItem(
                  value: 'specific_days',
                  child: Text('Hari-hari Tertentu'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _frequencyType = val);
              },
            ),
            const SizedBox(height: 16),

            // Pilihan Hari untuk specific_days
            if (_frequencyType == 'specific_days') ...[
              const Text(
                'Pilih Hari Aktif:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _weekdayLabels.entries.map((entry) {
                  final isSelected = _selectedDays.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(entry.key);
                          _selectedDays.sort();
                        } else {
                          _selectedDays.remove(entry.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Pilihan Warna
            const Text(
              'Warna Kebiasaan',
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
            const SizedBox(height: 16),

            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi / Catatan Tambahan',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
