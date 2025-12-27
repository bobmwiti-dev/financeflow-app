import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/budget_model.dart';
import '../../../themes/app_theme.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onTap;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd');
    final progress = budget.percentUsed;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCategoryIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateFormat.format(budget.startDate)} - ${dateFormat.format(budget.endDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(budget.amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: ${currencyFormat.format(budget.spent)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Remaining: ${currencyFormat.format(budget.remainingAmount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: budget.remainingAmount >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${progress.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getProgressColor(progress),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: budget.spent / budget.amount,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    IconData iconData;
    
    switch (budget.category) {
      case 'Food':
        iconData = Icons.restaurant;
        break;
      case 'Transport':
        iconData = Icons.directions_car;
        break;
      case 'Shopping':
        iconData = Icons.shopping_bag;
        break;
      case 'Bills':
        iconData = Icons.receipt;
        break;
      case 'Entertainment':
        iconData = Icons.movie;
        break;
      case 'Health':
        iconData = Icons.medical_services;
        break;
      case 'Housing':
        iconData = Icons.home;
        break;
      default:
        iconData = Icons.category;
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _getCategoryColor().withAlpha((0.1 * 255).toInt()),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: _getCategoryColor(),
        size: 24,
      ),
    );
  }

  Color _getCategoryColor() {
    if (AppTheme.categoryColors.containsKey(budget.category)) {
      return AppTheme.categoryColors[budget.category]!;
    }
    return AppTheme.categoryColors['Other']!;
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 50) {
      return AppTheme.successColor;
    } else if (percentage < 80) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }
}
