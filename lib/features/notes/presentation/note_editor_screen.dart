import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/note.dart';
import 'note_controller.dart';
import '../../categories/presentation/category_controller.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? initialNote;
  const NoteEditorScreen({super.key, this.initialNote});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  String? _selectedCategoryId;
  bool _isPinned = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialNote?.title ?? '');
    _contentController = TextEditingController(text: widget.initialNote?.content ?? '');
    _selectedCategoryId = widget.initialNote?.categoryId;
    _isPinned = widget.initialNote?.isPinned ?? false;

    _titleController.addListener(_markDirty);
    _contentController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    final title = _titleController.text.trim();

    if (content.isEmpty && title.isEmpty) {
      if (mounted) context.pop();
      return;
    }

    final isNew = widget.initialNote == null;
    bool success = false;

    if (isNew) {
      success = await ref.read(noteActionsProvider.notifier).createNote(
            title: title.isEmpty ? null : title,
            content: content,
            categoryId: _selectedCategoryId,
            isPinned: _isPinned,
          );
    } else {
      success = await ref.read(noteActionsProvider.notifier).updateNote(
            id: widget.initialNote!.id,
            title: title.isEmpty ? null : title,
            content: content,
            categoryId: _selectedCategoryId,
            isPinned: _isPinned,
            lastKnownUpdatedAt: widget.initialNote!.updatedAt,
          );
    }

    if (success && mounted) {
      context.pop();
    } else if (mounted) {
      final err = ref.read(noteActionsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.hasError ? err.error.toString() : 'Gagal menyimpan catatan'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final isSaving = ref.watch(noteActionsProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialNote == null ? 'Catatan Baru' : 'Ubah Catatan'),
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            tooltip: _isPinned ? 'Lepas Pin' : 'Pin Catatan',
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            tooltip: 'Simpan',
            onPressed: isSaving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category selector dropdown
          categoriesAsync.maybeWhen(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedCategoryId,
                          hint: const Text('Pilih Kategori (Opsional)'),
                          isDense: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tanpa Kategori'),
                            ),
                            ...categories.map((c) => DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Text(c.name),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedCategoryId = val;
                              _isDirty = true;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const Divider(height: 1),

          // Title & Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              children: [
                TextField(
                  controller: _titleController,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Judul (Opsional)',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Tulis sesuatu...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
