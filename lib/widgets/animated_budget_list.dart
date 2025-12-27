import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../models/budget_model.dart';
import '../widgets/animated_data_list.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/sync_status_indicator.dart';

/// A widget that displays a list of budgets with animations
class AnimatedBudgetList extends StatelessWidget {
  final List<Budget> budgets;
  final bool isLoading;
  final Function(Budget) onTap;
  final Function(Budget) onDelete;
  final Function(Budget) onEdit;
  final String emptyMessage;
  final bool showSyncStatus;

  const AnimatedBudgetList({
    super.key,
    required this.budgets,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    this.isLoading = false,
    this.emptyMessage = 'No budgets found',
    this.showSyncStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && budgets.isEmpty) {
      return Center(
        child: DataLoadingIndicator(
          isLoading: true,
          message: 'Loading budgets...',
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
      );
    }

    return Column(
      children: [
        if (showSyncStatus && isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SyncStatusIndicator(
                  isSyncing: isLoading,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Syncing budgets...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: AnimatedDataList<Budget>(
            items: budgets,
            itemBuilder: (context, budget, animation) {
              return _buildBudgetItem(context, budget, animation);
            },
            keyExtractor: (budget) => 'budget-${budget.id ?? 0}',
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetItem(BuildContext context, Budget budget, Animation<double> animation) {
    final theme = Theme.of(context);
    final percentSpent = budget.amount > 0 ? budget.spent / budget.amount : 0.0;
    final isOverBudget = percentSpent > 1.0;
    
    // Determine progress color based on percentage
    Color progressColor;
    if (isOverBudget) {
      progressColor = Colors.red;
    } else if (percentSpent > 0.75) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }
    
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => onTap(budget),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          budget.category,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${budget.spent.toStringAsFixed(2)} / \$${budget.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isOverBudget ? Colors.red : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearPercentIndicator(
                    animation: true,
                    animationDuration: 750,
                    lineHeight: 12.0,
                    percent: isOverBudget ? 1.0 : percentSpent,
                    backgroundColor: theme.colorScheme.primary.withAlpha(30),
                    progressColor: progressColor,
                    barRadius: const Radius.circular(6),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getBudgetStatusText(percentSpent),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(percentSpent * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate()
          .slideX(begin: 0.05, end: 0, duration: const Duration(milliseconds: 200))
          .fadeIn(duration: const Duration(milliseconds: 300)),
      ),
    );
  }

  String _getBudgetStatusText(double percentSpent) {
    if (percentSpent >= 1.0) {
      return 'Over Budget';
    } else if (percentSpent >= 0.9) {
      return 'Almost Depleted';
    } else if (percentSpent >= 0.75) {
      return 'Caution';
    } else if (percentSpent >= 0.5) {
      return 'On Track';
    } else {
      return 'Good Standing';
    }
  }
}
