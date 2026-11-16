import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_settings.dart';
import '../../../core/errors/app_error.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(Supabase.instance.client);
});

final userSettingsProvider = FutureProvider<UserSettings?>((ref) async {
  return ref.watch(settingsRepositoryProvider).fetchSettings();
});

class SettingsRepository {
  final SupabaseClient _client;

  SettingsRepository(this._client);

  Future<UserSettings?> fetchSettings() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return UserSettings.fromJson(data);
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> updateSettings(
    Map<String, dynamic> updates, {
    DateTime? lastKnownUpdatedAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      var query =
          _client.from('user_settings').update(updates).eq('user_id', user.id);

      if (lastKnownUpdatedAt != null) {
        query = query.lte('updated_at', lastKnownUpdatedAt.toIso8601String());
      }

      await query;
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }

  Future<void> updateDisplayName(String name,
      {DateTime? lastKnownUpdatedAt}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      var query = _client.from('profiles').update({
        'display_name': name.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);

      if (lastKnownUpdatedAt != null) {
        query = query.lte('updated_at', lastKnownUpdatedAt.toIso8601String());
      }

      await query;
    } catch (e) {
      throw AppError(AppError.mapMessage(e), originalError: e);
    }
  }
}
