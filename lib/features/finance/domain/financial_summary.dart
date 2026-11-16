class FinancialSummary {
  final BigInt totalBalance;
  final BigInt monthlyIncome;
  final BigInt monthlyExpense;

  const FinancialSummary({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });

  BigInt get netCashflow => monthlyIncome - monthlyExpense;
}
