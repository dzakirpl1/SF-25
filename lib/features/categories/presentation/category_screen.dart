import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category_controller.dart';
import '../domain/note_category.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      [NoteCategory? category]) {
    final controller = TextEditingController(text: category?.name ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(category == null ? 'Kategori Baru' : 'Ubah Kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            hintText: 'Contoh: Ide, Kerja, Pribadi',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.of(dialogCtx).pop();

              if (category == null) {
                await ref.read(categoryListProvider.notifier).addCategory(name);
              } else {
                await ref
                    .read(categoryListProvider.notifier)
                    .updateCategory(category.id, name);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Kategori',
            onPressed: () => _showAddEditDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const LoadingView(message: 'Memuat kategori...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(categoryListProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyView(
              icon: Icons.category_outlined,
              title: 'Belum Ada Kategori',
              subtitle: 'Buat kategori untuk mengelompokkan catatan Anda.',
              action: FilledButton.icon(
                onPressed: () => _showAddEditDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Buat Kategori'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.folder_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Ubah',
                        onPressed: () => _showAddEditDialog(context, ref, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Hapus',
                        onPressed: () async {
                          final confirmed = await ConfirmDialog.show(
                            context,
                            title: 'Hapus Kategori',
                            message:
                                'Hapus kategori "${cat.name}"? Kategori hanya bisa dihapus jika tidak dipakai catatan aktif.',
                            confirmLabel: 'Hapus',
                            isDestructive: true,
                          );
                          if (!confirmed) return;

                          try {
                            await ref
                                .read(categoryListProvider.notifier)
                                .deleteCategory(cat.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Kategori berhasil dihapus')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
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
    );
  }
}
