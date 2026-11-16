import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final networkConnectivityServiceProvider =
    Provider<NetworkConnectivityService>((ref) {
  return NetworkConnectivityService(Supabase.instance.client);
});

final isOnlineProvider = StateProvider<bool>((ref) => true);

class NetworkConnectivityService {
  final SupabaseClient _client;

  NetworkConnectivityService(this._client);

  Future<bool> checkConnection() async {
    try {
      await _client.rpc('check_connection').timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      try {
        // Fallback check ke rest endpoint
        await _client
            .from('profiles')
            .select('id')
            .limit(1)
            .timeout(const Duration(seconds: 4));
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}
