import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/budget_viewmodel.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart' as fixed;
import '../../../models/budget_model.dart';
import '../../../models/transaction_model.dart';

/// Budget Alert card showing budget status with warnings for overspending
/// and progress indicators for active budgets
class BudgetAlertCard extends StatelessWidget {
  final DateTime? selectedMonth;
  
  const BudgetAlertCard({super.key, this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BudgetViewModel, fixed.TransactionViewModel>(
      builder: (context, budgetViewModel, transactionViewModel, child) {
        final budgets = budgetViewModel.budgets;
        final transactions = transactionViewModel.transactions;
        
        if (budgets.isEmpty) {
          return _buildEmptyState(context);
        }

        // Calculate spending for each budget
        final budgetAlerts = _calculateBudgetAlerts(budgets, transactions, selectedMonth);
        
        // Show budgets with alerts, near limits, or significant progress
        final alertBudgets = budgetAlerts
            .where((alert) => alert.isOverBudget || alert.isNearLimit || alert.progressPercentage >= 60)
            .take(4)
            .toList();

        if (alertBudgets.isEmpty) {
          return _buildNoAlertsState(context);
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                ...alertBudgets.map((alert) => _buildBudgetAlert(context, alert)),
                if (budgetAlerts.length > 4)
                  _buildViewAllButton(context),
                const SizedBox(height: 8),
                _buildBudgetSummary(context, budgetAlerts),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.warning_amber,
            color: Colors.amber.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Budget Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/budgets'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'View All',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetAlert(BuildContext context, BudgetAlert alert) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final isOverBudget = alert.isOverBudget;
    final isNearLimit = alert.isNearLimit;
    
    Color alertColor;
    IconData alertIcon;
    String alertTitle;
    
    if (isOverBudget) {
      alertColor = Colors.red;
      alertIcon = Icons.error;
      alertTitle = 'Over Budget: ${alert.budget.category}';
    } else if (isNearLimit) {
      alertColor = Colors.orange;
      alertIcon = Icons.warning;
      alertTitle = 'Near Limit: ${alert.budget.category}';
    } else {
      alertColor = Colors.green;
      alertIcon = Icons.info;
      alertTitle = 'On Track: ${alert.budget.category}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColor.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(alertIcon, color: alertColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alertTitle,
                  style: TextStyle(
                    color: alertColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${alert.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: alertColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${currency.format(alert.spent)}',
                style: TextStyle(
                  color: alertColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Budget: ${currency.format(alert.budget.amount)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (alert.remainingAmount > 0)
            Text(
              'Remaining: ${currency.format(alert.remainingAmount)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (alert.progressPercentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(alertColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No budgets created yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/budgets'),
                    child: const Text('Create Budget'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAlertsState(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.green.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'All budgets on track!',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Great job staying within your budget limits',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, '/budgets'),
        child: const Text('View All Budgets'),
      ),
    );
  }

  List<BudgetAlert> _calculateBudgetAlerts(List<Budget> budgets, List<Transaction> transactions, DateTime? selectedMonth) {
    final targetMonth = selectedMonth ?? DateTime.now();
    
    return budgets.map((budget) {
      // Calculate spending for this budget category in selected month
      final categorySpending = transactions
          .where((transaction) => 
              transaction.category.toLowerCase() == budget.category.toLowerCase() &&
              transaction.type == TransactionType.expense &&
              transaction.date.year == targetMonth.year &&
              transaction.date.month == targetMonth.month)
          .fold<double>(0.0, (sum, transaction) => sum + transaction.amount.abs());

      return BudgetAlert(
        budget: budget,
        spent: categorySpending,
        progressPercentage: budget.amount > 0 ? (categorySpending / budget.amount * 100) : 0,
      );
    }).toList()
      ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
  }

  Widget _buildBudgetSummary(BuildContext context, List<BudgetAlert> budgetAlerts) {
    final totalBudgets = budgetAlerts.length;
    final overBudgetCount = budgetAlerts.where((alert) => alert.isOverBudget).length;
    final nearLimitCount = budgetAlerts.where((alert) => alert.isNearLimit).length;
    final onTrackCount = totalBudgets - overBudgetCount - nearLimitCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.check_circle,
            color: Colors.green,
            count: onTrackCount,
            label: 'On Track',
          ),
          _buildSummaryItem(
            icon: Icons.warning,
            color: Colors.orange,
            count: nearLimitCount,
            label: 'Near Limit',
          ),
          _buildSummaryItem(
            icon: Icons.error,
            color: Colors.red,
            count: overBudgetCount,
            label: 'Over Budget',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color color,
    required int count,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class BudgetAlert {
  final Budget budget;
  final double spent;
  final double progressPercentage;

  BudgetAlert({
    required this.budget,
    required this.spent,
    required this.progressPercentage,
  });

  bool get isOverBudget => progressPercentage > 100;
  bool get isNearLimit => progressPercentage >= 80 && progressPercentage <= 100;
  double get remainingAmount => (budget.amount - spent).clamp(0.0, double.infinity);
}
