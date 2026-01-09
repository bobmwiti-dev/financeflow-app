import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/navigation_service.dart';
import '../../constants/app_constants.dart';

import '../../viewmodels/goal_viewmodel.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import 'widgets/goal_card.dart';
import 'add_goal_screen.dart';
import 'goal_details_screen.dart';
import '../../models/goal_model.dart';
import 'widgets/add_goal_button.dart';

enum GoalSortOption {
  priority,
  targetDate,
  progress,
  name,
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with TickerProviderStateMixin {
  final int _selectedIndex = 2; // Goals tab selected
  GoalSortOption _currentSortOption = GoalSortOption.priority; // Default sort
  late AnimationController _summaryAnimationController;
  late AnimationController _listAnimationController;
  bool _isInteractiveMode = false;

  static const Color _accentColor = AppTheme.primaryColor;

  LinearGradient get _accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.primaryColor,
          AppTheme.secondaryColor,
        ],
      );

  BoxDecoration _premiumCardDecoration(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.surface,
          colorScheme.surfaceContainerHighest,
        ],
      ),
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      boxShadow: AppTheme.boxShadow,
    );
  }

  @override
  void initState() {
    super.initState();
    _summaryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadGoals();
    _summaryAnimationController.forward();
  }

  @override
  void dispose() {
    _summaryAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  void _loadGoals() {
    // The view model now uses a stream, so we just need to trigger the load.
    // The Consumer widget will handle UI updates automatically.
    Provider.of<GoalViewModel>(context, listen: false).loadGoals();
  }

  void _onItemSelected(int index) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(); // close drawer
    switch (index) {
      case 0:
        NavigationService.navigateTo(AppConstants.dashboardRoute);
        break;
      case 1:
        NavigationService.navigateTo(AppConstants.expensesRoute);
        break;
      case 6:
        NavigationService.navigateTo(AppConstants.incomeRoute);
        break;
      case 7:
        NavigationService.navigateTo('/budgets');
        break;
      case 8:
        NavigationService.navigateTo(AppConstants.loansRoute);
        break;
      case 3:
        NavigationService.navigateTo(AppConstants.reportsRoute);
        break;
      case 9:
        NavigationService.navigateTo(AppConstants.insightsRoute);
        break;
      case 4:
        NavigationService.navigateTo(AppConstants.familyRoute);
        break;
      case 5:
        NavigationService.navigateTo(AppConstants.settingsRoute);
        break;
      case 10:
        NavigationService.navigateTo(AppConstants.profileRoute);
        break;
      default:
        // already on Goals (index 2) or unknown
        break;
    }

  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.borderRadius * 1.25),
        ),
      ),
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.star_border),
              title: const Text('Sort by Priority'),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentSortOption = GoalSortOption.priority);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Sort by Target Date'),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentSortOption = GoalSortOption.targetDate);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('Sort by Progress'),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentSortOption = GoalSortOption.progress);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Sort by Name'),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentSortOption = GoalSortOption.name);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              HapticFeedback.selectionClick();
              _showSortOptions();
            },
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withAlpha((0.06 * 255).toInt()),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Consumer<GoalViewModel>(
          builder: (context, goalViewModel, child) {
            return RefreshIndicator(
              onRefresh: () async {
                goalViewModel.loadGoals();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    sliver: SliverToBoxAdapter(
                      child: _buildSummaryCard(goalViewModel),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    sliver: _buildGoalsSliver(goalViewModel),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: AddGoalButton(
        onPressed: () async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddGoalScreen(),
            ),
          );
          // No need to manually reload - Consumer will automatically update via stream
          if (added == true && mounted) {
            // Show success message using captured ScaffoldMessenger
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Goal added successfully!')),
            );
          }
        },
      ),
    );
  }

  Widget _buildSummaryCard(GoalViewModel viewModel) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final totalGoals = viewModel.getTotalSavingsGoals();
    final currentSavings = viewModel.getTotalCurrentSavings();
    final progressRatio = viewModel.getOverallProgress();
    final progressPercent = (progressRatio * 100).clamp(0.0, 100.0);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _isInteractiveMode = !_isInteractiveMode;
        });
        if (_isInteractiveMode) {
          _summaryAnimationController.forward();
        } else {
          _summaryAnimationController.reverse();
        }
      },
      child: Container(
        margin: EdgeInsets.zero,
        decoration: _premiumCardDecoration(theme),
        child: AnimatedBuilder(
          animation: _summaryAnimationController,
          builder: (context, child) {
            return Container(
              padding: EdgeInsets.all(20.0 + (4 * _summaryAnimationController.value)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: _accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.savings_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => _accentGradient.createShader(bounds),
                              child: const Text(
                                'Total Savings Progress',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to interact',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isInteractiveMode ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: _accentColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Current Savings',
                          currencyFormat.format(currentSavings),
                          'of ${currencyFormat.format(totalGoals)}',
                          Icons.account_balance_wallet_rounded,
                          AppTheme.incomeColor,
                          0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Progress',
                          '${progressPercent.toStringAsFixed(1)}%',
                          'Overall completion',
                          Icons.trending_up_rounded,
                          progressPercent >= 75 ? Colors.green : progressPercent >= 50 ? Colors.orange : Colors.red,
                          1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInteractiveProgressBar(progressPercent),
                ],
              ),
            );
          },
        ),
      ).animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.2, duration: 600.ms, curve: Curves.easeOutCubic)
        .shimmer(duration: 1500.ms, delay: 800.ms),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color, int index) {
    return AnimatedBuilder(
      animation: _summaryAnimationController,
      builder: (context, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(16 + (2 * _summaryAnimationController.value)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.05),
                color.withValues(alpha: 0.02),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                ).createShader(bounds),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 200 + (index * 100)))
          .fadeIn(duration: 400.ms)
          .slideX(begin: index == 0 ? -0.3 : 0.3, duration: 400.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildInteractiveProgressBar(double progress) {
    return GestureDetector(
      onTap: () {
        _summaryAnimationController.reset();
        _summaryAnimationController.forward();
      },
      child: AnimatedBuilder(
        animation: _summaryAnimationController,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: progress >= 75 
                          ? Colors.green.withValues(alpha: 0.1)
                          : progress >= 50 
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: progress >= 75 
                            ? Colors.green
                            : progress >= 50 
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.withValues(alpha: 0.1),
                      Colors.grey.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 800 + (progress * 10).toInt()),
                        curve: Curves.easeOutCubic,
                        width: MediaQuery.of(context).size.width * 
                               (progress / 100) * _summaryAnimationController.value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: progress >= 75 
                                ? [Colors.green.withValues(alpha: 0.8), Colors.green]
                                : progress >= 50 
                                    ? [Colors.orange.withValues(alpha: 0.8), Colors.orange]
                                    : [Colors.red.withValues(alpha: 0.8), Colors.red],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      if (_isInteractiveMode)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.3),
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.3),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 2000.ms),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap progress bar to animate',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGoalsSliver(GoalViewModel viewModel) {
    if (viewModel.isLoading) {
      return SliverToBoxAdapter(
        child: _buildLoadingState(),
      );
    }

    if (viewModel.goals.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    final goals = List<Goal>.from(viewModel.goals);

    goals.sort((a, b) {
      switch (_currentSortOption) {
        case GoalSortOption.priority:
          return b.priority.compareTo(a.priority);
        case GoalSortOption.targetDate:
          return (a.targetDate ?? DateTime.now()).compareTo(b.targetDate ?? DateTime.now());
        case GoalSortOption.progress:
          final progressA = a.targetAmount > 0 ? a.currentAmount / a.targetAmount : 0;
          final progressB = b.targetAmount > 0 ? b.currentAmount / b.targetAmount : 0;
          return progressA.compareTo(progressB);
        case GoalSortOption.name:
          return a.name.compareTo(b.name);
      }
    });

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final goal = goals[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == goals.length - 1 ? 0 : 16),
            child: GoalCard(
              heroTag: goal.id != null ? 'goal_${goal.id}' : null,
              name: goal.name,
              currentAmount: goal.currentAmount,
              targetAmount: goal.targetAmount,
              targetDate: goal.targetDate ?? DateTime.now(),
              category: goal.category ?? 'General',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalDetailsScreen(
                      goal: goal,
                      heroTag: goal.id != null ? 'goal_${goal.id}' : null,
                    ),
                  ),
                );
              },
              onAddFunds: () {
                HapticFeedback.lightImpact();
                _showEnhancedAddFundsDialog(goal);
              },
            ),
          ).animate(delay: Duration(milliseconds: 100 * index))
              .fadeIn(duration: 500.ms)
              .slideX(
                begin: index.isEven ? -0.3 : 0.3,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              );
        },
        childCount: goals.length,
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(3, (index) {
        return Container(
          height: 120,
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : 16),
          decoration: _premiumCardDecoration(theme),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 40),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 12,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 10,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate()
          .fadeIn(duration: 300.ms)
          .shimmer(duration: 1300.ms, delay: (150 * index).ms);
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: _accentGradient,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.savings_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  _accentColor,
                  _accentColor.withValues(alpha: 0.7),
                ],
              ).createShader(bounds),
              child: const Text(
                'Create your first goal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set a savings target and track your progress over time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentColor.withValues(alpha: 0.1),
                    _accentColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: _accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap + to get started',
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate()
        .fadeIn(duration: 800.ms)
        .slideY(begin: 0.3, duration: 800.ms, curve: Curves.easeOutCubic),
    );
  }

  // _buildGoalsList replaced by sliver-based layout (_buildGoalsSliver)

  void _showEnhancedAddFundsDialog(Goal goal) {
    final TextEditingController amountController = TextEditingController();
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                HapticFeedback.vibrate();
                return;
              }

              setState(() {
                isSubmitting = true;
              });

              final vm = Provider.of<GoalViewModel>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              final success = await vm.updateGoalProgress(goal, amount);

              if (success) {
                HapticFeedback.heavyImpact();
              } else {
                HapticFeedback.vibrate();
              }

              if (!context.mounted) return;

              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Added ${currencyFormat.format(amount)} to ${goal.name}!'
                        : 'Failed to add funds. Please try again.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      _accentColor.withValues(alpha: 0.02),
                      Colors.white,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  boxShadow: AppTheme.boxShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accentColor.withValues(alpha: 0.1),
                            _accentColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        color: _accentColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          _accentColor,
                          _accentColor.withValues(alpha: 0.8),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Add Funds to ${goal.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current: ${currencyFormat.format(goal.currentAmount)} of ${currencyFormat.format(goal.targetAmount)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.2),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            _accentColor.withValues(alpha: 0.02),
                            Colors.white,
                          ],
                        ),
                      ),
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount to add',
                          prefixText: '\$',
                          prefixStyle: TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        onSubmitted: (_) {
                          if (!isSubmitting) {
                            HapticFeedback.selectionClick();
                            submit();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    Navigator.pop(context);
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    submit();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: AnimatedSwitcher(
                              duration: AppTheme.mediumAnimationDuration,
                              child: isSubmitting
                                  ? const SizedBox(
                                      key: ValueKey('submitting'),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Add Funds',
                                      key: ValueKey('add'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.easeOutBack),
            );
          },
        );
      },
    );
  }
}
