import 'package:test/test.dart';
import 'package:personal_os/core/utils/currency_utils.dart';
import 'package:personal_os/features/finance/domain/wallet.dart';
import 'package:personal_os/features/finance/domain/fin_category.dart';
import 'package:personal_os/features/finance/domain/transaction.dart';
import 'package:personal_os/features/finance/domain/financial_summary.dart';

void main() {
  group('Finance Core Model Tests (Fase 9)', () {
    test('Wallet serialization dan initial balance BigInt valid', () {
      final now = DateTime.now().toUtc();
      final wallet = Wallet(
        id: 'w-1',
        userId: 'usr-1',
        name: 'Rekening Bank BCA',
        type: 'bank',
        initialBalance: BigInt.from(5000000),
        color: '#1976D2',
        currentBalance: BigInt.from(5500000),
        createdAt: now,
        updatedAt: now,
      );

      final json = wallet.toJson();
      expect(json['initial_balance'], 5000000);

      final revived = Wallet.fromJson(json);
      expect(revived.id, 'w-1');
      expect(revived.name, 'Rekening Bank BCA');
      expect(revived.type, 'bank');
      expect(revived.initialBalance, BigInt.from(5000000));
      expect(revived.currentBalance,
          BigInt.from(5000000)); // saat parse json murni
    });

    test('FinCategory serialization valid', () {
      final now = DateTime.now().toUtc();
      final cat = FinCategory(
        id: 'cat-makan',
        userId: 'usr-1',
        name: 'Makanan & Minuman',
        kind: 'expense',
        icon: 'restaurant',
        color: '#E53935',
        createdAt: now,
        updatedAt: now,
      );

      final json = cat.toJson();
      final revived = FinCategory.fromJson(json);

      expect(revived.id, 'cat-makan');
      expect(revived.kind, 'expense');
      expect(revived.isExpense, true);
      expect(revived.isIncome, false);
    });

    test('TransactionItem serialization dan properti tipe mutasi', () {
      final now = DateTime.now().toUtc();
      final txIncome = TransactionItem(
        id: 'tx-1',
        userId: 'usr-1',
        walletId: 'w-1',
        type: 'income',
        amount: BigInt.from(12000000),
        occurredAt: now,
        note: 'Gaji Bulanan',
        createdAt: now,
        updatedAt: now,
      );

      expect(txIncome.isIncome, true);
      expect(txIncome.isExpense, false);
      expect(txIncome.isTransfer, false);

      final txTransfer = TransactionItem(
        id: 'tx-2',
        userId: 'usr-1',
        walletId: 'w-1',
        toWalletId: 'w-2',
        type: 'transfer',
        amount: BigInt.from(500000),
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(txTransfer.isTransfer, true);
      expect(txTransfer.toWalletId, 'w-2');

      final json = txTransfer.toJson();
      expect(json['to_wallet_id'], 'w-2');
      expect(json['amount'], 500000);

      final revived = TransactionItem.fromJson(json);
      expect(revived.id, 'tx-2');
      expect(revived.amount, BigInt.from(500000));
    });

    test('CurrencyUtils formatting dan parsing rupiah dengan BigInt', () {
      final parsed = CurrencyUtils.parseNominal('Rp 2.500.000');
      expect(parsed, BigInt.from(2500000));

      final parsedZero = CurrencyUtils.parseNominal('abc');
      expect(parsedZero, BigInt.zero);

      final formattedBigInt = CurrencyUtils.formatRupiah(BigInt.from(1500000));
      expect(formattedBigInt, contains('1.500.000'));
      expect(formattedBigInt, contains('Rp'));

      final formattedNum = CurrencyUtils.formatRupiah(75000);
      expect(formattedNum, contains('75.000'));
    });

    test('FinancialSummary menghitung saldo bersih dan mutasi dengan benar',
        () {
      final summary = FinancialSummary(
        totalBalance: BigInt.from(10000000),
        monthlyIncome: BigInt.from(6000000),
        monthlyExpense: BigInt.from(4000000),
      );

      expect(summary.netCashflow, BigInt.from(2000000));
      expect(summary.totalBalance, BigInt.from(10000000));
      expect(summary.monthlyIncome, BigInt.from(6000000));
      expect(summary.monthlyExpense, BigInt.from(4000000));
    });
  });
}
