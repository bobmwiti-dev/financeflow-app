import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/budget_viewmodel.dart';
import '../../../viewmodels/bill_viewmodel.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart';

class SmartAlertsCard extends StatelessWidget {
  const SmartAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<BudgetViewModel, BillViewModel, TransactionViewModel>(
      builder: (context, budgetViewModel, billViewModel, transactionViewModel, child) {
        final alerts = _generateSmartAlerts(budgetViewModel, billViewModel, transactionViewModel);
        
        if (alerts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, alerts.length),
                const SizedBox(height: 12),
                ...alerts.map((alert) => _buildAlertItem(context, alert)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int alertCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.warning, color: Colors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '$alertCount alert${alertCount > 1 ? 's' : ''} need attention',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            alertCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(BuildContext context, SmartAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alert.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: alert.color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(alert.icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (alert.amount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(symbol: 'KES ').format(alert.amount),
                    style: TextStyle(
                      color: alert.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (alert.actionText != null)
            TextButton(
              onPressed: () => alert.onAction?.call(context),
              child: Text(alert.actionText!, style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  List<SmartAlert> _generateSmartAlerts(
    BudgetViewModel budgetViewModel,
    BillViewModel billViewModel,
    TransactionViewModel transactionViewModel,
  ) {
    final alerts = <SmartAlert>[];
    final now = DateTime.now();

    // Budget overspend alerts - use real transaction data
    for (final budget in budgetViewModel.budgets) {
      // Filter transactions for current month and matching category
      final categoryTransactions = transactionViewModel.allTransactions
          .where((t) => 
              t.category.toLowerCase() == budget.category.toLowerCase() &&
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.amount < 0) // Only expense transactions (negative amounts)
          .toList();

      final categorySpending = categoryTransactions
          .fold<double>(0.0, (sum, t) => sum + t.amount.abs());

      // Alert if spending exceeds budget by more than 5% to avoid minor overages
      if (categorySpending > budget.amount * 1.05) {
        final overPercentage = ((categorySpending / budget.amount - 1) * 100);
        alerts.add(SmartAlert(
          type: AlertType.budgetOverspend,
          title: '${budget.category} Budget',
          subtitle: 'You\'ve spent ${overPercentage.toStringAsFixed(0)}% over your budget this month',
          amount: categorySpending - budget.amount,
          color: Colors.red,
          icon: Icons.trending_up,
          actionText: 'Take Action',
          onAction: (context) => Navigator.pushNamed(context, '/budgets'),
        ));
      }
      // Near budget limit warning (80-100% of budget)
      else if (categorySpending > budget.amount * 0.8) {
        final usedPercentage = (categorySpending / budget.amount * 100);
        alerts.add(SmartAlert(
          type: AlertType.budgetOverspend,
          title: '${budget.category} Budget',
          subtitle: 'You\'ve used ${usedPercentage.toStringAsFixed(0)}% of your budget this month',
          amount: budget.amount - categorySpending,
          color: Colors.orange,
          icon: Icons.warning,
          actionText: 'View Budget',
          onAction: (context) => Navigator.pushNamed(context, '/budgets'),
        ));
      }
    }

    // Bill due alerts - use real bill data
    for (final bill in billViewModel.bills) {
      final daysDue = bill.dueDate.difference(now).inDays;
        
        // Alert for bills due within 3 days
        if (daysDue <= 3 && daysDue >= -1) { // Include 1 day overdue
          String subtitle;
          Color alertColor;
          
          if (daysDue < 0) {
            subtitle = 'Overdue by ${daysDue.abs()} day${daysDue.abs() > 1 ? 's' : ''}';
            alertColor = Colors.red.shade700;
          } else if (daysDue == 0) {
            subtitle = 'Due today';
            alertColor = Colors.red;
          } else {
            subtitle = 'Due in $daysDue day${daysDue > 1 ? 's' : ''}';
            alertColor = daysDue == 1 ? Colors.red : Colors.orange;
          }
          
          alerts.add(SmartAlert(
            type: AlertType.billDue,
            title: '${bill.name} Due',
            subtitle: subtitle,
            amount: bill.amount,
            color: alertColor,
            icon: daysDue < 0 ? Icons.error : Icons.receipt,
            actionText: 'Take Action',
            onAction: (context) => Navigator.pushNamed(context, '/bills'),
          ));
        }
    }

    // Sort by priority: overdue bills, due today, budget overspends, then by amount
    alerts.sort((a, b) {
      // First sort by type priority
      final aPriority = a.priority;
      final bPriority = b.priority;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      
      // Then by amount (higher amounts first)
      if (a.amount != null && b.amount != null) {
        return b.amount!.compareTo(a.amount!);
      }
      
      return 0;
    });
    
    return alerts;
  }
}

class SmartAlert {
  final AlertType type;
  final String title;
  final String subtitle;
  final double? amount;
  final Color color;
  final IconData icon;
  final String? actionText;
  final Function(BuildContext)? onAction;

  SmartAlert({
    required this.type,
    required this.title,
    required this.subtitle,
    this.amount,
    required this.color,
    required this.icon,
    this.actionText,
    this.onAction,
  });

  int get priority {
    switch (type) {
      case AlertType.billDue:
        return 1;
      case AlertType.budgetOverspend:
        return 2;
      case AlertType.lowBalance:
        return 3;
    }
  }
}

enum AlertType {
  budgetOverspend,
  billDue,
  lowBalance,
}
