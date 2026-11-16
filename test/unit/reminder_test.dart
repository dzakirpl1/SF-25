import 'package:test/test.dart';
import 'package:personal_os/features/reminders/domain/reminder.dart';

void main() {
  group('Reminder Domain Model Tests (Fase 8)', () {
    test('Reminder JSON Serialization bolak-balik valid', () {
      final now = DateTime.now().toUtc();
      final reminder = Reminder(
        id: 'rem-101',
        userId: 'usr-1',
        title: 'Minum Obat Maag',
        body: '30 menit sebelum makan',
        targetType: 'medicine',
        targetId: 'med-55',
        remindAt: now.add(const Duration(hours: 2)),
        status: 'scheduled',
        createdAt: now,
        updatedAt: now,
      );

      final json = reminder.toJson();
      final revived = Reminder.fromJson(json);

      expect(revived.id, reminder.id);
      expect(revived.userId, reminder.userId);
      expect(revived.title, reminder.title);
      expect(revived.targetType, 'medicine');
      expect(revived.isScheduled, true);
      expect(revived.isSnoozed, false);
      expect(revived.isDismissed, false);
    });

    test('Reminder status getters mendeteksi status dengan benar', () {
      final now = DateTime.now().toUtc();
      final r1 = Reminder(
        id: 'r1',
        userId: 'u',
        title: 'T1',
        remindAt: now,
        status: 'snoozed',
        snoozedUntil: now.add(const Duration(minutes: 10)),
        createdAt: now,
        updatedAt: now,
      );

      expect(r1.isSnoozed, true);
      expect(r1.isScheduled, false);

      final r2 = Reminder(
        id: 'r2',
        userId: 'u',
        title: 'T2',
        remindAt: now,
        status: 'dismissed',
        createdAt: now,
        updatedAt: now,
      );

      expect(r2.isDismissed, true);
    });
  });
}
