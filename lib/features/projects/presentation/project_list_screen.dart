import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/project.dart';
import 'project_controller.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      [Project? project]) {
    final nameController = TextEditingController(text: project?.name ?? '');
    final descController =
        TextEditingController(text: project?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(project == null ? 'Proyek Baru' : 'Ubah Proyek'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nama Proyek'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                  labelText: 'Deskripsi Singkat (Opsional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                if (project == null) {
                  await ref.read(projectActionsProvider.notifier).createProject(
                        name: name,
                        description: descController.text.trim(),
                      );
                } else {
                  await ref.read(projectActionsProvider.notifier).updateProject(
                        id: project.id,
                        name: name,
                        description: descController.text.trim(),
                        lastKnownUpdatedAt: project.updatedAt,
                      );
                }
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
    final projectsAsync = ref.watch(projectListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyek'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Proyek',
            onPressed: () => _showAddEditDialog(context, ref),
          ),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const LoadingView(message: 'Memuat proyek...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(projectListProvider),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return EmptyView(
              icon: Icons.folder_special_outlined,
              title: 'Belum Ada Proyek',
              subtitle:
                  'Kelompokkan tugas, catatan, dan progres tujuan hidup dalam Proyek.',
              action: FilledButton.icon(
                onPressed: () => _showAddEditDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Buat Proyek'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final proj = projects[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.folder_outlined,
                        color: theme.colorScheme.primary),
                  ),
                  title: Text(proj.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                      proj.description != null && proj.description!.isNotEmpty
                          ? Text(proj.description!,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Ubah',
                        onPressed: () => _showAddEditDialog(context, ref, proj),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Hapus Proyek',
                        onPressed: () async {
                          final confirmed = await ConfirmDialog.show(
                            context,
                            title: 'Hapus Proyek',
                            message:
                                'Hapus proyek "${proj.name}"? Tugas di dalamnya akan tetap ada.',
                            confirmLabel: 'Hapus',
                            isDestructive: true,
                          );
                          if (confirmed) {
                            await ref
                                .read(projectActionsProvider.notifier)
                                .deleteProject(proj.id);
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
