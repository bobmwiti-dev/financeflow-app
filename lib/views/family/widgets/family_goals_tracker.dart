import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../models/family_budget_model.dart';
import '../../../themes/app_theme.dart';

class FamilyGoalsTracker extends StatefulWidget {
  const FamilyGoalsTracker({super.key});

  @override
  State<FamilyGoalsTracker> createState() => _FamilyGoalsTrackerState();
}

class _FamilyGoalsTrackerState extends State<FamilyGoalsTracker> {
  int _selectedGoalIndex = -1;

  @override
  Widget build(BuildContext context) {
    // In a real app, this would come from the ViewModel
    final goals = FamilyBudgetSampleData.getSampleData().goals;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Family Goals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showAddGoalDialog(context),
                tooltip: 'Add new goal',
                color: AppTheme.accentColor,
              ),
            ],
          ).animate()
            .fadeIn(duration: const Duration(milliseconds: 400))
            .slideY(begin: -0.1, end: 0),
          const SizedBox(height: 16),
          ...List.generate(
            goals.length,
            (index) => _buildGoalCard(context, goals[index], index),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, FamilyGoal goal, int index) {
    final isSelected = _selectedGoalIndex == index;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final percentComplete = goal.percentComplete;
    final daysRemaining = goal.daysRemaining;
    
    Color progressColor;
    if (goal.isCompleted) {
      progressColor = AppTheme.successColor;
    } else if (daysRemaining < 30) {
      progressColor = AppTheme.warningColor;
    } else {
      progressColor = goal.color;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoalIndex = isSelected ? -1 : index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? goal.color.withAlpha((255 * 0.05).round()) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? goal.color : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: goal.color.withAlpha((255 * 0.2).round()),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          goal.icon,
                          color: goal.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              goal.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${percentComplete.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                          Text(
                            goal.isCompleted
                                ? 'Completed!'
                                : '$daysRemaining days left',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Target: ${currencyFormat.format(goal.targetAmount)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Saved: ${currencyFormat.format(goal.currentAmount)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: progressColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentComplete / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected) _buildExpandedContent(context, goal),
          ],
        ),
      ).animate()
        .fadeIn(
            duration: const Duration(milliseconds: 400),
            delay: Duration(milliseconds: 100 * index))
        .slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildExpandedContent(BuildContext context, FamilyGoal goal) {
    final targetDate = DateFormat('MMM d, yyyy').format(goal.targetDate);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final remaining = goal.targetAmount - goal.currentAmount;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(
                'Target Date',
                targetDate,
                Icons.calendar_today,
              ),
              _buildDetailItem(
                'Remaining',
                currencyFormat.format(remaining),
                Icons.account_balance_wallet,
              ),
              _buildDetailItem(
                'Monthly Need',
                currencyFormat.format(
                  goal.daysRemaining > 0
                      ? (remaining / (goal.daysRemaining / 30)).round()
                      : 0,
                ),
                Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showContributeDialog(context, goal),
                  icon: const Icon(Icons.add),
                  label: const Text('Contribute'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goal.color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showGoalDetailsDialog(context, goal),
                icon: const Icon(Icons.info_outline),
                tooltip: 'Goal details',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g., Summer Vacation',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Trip to Hawaii',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Target Date',
                hintText: 'MM/DD/YYYY',
              ),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add goal logic would go here
              Navigator.pop(context);
              _showSuccessSnackbar(context, 'Goal added successfully!');
            },
            child: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }

  void _showContributeDialog(BuildContext context, FamilyGoal goal) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contribute to ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current progress: ${goal.percentComplete.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Contribute logic would go here
              Navigator.pop(context);
              _showSuccessSnackbar(
                  context, 'Contribution added successfully!');
              
              // In a real app, we would update the goal here
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: goal.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Contribute'),
          ),
        ],
      ),
    );
  }

  void _showGoalDetailsDialog(BuildContext context, FamilyGoal goal) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.description),
            const SizedBox(height: 16),
            _buildDetailRow('Target Amount', currencyFormat.format(goal.targetAmount)),
            _buildDetailRow('Current Amount', currencyFormat.format(goal.currentAmount)),
            _buildDetailRow('Remaining', currencyFormat.format(goal.targetAmount - goal.currentAmount)),
            _buildDetailRow('Target Date', DateFormat('MMM d, yyyy').format(goal.targetDate)),
            _buildDetailRow('Days Remaining', '${goal.daysRemaining} days'),
            _buildDetailRow('Progress', '${goal.percentComplete.toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
