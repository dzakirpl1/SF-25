import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/ephemeral_draft_service.dart';
import '../../../shared/widgets/markdown_view.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../categories/presentation/category_controller.dart';
import '../../templates/presentation/template_picker_dialog.dart';
import '../domain/note.dart';
import 'note_controller.dart';

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
  bool _isPreviewMode = false;
  late final String _draftKey;

  @override
  void initState() {
    super.initState();
    _draftKey = widget.initialNote?.id ?? 'new_note';
    _titleController =
        TextEditingController(text: widget.initialNote?.title ?? '');
    _contentController =
        TextEditingController(text: widget.initialNote?.content ?? '');
    _selectedCategoryId = widget.initialNote?.categoryId;
    _isPinned = widget.initialNote?.isPinned ?? false;

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);

    _checkDraft();
  }

  void _checkDraft() async {
    final draftService = ref.read(ephemeralDraftServiceProvider);
    final draft = await draftService.getDraft(_draftKey);
    if (draft != null && mounted) {
      final draftContent = draft['content'] as String? ?? '';
      final draftTitle = draft['title'] as String? ?? '';
      if (draftContent != _contentController.text ||
          draftTitle != _titleController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Ditemukan draf tersimpan yang belum tersinkron.'),
            action: SnackBarAction(
              label: 'Pulihkan',
              onPressed: () {
                setState(() {
                  _titleController.text = draftTitle;
                  _contentController.text = draftContent;
                  _isDirty = true;
                });
              },
            ),
          ),
        );
      }
    }
  }

  void _onTextChanged() {
    if (!_isDirty) setState(() => _isDirty = true);
    ref.read(ephemeralDraftServiceProvider).saveDraft(_draftKey, {
      'title': _titleController.text,
      'content': _contentController.text,
      'category_id': _selectedCategoryId,
    });
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
      await ref.read(ephemeralDraftServiceProvider).clearDraft(_draftKey);
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

    if (success) {
      await ref.read(ephemeralDraftServiceProvider).clearDraft(_draftKey);
      if (mounted) context.pop();
    } else if (mounted) {
      final err = ref.read(noteActionsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err.hasError
                ? '${err.error} Draf Anda tetap aman tersimpan di perangkat.'
                : 'Gagal menyimpan. Draf Anda aman tersimpan.',
          ),
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
        title:
            Text(widget.initialNote == null ? 'Catatan Baru' : 'Ubah Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: 'Gunakan Template',
            onPressed: () =>
                TemplatePickerDialog.show(context, (tTitle, tContent) {
              setState(() {
                if (_titleController.text.isEmpty) {
                  _titleController.text = tTitle;
                }
                if (_contentController.text.isEmpty) {
                  _contentController.text = tContent;
                } else {
                  _contentController.text += '\n\n$tContent';
                }
                _isDirty = true;
              });
            }),
          ),
          IconButton(
            icon: Icon(_isPreviewMode
                ? Icons.edit_outlined
                : Icons.visibility_outlined),
            tooltip: _isPreviewMode ? 'Mode Edit' : 'Pratinjau Markdown',
            onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
          ),
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
          const OfflineBanner(),
          // Category selector dropdown
          categoriesAsync.maybeWhen(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

          // Title & Content / Markdown Preview
          Expanded(
            child: _isPreviewMode
                ? ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                    children: [
                      if (_titleController.text.isNotEmpty)
                        Text(
                          _titleController.text,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 16),
                      MarkdownView(content: _contentController.text),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                    children: [
                      TextField(
                        controller: _titleController,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                          hintText:
                              'Tulis sesuatu... (Mendukung Markdown #, ##, - [ ] checklist)',
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
