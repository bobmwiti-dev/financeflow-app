import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../models/financial_goal.dart';

/// Dashboard financial goals widget showing progress towards savings goals
class DashboardGoals extends StatelessWidget {
  final List<dynamic> goals;
  final int maxItems;
  final Function(FinancialGoal)? onGoalTap;

  const DashboardGoals({
    super.key,
    required this.goals,
    this.maxItems = 3,
    this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeGoals = goals.isEmpty 
        ? [] 
        : goals
            .where((goal) => !goal.isCompleted)
            .take(maxItems)
            .toList();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1 * 255),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Goals',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/goals');
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (activeGoals.isEmpty)
              _buildEmptyState()
            else
              ...activeGoals.asMap().entries.map(
                (entry) => _buildGoalItem(
                  context,
                  entry.value,
                  delay: 100.ms + (entry.key * 50).ms,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget when no goals are available
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No active financial goals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set financial goals to track your progress and stay motivated',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  /// Build a goal item in the list
  Widget _buildGoalItem(
    BuildContext context, 
    FinancialGoal goal,
    {required Duration delay}
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final progressColor = _getProgressColor(goal.progressPercentage);
    
    return InkWell(
      onTap: () {
        if (onGoalTap != null) {
          onGoalTap!(goal);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.1 * 255),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    goal.getIcon(),
                    color: progressColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${currencyFormat.format(goal.targetAmount)} • By ${dateFormat.format(goal.targetDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFormat.format(goal.currentAmount),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currencyFormat.format(goal.targetAmount),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: goal.progressPercentage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        height: 8,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  goal.daysRemaining <= 0
                      ? 'Due date passed'
                      : '${goal.daysRemaining} days remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: goal.daysRemaining <= 0 ? Colors.red : Colors.grey[600],
                    fontStyle: goal.daysRemaining <= 0 ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay, duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  /// Get color based on progress percentage
  Color _getProgressColor(double progress) {
    if (progress >= 1.0) {
      return Colors.green;
    } else if (progress >= 0.7) {
      return Colors.lightGreen;
    } else if (progress >= 0.4) {
      return Colors.amber;
    } else if (progress >= 0.2) {
      return Colors.orange;
    } else {
      return Colors.redAccent;
    }
  }
}
