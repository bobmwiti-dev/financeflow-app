import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:logging/logging.dart';

import '../../../viewmodels/budget_viewmodel.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart' as fixed;
import '../../../models/budget_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/navigation_service.dart';
import '../../../constants/app_constants.dart';
import '../../../services/analytics_service.dart';

class BudgetAdherenceCard extends StatefulWidget {
  final DateTime? selectedMonth;
  
  const BudgetAdherenceCard({super.key, this.selectedMonth});

  @override
  State<BudgetAdherenceCard> createState() => _BudgetAdherenceCardState();
}

class _BudgetAdherenceCardState extends State<BudgetAdherenceCard>
    with TickerProviderStateMixin {
  static final Logger _logger = Logger('BudgetAdherenceCard');
  bool _isExpanded = false;
  late ConfettiController _confettiController;
  late AnimationController _cardAnimationController;
  late AnimationController _pulseController;
  bool _hasShownCelebration = false;
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _logger.info('BudgetAdherenceCard initialized');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasShownCelebration) {
      AnalyticsService.logEvent('budget_adherence_card_impression', {});
      _hasShownCelebration = true;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cardAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double _calculateRealSpentAmount(Budget budget, List<Transaction> transactions, DateTime selectedMonth) {
    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    // Only count expense transactions for budget calculations
    return transactions
        .where((transaction) => 
            transaction.type == TransactionType.expense &&
            transaction.category.toLowerCase() == budget.category.toLowerCase() &&
            transaction.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            transaction.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .fold(0.0, (sum, transaction) => sum + transaction.amount.abs());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BudgetViewModel, fixed.TransactionViewModel>(
      builder: (context, budgetVm, transactionVm, child) {
        final selectedMonth = widget.selectedMonth ?? DateTime.now();
        _logger.info('Building BudgetAdherenceCard for month: ${DateFormat('yyyy-MM').format(selectedMonth)}');
        
        // Load budgets for the selected month if not already loaded.
        // Defer to a post-frame callback to avoid ChangeNotifier
        // notifications during the build phase.
        if (budgetVm.selectedMonth.year != selectedMonth.year ||
            budgetVm.selectedMonth.month != selectedMonth.month) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _logger.info('Loading budgets for selected month');
            budgetVm.loadBudgetsForMonth(selectedMonth);
          });
        }
        
        final budgets = budgetVm.budgets;
        final transactions = transactionVm.transactions;
        _logger.info('Found ${budgets.length} budgets and ${transactions.length} transactions');
        
        if (budgets.isEmpty) {
          return _buildEmptyState(context, selectedMonth);
        }
        
        // Calculate real spent amounts for each budget
        final budgetsWithRealData = budgets.map((budget) {
          final realSpent = _calculateRealSpentAmount(budget, transactions, selectedMonth);
          _logger.fine('Budget ${budget.category}: spent \$${realSpent.toStringAsFixed(2)} of \$${budget.amount.toStringAsFixed(2)}');
          return budget.copyWith(spent: realSpent);
        }).toList();
        
        final double totalBudget = budgetsWithRealData.fold(0.0, (sum, b) => sum + b.amount);
        final double totalSpent = budgetsWithRealData.fold(0.0, (sum, b) => sum + b.spent);
        final double ratio = totalBudget > 0 ? totalSpent / totalBudget : 0;
        
        _logger.info('Total budget: \$${totalBudget.toStringAsFixed(2)}, Total spent: \$${totalSpent.toStringAsFixed(2)}, Ratio: ${(ratio * 100).toStringAsFixed(1)}%');
        
        // Trigger celebration for good budget adherence
        if (ratio <= 0.8 && !_hasShownCelebration) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _confettiController.play();
            _hasShownCelebration = true;
            _logger.info('Triggered celebration for good budget adherence');
          });
        }
        
        final oversTop = budgetsWithRealData
            .where((b) => b.spent > b.amount)
            .toList()
            ..sort((a, b) => (b.spent - b.amount).compareTo(a.spent - a.amount));
        
        final undersTop = budgetsWithRealData
            .where((b) => b.spent <= b.amount)
            .toList()
            ..sort((a, b) => (a.amount - a.spent).compareTo(b.amount - b.spent));
        
        final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
        
        // Calculate days until next payday (assuming monthly salary on 1st)
        final now = DateTime.now();
        final nextPayday = DateTime(now.year, now.month + 1, 1);
        final daysLeft = nextPayday.difference(now).inDays;
        
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
                if (_isExpanded) {
                  _cardAnimationController.forward();
                } else {
                  _cardAnimationController.reverse();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: Card(
                  elevation: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(ratio, selectedMonth),
                      _buildProgressBar(ratio, context),
                      _buildLegendRow(ratio),
                      _buildSummaryContainer(currency, totalSpent, totalBudget, ratio),
                      if (_isExpanded) ..._buildExpandedContent(oversTop, undersTop, currency, selectedMonth),
                      _buildPayDayContainer(daysLeft),
                      _buildAlertSummary(budgetsWithRealData),
                    ],
                  ),
                ),
              ),
            ),
            // Wrap ConfettiWidget in a SizedBox so it gets finite
            // layout constraints inside the scrollable dashboard.
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -3.14 / 2,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, DateTime selectedMonth) {
    final monthName = DateFormat('MMMM yyyy').format(selectedMonth);
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 180, minWidth: double.infinity),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.red.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 56,
              color: Colors.orange.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              'No budgets for $monthName',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first budget to start tracking expenses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => NavigationService.navigateTo(AppConstants.addBudgetRoute),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double ratio, DateTime selectedMonth) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (ratio <= 0.8) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'On Track';
    } else if (ratio <= 1.0) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Near Limit';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Over Budget';
    }

    final monthName = DateFormat('MMMM yyyy').format(selectedMonth);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget Adherence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $monthName',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => NavigationService.navigateTo(AppConstants.budgetsRoute),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Manage',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              if (_isExpanded) {
                _cardAnimationController.forward();
              } else {
                _cardAnimationController.reverse();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double ratio, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Container(
                    width: constraints.maxWidth * value,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: ratio > 1.0
                            ? [Colors.red.shade400, Colors.red.shade600]
                            : ratio > 0.75
                                ? [Colors.orange.shade400, Colors.orange.shade600]
                                : [Colors.green.shade400, Colors.green.shade600],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (ratio > 1.0
                              ? Colors.red
                              : ratio > 0.75
                                  ? Colors.orange
                                  : Colors.green).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (ratio > 1.0)
                Positioned(
                  right: 8,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'OVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendRow(double ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: _buildLegendDot(Colors.green, 'Good', ratio <= 0.75)),
          Flexible(child: _buildLegendDot(Colors.orange, 'Caution', ratio > 0.75 && ratio <= 1.0)),
          Flexible(child: _buildLegendDot(Colors.red, 'Over', ratio > 1.0)),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? color : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContainer(NumberFormat currency, double totalSpent, double totalBudget, double ratio) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                    'Spent',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(totalSpent),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ratio > 1.0 ? Colors.red.shade600 : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ratio > 1.0
                          ? Colors.red.shade100
                          : ratio > 0.75
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(ratio * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ratio > 1.0
                            ? Colors.red.shade700
                            : ratio > 0.75
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(totalBudget),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                totalBudget - totalSpent >= 0 ? Icons.savings : Icons.warning,
                size: 16,
                color: totalBudget - totalSpent >= 0 ? Colors.green.shade600 : Colors.red.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                totalBudget - totalSpent >= 0
                    ? 'Remaining: ${currency.format(totalBudget - totalSpent)}'
                    : 'Over budget by: ${currency.format((totalSpent - totalBudget).abs())}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: totalBudget - totalSpent >= 0 ? Colors.green.shade600 : Colors.red.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayDayContainer(int daysLeft) {
    String label;
    if (daysLeft <= 0) {
      label = 'Payday is today';
    } else if (daysLeft == 1) {
      label = 'Payday in 1 day';
    } else {
      label = 'Payday in $daysLeft days';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today,
              size: 18,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next payday',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandedContent(List<Budget> oversTop, List<Budget> undersTop, NumberFormat currency, DateTime selectedMonth) {
    List<Widget> widgets = [];
    
    if (oversTop.isNotEmpty) {
      widgets.addAll([
        Text(
          'Overspent Categories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...oversTop.asMap().entries.map((entry) {
          final index = entry.key;
          final budget = entry.value;
          return _buildCategoryItem(budget, index, currency, true);
        }),
        const SizedBox(height: 16),
      ]);
    }
    
    if (undersTop.isNotEmpty) {
      widgets.addAll([
        Text(
          'Underspent Categories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...undersTop.asMap().entries.map((entry) {
          final index = entry.key + oversTop.length;
          final budget = entry.value;
          return _buildCategoryItem(budget, index, currency, false);
        }),
        const SizedBox(height: 16),
      ]);
    }
    
    return widgets;
  }

  Widget _buildCategoryItem(Budget budget, int index, NumberFormat currency, bool isOverspent) {
    final color = isOverspent ? Colors.red : Colors.green;
    final progressPercentage = budget.amount > 0 ? (budget.spent / budget.amount * 100) : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOverspent ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: color.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  budget.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Budget: ${currency.format(budget.amount)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOverspent
                    ? '+${currency.format(budget.spent - budget.amount)}'
                    : currency.format(budget.amount - budget.spent),
                style: TextStyle(
                  color: color.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                isOverspent ? 'over budget' : 'remaining',
                style: TextStyle(
                  fontSize: 10,
                  color: color.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color.shade600,
                ),
              ),
              Text(
                currency.format(budget.spent),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) => _handleBudgetAction(value, budget),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit Budget'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Budget', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Icon(
              Icons.more_vert,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSummary(List<Budget> budgets) {
    final overBudgetCount = budgets.where((b) => b.spent > b.amount).length;
    final nearLimitCount = budgets.where((b) => b.spent > b.amount * 0.8 && b.spent <= b.amount).length;
    final onTrackCount = budgets.length - overBudgetCount - nearLimitCount;

    if (budgets.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Alert Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                child: _buildAlertSummaryItem(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  count: onTrackCount,
                  label: 'On Track',
                ),
              ),
              Flexible(
                child: _buildAlertSummaryItem(
                  icon: Icons.warning,
                  color: Colors.orange,
                  count: nearLimitCount,
                  label: 'Near Limit',
                ),
              ),
              Flexible(
                child: _buildAlertSummaryItem(
                  icon: Icons.error,
                  color: Colors.red,
                  count: overBudgetCount,
                  label: 'Over Budget',
                ),
              ),
            ],
          ),
          if (overBudgetCount > 0 || nearLimitCount > 0) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => NavigationService.navigateTo(AppConstants.budgetsRoute),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Review Budget Details →',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertSummaryItem({
    required IconData icon,
    required Color color,
    required int count,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _handleBudgetAction(String action, Budget budget) {
    _logger.info('Handling budget action: $action for budget: ${budget.category}');
    
    switch (action) {
      case 'edit':
        Navigator.pushNamed(
          context,
          AppConstants.addBudgetRoute,
          arguments: {'budget': budget, 'isEdit': true},
        );
        break;
      case 'delete':
        _showDeleteConfirmation(budget);
        break;
    }
  }

  void _showDeleteConfirmation(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete the ${budget.category} budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBudget(budget);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(Budget budget) async {
    try {
      final budgetVm = Provider.of<BudgetViewModel>(context, listen: false);
      await budgetVm.deleteBudget(budget.id ?? '');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${budget.category} budget deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _logger.info('Budget deleted successfully: ${budget.category}');
    } catch (e) {
      _logger.severe('Error deleting budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting budget: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
