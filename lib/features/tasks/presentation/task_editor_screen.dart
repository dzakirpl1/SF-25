import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../projects/presentation/project_controller.dart';
import '../domain/task.dart';
import 'task_controller.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  final TaskItem? initialTask;
  const TaskEditorScreen({super.key, this.initialTask});

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _newSubtaskController;

  String? _selectedProjectId;
  int _priority = 4;
  bool _isImportant = false;
  bool _isUrgent = false;
  DateTime? _dueDate;
  String? _recurrenceRule;

  final List<String> _initialSubtasks = [];

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _newSubtaskController = TextEditingController();

    _selectedProjectId = t?.projectId;
    _priority = t?.priority ?? 4;
    _isImportant = t?.isImportant ?? false;
    _isUrgent = t?.isUrgent ?? false;
    _dueDate = t?.dueDate;
    _recurrenceRule = t?.recurrenceRule;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tugas tidak boleh kosong')),
      );
      return;
    }

    final isNew = widget.initialTask == null;
    bool success = false;

    if (isNew) {
      success = await ref.read(taskActionsProvider.notifier).createTask(
            projectId: _selectedProjectId,
            title: title,
            description: _descController.text.trim(),
            priority: _priority,
            isImportant: _isImportant,
            isUrgent: _isUrgent,
            dueDate: _dueDate,
            recurrenceRule: _recurrenceRule,
            initialSubtasks: _initialSubtasks,
          );
    } else {
      success = await ref.read(taskActionsProvider.notifier).updateTask(
            id: widget.initialTask!.id,
            projectId: _selectedProjectId,
            title: title,
            description: _descController.text.trim(),
            priority: _priority,
            isImportant: _isImportant,
            isUrgent: _isUrgent,
            dueDate: _dueDate,
            recurrenceRule: _recurrenceRule,
            lastKnownUpdatedAt: widget.initialTask!.updatedAt,
          );
    }

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectListProvider);
    final isSaving = ref.watch(taskActionsProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTask == null ? 'Tugas Baru' : 'Ubah Tugas'),
        actions: [
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            tooltip: 'Simpan',
            onPressed: isSaving ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Judul Tugas',
              hintText: 'Apa yang ingin diselesaikan?',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan / Deskripsi Tambahan (Opsional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          // Project Dropdown
          projectsAsync.maybeWhen(
            data: (projects) => DropdownButtonFormField<String?>(
              initialValue: _selectedProjectId,
              decoration: const InputDecoration(
                labelText: 'Proyek',
                prefixIcon: Icon(Icons.folder_special_outlined),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Tanpa Proyek (Pribadi)')),
                ...projects.map(
                    (p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
              ],
              onChanged: (val) => setState(() => _selectedProjectId = val),
            ),
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Tanggal Jatuh Tempo
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            leading: const Icon(Icons.event_outlined),
            title: const Text('Tenggat Waktu'),
            subtitle: Text(
              _dueDate != null
                  ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                  : 'Belum diatur',
            ),
            trailing: _dueDate != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _dueDate = null),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _pickDueDate,
          ),

          const SizedBox(height: 16),

          // Pengulangan (Recurrence)
          DropdownButtonFormField<String?>(
            initialValue: _recurrenceRule,
            decoration: const InputDecoration(
              labelText: 'Aturan Pengulangan',
              prefixIcon: Icon(Icons.repeat_rounded),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tidak Berulang')),
              DropdownMenuItem(
                  value: 'FREQ=DAILY;INTERVAL=1', child: Text('Setiap Hari')),
              DropdownMenuItem(
                  value: 'FREQ=WEEKLY;INTERVAL=1',
                  child: Text('Setiap Minggu')),
              DropdownMenuItem(
                  value: 'FREQ=MONTHLY;INTERVAL=1',
                  child: Text('Setiap Bulan')),
            ],
            onChanged: (val) => setState(() => _recurrenceRule = val),
          ),

          const SizedBox(height: 20),

          // Prioritas
          Text('Tingkat Prioritas',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                  value: 1,
                  label: Text('Tinggi'),
                  icon: Icon(Icons.flag, color: Colors.red)),
              ButtonSegment(
                  value: 2,
                  label: Text('Sedang'),
                  icon: Icon(Icons.flag, color: Colors.orange)),
              ButtonSegment(
                  value: 3,
                  label: Text('Rendah'),
                  icon: Icon(Icons.flag, color: Colors.blue)),
              ButtonSegment(value: 4, label: Text('Biasa')),
            ],
            selected: {_priority},
            onSelectionChanged: (set) => setState(() => _priority = set.first),
          ),

          const SizedBox(height: 20),

          // Matriks Eisenhower
          Text('Matriks Eisenhower (Prioritas Cerdas)',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Penting (Important)'),
                  subtitle:
                      const Text('Berdampak besar pada tujuan jangka panjang'),
                  value: _isImportant,
                  onChanged: (val) => setState(() => _isImportant = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Mendesak (Urgent)'),
                  subtitle:
                      const Text('Harus ditangani dalam waktu sangat dekat'),
                  value: _isUrgent,
                  onChanged: (val) => setState(() => _isUrgent = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Subtugas Builder (jika tugas baru)
          if (widget.initialTask == null) ...[
            Text('Subtugas (Checklist)',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubtaskController,
                    decoration: const InputDecoration(
                      labelText: 'Tambah Subtugas',
                      hintText: 'Langkah pengerjaan kecil...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final txt = _newSubtaskController.text.trim();
                    if (txt.isNotEmpty) {
                      setState(() {
                        _initialSubtasks.add(txt);
                        _newSubtaskController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._initialSubtasks.asMap().entries.map((entry) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.check_box_outline_blank, size: 20),
                title: Text(entry.value),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () =>
                      setState(() => _initialSubtasks.removeAt(entry.key)),
                ),
              );
            }),
          ] else ...[
            // Subtugas pada tugas yang sudah ada
            Text('Subtugas Terkait',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubtaskController,
                    decoration: const InputDecoration(
                        labelText: 'Tambah Subtugas Baru'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final txt = _newSubtaskController.text.trim();
                    if (txt.isNotEmpty) {
                      await ref.read(taskActionsProvider.notifier).addSubtask(
                            widget.initialTask!.id,
                            txt,
                            widget.initialTask!.subtasks.length,
                          );
                      _newSubtaskController.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...widget.initialTask!.subtasks.map((st) {
              return ListTile(
                dense: true,
                leading: Checkbox(
                  value: st.isDone,
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(taskActionsProvider.notifier)
                          .toggleSubtask(st.id, val);
                    }
                  },
                ),
                title: Text(
                  st.title,
                  style: TextStyle(
                      decoration:
                          st.isDone ? TextDecoration.lineThrough : null),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => ref
                      .read(taskActionsProvider.notifier)
                      .deleteSubtask(st.id),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
