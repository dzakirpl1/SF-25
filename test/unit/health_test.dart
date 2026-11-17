import 'package:test/test.dart';
import 'package:personal_os/features/health/domain/workout.dart';
import 'package:personal_os/features/health/domain/sleep_log.dart';
import 'package:personal_os/features/health/domain/water_log.dart';
import 'package:personal_os/features/health/domain/medication.dart';
import 'package:personal_os/features/health/domain/health_summary.dart';

void main() {
  group('Health & Wellness Domain Tests (Fase 13)', () {
    test('Workout model serialization dan durasi valid', () {
      final now = DateTime.now().toUtc();
      final workout = Workout(
        id: 'w-1',
        userId: 'usr-1',
        type: 'Lari Pagi',
        startedAt: now,
        durationMinutes: 45,
        caloriesBurned: 350,
        note: 'Keliling komplek',
        createdAt: now,
        updatedAt: now,
      );

      final json = workout.toJson();
      expect(json['type'], 'Lari Pagi');
      expect(json['duration_minutes'], 45);
      expect(json['calories_burned'], 350);

      final revived = Workout.fromJson(json);
      expect(revived.id, 'w-1');
      expect(revived.durationMinutes, 45);
    });

    test('SleepLog durasi dan qualityLabel tepat', () {
      final now = DateTime.now().toUtc();
      final sleepTime = now.subtract(const Duration(hours: 7, minutes: 30));
      final sleep = SleepLog(
        id: 'sl-1',
        userId: 'usr-1',
        sleepAt: sleepTime,
        wakeAt: now,
        quality: 5,
        note: 'Tidur nyenyak tanpa terbangun',
        createdAt: now,
        updatedAt: now,
      );

      expect(sleep.duration.inMinutes, 450); // 7.5 jam = 450 menit
      expect(sleep.formattedDuration, '7j 30m');
      expect(sleep.qualityLabel, 'Sangat Nyenyak');

      final json = sleep.toJson();
      expect(json['quality'], 5);

      final revived = SleepLog.fromJson(json);
      expect(revived.formattedDuration, '7j 30m');
    });

    test('WaterLog dan HealthSummary progress air minum', () {
      final now = DateTime.now().toUtc();
      final water = WaterLog(
        id: 'wl-1',
        userId: 'usr-1',
        loggedAt: now,
        amountMl: 500,
        createdAt: now,
        updatedAt: now,
      );

      final json = water.toJson();
      expect(json['amount_ml'], 500);

      const summaryNotMet = HealthSummary(
        todayWaterMl: 1500,
        targetWaterMl: 2000,
      );
      expect(summaryNotMet.waterProgress, 0.75);
      expect(summaryNotMet.isWaterTargetMet, false);

      const summaryMet = HealthSummary(
        todayWaterMl: 2200,
        targetWaterMl: 2000,
      );
      expect(summaryMet.waterProgress, 1.0); // max 1.0
      expect(summaryMet.isWaterTargetMet, true);
    });

    test('Medication & MedicationLog serialization dan kepatuhan', () {
      final now = DateTime.now().toUtc();
      final med = Medication(
        id: 'med-1',
        userId: 'usr-1',
        name: 'Vitamin D3',
        dosage: '1000 IU',
        schedule: const ['08:00'],
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = med.toJson();
      expect(json['name'], 'Vitamin D3');
      expect(json['dosage'], '1000 IU');
      expect(json['schedule'], contains('08:00'));

      final revived = Medication.fromJson(json);
      expect(revived.name, 'Vitamin D3');
      expect(revived.active, true);

      final log = MedicationLog(
        id: 'mlog-1',
        userId: 'usr-1',
        medicationId: 'med-1',
        scheduledAt: now,
        takenAt: now,
        status: 'taken',
        createdAt: now,
        updatedAt: now,
      );

      expect(log.isTaken, true);
      final logJson = log.toJson();
      expect(logJson['status'], 'taken');
    });
  });
}
