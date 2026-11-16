import 'package:flutter/material.dart';

class MarkdownView extends StatelessWidget {
  final String content;

  const MarkdownView({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();

        // Header 1
        if (trimmed.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              trimmed.substring(2),
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        }

        // Header 2
        if (trimmed.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Text(
              trimmed.substring(3),
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        }

        // Header 3
        if (trimmed.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              trimmed.substring(4),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        }

        // Checklist [ ] atau [x]
        if (trimmed.startsWith('- [ ] ') ||
            trimmed.startsWith('- [x] ') ||
            trimmed.startsWith('- [X] ')) {
          final isChecked =
              trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] ');
          final label = trimmed.substring(6);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Icon(
                  isChecked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 20,
                  color: isChecked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? theme.colorScheme.outline : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Bullet point
        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Expanded(
                  child: Text(trimmed.substring(2),
                      style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          );
        }

        // Quote
        if (trimmed.startsWith('> ')) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                  left: BorderSide(color: theme.colorScheme.primary, width: 3)),
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
            ),
            child: Text(
              trimmed.substring(2),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          );
        }

        // Standard text
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            line,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        );
      }).toList(),
    );
  }
}
