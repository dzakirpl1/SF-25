import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/goal.dart';
import '../domain/journal_entry.dart';
import '../domain/mood_log.dart';
import '../domain/periodic_review.dart';

final reflectionRepositoryProvider = Provider<ReflectionRepository>((ref) {
  return ReflectionRepository(Supabase.instance.client);
});

class ReflectionRepository {
  final SupabaseClient _client;

  ReflectionRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  // ===========================================================================
  // JURNAL HARIAN
  // ===========================================================================

  Future<List<JournalEntry>> fetchJournalEntries({int limit = 50}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('entry_date', ascending: false)
          .limit(limit);

      return (data as List).map((j) => JournalEntry.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<JournalEntry?> fetchJournalEntryByDate(DateTime date) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final data = await _client
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .eq('entry_date', dateStr)
          .filter('deleted_at', 'is', null)
          .maybeSingle();

      if (data == null) return null;
      return JournalEntry.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<JournalEntry> upsertJournalEntry(JournalEntry entry) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = entry.toJson();
      if (entry.id.isEmpty) payload.remove('id');
      payload['user_id'] = userId;

      final res = await _client
          .from('journal_entries')
          .upsert(payload, onConflict: 'user_id, entry_date')
          .select()
          .single();
      return JournalEntry.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<void> deleteJournalEntry(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('journal_entries')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  // ===========================================================================
  // MOOD TRACKER
  // ===========================================================================

  Future<List<MoodLog>> fetchMoodLogs({int limit = 60}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('mood_logs')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('log_date', ascending: false)
          .limit(limit);

      return (data as List).map((j) => MoodLog.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<MoodLog> upsertMoodLog(MoodLog mood) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = mood.toJson();
      if (mood.id.isEmpty) payload.remove('id');
      payload['user_id'] = userId;

      final res = await _client
          .from('mood_logs')
          .upsert(payload, onConflict: 'user_id, log_date')
          .select()
          .single();
      return MoodLog.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  // ===========================================================================
  // REVIEWS
  // ===========================================================================

  Future<List<PeriodicReview>> fetchReviews() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('period_start', ascending: false);

      return (data as List).map((j) => PeriodicReview.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<PeriodicReview> upsertReview(PeriodicReview review) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = review.toJson();
      if (review.id.isEmpty) payload.remove('id');
      payload['user_id'] = userId;

      final res = await _client
          .from('reviews')
          .upsert(payload, onConflict: 'user_id, period, period_start')
          .select()
          .single();
      return PeriodicReview.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  // ===========================================================================
  // GOALS & KEY RESULTS
  // ===========================================================================

  Future<List<Goal>> fetchGoals() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('goals')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return (data as List).map((j) => Goal.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<List<KeyResult>> fetchAllKeyResults() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('key_results')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: true);

      return (data as List).map((j) => KeyResult.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<Goal> createGoal(Goal goal) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = goal.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res = await _client.from('goals').insert(payload).select().single();
      return Goal.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<Goal> updateGoal(Goal goal) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = goal.toJson();
      payload['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final res = await _client
          .from('goals')
          .update(payload)
          .eq('id', goal.id)
          .eq('user_id', userId)
          .select()
          .single();
      return Goal.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<void> deleteGoal(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('goals')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<KeyResult> upsertKeyResult(KeyResult kr) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = kr.toJson();
      if (kr.id.isEmpty) payload.remove('id');
      payload['user_id'] = userId;

      final res = await _client
          .from('key_results')
          .upsert(payload, onConflict: 'id')
          .select()
          .single();
      return KeyResult.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<void> deleteKeyResult(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('key_results')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }
}
