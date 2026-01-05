class MonthlySummary {
  final DateTime month;
  final double income;
  final double expenses;
  final double net;
  final Map<String, double> categoryTotals;
  final double? budgetTotal;

  const MonthlySummary({
    required this.month,
    required this.income,
    required this.expenses,
    required this.net,
    required this.categoryTotals,
    required this.budgetTotal,
  });

  double get budgetRemaining {
    final b = budgetTotal;
    if (b == null) return 0.0;
    return b - expenses;
  }

  double get budgetUtilization {
    final b = budgetTotal;
    if (b == null || b <= 0) return 0.0;
    return expenses / b;
  }
}
