import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/settings_repository.dart';
import '../domain/user_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditNameDialog(
      BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Tampilan'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(labelText: 'Nama Lengkap/Panggilan'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                await ref
                    .read(settingsRepositoryProvider)
                    .updateDisplayName(newName);
                ref.invalidate(userProfileProvider);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showSetPinDialog(
      BuildContext context, WidgetRef ref, UserSettings settings) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur PIN Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Masukkan 6 digit angka untuk PIN keamanan Personal OS:'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'PIN (6 Digit)',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length == 6) {
                Navigator.pop(ctx);
                final lockService = ref.read(appLockServiceProvider);
                await lockService.savePin(pin);
                await ref.read(settingsRepositoryProvider).updateSettings({
                  'app_lock_enabled': true,
                  'pin_enabled': true,
                }, lastKnownUpdatedAt: settings.updatedAt);
                ref.invalidate(userSettingsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('PIN keamanan berhasil diaktifkan')),
                  );
                }
              }
            },
            child: const Text('Simpan PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final settingsAsync = ref.watch(userSettingsProvider);
    final theme = Theme.of(context);

    final settings = settingsAsync.value ?? UserSettings(userId: '');
    final displayName = profileAsync.value?.displayName ?? 'Pemilik';

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
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'P',
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
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ref
                                  .watch(authRepositoryProvider)
                                  .currentUser
                                  ?.email ??
                              '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Ubah Nama',
                    onPressed: () =>
                        _showEditNameDialog(context, ref, displayName),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pengaturan Tampilan & Waktu
          Text(
            'Tampilan & Waktu',
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
                  subtitle: Text(
                    settings.theme == 'light'
                        ? 'Terang'
                        : (settings.theme == 'dark'
                            ? 'Gelap'
                            : 'Mengikuti Sistem'),
                  ),
                  trailing: DropdownButton<String>(
                    value: settings.theme,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('Sistem')),
                      DropdownMenuItem(value: 'light', child: Text('Terang')),
                      DropdownMenuItem(value: 'dark', child: Text('Gelap')),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        await ref
                            .read(settingsRepositoryProvider)
                            .updateSettings({
                          'theme': val,
                        }, lastKnownUpdatedAt: settings.updatedAt);
                        ref.invalidate(userSettingsProvider);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Zona Waktu'),
                  subtitle: Text(settings.timezone),
                  trailing: DropdownButton<String>(
                    value: settings.timezone,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                          value: 'Asia/Jakarta', child: Text('WIB (Jakarta)')),
                      DropdownMenuItem(
                          value: 'Asia/Makassar',
                          child: Text('WITA (Makassar)')),
                      DropdownMenuItem(
                          value: 'Asia/Jayapura',
                          child: Text('WIT (Jayapura)')),
                      DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        await ref
                            .read(settingsRepositoryProvider)
                            .updateSettings({
                          'timezone': val,
                        }, lastKnownUpdatedAt: settings.updatedAt);
                        ref.invalidate(userSettingsProvider);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('Jam Awal Hari Logis'),
                  subtitle: Text(
                      'Hari berganti pada pukul ${settings.dayStartHour}:00'),
                  trailing: DropdownButton<int>(
                    value: settings.dayStartHour,
                    underline: const SizedBox.shrink(),
                    items: [0, 3, 4, 5, 6]
                        .map((h) =>
                            DropdownMenuItem(value: h, child: Text('$h:00')))
                        .toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        await ref
                            .read(settingsRepositoryProvider)
                            .updateSettings({
                          'day_start_hour': val,
                        }, lastKnownUpdatedAt: settings.updatedAt);
                        ref.invalidate(userSettingsProvider);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Keamanan & Kunci Aplikasi (F-SEC-02)
          Text(
            'Keamanan & Kunci Aplikasi',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.pin_outlined),
                  title: const Text('Kunci PIN'),
                  subtitle: Text(
                    settings.pinEnabled
                        ? 'PIN aktif saat membuka aplikasi'
                        : 'Belum diaktifkan (disarankan)',
                  ),
                  value: settings.pinEnabled,
                  onChanged: (enabled) async {
                    if (enabled) {
                      _showSetPinDialog(context, ref, settings);
                    } else {
                      final confirmed = await ConfirmDialog.show(
                        context,
                        title: 'Matikan Kunci PIN',
                        message:
                            'Apakah Anda yakin ingin mematikan kunci PIN aplikasi?',
                        confirmLabel: 'Matikan',
                        isDestructive: true,
                      );
                      if (confirmed) {
                        final lockService = ref.read(appLockServiceProvider);
                        await lockService.removePin();
                        await ref
                            .read(settingsRepositoryProvider)
                            .updateSettings({
                          'app_lock_enabled': false,
                          'pin_enabled': false,
                          'biometric_enabled': false,
                        }, lastKnownUpdatedAt: settings.updatedAt);
                        ref.invalidate(userSettingsProvider);
                      }
                    }
                  },
                ),
                if (settings.pinEnabled) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint_rounded),
                    title: const Text('Buka Kunci Biometrik'),
                    subtitle: const Text('Gunakan sidik jari atau wajah'),
                    value: settings.biometricEnabled,
                    onChanged: (enabled) async {
                      await ref
                          .read(settingsRepositoryProvider)
                          .updateSettings({
                        'biometric_enabled': enabled,
                      }, lastKnownUpdatedAt: settings.updatedAt);
                      ref.invalidate(userSettingsProvider);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Batas Waktu Penguncian'),
                    subtitle: Text(
                        'Kunci kembali setelah ${settings.lockTimeoutMinutes} menit di latar belakang'),
                    trailing: DropdownButton<int>(
                      value: settings.lockTimeoutMinutes,
                      underline: const SizedBox.shrink(),
                      items: [1, 5, 15, 30]
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text('$m mnt')))
                          .toList(),
                      onChanged: (val) async {
                        if (val != null) {
                          await ref
                              .read(settingsRepositoryProvider)
                              .updateSettings({
                            'lock_timeout_minutes': val,
                          }, lastKnownUpdatedAt: settings.updatedAt);
                          ref.invalidate(userSettingsProvider);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: theme.colorScheme.error,
              backgroundColor:
                  theme.colorScheme.errorContainer.withValues(alpha: 0.4),
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
