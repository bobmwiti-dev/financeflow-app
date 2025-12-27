import 'dart:async';
import 'package:flutter/material.dart';
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
    _progressAnimationController.forward(from: 0.0);
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!_isPaused) {
        _nextInsight(isAutomatic: true);
      }
    });
  }

  void _nextInsight({bool isAutomatic = false}) {
    setState(() {
      _swipeDirection = 1;
      if (_currentIndex < _insights.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0; // Loop back to the start
      }
      if (!_isPaused) {
        _progressAnimationController.forward(from: 0.0);
      }
    });
  }

  void _previousInsight() {
    setState(() {
      _swipeDirection = -1;
      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        _currentIndex = _insights.length - 1; // Loop to the end
      }
      if (!_isPaused) {
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
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha:0.2),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCardContent(),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Insight of the Day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 12),
        Text('Fetching your daily insight...', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
        SizedBox(height: 12),
        LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _fetchInsights, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const Text('No new insights for today.', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _fetchInsights, child: const Text('Check for Insights')),
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
  }

  Widget _buildInsightDisplay() {
    final insight = _insights[_currentIndex];
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
                  scale: Tween<double>(begin: 0.9, end: 1.1).animate(_iconAnimationController),
                  child: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 8),
                const Text('Insight of the Day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_currentIndex + 1} of ${_insights.length}', style: const TextStyle(color: Colors.grey)),
                IconButton(
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: _togglePause,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(insight.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (!insight.isRead)
                  const Chip(
                    label: Text('NEW'),
                    backgroundColor: Colors.amber,
                    padding: EdgeInsets.zero,
                    labelStyle: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight.description, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            if (_isExpanded) _buildExpandedDetails(insight),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => _showDismissConfirmationDialog(_currentIndex), child: const Text('Dismiss')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () => _takeAction(insight), child: const Text('Take Action')),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _progressAnimationController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimationController.value,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
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
