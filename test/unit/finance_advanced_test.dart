import 'package:test/test.dart';
import 'package:personal_os/features/finance/domain/budget.dart';
import 'package:personal_os/features/finance/domain/savings_goal.dart';
import 'package:personal_os/features/finance/domain/debt.dart';

void main() {
  group('Finance Advanced Domain Tests (Fase 10)', () {
    test('Budget serialization dan perhitungan status peringatan', () {
      final now = DateTime.now().toUtc();
      final month = DateTime.utc(2026, 3, 1);
      final budget = Budget(
        id: 'b-1',
        userId: 'usr-1',
        categoryId: 'cat-makan',
        month: month,
        limitAmount: BigInt.from(1000000),
        createdAt: now,
        updatedAt: now,
        spentAmount: BigInt.from(850000),
      );

      expect(budget.progress, 0.85);
      expect(budget.isWarning, true);
      expect(budget.isExceeded, false);
      expect(budget.remainingAmount, BigInt.from(150000));
      expect(budget.overAmount, BigInt.zero);

      // Anggaran terlampaui
      final exceededBudget = budget.copyWith(
        spentAmount: BigInt.from(1200000),
      );
      expect(exceededBudget.isExceeded, true);
      expect(exceededBudget.isWarning, false);
      expect(exceededBudget.remainingAmount, BigInt.zero);
      expect(exceededBudget.overAmount, BigInt.from(200000));

      // Serialization
      final json = budget.toJson();
      expect(json['category_id'], 'cat-makan');
      expect(json['month'], '2026-03-01');
      expect(json['limit_amount'], 1000000);

      final revived = Budget.fromJson(json, computedSpent: BigInt.from(500000));
      expect(revived.id, 'b-1');
      expect(revived.limitAmount, BigInt.from(1000000));
      expect(revived.spentAmount, BigInt.from(500000));
      expect(revived.status, 'safe');
    });

    test('SavingsGoal & Contribution progres target dan status selesai', () {
      final now = DateTime.now().toUtc();
      final goal = SavingsGoal(
        id: 'goal-1',
        userId: 'usr-1',
        name: 'Dana Darurat',
        targetAmount: BigInt.from(15000000),
        targetDate: DateTime(2026, 12, 31),
        createdAt: now,
        updatedAt: now,
        currentAmount: BigInt.from(7500000),
      );

      expect(goal.progress, 0.5);
      expect(goal.isCompleted, false);
      expect(goal.remainingAmount, BigInt.from(7500000));

      // Kontribusi mencukupi target penuh
      final completedGoal = goal.copyWith(
        currentAmount: BigInt.from(15000000),
      );
      expect(completedGoal.isCompleted, true);
      expect(completedGoal.remainingAmount, BigInt.zero);
      expect(completedGoal.progress, 1.0);

      // Serialization SavingsGoal
      final json = goal.toJson();
      expect(json['name'], 'Dana Darurat');
      expect(json['target_amount'], 15000000);

      final revived =
          SavingsGoal.fromJson(json, computedCurrent: BigInt.from(3000000));
      expect(revived.id, 'goal-1');
      expect(revived.currentAmount, BigInt.from(3000000));

      // Serialization SavingsContribution
      final contrib = SavingsContribution(
        id: 'c-1',
        userId: 'usr-1',
        goalId: 'goal-1',
        amount: BigInt.from(1000000),
        contributedAt: now,
        note: 'Gaji Maret',
        createdAt: now,
        updatedAt: now,
      );
      final cJson = contrib.toJson();
      final cRevived = SavingsContribution.fromJson(cJson);
      expect(cRevived.id, 'c-1');
      expect(cRevived.amount, BigInt.from(1000000));
      expect(cRevived.note, 'Gaji Maret');
    });

    test('Debt & DebtPayment direction, kalkulasi sisa, dan status lunas', () {
      final now = DateTime.now().toUtc();
      final debt = Debt(
        id: 'd-1',
        userId: 'usr-1',
        personName: 'Rudi Hartono',
        direction: 'owed_by_me', // utang saya
        principal: BigInt.from(2000000),
        dueDate: DateTime(2026, 6, 1),
        createdAt: now,
        updatedAt: now,
        paidAmount: BigInt.from(500000),
      );

      expect(debt.isOwedByMe, true);
      expect(debt.isOwedToMe, false);
      expect(debt.isSettled, false);
      expect(debt.remainingAmount, BigInt.from(1500000));
      expect(debt.progress, 0.25);

      // Status lunas saat dibayar penuh
      final settledDebt = debt.copyWith(
        paidAmount: BigInt.from(2000000),
        settledAt: now,
      );
      expect(settledDebt.isSettled, true);
      expect(settledDebt.remainingAmount, BigInt.zero);
      expect(settledDebt.progress, 1.0);

      // Serialization Debt
      final json = debt.toJson();
      expect(json['person_name'], 'Rudi Hartono');
      expect(json['direction'], 'owed_by_me');
      expect(json['principal'], 2000000);

      final revived = Debt.fromJson(json, computedPaid: BigInt.from(500000));
      expect(revived.id, 'd-1');
      expect(revived.paidAmount, BigInt.from(500000));

      // Serialization DebtPayment
      final payment = DebtPayment(
        id: 'p-1',
        userId: 'usr-1',
        debtId: 'd-1',
        amount: BigInt.from(500000),
        paidAt: now,
        note: 'Transfer cicilan 1',
        createdAt: now,
        updatedAt: now,
      );
      final pJson = payment.toJson();
      final pRevived = DebtPayment.fromJson(pJson);
      expect(pRevived.id, 'p-1');
      expect(pRevived.amount, BigInt.from(500000));
      expect(pRevived.note, 'Transfer cicilan 1');
    });
  });
}
