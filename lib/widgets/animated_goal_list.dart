import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/goal_model.dart';
import '../widgets/animated_data_list.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/sync_status_indicator.dart';

/// A widget that displays a list of financial goals with animations
class AnimatedGoalList extends StatelessWidget {
  final List<Goal> goals;
  final bool isLoading;
  final Function(Goal) onTap;
  final Function(Goal) onDelete;
  final Function(Goal) onEdit;
  final String emptyMessage;
  final bool showSyncStatus;

  const AnimatedGoalList({
    super.key,
    required this.goals,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    this.isLoading = false,
    this.emptyMessage = 'No goals found',
    this.showSyncStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && goals.isEmpty) {
      return Center(
        child: DataLoadingIndicator(
          isLoading: true,
          message: 'Loading goals...',
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
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
                  'Syncing goals...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: AnimatedDataList<Goal>(
            items: goals,
            itemBuilder: (context, goal, animation) {
              return _buildGoalItem(context, goal, animation);
            },
            keyExtractor: (goal) => 'goal-${goal.id ?? 0}',
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem(BuildContext context, Goal goal, Animation<double> animation) {
    final theme = Theme.of(context);
    final percentCompleted = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0.0;
    final isCompleted = percentCompleted >= 1.0;
    
    // Determine progress color based on percentage
    Color progressColor;
    if (isCompleted) {
      progressColor = Colors.green;
    } else if (percentCompleted > 0.75) {
      progressColor = Colors.lightGreen;
    } else if (percentCompleted > 0.5) {
      progressColor = Colors.amber;
    } else if (percentCompleted > 0.25) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.deepOrange;
    }
    
    // Calculate days remaining
    final daysRemaining = goal.targetDate != null
        ? goal.targetDate!.difference(DateTime.now()).inDays
        : 0;
    final daysRemainingText = daysRemaining > 0 
        ? '$daysRemaining days left' 
        : daysRemaining == 0 
            ? 'Due today' 
            : 'Overdue by ${-daysRemaining} days';
    
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => onTap(goal),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 30.0,
                    lineWidth: 5.0,
                    animation: true,
                    animationDuration: 1000,
                    percent: percentCompleted > 1.0 ? 1.0 : percentCompleted,
                    center: isCompleted 
                        ? const Icon(Icons.check, color: Colors.green, size: 24)
                        : Text(
                            '${(percentCompleted * 100).toInt()}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: progressColor,
                    backgroundColor: theme.colorScheme.primary.withAlpha(30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          daysRemainingText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: daysRemaining < 0 ? Colors.red : theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${goal.currentAmount.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of \$${goal.targetAmount.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(150),
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
}
