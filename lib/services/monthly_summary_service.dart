import '../models/budget_model.dart';
import '../models/income_source_model.dart';
import '../models/monthly_summary.dart';
import '../models/transaction_model.dart' as app_models;

class MonthlySummaryService {
  static MonthlySummary getSummary({
    required DateTime month,
    required List<IncomeSource> incomeSources,
    required List<app_models.Transaction> transactions,
    required List<Budget> budgets,
  }) {
    final normalizedMonth = DateTime(month.year, month.month, 1);
    final startDate = DateTime(normalizedMonth.year, normalizedMonth.month, 1);
    final endDate =
        DateTime(normalizedMonth.year, normalizedMonth.month + 1, 0, 23, 59, 59);

    final income = incomeSources
        .where((i) => !i.date.isBefore(startDate) && !i.date.isAfter(endDate))
        .fold<double>(0.0, (sum, i) => sum + i.amount);

    final Map<String, double> categoryTotals = {};
    double expenses = 0.0;

    for (final t in transactions) {
      if (t.date.isBefore(startDate) || t.date.isAfter(endDate)) continue;
      if (!t.isExpense && !t.type.toString().contains('expense')) continue;

      final amount = t.amount.abs();
      expenses += amount;

      final category = t.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
    }

    final monthBudgets = budgets.where((b) {
      return b.startDate.isBefore(endDate.add(const Duration(days: 1))) &&
          b.endDate.isAfter(startDate.subtract(const Duration(days: 1)));
    });

    final budgetTotal = monthBudgets.fold<double>(0.0, (sum, b) => sum + b.amount);

    return MonthlySummary(
      month: normalizedMonth,
      income: income,
      expenses: expenses,
      net: income - expenses,
      categoryTotals: categoryTotals,
      budgetTotal: budgetTotal > 0 ? budgetTotal : null,
    );
  }
}
