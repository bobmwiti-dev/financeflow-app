import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../themes/app_theme.dart';
import '../../utils/enhanced_animations.dart';
import '../../widgets/animated_progress_indicator.dart';
import '../../utils/currency_extensions.dart';

/// A comprehensive summary of all budget categories with visual indicators
/// Shows progress bars for each budget with color-coded status indicators
class BudgetStatusSummary extends StatelessWidget {
  final List<BudgetCategory> categories;
  final VoidCallback? onViewAll;
  final Function(BudgetCategory category)? onAdjustBudget;

  const BudgetStatusSummary({
    super.key,
    required this.categories,
    this.onViewAll,
    this.onAdjustBudget,
  });

  @override
  Widget build(BuildContext context) {
    final sortedCategories = List<BudgetCategory>.from(categories)
      ..sort((a, b) => b.percentUsed.compareTo(a.percentUsed));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and view all button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (onViewAll != null)
                  EnhancedAnimations.animatedButton(
                    TextButton(
                      onPressed: onViewAll,
                      child: Text(
                        'View All',
                        style: TextStyle(color: AppTheme.accentColor),
                      ),
                    ),
                  ),
              ],
            )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 400))
            .slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 12),
            
            // Budget category list or empty state
            sortedCategories.isEmpty
                ? _buildEmptyState(context)
                : Column(
                    children: List.generate(
                      sortedCategories.length,
                      (index) => _buildBudgetCategoryItem(
                        context,
                        sortedCategories[index],
                        index,
                      ),
                    ),
                  ),
                  
            if (sortedCategories.isNotEmpty && onAdjustBudget != null) ...[
              const SizedBox(height: 16),
              Center(
                child: EnhancedAnimations.scaleOnTap(
                  onTap: () => onAdjustBudget!(sortedCategories[0]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppTheme.accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Adjust Budgets',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 800))
    .moveY(begin: 30, end: 0, curve: Curves.easeOutQuint);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Colors.blue.shade300,
          )
          .animate()
          .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'No budgets set',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create budgets to track your spending goals',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (onAdjustBudget != null)
            EnhancedAnimations.animatedButton(
              ElevatedButton.icon(
                onPressed: () => onAdjustBudget!(BudgetCategory.empty()),
                icon: const Icon(Icons.add),
                label: const Text('Create Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      )
      .animate()
      .fadeIn()
      .slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildBudgetCategoryItem(BuildContext context, BudgetCategory category, int index) {
    // Determine color based on percentage used
    Color statusColor;
    if (category.percentUsed >= 1.0) {
      statusColor = Colors.red.shade700; // Over budget
    } else if (category.percentUsed >= 0.85) {
      statusColor = Colors.orange.shade700; // Approaching limit
    } else if (category.percentUsed >= 0.75) {
      statusColor = Colors.amber.shade700; // Getting close
    } else {
      statusColor = Colors.green.shade700; // Safe
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedBudgetProgressBar(
        progress: category.percentUsed > 1.0 ? 1.0 : category.percentUsed,
        color: statusColor,
        label: '${category.name} ${_getTrendIndicator(category.trend)}',
        valueLabel: '${category.amountSpent.toCurrency()} of ${category.budgetAmount.toCurrency()}',
        animationDelayMs: 200 + (index * 100),
      ),
    )
    .animate(delay: Duration(milliseconds: 100 * index))
    .fadeIn()
    .slideX(begin: 0.05, end: 0);
  }

  // Get trend indicator based on spending trend
  String _getTrendIndicator(SpendingTrend trend) {
    switch (trend) {
      case SpendingTrend.increasing:
        return '↑'; // Up arrow
      case SpendingTrend.decreasing:
        return '↓'; // Down arrow
      case SpendingTrend.stable:
        return '→'; // Right arrow
      default:
        return '';
    }
  }
}

/// Types of spending trends
enum SpendingTrend {
  increasing,
  decreasing,
  stable,
  unknown,
}

/// Model class for budget categories
class BudgetCategory {
  final String id;
  final String name;
  final double budgetAmount;
  final double amountSpent;
  final SpendingTrend trend;
  final String? icon;
  final Color? color;
  final DateTime? updatedAt;

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.budgetAmount,
    required this.amountSpent,
    this.trend = SpendingTrend.unknown,
    this.icon,
    this.color,
    this.updatedAt,
  });

  /// Get percentage of budget used
  double get percentUsed => amountSpent / budgetAmount;

  /// Empty budget category for initializing
  factory BudgetCategory.empty() => BudgetCategory(
        id: '',
        name: '',
        budgetAmount: 0,
        amountSpent: 0,
      );
}
