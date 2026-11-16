import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../errors/app_error.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(Supabase.instance.client);
});

class NotificationService {
  final SupabaseClient _client;

  NotificationService(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Mendaftarkan token perangkat (FCM / Push Token).
  /// Sesuai instruksi: Jika token belum tersedia atau diberikan nanti,
  /// fungsi ini dapat dipanggil dengan token khusus atau placeholder.
  Future<bool> registerDeviceToken({
    required String fcmToken,
    String platform = 'android',
  }) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': fcmToken.trim(),
          'platform': platform,
          'last_seen_at': now,
          'updated_at': now,
        },
        onConflict: 'user_id, fcm_token',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Menjadwalkan pengingat di database dan sistem notifikasi
  Future<void> scheduleReminder({
    required String title,
    String? body,
    required DateTime remindAt,
    String targetType = 'custom',
    String? targetId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Pengguna tidak terautentikasi');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('reminders').insert({
        'user_id': userId,
        'title': title.trim(),
        'body': body?.trim(),
        'target_type': targetType,
        'target_id': targetId,
        'remind_at': remindAt.toUtc().toIso8601String(),
        'status': 'scheduled',
        'created_at': now,
        'updated_at': now,
      });
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Menunda pengingat (snooze) selama [minutes] menit (default: 10 menit)
  Future<void> snoozeReminder(String reminderId, {int minutes = 10}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Pengguna tidak terautentikasi');

    final snoozeTime =
        DateTime.now().toUtc().add(Duration(minutes: minutes)).toIso8601String();

    try {
      await _client.from('reminders').update({
        'status': 'snoozed',
        'snoozed_until': snoozeTime,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', reminderId).eq('user_id', userId);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  /// Menandai pengingat selesai atau diabaikan (dismissed)
  Future<void> dismissReminder(String reminderId) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Pengguna tidak terautentikasi');

    try {
      await _client.from('reminders').update({
        'status': 'dismissed',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', reminderId).eq('user_id', userId);
    } catch (e) {
      throw AppError(e.toString());
    }
  }
}
