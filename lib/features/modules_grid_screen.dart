import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModulesGridScreen extends StatelessWidget {
  const ModulesGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final modules = [
      {
        'title': 'Catatan & Kategori',
        'icon': Icons.note_alt_outlined,
        'route': '/notes',
        'fase': 'Fase 2 (Aktif)'
      },
      {
        'title': 'Tugas & Subtugas',
        'icon': Icons.check_circle_outline,
        'route': '/tasks',
        'fase': 'Fase 4 (Aktif)'
      },
      {
        'title': 'Proyek',
        'icon': Icons.folder_special_outlined,
        'route': '/projects',
        'fase': 'Fase 4 (Aktif)'
      },
      {
        'title': 'Inbox & Triase',
        'icon': Icons.all_inbox_rounded,
        'route': '/inbox',
        'fase': 'Fase 5 (Aktif)'
      },
      {
        'title': 'Tempat Sampah',
        'icon': Icons.delete_sweep_outlined,
        'route': '/trash',
        'fase': 'Fase 5 (Aktif)'
      },
      {
        'title': 'Pengaturan',
        'icon': Icons.settings_outlined,
        'route': '/settings',
        'fase': 'Fase 1 & 3 (Aktif)'
      },
      {
        'title': 'Kalender',
        'icon': Icons.calendar_month_outlined,
        'route': '/calendar',
        'fase': 'Fase 6 (Aktif)'
      },
      {
        'title': 'Kebiasaan & Rutinitas',
        'icon': Icons.repeat_rounded,
        'route': '/habits',
        'fase': 'Fase 7 (Aktif)'
      },
      {
        'title': 'Pengingat & Notifikasi',
        'icon': Icons.alarm_rounded,
        'route': '/reminders',
        'fase': 'Fase 8 (Aktif)'
      },
      {
        'title': 'Keuangan (Money Tracker)',
        'icon': Icons.account_balance_wallet_outlined,
        'route': null,
        'fase': 'Fase 9'
      },
      {
        'title': 'Fokus & Waktu',
        'icon': Icons.timer_outlined,
        'route': null,
        'fase': 'Fase 11'
      },
      {
        'title': 'Jurnal & Refleksi',
        'icon': Icons.auto_stories_outlined,
        'route': null,
        'fase': 'Fase 12'
      },
      {
        'title': 'Kesehatan',
        'icon': Icons.favorite_outline_rounded,
        'route': null,
        'fase': 'Fase 13'
      },
      {
        'title': 'Belajar & Media',
        'icon': Icons.school_outlined,
        'route': null,
        'fase': 'Fase 14'
      },
      {
        'title': 'Kehidupan Sehari-hari',
        'icon': Icons.shopping_bag_outlined,
        'route': null,
        'fase': 'Fase 15'
      },
      {
        'title': 'Relasi & Kontak',
        'icon': Icons.people_outline_rounded,
        'route': null,
        'fase': 'Fase 16'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Modul'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.25,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final m = modules[index];
          final isActive = m['route'] != null;

          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isActive
                  ? () => context.push(m['route'] as String)
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${m['title']} dijadwalkan pada ${m['fase']}')),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: isActive
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        m['icon'] as IconData,
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m['fase'] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
