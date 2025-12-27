import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/goal_model.dart';

class GoalProgressCard extends StatelessWidget {
  final List<Goal> goals;
  final bool isLoading;
  final Function(Goal) onGoalTap;
  
  const GoalProgressCard({
    super.key,
    required this.goals,
    this.isLoading = false,
    required this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Goal Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add New Goal',
                  onPressed: () {
                    // Navigate to add goal screen
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (goals.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No savings goals found',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Goal'),
                      onPressed: () {
                        // Navigate to add goal screen
                      },
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final progress = goal.currentAmount / goal.targetAmount;
                    final daysLeft = goal.targetDate?.difference(DateTime.now()).inDays;
                        
                    // Calculate projected completion date based on savings rate
                    String projectedCompletionText = '';
                    if (goal.currentAmount > 0 && goal.targetAmount > goal.currentAmount) {
                      // Simple projection based on current progress
                      final averageDailySavings = goal.currentAmount / 
                          max(1, DateTime.now().difference(DateTime.now().subtract(const Duration(days: 90))).inDays);
                      
                      if (averageDailySavings > 0) {
                        final daysToComplete = (goal.targetAmount - goal.currentAmount) / averageDailySavings;
                        final projectedDate = DateTime.now().add(Duration(days: daysToComplete.toInt()));
                        
                        if (goal.targetDate != null) {
                          final onTrack = projectedDate.isBefore(goal.targetDate!);
                          projectedCompletionText = onTrack 
                              ? 'On track to complete ${DateFormat.yMMMd().format(projectedDate)}'
                              : 'Projected to complete ${DateFormat.yMMMd().format(projectedDate)} (${projectedDate.difference(goal.targetDate!).inDays} days late)';
                        } else {
                          projectedCompletionText = 'Projected to complete ${DateFormat.yMMMd().format(projectedDate)}';
                        }
                      }
                    }
                    
                    return GestureDetector(
                      onTap: () => onGoalTap(goal),
                      child: Container(
                        width: 250,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor.withValues(alpha: 179),  // 0.7 * 255 = 179
                              Theme.of(context).colorScheme.secondary.withValues(alpha: 204),  // 0.8 * 255 = 204
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              goal.description ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '\$${goal.currentAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (daysLeft != null)
                              Text(
                                daysLeft > 0 
                                    ? '$daysLeft days left' 
                                    : daysLeft == 0 
                                        ? 'Due today!' 
                                        : 'Overdue by ${-daysLeft} days',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: daysLeft < 0 ? Colors.red[100] : Colors.white70,
                                ),
                              ),
                            if (projectedCompletionText.isNotEmpty)
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    projectedCompletionText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: Duration(milliseconds: index * 100))
                      .slideX(begin: 0.2, end: 0);
                  },
                ),
              ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.1, end: 0);
  }
  
  int max(int a, int b) => a > b ? a : b;
}
