import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../categories/presentation/category_controller.dart';
import '../../projects/presentation/project_controller.dart';
import '../domain/inbox_item.dart';
import 'inbox_controller.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submitQuick() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    await ref.read(inboxActionsProvider.notifier).addItem(text);
  }

  void _showTriageDialog(BuildContext context, InboxItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TriageBottomSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inboxAsync = ref.watch(inboxListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox & Triase'),
      ),
      body: Column(
        children: [
          // Quick input header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Tampung ide cepat ke Inbox...',
                      prefixIcon: Icon(Icons.all_inbox_rounded),
                    ),
                    onSubmitted: (_) => _submitQuick(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.arrow_upward_rounded),
                  tooltip: 'Tampung',
                  onPressed: _submitQuick,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: inboxAsync.when(
              loading: () => const LoadingView(message: 'Memuat inbox...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(inboxListProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyView(
                    icon: Icons.inbox_rounded,
                    title: 'Inbox Kosong (Zero Inbox)',
                    subtitle:
                        'Semua tangkapan ide cepat telah dipilah menjadi Catatan atau Tugas.',
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.lightbulb_outline_rounded,
                              color: theme.colorScheme.primary),
                        ),
                        title: Text(item.content,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${AppDateUtils.formatRelatif(item.createdAt)} • Sumber: ${item.source}',
                          style: TextStyle(
                              fontSize: 11, color: theme.colorScheme.outline),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _showTriageDialog(context, item),
                              child: const Text('Pilah'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () async {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'Hapus dari Inbox',
                                  message: 'Hapus item inbox ini?',
                                  confirmLabel: 'Hapus',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  ref
                                      .read(inboxActionsProvider.notifier)
                                      .deleteItem(item.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TriageBottomSheet extends ConsumerStatefulWidget {
  final InboxItem item;
  const _TriageBottomSheet({required this.item});

  @override
  ConsumerState<_TriageBottomSheet> createState() => _TriageBottomSheetState();
}

class _TriageBottomSheetState extends ConsumerState<_TriageBottomSheet> {
  String? _selectedCategoryId;
  String? _selectedProjectId;
  DateTime? _dueDate;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final projectsAsync = ref.watch(projectListProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Pilah Item Inbox',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(widget.item.content),
          ),
          const SizedBox(height: 16),

          // Pilihan 1: Jadikan Catatan
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.note_alt_outlined),
            title: const Text('Jadikan Catatan'),
            subtitle: categoriesAsync.maybeWhen(
              data: (cats) => DropdownButton<String?>(
                value: _selectedCategoryId,
                hint: const Text('Pilih Kategori'),
                isDense: true,
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Tanpa Kategori')),
                  ...cats.map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              orElse: () => const Text('Simpan ke daftar Catatan'),
            ),
            trailing: FilledButton.tonal(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(inboxActionsProvider.notifier).convertToNote(
                      widget.item.id,
                      widget.item.content,
                      categoryId: _selectedCategoryId,
                    );
              },
              child: const Text('Simpan Catatan'),
            ),
          ),

          const Divider(height: 24),

          // Pilihan 2: Jadikan Tugas
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Jadikan Tugas'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                projectsAsync.maybeWhen(
                  data: (projs) => DropdownButton<String?>(
                    value: _selectedProjectId,
                    hint: const Text('Pilih Proyek'),
                    isDense: true,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Tanpa Proyek')),
                      ...projs.map((p) =>
                          DropdownMenuItem(value: p.id, child: Text(p.name))),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedProjectId = val),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.event, size: 16),
                  label: Text(_dueDate == null
                      ? 'Atur Tenggat'
                      : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _dueDate = d);
                  },
                ),
              ],
            ),
            trailing: FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(inboxActionsProvider.notifier).convertToTask(
                      widget.item.id,
                      widget.item.content,
                      projectId: _selectedProjectId,
                      dueDate: _dueDate,
                    );
              },
              child: const Text('Simpan Tugas'),
            ),
          ),
          const SizedBox(height: 8),

          // Pilihan 3: Jadikan Acara Kalender (Fase 6 Integrasi)
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Jadikan Acara Kalender'),
            subtitle:
                const Text('Jadwalkan ke kalender hari ini / waktu tertentu'),
            trailing: FilledButton.tonal(
              onPressed: () async {
                Navigator.pop(context);
                final now = DateTime.now();
                await ref.read(inboxActionsProvider.notifier).convertToEvent(
                      widget.item.id,
                      widget.item.content,
                      startsAt: now,
                      endsAt: now.add(const Duration(hours: 1)),
                    );
              },
              child: const Text('Jadwalkan'),
            ),
          ),
        ],
      ),
    );
  }
}
