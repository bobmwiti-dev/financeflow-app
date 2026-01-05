import 'package:flutter_test/flutter_test.dart';

import 'package:financeflow_app/models/budget_model.dart';
import 'package:financeflow_app/models/income_source_model.dart';
import 'package:financeflow_app/models/transaction_model.dart' as app_models;
import 'package:financeflow_app/services/monthly_summary_service.dart';

void main() {
  group('MonthlySummaryService.getSummary', () {
    test('aggregates income/expenses/category totals for the requested month only', () {
      final month = DateTime(2025, 3, 15);

      final incomeSources = <IncomeSource>[
        IncomeSource(
          id: 'i1',
          name: 'Salary',
          type: 'Salary',
          amount: 1000,
          date: DateTime(2025, 3, 1),
          accountId: 'a1',
        ),
        IncomeSource(
          id: 'i2',
          name: 'Bonus',
          type: 'Bonus',
          amount: 200,
          date: DateTime(2025, 4, 1),
          accountId: 'a1',
        ),
      ];

      final transactions = <app_models.Transaction>[
        app_models.TransactionModel(
          id: 't1',
          title: 'Groceries',
          amount: -50,
          date: DateTime(2025, 3, 10),
          category: 'Food',
          type: app_models.TransactionType.expense,
          accountId: 'a1',
          userId: 'u1',
        ),
        app_models.TransactionModel(
          id: 't2',
          title: 'Transport',
          amount: -30,
          date: DateTime(2025, 3, 11),
          category: 'Transport',
          type: app_models.TransactionType.expense,
          accountId: 'a1',
          userId: 'u1',
        ),
        app_models.TransactionModel(
          id: 't3',
          title: 'Groceries 2',
          amount: -20,
          date: DateTime(2025, 2, 28),
          category: 'Food',
          type: app_models.TransactionType.expense,
          accountId: 'a1',
          userId: 'u1',
        ),
      ];

      final budgets = <Budget>[
        Budget(
          id: 'b1',
          category: 'Food',
          amount: 500,
          startDate: DateTime(2025, 3, 1),
          endDate: DateTime(2025, 3, 31),
        ),
      ];

      final summary = MonthlySummaryService.getSummary(
        month: month,
        incomeSources: incomeSources,
        transactions: transactions,
        budgets: budgets,
      );

      expect(summary.month, DateTime(2025, 3, 1));
      expect(summary.income, 1000);
      expect(summary.expenses, 80);
      expect(summary.net, 920);
      expect(summary.categoryTotals['Food'], 50);
      expect(summary.categoryTotals['Transport'], 30);
      expect(summary.budgetTotal, 500);
    });

    test('handles negative and positive expense transaction amounts equivalently via abs()', () {
      final month = DateTime(2025, 3, 1);

      final incomeSources = <IncomeSource>[];

      final transactions = <app_models.Transaction>[
        app_models.TransactionModel(
          id: 't1',
          title: 'Expense negative',
          amount: -100,
          date: DateTime(2025, 3, 2),
          category: 'Bills',
          type: app_models.TransactionType.expense,
          accountId: 'a1',
          userId: 'u1',
        ),
        app_models.TransactionModel(
          id: 't2',
          title: 'Expense positive',
          amount: 40,
          date: DateTime(2025, 3, 3),
          category: 'Bills',
          type: app_models.TransactionType.expense,
          accountId: 'a1',
          userId: 'u1',
        ),
      ];

      final summary = MonthlySummaryService.getSummary(
        month: month,
        incomeSources: incomeSources,
        transactions: transactions,
        budgets: const [],
      );

      expect(summary.expenses, 140);
      expect(summary.categoryTotals['Bills'], 140);
    });

    test('budgetTotal is null when there are no overlapping budgets', () {
      final month = DateTime(2025, 3, 1);

      final summary = MonthlySummaryService.getSummary(
        month: month,
        incomeSources: const [],
        transactions: const [],
        budgets: [
          Budget(
            id: 'b1',
            category: 'Food',
            amount: 100,
            startDate: DateTime(2025, 4, 1),
            endDate: DateTime(2025, 4, 30),
          ),
        ],
      );

      expect(summary.budgetTotal, isNull);
      expect(summary.expenses, 0);
      expect(summary.income, 0);
      expect(summary.net, 0);
    });
  });
}
