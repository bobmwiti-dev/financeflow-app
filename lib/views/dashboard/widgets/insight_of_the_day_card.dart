import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/insight_model.dart';
import '../../../services/insight_service.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../viewmodels/budget_viewmodel.dart';
import '../../../viewmodels/bill_viewmodel.dart';
import '../../../viewmodels/goal_viewmodel.dart';
import '../../../viewmodels/income_viewmodel.dart';

class InsightOfTheDayCard extends StatefulWidget {
  final DateTime? selectedMonth;
  
  const InsightOfTheDayCard({super.key, this.selectedMonth});

  @override
  State<InsightOfTheDayCard> createState() => _InsightOfTheDayCardState();
}

class _InsightOfTheDayCardState extends State<InsightOfTheDayCard>
    with TickerProviderStateMixin {
  InsightService? _insightService;
  late Future<List<Insight>> _insightsFuture;
  List<Insight> _insights = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  late AnimationController _iconAnimationController;
  late AnimationController _progressAnimationController;
  int _swipeDirection = 0;
  Timer? _timer;
  bool _isPaused = false;
  bool _isExpanded = false;
  bool _preAutoAdvanceHapticPlayed = false;
  Insight? _lastDismissed;
  int? _lastDismissedIndex;
  DateTime? _lastSelectedMonth;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _progressAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextInsight(isAutomatic: true);
      }
    });

    _progressAnimationController.addListener(() {
      final value = _progressAnimationController.value;
      if (!_isPaused && !_isExpanded && !_preAutoAdvanceHapticPlayed && value >= 0.875) {
        _preAutoAdvanceHapticPlayed = true;
        HapticFeedback.selectionClick();
      }
    });

    // Initialize service and fetch insights after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeService();
    });
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    _progressAnimationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _preAutoAdvanceHapticPlayed = false;
    _progressAnimationController.forward(from: 0.0);
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!_isPaused) {
        _nextInsight(isAutomatic: true);
      }
    });
  }

  void _nextInsight({bool isAutomatic = false}) {
    if (!isAutomatic) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _swipeDirection = 1;
      if (_currentIndex < _insights.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0; // Loop back to the start
      }
      if (!_isPaused) {
        _preAutoAdvanceHapticPlayed = false;
        _progressAnimationController.forward(from: 0.0);
      }
    });
  }

  void _previousInsight() {
    HapticFeedback.lightImpact();
    setState(() {
      _swipeDirection = -1;
      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        _currentIndex = _insights.length - 1; // Loop to the end
      }
      if (!_isPaused) {
        _preAutoAdvanceHapticPlayed = false;
        _progressAnimationController.forward(from: 0.0);
      }
    });
  }

  void _initializeService() {
    final transactionVM = Provider.of<TransactionViewModel>(context, listen: false);
    final budgetVM = Provider.of<BudgetViewModel>(context, listen: false);
    final billVM = Provider.of<BillViewModel>(context, listen: false);
    final goalVM = Provider.of<GoalViewModel>(context, listen: false);
    final incomeVM = Provider.of<IncomeViewModel>(context, listen: false);
    
    _insightService = InsightService(
      transactionViewModel: transactionVM,
      budgetViewModel: budgetVM,
      billViewModel: billVM,
      goalViewModel: goalVM,
      incomeViewModel: incomeVM,
    );
    
    _fetchInsights();
  }

  void _fetchInsights() {
    if (_insightService == null) return;
    
    final selectedMonth = widget.selectedMonth ?? DateTime.now();
    
    // Only fetch if month changed or first time
    if (_lastSelectedMonth == null || 
        _lastSelectedMonth!.year != selectedMonth.year ||
        _lastSelectedMonth!.month != selectedMonth.month) {
      
      setState(() {
        _isLoading = true;
        _error = null;
        _lastSelectedMonth = selectedMonth;
      });
      
      _insightsFuture = _insightService!.getInsights(selectedMonth: selectedMonth);
      _insightsFuture.then((insights) {
        if (mounted) {
          setState(() {
            _insights = insights;
            _isLoading = false;
            _currentIndex = 0; // Reset to first insight
            if (insights.isNotEmpty) {
              _startTimer();
            }
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _error = "Failed to load insights. Please try again.";
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(InsightOfTheDayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch insights if selected month changed
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      _fetchInsights();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.10),
            colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.90 : 0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.14),
            blurRadius: _isExpanded ? 22 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildCardContent(),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    if (_isLoading) {
      return _buildLoadingState();
    } else if (_error != null) {
      return _buildErrorState();
    } else if (_insights.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildInsightDisplay();
    }
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Insight of the Day',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Fetching your daily insight...',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurface.withValues(alpha: 0.80),
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _error!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: _fetchInsights,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error.withValues(alpha: 0.12),
              foregroundColor: colorScheme.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No new insights for today.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: _fetchInsights,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Check for Insights'),
          ),
        ),
      ],
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _timer?.cancel();
        _progressAnimationController.stop();
      } else {
        _startTimer();
      }
    });
  }

  void _dismissInsight(int index) {
    setState(() {
      _lastDismissed = _insights.removeAt(index);
      _lastDismissedIndex = index;

      if (_currentIndex >= _insights.length && _insights.isNotEmpty) {
        _currentIndex = _insights.length - 1;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insight dismissed.'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              setState(() {
                if (_lastDismissed != null && _lastDismissedIndex != null) {
                  _insights.insert(_lastDismissedIndex!, _lastDismissed!);
                  _lastDismissed = null;
                  _lastDismissedIndex = null;
                }
              });
            },
          ),
        ),
      );
    });
  }

  void _showDismissConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dismiss Insight'),
          content: const Text('Are you sure you want to dismiss this insight?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop();
                _dismissInsight(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _takeAction(Insight insight) {
    Navigator.of(context).pop(); // Close any existing dialogs
    
    if (insight is SpendingPatternInsight) {
      _handleSpendingPatternAction(insight);
    } else if (insight is BudgetAlertInsight) {
      _handleBudgetAlertAction(insight);
    } else if (insight is SavingOpportunityInsight) {
      _handleSavingOpportunityAction(insight);
    } else if (insight is FinancialHealthInsight) {
      _handleFinancialHealthAction(insight);
    } else if (insight.type == 'Bill Alert') {
      _handleBillAlertAction(insight);
    } else if (insight.type == 'Goal Progress') {
      _handleGoalProgressAction(insight);
    } else {
      _showGenericActionDialog(insight);
    }
  }

  void _handleSpendingPatternAction(SpendingPatternInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review ${insight.category} Spending'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your ${insight.category} spending increased by ${insight.percentageChange.toStringAsFixed(1)}%.'),
            const SizedBox(height: 12),
            Text('Previous month: \$${insight.previousAmount.toStringAsFixed(0)}'),
            Text('This month: \$${insight.currentAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToExpenses(insight.category);
            },
            child: const Text('View Transactions'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createBudgetAlert(insight.category, insight.currentAmount);
            },
            child: const Text('Set Budget Alert'),
          ),
        ],
      ),
    );
  }

  void _handleBudgetAlertAction(BudgetAlertInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${insight.category} Budget Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget: \$${insight.budgetAmount.toStringAsFixed(0)}'),
            Text('Spent: \$${insight.spentAmount.toStringAsFixed(0)}'),
            Text('Usage: ${insight.percentageUsed.toStringAsFixed(0)}%'),
            const SizedBox(height: 12),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToExpenses(insight.category);
            },
            child: const Text('View Spending'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('Adjust Budget button pressed');
              if (mounted) {
                debugPrint('Widget is mounted, proceeding with navigation');
                // Navigate directly without closing dialog first
                Navigator.of(context).pushNamed('/budgets').then((_) {
                  debugPrint('Navigation completed successfully');
                }).catchError((error) {
                  debugPrint('Navigation error: $error');
                });
              } else {
                debugPrint('Widget not mounted when button pressed');
              }
            },
            child: const Text('Adjust Budget'),
          ),
        ],
      ),
    );
  }

  void _handleSavingOpportunityAction(SavingOpportunityInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Optimize ${insight.category}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Potential savings: \$${insight.potentialSavings.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Text(insight.suggestion),
            const SizedBox(height: 12),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToExpenses(insight.category);
            },
            child: const Text('Review Transactions'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createSavingsGoal(insight.potentialSavings);
            },
            child: const Text('Create Savings Goal'),
          ),
        ],
      ),
    );
  }

  void _handleFinancialHealthAction(FinancialHealthInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Improve Financial Health'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Savings Rate: ${insight.savingsRate.toStringAsFixed(1)}%'),
            Text('Health Status: ${insight.overallHealth}'),
            const SizedBox(height: 12),
            const Text('Recommendations:'),
            ...insight.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Text('• $rec'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToReports();
            },
            child: const Text('View Reports'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToGoals();
            },
            child: const Text('Set Savings Goal'),
          ),
        ],
      ),
    );
  }

  void _handleBillAlertAction(Insight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upcoming Bills'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(insight.description),
            const SizedBox(height: 12),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToBills();
            },
            child: const Text('View Bills'),
          ),
        ],
      ),
    );
  }

  void _handleGoalProgressAction(Insight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Goal Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(insight.description),
            const SizedBox(height: 12),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToGoals();
            },
            child: const Text('View Goals'),
          ),
        ],
      ),
    );
  }

  void _showGenericActionDialog(Insight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(insight.title),
        content: Text(insight.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Navigation helper methods
  void _navigateToExpenses([String? category]) {
    if (mounted) {
      Navigator.pushNamed(context, '/expenses');
      if (category != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing $category transactions')),
        );
      }
    }
  }


  void _navigateToReports() {
    if (mounted) {
      Navigator.pushNamed(context, '/reports');
    }
  }

  void _navigateToGoals() {
    if (mounted) {
      Navigator.pushNamed(context, '/goals');
    }
  }

  void _navigateToBills() {
    if (mounted) {
      Navigator.pushNamed(context, '/bills');
    }
  }

  // Action helper methods
  void _createBudgetAlert(String category, double suggestedAmount) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Budget alert created for $category: \$${suggestedAmount.toStringAsFixed(0)}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _createSavingsGoal(double amount) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Savings goal created: \$${amount.toStringAsFixed(0)}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildExpandedDetails(Insight insight) {
    if (insight is SpendingPatternInsight) {
      return _buildDetailRow('Category:', insight.category);
    } else if (insight is BudgetAlertInsight) {
      return _buildDetailRow('Budget:', '\$${insight.budgetAmount.toStringAsFixed(2)}');
    } else if (insight is SavingOpportunityInsight) {
      return _buildDetailRow('Potential Savings:', '\$${insight.potentialSavings.toStringAsFixed(2)}');
    } else if (insight is FinancialHealthInsight) {
      return _buildDetailRow('Health:', insight.overallHealth);
    }
    return const SizedBox.shrink(); // No details for generic insights
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  void _toggleExpand() {
    final willExpand = !_isExpanded;
    setState(() {
      _isExpanded = !_isExpanded;
      // Smart pause: pause timer when expanded, resume when collapsed (if not manually paused)
      if (_isExpanded) {
        _timer?.cancel();
        _progressAnimationController.stop();
      } else if (!_isPaused) {
        _startTimer();
      }
    });
    if (willExpand) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Widget _buildInsightDisplay() {
    final insight = _insights[_currentIndex];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (_isExpanded) return; // Disable swipe when expanded
        if (details.primaryVelocity! > 0) {
          _previousInsight();
        } else if (details.primaryVelocity! < 0) {
          _nextInsight();
        }
      },
      onTap: _toggleExpand,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final offsetAnimation = Tween<Offset>(
            begin: Offset(_swipeDirection.toDouble(), 0.0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            key: ValueKey<int>(_currentIndex),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.05).animate(_iconAnimationController),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.18),
                      ),
                      child: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Insight of the Day',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: colorScheme.surface.withValues(alpha: 0.70),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_currentIndex + 1}/${_insights.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: _togglePause,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(
                              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 16,
                              color: colorScheme.onSurface.withValues(alpha: 0.80),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      insight.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!insight.isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: colorScheme.secondary.withValues(alpha: 0.20),
                      ),
                      child: Text(
                        'NEW',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                insight.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.90),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Text(
                  insight.type,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isExpanded) _buildExpandedDetails(insight),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _showDismissConfirmationDialog(_currentIndex),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withValues(alpha: 0.80),
                    ),
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _takeAction(insight),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Take Action'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _progressAnimationController,
                builder: (context, child) {
                  final theme = Theme.of(context);
                  final colorScheme = theme.colorScheme;
                  final progress = _progressAnimationController.value;
                  const totalSeconds = 8;
                  int? remainingSeconds;
                  if (!_isPaused) {
                    final remaining = (totalSeconds - (progress * totalSeconds)).clamp(0.0, totalSeconds.toDouble());
                    remainingSeconds = remaining.ceil();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isExpanded) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Swipe to see more',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.60),
                              ),
                            ),
                            Text(
                              _isPaused
                                  ? 'Paused'
                                  : 'Next tip in ${remainingSeconds ?? totalSeconds}s',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
