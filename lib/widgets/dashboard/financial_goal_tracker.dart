import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_extensions.dart';
import '../../utils/enhanced_animations.dart';

/// A widget to track progress toward financial goals with animated visualizations
/// and celebration animations when milestones are reached
class FinancialGoalTracker extends StatefulWidget {
  final List<FinancialGoal> goals;
  final Function(FinancialGoal)? onGoalTap;
  final VoidCallback? onAddGoal;

  const FinancialGoalTracker({
    super.key,
    required this.goals,
    this.onGoalTap,
    this.onAddGoal,
  });

  @override
  State<FinancialGoalTracker> createState() => _FinancialGoalTrackerState();
}

class _FinancialGoalTrackerState extends State<FinancialGoalTracker> {
  // Track which goals have shown celebration animation
  final Set<String> _celebratedGoals = <String>{};

  @override
  Widget build(BuildContext context) {
    // Sort goals by priority
    final sortedGoals = List<FinancialGoal>.from(widget.goals)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    
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
            // Header with title and add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Goals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.onAddGoal != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add New Goal',
                    onPressed: widget.onAddGoal,
                  ),
              ],
            )
            .animate()
            .fadeIn()
            .slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 16),
            
            // Goals list or empty state
            widget.goals.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: List.generate(
                      sortedGoals.length,
                      (index) => _buildGoalItem(sortedGoals[index], index),
                    ),
                  ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 800))
    .slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: Colors.grey.shade300,
          )
          .animate()
          .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'No financial goals yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Set savings goals to track your progress and stay motivated',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (widget.onAddGoal != null) ...[  
            const SizedBox(height: 16),
            EnhancedAnimations.animatedButton(
              ElevatedButton.icon(
                onPressed: widget.onAddGoal,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Goal'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalItem(FinancialGoal goal, int index) {
    // Calculate progress percentage
    final progress = goal.currentAmount / goal.targetAmount;
    final progressPercent = (progress * 100).toStringAsFixed(1);
    final isComplete = progress >= 1.0;
    
    // Determine if we need to celebrate this goal
    final shouldCelebrate = isComplete && !_celebratedGoals.contains(goal.id);
    if (shouldCelebrate) {
      Future.delayed(Duration(milliseconds: 500 + (index * 100)), () {
        if (mounted) {
          setState(() {
            _celebratedGoals.add(goal.id);
          });
        }
      });
    }
    
    // Calculate estimated completion date if not already complete
    String estimatedCompletion = '';
    if (!isComplete && goal.monthlyContribution > 0) {
      final remainingAmount = goal.targetAmount - goal.currentAmount;
      final monthsRemaining = remainingAmount / goal.monthlyContribution;
      
      // Format the projected date
      if (monthsRemaining.isFinite && monthsRemaining > 0) {
        final today = DateTime.now();
        final projectedDate = DateTime(
          today.year,
          today.month + monthsRemaining.ceil(),
          today.day,
        );
        estimatedCompletion = 'Est. completion: ${DateFormat('MMM yyyy').format(projectedDate)}';
      }
    }
    
    return EnhancedAnimations.scaleOnTap(
      onTap: () {
        HapticFeedback.selectionClick();
        if (widget.onGoalTap != null) {
          widget.onGoalTap!(goal);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isComplete ? [
            BoxShadow(
              color: goal.color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal name and icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    goal.icon ?? Icons.emoji_events,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        goal.description ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isComplete)
                  Icon(
                    Icons.verified,
                    color: goal.color,
                    size: 20,
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isComplete 
                          ? 'Goal Achieved!' 
                          : '$progressPercent% Complete',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isComplete ? goal.color : null,
                      ),
                    ),
                    Text(
                      '${goal.currentAmount.toCurrency()} of ${goal.targetAmount.toCurrency()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildProgressBar(progress, goal.color, isComplete, shouldCelebrate),
                if (estimatedCompletion.isNotEmpty) ...[  
                  const SizedBox(height: 8),
                  Text(
                    estimatedCompletion,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    )
    .animate(delay: Duration(milliseconds: 100 * index))
    .fadeIn(duration: const Duration(milliseconds: 600))
    .moveY(begin: 20, end: 0);
  }

  Widget _buildProgressBar(
    double progress, 
    Color color, 
    bool isComplete, 
    bool shouldCelebrate,
  ) {
    final effectiveProgress = progress > 1.0 ? 1.0 : progress;
    
    return Stack(
      children: [
        // Background track
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        
        // Filled portion with conditional animation
        FractionallySizedBox(
          widthFactor: effectiveProgress,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        )
        .animate(
          onPlay: shouldCelebrate 
              ? (controller) => controller.repeat(reverse: true, min: 0.8, max: 1.0, period: const Duration(milliseconds: 1000)) 
              : null,
        )
        .shimmer(
          duration: const Duration(milliseconds: 1500),
          color: Colors.white,
          delay: const Duration(milliseconds: 300),
        ).animate(target: isComplete ? 1 : 0),
      ],
    );
  }
}

/// Model class for financial goals
class FinancialGoal {
  final String id;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final double monthlyContribution;
  final DateTime createdDate;
  final DateTime? targetDate;
  final Color color;
  final IconData? icon;
  final int priority; // Lower number = higher priority

  const FinancialGoal({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    this.monthlyContribution = 0,
    required this.createdDate,
    this.targetDate,
    required this.color,
    this.icon,
    this.priority = 999,
  });

  // Calculate progress as a percentage
  double get progressPercentage => (currentAmount / targetAmount) * 100;
  
  // Check if the goal is completed
  bool get isComplete => currentAmount >= targetAmount;
}
