import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/goal_viewmodel.dart';
import '../../../models/goal_model.dart';

/// Enhanced Savings Goals card with progress animations and gamification
/// Inspired by modern fintech apps with visual progress tracking
class EnhancedSavingsGoalsCard extends StatefulWidget {
  final VoidCallback? onViewAllGoals;
  final Function(Goal)? onGoalTap;

  const EnhancedSavingsGoalsCard({
    super.key,
    this.onViewAllGoals,
    this.onGoalTap,
  });

  @override
  State<EnhancedSavingsGoalsCard> createState() => _EnhancedSavingsGoalsCardState();
}

class _EnhancedSavingsGoalsCardState extends State<EnhancedSavingsGoalsCard> 
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  String _selectedFilter = 'Active';
  final List<String> _filters = ['All', 'Active', 'Completed', 'Paused'];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Start progress animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalViewModel>(
      builder: (context, goalViewModel, child) {
        final goals = _getFilteredGoals(goalViewModel.goals);
        final totalSaved = goals.fold<double>(0.0, (sum, goal) => sum + goal.currentAmount);
        final totalTarget = goals.fold<double>(0.0, (sum, goal) => sum + goal.targetAmount);
        final completedGoals = goalViewModel.goals.where((g) => g.isCompleted).length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(completedGoals, goals.length),
              _buildOverallProgress(totalSaved, totalTarget),
              _buildFilterChips(),
              _buildGoalsList(goals, goalViewModel.isLoading),
              _buildFooter(),
            ],
          ),
        ).animate()
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildHeader(int completedGoals, int totalGoals) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Savings Goals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$completedGoals of $totalGoals goals completed',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (completedGoals > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.amber[600],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$completedGoals achieved',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.savings,
                  color: Colors.purple[600],
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress(double totalSaved, double totalTarget) {
    if (totalTarget == 0) return const SizedBox.shrink();

    final progressPercentage = (totalSaved / totalTarget).clamp(0.0, 1.0);
    final currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withValues(alpha: 0.1), Colors.blue.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
              Text(
                '${(progressPercentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[600]!),
              minHeight: 8,
            ),
          ).animate(controller: _progressController)
            .scaleX(begin: 0.0, duration: 1000.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    currencyFormat.format(totalSaved),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Target',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    currencyFormat.format(totalTarget),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.purple.withValues(alpha: 0.2),
              checkmarkColor: Colors.purple[700],
              labelStyle: TextStyle(
                color: isSelected ? Colors.purple[700] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> goals, bool isLoading) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (goals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return _buildGoalTile(goal, index);
      },
    );
  }

  Widget _buildGoalTile(Goal goal, int index) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
    final progressPercentage = (goal.progressPercentage / 100).clamp(0.0, 1.0);
    final remainingAmount = goal.targetAmount - goal.currentAmount;
    final daysRemaining = goal.targetDate?.difference(DateTime.now()).inDays ?? 0;
    
    // Determine status and colors
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (goal.isCompleted) {
      statusColor = Colors.green;
      statusText = 'Completed!';
      statusIcon = Icons.check_circle;
    // No paused state in Goal model
    } else if (daysRemaining < 0) {
      statusColor = Colors.red;
      statusText = 'Overdue';
      statusIcon = Icons.error;
    } else if (daysRemaining <= 30) {
      statusColor = Colors.amber;
      statusText = '$daysRemaining days left';
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.blue;
      statusText = 'On track';
      statusIcon = Icons.trending_up;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: goal.isCompleted ? Colors.green.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: goal.isCompleted ? Colors.green.withValues(alpha: 0.2) : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                strokeWidth: 3,
              ).animate(delay: (index * 200).ms)
                .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
              Icon(
                _getGoalIcon(goal.category ?? 'other'),
                color: statusColor,
                size: 24,
              ),
            ],
          ),
        ),
        title: Text(
          goal.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
            color: goal.isCompleted ? Colors.grey[600] : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progressPercentage * 100).toStringAsFixed(0)}% complete',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (!goal.isCompleted)
              Text(
                '${currencyFormat.format(remainingAmount)} remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(goal.currentAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: goal.isCompleted ? Colors.green[600] : Colors.black87,
              ),
            ),
            Text(
              'of ${currencyFormat.format(goal.targetAmount)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            if (goal.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 10,
                      color: Colors.amber[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'ACHIEVED',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        onTap: () => widget.onGoalTap?.call(goal),
      ),
    ).animate(delay: (index * 100).ms)
      .fadeIn(duration: 400.ms)
      .slideX(begin: 0.3, duration: 400.ms);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.savings_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateTitle(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add_goal');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Stay motivated with visual progress',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
          if (widget.onViewAllGoals != null)
            TextButton(
              onPressed: widget.onViewAllGoals,
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple[700],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Goal> _getFilteredGoals(List<Goal> goals) {
    switch (_selectedFilter) {
      case 'Active':
        return goals.where((g) => !g.isCompleted).toList();
      case 'Completed':
        return goals.where((g) => g.isCompleted).toList();
      case 'Paused':
        return goals.toList(); // Goal model doesn't have isPaused, so return all for now
      default:
        return goals;
    }
  }

  IconData _getGoalIcon(String category) {
    switch (category.toLowerCase()) {
      case 'emergency fund':
        return Icons.security;
      case 'vacation':
        return Icons.flight;
      case 'car':
        return Icons.directions_car;
      case 'house':
        return Icons.home;
      case 'education':
        return Icons.school;
      case 'wedding':
        return Icons.favorite;
      case 'retirement':
        return Icons.elderly;
      default:
        return Icons.savings;
    }
  }

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 'Active':
        return 'No active goals';
      case 'Completed':
        return 'No completed goals yet';
      case 'Paused':
        return 'No paused goals';
      default:
        return 'No savings goals yet';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedFilter) {
      case 'Active':
        return 'Create a savings goal to start building your future.';
      case 'Completed':
        return 'Completed goals will appear here once you achieve them.';
      case 'Paused':
        return 'Paused goals will appear here.';
      default:
        return 'Set savings goals and track your progress with beautiful visualizations.';
    }
  }
}
