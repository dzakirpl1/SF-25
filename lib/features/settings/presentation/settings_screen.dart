import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/settings_repository.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final settingsAsync = ref.watch(userSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Profil Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (profileAsync.value?.displayName ?? 'P')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileAsync.value?.displayName ?? 'Pemilik Personal OS',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ref.watch(authRepositoryProvider).currentUser?.email ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pengaturan Sistem
          Text(
            'Konfigurasi Dasar',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Tema Tampilan'),
                  subtitle: Text(settingsAsync.value?.theme ?? 'Mengikuti Sistem'),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Zona Waktu'),
                  subtitle: Text(settingsAsync.value?.timezone ?? 'Asia/Jakarta (WIB)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Mata Uang Default'),
                  subtitle: Text(settingsAsync.value?.currency ?? 'IDR (Rupiah)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('Jam Awal Hari Logis'),
                  subtitle: Text('${settingsAsync.value?.dayStartHour ?? 4}:00 WIB'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info Aplikasi
          Text(
            'Tentang Aplikasi',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Versi Blueprint'),
                  subtitle: Text('2.1.0 (Fase 0–2 Terimplementasi)'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.cloud_done_outlined),
                  title: Text('Backend'),
                  subtitle: Text('Supabase PostgreSQL (Online-first)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: theme.colorScheme.error,
              backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.4),
            ),
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'Keluar Akun',
                message: 'Apakah Anda yakin ingin keluar dari Personal OS?',
                confirmLabel: 'Keluar',
                isDestructive: true,
              );
              if (confirmed) {
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar dari Akun'),
          ),
        ],
      ),
    );
  }
}
