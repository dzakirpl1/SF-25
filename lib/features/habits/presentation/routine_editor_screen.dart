import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../domain/routine.dart';
import 'routine_controller.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final Routine? initialRoutine;

  const RoutineEditorScreen({super.key, this.initialRoutine});

  @override
  ConsumerState<RoutineEditorScreen> createState() =>
      _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  final _stepInputController = TextEditingController();

  late String _timeOfDay;
  late List<String> _steps;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRoutine;
    _nameController = TextEditingController(text: r?.name ?? '');
    _descController = TextEditingController(text: r?.description ?? '');
    _timeOfDay = r?.timeOfDay ?? 'morning';
    _steps = r != null ? r.steps.map((s) => s.title).toList() : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _stepInputController.dispose();
    super.dispose();
  }

  void _addStep() {
    final text = _stepInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _steps.add(text);
      _stepInputController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal satu langkah dalam rutinitas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now().toUtc();
      if (widget.initialRoutine == null) {
        // Buat baru
        final newRoutine = Routine(
          id: '',
          userId: '',
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          timeOfDay: _timeOfDay,
          createdAt: now,
          updatedAt: now,
        );
        await ref
            .read(routineActionsProvider.notifier)
            .createRoutine(newRoutine, _steps);
      } else {
        // Update
        final updated = widget.initialRoutine!.copyWith(
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          timeOfDay: _timeOfDay,
        );
        await ref
            .read(routineActionsProvider.notifier)
            .updateRoutine(updated, _steps);
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
    final isEditing = widget.initialRoutine != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Rutinitas' : 'Rutinitas Baru'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Hapus',
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Hapus Rutinitas',
                  message: 'Pindahkan rutinitas ini ke tempat sampah?',
                  confirmLabel: 'Hapus',
                  isDestructive: true,
                );
                if (confirm && mounted) {
                  await ref
                      .read(routineActionsProvider.notifier)
                      .deleteRoutine(widget.initialRoutine!.id);
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
                labelText: 'Nama Rutinitas *',
                hintText: 'Misal: Rutinitas Pagi, Sebelum Tidur',
                prefixIcon: Icon(Icons.wb_sunny_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama rutinitas wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Waktu dalam Hari
            DropdownButtonFormField<String>(
              initialValue: _timeOfDay,
              decoration: const InputDecoration(
                labelText: 'Waktu Rutinitas',
                prefixIcon: Icon(Icons.schedule_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'morning',
                  child: Text('Pagi Hari (Morning)'),
                ),
                DropdownMenuItem(
                  value: 'evening',
                  child: Text('Malam Hari (Evening)'),
                ),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text('Waktu Khusus (Custom)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _timeOfDay = val);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Tambahan',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 24),

            // Bagian Langkah-Langkah (Steps)
            const Text(
              'Daftar Langkah Rutinitas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepInputController,
                    decoration: const InputDecoration(
                      hintText: 'Tulis langkah baru...',
                      prefixIcon: Icon(Icons.check_box_outlined),
                    ),
                    onSubmitted: (_) => _addStep(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  tooltip: 'Tambah Langkah',
                  onPressed: _addStep,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_steps.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Belum ada langkah. Tulis langkah di atas lalu tekan tombol +',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final item = _steps.removeAt(oldIndex);
                    _steps.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  return Card(
                    key: ValueKey('step_${_steps[index]}_$index'),
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 12,
                        child: Text('${index + 1}',
                            style: const TextStyle(fontSize: 11)),
                      ),
                      title: Text(_steps[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() => _steps.removeAt(index));
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
