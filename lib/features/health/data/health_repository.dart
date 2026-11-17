import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error.dart';
import '../domain/medication.dart';
import '../domain/sleep_log.dart';
import '../domain/water_log.dart';
import '../domain/workout.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(Supabase.instance.client);
});

class HealthRepository {
  final SupabaseClient _client;

  HealthRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  // WORKOUTS
  Future<List<Workout>> fetchWorkouts({int limit = 50}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('workouts')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('started_at', ascending: false)
          .limit(limit);

      return (data as List).map((j) => Workout.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<Workout> createWorkout(Workout workout) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = workout.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('workouts').insert(payload).select().single();
      return Workout.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<void> deleteWorkout(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('workouts')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  // SLEEP LOGS
  Future<List<SleepLog>> fetchSleepLogs({int limit = 30}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('sleep_logs')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('wake_at', ascending: false)
          .limit(limit);

      return (data as List).map((j) => SleepLog.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<SleepLog> createSleepLog(SleepLog sleep) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = sleep.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('sleep_logs').insert(payload).select().single();
      return SleepLog.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  // WATER LOGS
  Future<List<WaterLog>> fetchWaterLogs({int limit = 50}) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('water_logs')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('logged_at', ascending: false)
          .limit(limit);

      return (data as List).map((j) => WaterLog.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<WaterLog> addWaterLog(int amountMl) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc();
      final res = await _client
          .from('water_logs')
          .insert({
            'user_id': userId,
            'amount_ml': amountMl,
            'logged_at': now.toIso8601String(),
          })
          .select()
          .single();
      return WaterLog.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  // MEDICATIONS
  Future<List<Medication>> fetchMedications() async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final data = await _client
          .from('medications')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return (data as List).map((j) => Medication.fromJson(j)).toList();
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<Medication> createMedication(Medication med) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = med.toJson();
      payload.remove('id');
      payload['user_id'] = userId;

      final res =
          await _client.from('medications').insert(payload).select().single();
      return Medication.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<Medication> updateMedication(Medication med) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final payload = med.toJson();
      payload['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final res = await _client
          .from('medications')
          .update(payload)
          .eq('id', med.id)
          .eq('user_id', userId)
          .select()
          .single();
      return Medication.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<void> deleteMedication(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('medications')
          .update({'deleted_at': now, 'updated_at': now})
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }

  Future<MedicationLog> logMedicationTaken(String medId) async {
    final userId = _currentUserId;
    if (userId == null) throw const AppError('Sesi pengguna tidak valid');

    try {
      final now = DateTime.now().toUtc();
      final res = await _client
          .from('medication_logs')
          .insert({
            'user_id': userId,
            'medication_id': medId,
            'scheduled_at': now.toIso8601String(),
            'taken_at': now.toIso8601String(),
            'status': 'taken',
          })
          .select()
          .single();
      return MedicationLog.fromJson(res);
    } on PostgrestException catch (e) {
      throw AppError.fromPostgres(e);
    } catch (e) {
      throw AppError(e.toString());
    }
  }
}
