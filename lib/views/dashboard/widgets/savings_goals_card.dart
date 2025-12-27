import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/goal_viewmodel.dart';
import '../../../models/goal_model.dart';

class SavingsGoalsCard extends StatelessWidget {
  const SavingsGoalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
    
    return Consumer<GoalViewModel>(
      builder: (context, goalViewModel, child) {
        final goals = goalViewModel.goals;
        final isLoading = goalViewModel.isLoading;
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Savings Goals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (goals.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getOverallProgressColor(goalViewModel.getOverallProgress()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(goalViewModel.getOverallProgress() * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/goals');
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (goals.isEmpty)
                  _buildEmptyState(context)
                else
                  ..._buildGoalsList(goals, currencyFormat),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildGoalsList(List<Goal> goals, NumberFormat currencyFormat) {
    // Show top 3 goals on dashboard
    final displayGoals = goals.take(3).toList();
    
    return displayGoals.map((goal) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildGoalItem(goal, currencyFormat),
    )).toList();
  }
  
  Widget _buildGoalItem(Goal goal, NumberFormat currencyFormat) {
    final progress = goal.progressPercentage / 100;
    final color = _getGoalColor(goal.category ?? 'General');
    final icon = _getGoalIcon(goal.category ?? 'General');
    
    return GestureDetector(
      onTap: () {
        _showGoalDetails(goal);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (goal.targetDate != null)
                        Text(
                          _getTimeRemaining(goal.targetDate!),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${progress.isNaN ? 0 : (progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress bar with animation
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.isNaN ? 0 : progress.clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(goal.currentAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'of ${currencyFormat.format(goal.targetAmount)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            // Show monthly contribution if set
            if (goal.targetMonthlyContribution != null && goal.targetMonthlyContribution! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Monthly: ${currencyFormat.format(goal.targetMonthlyContribution!)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.savings_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No savings goals yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start saving for your dreams!\nEmergency fund, school fees, or vacation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/goals');
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Goal'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getGoalColor(String category) {
    switch (category.toLowerCase()) {
      case 'emergency':
      case 'savings':
        return Colors.green;
      case 'education':
      case 'school fees':
        return Colors.blue;
      case 'travel':
      case 'vacation':
        return Colors.orange;
      case 'electronics':
      case 'gadgets':
        return Colors.purple;
      case 'vehicle':
      case 'transport':
        return Colors.indigo;
      case 'home':
      case 'property':
        return Colors.brown;
      case 'business':
      case 'investment':
        return Colors.teal;
      case 'wedding':
      case 'celebration':
        return Colors.pink;
      case 'health':
      case 'medical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getGoalIcon(String category) {
    switch (category.toLowerCase()) {
      case 'emergency':
      case 'savings':
        return Icons.shield;
      case 'education':
      case 'school fees':
        return Icons.school;
      case 'travel':
      case 'vacation':
        return Icons.flight;
      case 'electronics':
      case 'gadgets':
        return Icons.laptop;
      case 'vehicle':
      case 'transport':
        return Icons.directions_car;
      case 'home':
      case 'property':
        return Icons.home;
      case 'business':
      case 'investment':
        return Icons.business;
      case 'wedding':
      case 'celebration':
        return Icons.celebration;
      case 'health':
      case 'medical':
        return Icons.local_hospital;
      default:
        return Icons.savings;
    }
  }
  
  Color _getOverallProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    if (progress >= 0.2) return Colors.blue;
    return Colors.grey;
  }
  
  String _getTimeRemaining(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;
    
    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference <= 30) {
      return '$difference days left';
    } else if (difference <= 365) {
      final months = (difference / 30).round();
      return '$months months left';
    } else {
      final years = (difference / 365).round();
      return '$years years left';
    }
  }
  
  void _showGoalDetails(Goal goal) {
    // Navigate to goal detail screen for full functionality
    // This provides access to contribution history, editing, and milestone tracking
  }
}
