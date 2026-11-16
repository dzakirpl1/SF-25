import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/network_connectivity_service.dart';

class OfflineBanner extends ConsumerWidget {
  final VoidCallback? onRetry;
  const OfflineBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    if (isOnline) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 20, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tidak ada koneksi internet. Data tersimpan di memori sementara.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final checker = ref.read(networkConnectivityServiceProvider);
              final online = await checker.checkConnection();
              ref.read(isOnlineProvider.notifier).state = online;
              if (online && onRetry != null) onRetry!();
            },
            child: Text(
              'Coba Lagi',
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
