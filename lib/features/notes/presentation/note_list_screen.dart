import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'note_controller.dart';
import '../domain/note.dart';
import '../../categories/presentation/category_controller.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'quick_capture_dialog.dart';

class NoteListScreen extends ConsumerStatefulWidget {
  const NoteListScreen({super.key});

  @override
  ConsumerState<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends ConsumerState<NoteListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(noteListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final currentFilter = ref.watch(noteFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          IconButton(
            icon: Icon(
              currentFilter.includeArchived ? Icons.inventory_2 : Icons.inventory_2_outlined,
            ),
            tooltip: currentFilter.includeArchived ? 'Sembunyikan Arsip' : 'Tampilkan Arsip',
            onPressed: () {
              ref.read(noteFilterProvider.notifier).state = currentFilter.copyWith(
                    includeArchived: !currentFilter.includeArchived,
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Kelola Kategori',
            onPressed: () => context.push('/categories'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari catatan...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(noteFilterProvider.notifier).state =
                              currentFilter.copyWith(searchQuery: '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(noteFilterProvider.notifier).state =
                    currentFilter.copyWith(searchQuery: val);
              },
            ),
          ),

          // Category Chips Filter
          categoriesAsync.maybeWhen(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: const Text('Semua'),
                        selected: currentFilter.categoryId == null,
                        onSelected: (_) {
                          ref.read(noteFilterProvider.notifier).state =
                              currentFilter.copyWith(clearCategory: true);
                        },
                      ),
                    ),
                    ...categories.map((cat) {
                      final isSelected = currentFilter.categoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            ref.read(noteFilterProvider.notifier).state =
                                currentFilter.copyWith(
                              categoryId: selected ? cat.id : null,
                              clearCategory: !selected,
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // Notes List
          Expanded(
            child: notesAsync.when(
              loading: () => const LoadingView(message: 'Memuat catatan...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(noteListProvider),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return EmptyView(
                    icon: Icons.note_alt_outlined,
                    title: 'Belum Ada Catatan',
                    subtitle: currentFilter.searchQuery?.isNotEmpty == true
                        ? 'Tidak ada catatan yang cocok dengan pencarian.'
                        : 'Mulai buat catatan pertama Anda atau gunakan Quick Capture.',
                    action: FilledButton.icon(
                      onPressed: () => context.push('/notes/edit'),
                      icon: const Icon(Icons.add),
                      label: const Text('Tulis Catatan'),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(noteListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteCard(note: note);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuickCaptureDialog.show(context),
        icon: const Icon(Icons.bolt_rounded),
        label: const Text('Quick Capture'),
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/notes/edit', extra: note),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.displayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.isPinned)
                    Icon(
                      Icons.push_pin,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  if (note.isArchived) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ],
              ),
              if (note.content.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.content.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppDateUtils.formatRelatif(note.updatedAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 18,
                        ),
                        tooltip: note.isPinned ? 'Lepas Pin' : 'Pin Catatan',
                        onPressed: () {
                          ref.read(noteActionsProvider.notifier).togglePin(note.id, note.isPinned);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          note.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                          size: 18,
                        ),
                        tooltip: note.isArchived ? 'Batal Arsip' : 'Arsipkan',
                        onPressed: () {
                          ref.read(noteActionsProvider.notifier).toggleArchive(note.id, note.isArchived);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: 'Hapus (Soft Delete)',
                        onPressed: () async {
                          final confirmed = await ConfirmDialog.show(
                            context,
                            title: 'Hapus Catatan',
                            message: 'Pindahkan catatan "${note.displayTitle}" ke tempat sampah?',
                            confirmLabel: 'Hapus',
                            isDestructive: true,
                          );
                          if (confirmed) {
                            ref.read(noteActionsProvider.notifier).softDelete(note.id);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
