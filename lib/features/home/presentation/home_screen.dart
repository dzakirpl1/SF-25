import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../settings/data/settings_repository.dart';
import '../../notes/presentation/note_controller.dart';
import '../../notes/presentation/quick_capture_dialog.dart';
import '../../../core/utils/date_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final settingsAsync = ref.watch(userSettingsProvider);
    final recentNotesAsync = ref.watch(recentNotesProvider);
    final theme = Theme.of(context);

    final dayStartHour = settingsAsync.value?.dayStartHour ?? 4;
    final logicalToday = AppDateUtils.getLogicalDate(DateTime.now().toUtc(), dayStartHour: dayStartHour);
    final tanggalStr = AppDateUtils.formatHariTanggal(logicalToday);

    final nama = profileAsync.value?.displayName ?? 'Pemilik';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, $nama',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              tanggalStr,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentNotesProvider);
          ref.invalidate(userProfileProvider);
          ref.invalidate(userSettingsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Quick Capture Banner
            Card(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.bolt_rounded, color: Colors.white),
                ),
                title: const Text(
                  'Quick Capture',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Simpan ide atau catatan dengan satu ketukan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => QuickCaptureDialog.show(context),
              ),
            ),
            const SizedBox(height: 20),

            // Bagian: Catatan Terbaru (F-HOME-01)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Catatan Terbaru',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/notes'),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            recentNotesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Gagal memuat catatan terbaru: $err'),
                ),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.note_add_outlined,
                            size: 36,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text('Belum ada catatan yang tersimpan.'),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () => context.push('/notes/edit'),
                            child: const Text('Buat Catatan Sekarang'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: notes.map((n) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(
                          n.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          n.content.isNotEmpty ? n.content.replaceAll('\n', ' ') : 'Catatan kosong',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          AppDateUtils.formatRelatif(n.updatedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        onTap: () => context.push('/notes/edit', extra: n),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Roadmap Modul Berikutnya (Fase 3 & 4 Preview Card)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Fase 0–2 Aktif',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fondasi Flutter, Supabase Auth, Profiles, Settings, Catatan, Kategori, dan RLS telah aktif dan terhubung langsung ke database Anda.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => QuickCaptureDialog.show(context),
        tooltip: 'Quick Capture',
        child: const Icon(Icons.bolt_rounded),
      ),
    );
  }
}
