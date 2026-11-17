import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../domain/mood_log.dart';
import 'reflection_controller.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  int _selectedScore = 4;
  final List<String> _selectedTags = [];
  final _noteController = TextEditingController();

  final List<String> _availableTags = [
    'Senang',
    'Bersyukur',
    'Produktif',
    'Tenang',
    'Bersemangat',
    'Lelah',
    'Cemas',
    'Stres',
    'Kecewa',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moodLogsAsync = ref.watch(moodLogsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
      ),
      body: moodLogsAsync.when(
        loading: () => const LoadingView(message: 'Memuat data mood...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(moodLogsProvider),
        ),
        data: (logs) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Kartu Pencatatan Mood Hari Ini
              Card(
                elevation: 0,
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Bagaimana Perasaan Anda Hari Ini?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pilihan Emoji Skor 1-5
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMoodOption(1, '😢', 'Buruk'),
                          _buildMoodOption(2, '🙁', 'Kurang'),
                          _buildMoodOption(3, '😐', 'Biasa'),
                          _buildMoodOption(4, '🙂', 'Baik'),
                          _buildMoodOption(5, '😄', 'Hebat'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Pemilihan Tag Emosi
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Faktor yang Memengaruhi:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _availableTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return FilterChip(
                            label:
                                Text(tag, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedTags.add(tag);
                                } else {
                                  _selectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Catatan Singkat
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          hintText:
                              'Catatan tambahan tentang perasaan hari ini...',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final now = DateTime.now().toUtc();
                            final log = MoodLog(
                              id: '',
                              userId: '',
                              logDate: DateTime.now(),
                              score: _selectedScore,
                              tags: List.from(_selectedTags),
                              note: _noteController.text.trim().isEmpty
                                  ? null
                                  : _noteController.text.trim(),
                              createdAt: now,
                              updatedAt: now,
                            );

                            await ref
                                .read(reflectionActionsProvider.notifier)
                                .logMood(log);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Mood hari ini berhasil dicatat!')),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Simpan Mood'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Riwayat Mood Terkini
              Text(
                'Riwayat Mood Terakhir',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (logs.isEmpty)
                const EmptyView(
                  icon: Icons.mood_rounded,
                  title: 'Belum Ada Log Mood',
                  subtitle:
                      'Catat mood harian Anda secara rutin untuk memahami pola emosi Anda.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = logs[index];

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: Text(
                          item.moodEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        title: Text(
                          item.moodLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                                  .format(item.logDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (item.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  item.tags.join(', '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (item.note != null && item.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  item.note!,
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
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

  Widget _buildMoodOption(int score, String emoji, String label) {
    final isSelected = _selectedScore == score;
    return GestureDetector(
      onTap: () => setState(() => _selectedScore = score),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
