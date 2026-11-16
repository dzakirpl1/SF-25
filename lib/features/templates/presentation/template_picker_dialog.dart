import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'template_controller.dart';

class TemplatePickerDialog extends ConsumerWidget {
  final Function(String title, String content) onTemplateSelected;

  const TemplatePickerDialog({super.key, required this.onTemplateSelected});

  static Future<void> show(
      BuildContext context, Function(String title, String content) onSelected) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TemplatePickerDialog(onTemplateSelected: onSelected),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templateListProvider('note'));
    final theme = Theme.of(context);

    // Template default bawaan jika database belum memiliki template
    final builtInTemplates = [
      {
        'name': 'Catatan Rapat / Diskusi',
        'title': 'Rapat: [Topik]',
        'content':
            '### Agenda\n- [ ] Pembahasan A\n- [ ] Pembahasan B\n\n### Keputusan\n1. \n2. \n\n### Tindak Lanjut\n- [ ] Tugas 1 (PIC)\n- [ ] Tugas 2 (PIC)',
      },
      {
        'name': 'Jurnal Refleksi Harian',
        'title': 'Refleksi: [Tanggal]',
        'content':
            '### Hal yang Disyukuri Hari Ini\n1. \n2. \n3. \n\n### Pencapaian & Pembelajaran\n- \n\n### Rencana Perbaikan Besok\n- ',
      },
      {
        'name': 'Rencana Proyek / Fitur',
        'title': 'Rencana: [Nama Fitur]',
        'content':
            '### Masalah / Kebutuhan\n> \n\n### Solusi Teknis\n- \n\n### Kriteria Selesai\n- [ ] Kriteria 1\n- [ ] Kriteria 2',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_customize_outlined,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Pilih Template Catatan',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tampilkan built-in templates
          Text('Template Standar',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 8),
          ...builtInTemplates.map((t) => ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.description_outlined),
                title: Text(t['name']!),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(context);
                  onTemplateSelected(t['title']!, t['content']!);
                },
              )),

          // Tampilkan template kustom dari database jika ada
          templatesAsync.maybeWhen(
            data: (customTemplates) {
              if (customTemplates.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 24),
                  Text('Template Kustom Anda',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 8),
                  ...customTemplates.map((t) => ListTile(
                        leading: const Icon(Icons.star_outline_rounded),
                        title: Text(t.name),
                        onTap: () {
                          Navigator.pop(context);
                          final title = t.payload['title'] as String? ?? t.name;
                          final content = t.payload['content'] as String? ?? '';
                          onTemplateSelected(title, content);
                        },
                      )),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
