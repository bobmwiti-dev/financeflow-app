import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/goal_viewmodel.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../viewmodels/income_viewmodel.dart';
import '../../../models/goal_model.dart';
import '../../../models/transaction_model.dart';
import '../../../utils/currency_extensions.dart';

/// Unified Savings Card that combines savings rate tracking and goals management
class UnifiedSavingsCard extends StatefulWidget {
  final double income;
  final double expenses;
  final double targetSavingsRate;
  final VoidCallback? onViewAllGoals;
  final Function(Goal)? onGoalTap;

  const UnifiedSavingsCard({
    super.key,
    required this.income,
    required this.expenses,
    this.targetSavingsRate = 0.30,
    this.onViewAllGoals,
    this.onGoalTap,
  });

  @override
  State<UnifiedSavingsCard> createState() => _UnifiedSavingsCardState();
}

class _UnifiedSavingsCardState extends State<UnifiedSavingsCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  
  bool _showRate = true;
  String _selectedGoalFilter = 'Active';
  final List<String> _goalFilters = ['All', 'Active', 'Completed'];
  int _hoveredGoalIndex = -1;
  
  // Analytics cache
  double? _ytdRate;
  int _savingsStreak = 0;
  int _completedGoals = 0;

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.forward();
      _calculateAnalytics();
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

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.98),
                colorScheme.surface.withValues(alpha: 0.98),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildAnalyticsRow(),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: _showRate 
                  ? _buildSavingsRateView() 
                  : _buildGoalsView(goals, goalViewModel.isLoading, totalSaved, totalTarget),
              ),
              _buildFooter(),
            ],
          ),
        ).animate()
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.06),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Savings Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
                const SizedBox(height: 2),
                Text(
                  _showRate ? 'Track your rate' : 'Manage goals',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            flex: 1,
            child: _buildToggleButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton('Rate', true),
            _buildToggleButton('Goals', false),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isRate) {
    final isSelected = _showRate == isRate;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _showRate = isRate;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected 
            ? const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
            letterSpacing: 0.0,
          ),
          overflow: TextOverflow.clip,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAnalyticItem(
            'YTD Rate',
            _ytdRate != null ? '${(_ytdRate! * 100).toStringAsFixed(1)}%' : '--',
            Icons.trending_up_rounded,
            const Color(0xFF2196F3),
          ),
          const SizedBox(width: 20),
          _buildAnalyticItem(
            'Streak',
            '${_savingsStreak}d',
            Icons.local_fire_department_rounded,
            const Color(0xFFFF5722),
          ),
          const SizedBox(width: 20),
          _buildAnalyticItem(
            'Goals',
            '$_completedGoals',
            Icons.emoji_events_rounded,
            const Color(0xFFFFC107),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRateView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final savings = widget.income - widget.expenses;
    final savingsRate = widget.income > 0 ? savings / widget.income : 0.0;
    final targetRate = widget.targetSavingsRate;
    final isOnTrack = savingsRate >= targetRate;

    return Container(
      key: const ValueKey('savings_rate'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Main savings display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.12),
                  colorScheme.primaryContainer.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Rate',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(savingsRate * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: isOnTrack ? colorScheme.primary : colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Target: ${(targetRate * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOnTrack 
                              ? colorScheme.primaryContainer
                              : colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOnTrack ? 'On Track' : 'Behind',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isOnTrack
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      final progress = (savingsRate / targetRate).clamp(0.0, 1.0);
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress * _progressController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isOnTrack ? colorScheme.primary : colorScheme.error,
                                (isOnTrack ? colorScheme.primary : colorScheme.error)
                                    .withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Amount breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAmountItem('Income', widget.income, colorScheme.primary),
                    _buildAmountItem('Expenses', widget.expenses, colorScheme.error),
                    _buildAmountItem('Saved', savings, colorScheme.tertiary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem(String label, double amount, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount.toKenyaDualCurrency(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsView(List<Goal> goals, bool isLoading, double totalSaved, double totalTarget) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      key: const ValueKey('goals_view'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Goals filter and summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _selectedGoalFilter,
                items: _goalFilters.map((filter) {
                  return DropdownMenuItem(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGoalFilter = value!;
                  });
                },
                underline: Container(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (totalTarget > 0)
                Text(
                  '${totalSaved.toKenyaDualCurrency()} / ${totalTarget.toKenyaDualCurrency()}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Goals list
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          else if (goals.isEmpty)
            _buildEmptyGoalsState()
          else
            _buildGoalsList(goals),
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedGoalFilter.toLowerCase()} goals',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set savings goals to track your progress',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> goals) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: goals.take(3).map((goal) {
        final index = goals.indexOf(goal);
        final progress = goal.targetAmount > 0 
          ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
          : 0.0;
        
        return MouseRegion(
          onEnter: (_) {
            if (mounted) {
              setState(() => _hoveredGoalIndex = index);
            }
          },
          onExit: (_) {
            if (mounted) {
              setState(() => _hoveredGoalIndex = -1);
            }
          },
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onGoalTap?.call(goal);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hoveredGoalIndex == index 
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.05)
                  : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hoveredGoalIndex == index
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          goal.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${goal.currentAmount.toKenyaDualCurrency()} / ${goal.targetAmount.toKenyaDualCurrency()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress * _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getGoalProgressColor(progress),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}% complete',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (goal.targetDate != null)
                        Text(
                          _formatTargetDate(goal.targetDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate(delay: (index * 100).ms)
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.2, duration: 400.ms);
      }).toList(),
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!_showRate && widget.onViewAllGoals != null)
            TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onViewAllGoals?.call();
              },
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View All Goals'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            )
          else
            const SizedBox.shrink(),
          
          TextButton.icon(
            onPressed: () {
              // Navigate to detailed savings analytics
            },
            icon: const Icon(Icons.analytics_outlined, size: 16),
            label: const Text('View Details'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<Goal> _getFilteredGoals(List<Goal> allGoals) {
    switch (_selectedGoalFilter) {
      case 'Active':
        return allGoals.where((goal) => !goal.isCompleted).toList();
      case 'Completed':
        return allGoals.where((goal) => goal.isCompleted).toList();
      default:
        return allGoals;
    }
  }

  Color _getGoalProgressColor(double progress) {
    if (progress >= 1.0) return const Color(0xFF4CAF50);
    if (progress >= 0.7) return const Color(0xFF8BC34A);
    if (progress >= 0.4) return const Color(0xFFFFC107);
    return const Color(0xFFFF5722);
  }

  String _formatTargetDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference < 30) {
      return '${difference}d left';
    } else {
      final months = (difference / 30).round();
      return '${months}mo left';
    }
  }

  void _calculateAnalytics() {
    final transactionVm = Provider.of<TransactionViewModel>(context, listen: false);
    final incomeVm = Provider.of<IncomeViewModel>(context, listen: false);
    final goalVm = Provider.of<GoalViewModel>(context, listen: false);
    
    setState(() {
      _ytdRate = _calculateYTDSavingsRate(transactionVm, incomeVm);
      _savingsStreak = _calculateSavingsStreak(transactionVm, incomeVm);
      _completedGoals = goalVm.goals.where((goal) => goal.isCompleted).length;
    });
  }

  double _calculateYTDSavingsRate(TransactionViewModel transactionVm, IncomeViewModel incomeVm) {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    
    // Calculate YTD income
    double ytdIncome = incomeVm.incomeSources
        .where((income) => income.date.isAfter(yearStart.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, income) => sum + income.amount);
    
    // Calculate YTD expenses
    double ytdExpenses = transactionVm.transactions
        .where((transaction) => 
            transaction.type == TransactionType.expense &&
            transaction.date.isAfter(yearStart.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
    
    // Calculate savings rate
    if (ytdIncome <= 0) return 0.0;
    return (ytdIncome - ytdExpenses) / ytdIncome;
  }

  int _calculateSavingsStreak(TransactionViewModel transactionVm, IncomeViewModel incomeVm) {
    final now = DateTime.now();
    int streak = 0;
    
    // Check each day going backwards from today
    for (int i = 0; i < 365; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      // Get income and expenses for this day
      final dayIncome = incomeVm.incomeSources
          .where((income) => 
              income.date.isAfter(dayStart.subtract(const Duration(days: 1))) &&
              income.date.isBefore(dayEnd))
          .fold(0.0, (sum, income) => sum + income.amount);
      
      final dayExpenses = transactionVm.transactions
          .where((transaction) => 
              transaction.type == TransactionType.expense &&
              transaction.date.isAfter(dayStart.subtract(const Duration(days: 1))) &&
              transaction.date.isBefore(dayEnd))
          .fold(0.0, (sum, transaction) => sum + transaction.amount);
      
      // If there was any financial activity and savings were positive
      if (dayIncome > 0 || dayExpenses > 0) {
        if (dayIncome > dayExpenses) {
          streak++;
        } else {
          break; // Streak broken
        }
      }
      // If no activity, continue streak (neutral day)
    }
    
    return streak;
  }
}
