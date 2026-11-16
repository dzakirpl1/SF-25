import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../inbox/presentation/inbox_controller.dart';
import 'note_controller.dart';

class QuickCaptureDialog extends ConsumerStatefulWidget {
  const QuickCaptureDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickCaptureDialog(),
    );
  }

  @override
  ConsumerState<QuickCaptureDialog> createState() => _QuickCaptureDialogState();
}

class _QuickCaptureDialogState extends ConsumerState<QuickCaptureDialog> {
  final _contentController = TextEditingController();
  bool _saveToInbox = true;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    Navigator.of(context).pop();

    if (_saveToInbox) {
      final success = await ref
          .read(inboxActionsProvider.notifier)
          .addItem(text, source: 'quick_capture');
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tersimpan ke Inbox untuk dipilah nanti')),
        );
      }
    } else {
      final success = await ref
          .read(noteActionsProvider.notifier)
          .createNote(content: text);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan langsung tersimpan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = ref.watch(noteActionsProvider).isLoading ||
        ref.watch(inboxActionsProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Capture',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              autofocus: true,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Tulis ide, tugas, atau tangkapan cepat...',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Ke Inbox (Triase)'),
                  selected: _saveToInbox,
                  onSelected: (val) => setState(() => _saveToInbox = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Langsung Catatan'),
                  selected: !_saveToInbox,
                  onSelected: (val) => setState(() => _saveToInbox = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isSaving ? null : _submit,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_saveToInbox ? 'Tampung ke Inbox' : 'Simpan Catatan'),
            ),
          ],
        ),
      ),
    );
  }
}
