import 'package:flutter/material.dart';

/// BudgetProgressBar widget displays a progress bar for budget tracking.
class BudgetProgressBar extends StatelessWidget {
  final double budget;
  final double spent;
  final String title;
  final Color? color;

  const BudgetProgressBar({
    super.key,
    required this.budget,
    required this.spent,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final Color barColor = color ?? Theme.of(context).primaryColor;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: barColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget: ${budget.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                Text('Spent: ${spent.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
