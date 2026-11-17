import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/journal_entry.dart';
import 'reflection_controller.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  DateTime _selectedDate = DateTime.now();
  final _contentController = TextEditingController();
  String? _selectedPrompt;

  final List<String> _prompts = [
    'Apa 3 hal yang paling Anda syukuri hari ini?',
    'Pencapaian kecil apa yang membuat Anda bangga hari ini?',
    'Pelajaran berharga apa yang Anda petik dari tantangan hari ini?',
    'Bagaimana Anda merawat energi dan ketenangan pikiran Anda hari ini?',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _loadEntryForDate(List<JournalEntry> entries) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final match = entries.where((e) {
      return DateFormat('yyyy-MM-dd').format(e.entryDate) == dateStr;
    }).firstOrNull;

    if (match != null) {
      _contentController.text = match.content;
      _selectedPrompt = match.prompt;
    } else {
      _contentController.clear();
      _selectedPrompt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final journalAsync = ref.watch(journalEntriesProvider);
    final onThisDayAsync = ref.watch(onThisDayJournalProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal & Refleksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: 'Pilih Tanggal',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
        ],
      ),
      body: journalAsync.when(
        loading: () => const LoadingView(message: 'Memuat jurnal...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(journalEntriesProvider),
        ),
        data: (entries) {
          final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Kartu Kilas Balik 1 Tahun Lalu (Jika Ada)
              onThisDayAsync.when(
                data: (onThisDay) {
                  if (onThisDay == null) return const SizedBox.shrink();
                  return Card(
                    elevation: 0,
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history_edu_rounded,
                                  color: Colors.amber, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Kilas Balik: 1 Tahun Lalu Hari Ini',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            onThisDay.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),

              // 2. Header Tanggal Jurnal yang Sedang Ditulis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isToday
                        ? 'Jurnal Hari Ini'
                        : DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                            .format(_selectedDate),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (!isToday)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedDate = DateTime.now());
                        _loadEntryForDate(entries);
                      },
                      child: const Text('Ke Hari Ini'),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Pilihan Prompt Inspirasi Refleksi
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _prompts.map((p) {
                    final isSelected = _selectedPrompt == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(p, style: const TextStyle(fontSize: 12)),
                        onSelected: (val) {
                          setState(() {
                            _selectedPrompt = val ? p : null;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Input Konten Jurnal
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_selectedPrompt != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedPrompt!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _contentController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText:
                              'Tuliskan pikiran, perasaan, dan refleksi Anda di sini...',
                          border: InputBorder.none,
                        ),
                      ),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final content = _contentController.text.trim();
                            if (content.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Tulis isi jurnal terlebih dahulu')),
                              );
                              return;
                            }

                            final now = DateTime.now().toUtc();
                            final entry = JournalEntry(
                              id: '',
                              userId: '',
                              entryDate: _selectedDate,
                              prompt: _selectedPrompt,
                              content: content,
                              createdAt: now,
                              updatedAt: now,
                            );

                            await ref
                                .read(reflectionActionsProvider.notifier)
                                .saveJournal(entry);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Jurnal berhasil disimpan!')),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Simpan Jurnal'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Riwayat Entri Jurnal Sebelumnya
              Text(
                'Entri Sebelumnya',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (entries.isEmpty)
                const EmptyView(
                  icon: Icons.auto_stories_outlined,
                  title: 'Belum Ada Jurnal',
                  subtitle:
                      'Tulis refleksi harian Anda untuk merawat kesehatan mental dan kesadaran diri.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            DateFormat('d').format(e.entryDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                              .format(e.entryDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          e.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedDate = e.entryDate;
                            _contentController.text = e.content;
                            _selectedPrompt = e.prompt;
                          });
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.grey),
                          onPressed: () async {
                            final confirmed = await ConfirmDialog.show(
                              context,
                              title: 'Hapus Jurnal',
                              message:
                                  'Apakah Anda yakin ingin menghapus jurnal tanggal ini?',
                              confirmLabel: 'Hapus',
                              isDestructive: true,
                            );
                            if (confirmed) {
                              await ref
                                  .read(reflectionActionsProvider.notifier)
                                  .deleteJournal(e.id);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
