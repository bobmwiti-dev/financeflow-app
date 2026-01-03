import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../utils/currency_extensions.dart';

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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
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
        
        final double totalBudget =
            budgetsWithRealData.fold(0.0, (sum, b) => sum + b.amount);
        final double totalSpent =
            budgetsWithRealData.fold(0.0, (sum, b) => sum + b.spent);
        final double ratio = totalBudget > 0 ? totalSpent / totalBudget : 0;
        
        _logger.info('Total budget: KES ${totalBudget.toStringAsFixed(2)}, Total spent: KES ${totalSpent.toStringAsFixed(2)}, Ratio: ${(ratio * 100).toStringAsFixed(1)}%');
        
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.surface,
                        colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: colorScheme.outlineVariant
                          .withValues(alpha: 0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(context, ratio, selectedMonth),
                        _buildProgressBar(ratio, context),
                        _buildLegendRow(context, ratio),
                        _buildSummaryContainer(context, totalSpent, totalBudget, ratio),
                        if (_isExpanded)
                          ..._buildExpandedContent(
                            context,
                            oversTop,
                            undersTop,
                            selectedMonth,
                          ),
                        _buildPayDayContainer(context, daysLeft),
                        _buildAlertSummary(context, budgetsWithRealData),
                      ],
                    ),
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

  Widget _buildHeader(BuildContext context, double ratio, DateTime selectedMonth) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (ratio <= 0.8) {
      statusColor = colorScheme.primary;
      statusIcon = Icons.check_circle;
      statusText = 'On Track';
    } else if (ratio <= 1.0) {
      statusColor = colorScheme.tertiary;
      statusIcon = Icons.warning;
      statusText = 'Near Limit';
    } else {
      statusColor = colorScheme.error;
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
              color: statusColor.withValues(alpha: 0.12),
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
                Text(
                  'Budget Adherence',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      statusText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $monthName',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              NavigationService.navigateTo(AppConstants.budgetsRoute);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Manage',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
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
                            ? [colorScheme.error, colorScheme.error.withValues(alpha: 0.8)]
                            : ratio > 0.75
                                ? [
                                    colorScheme.tertiary,
                                    colorScheme.tertiary.withValues(alpha: 0.8),
                                  ]
                                : [
                                    colorScheme.primary,
                                    colorScheme.primary.withValues(alpha: 0.8),
                                  ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (ratio > 1.0
                                  ? colorScheme.error
                                  : ratio > 0.75
                                      ? colorScheme.tertiary
                                      : colorScheme.primary)
                              .withValues(alpha: 0.3),
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

  Widget _buildLegendRow(BuildContext context, double ratio) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: _buildLegendDot(colorScheme.primary, 'Good', ratio <= 0.75),
          ),
          Flexible(
            child: _buildLegendDot(
              colorScheme.tertiary,
              'Caution',
              ratio > 0.75 && ratio <= 1.0,
            ),
          ),
          Flexible(
            child:
                _buildLegendDot(colorScheme.error, 'Over', ratio > 1.0),
          ),
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

  Widget _buildSummaryContainer(
    BuildContext context,
    double totalSpent,
    double totalBudget,
    double ratio,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                    'Spent',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalSpent.toKenyaDualCurrency(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          ratio > 1.0 ? colorScheme.error : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Progress',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ratio > 1.0
                          ? colorScheme.errorContainer
                          : ratio > 0.75
                              ? colorScheme.tertiaryContainer
                              : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(ratio * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ratio > 1.0
                            ? colorScheme.onErrorContainer
                            : ratio > 0.75
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onPrimaryContainer,
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalBudget.toKenyaDualCurrency(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
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
                color: totalBudget - totalSpent >= 0
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                totalBudget - totalSpent >= 0
                    ? 'Remaining: ${(totalBudget - totalSpent).toKenyaDualCurrency()}'
                    : 'Over budget by: ${(totalSpent - totalBudget).abs().toKenyaDualCurrency()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: totalBudget - totalSpent >= 0
                      ? colorScheme.primary
                      : colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayDayContainer(BuildContext context, int daysLeft) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primaryContainer.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next payday',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandedContent(
    BuildContext context,
    List<Budget> oversTop,
    List<Budget> undersTop,
    DateTime selectedMonth,
  ) {
    final theme = Theme.of(context);
    List<Widget> widgets = [];
    
    if (oversTop.isNotEmpty) {
      widgets.addAll([
        Text(
          'Overspent Categories',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        ...oversTop.asMap().entries.map((entry) {
          final index = entry.key;
          final budget = entry.value;
          return _buildCategoryItem(context, budget, index, true);
        }),
        const SizedBox(height: 16),
      ]);
    }
    
    if (undersTop.isNotEmpty) {
      widgets.addAll([
        Text(
          'Underspent Categories',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...undersTop.asMap().entries.map((entry) {
          final index = entry.key + oversTop.length;
          final budget = entry.value;
          return _buildCategoryItem(context, budget, index, false);
        }),
        const SizedBox(height: 16),
      ]);
    }
    
    return widgets;
  }

  Widget _buildCategoryItem(
    BuildContext context,
    Budget budget,
    int index,
    bool isOverspent,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color color = isOverspent ? colorScheme.error : colorScheme.primary;
    final progressPercentage = budget.amount > 0 ? (budget.spent / budget.amount * 100) : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOverspent ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: color,
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Budget: ${budget.amount.toKenyaDualCurrency()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
                    ? '+${(budget.spent - budget.amount).toKenyaDualCurrency()}'
                    : (budget.amount - budget.spent).toKenyaDualCurrency(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                isOverspent ? 'over budget' : 'remaining',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                budget.spent.toKenyaDualCurrency(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
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

  Widget _buildAlertSummary(BuildContext context, List<Budget> budgets) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final overBudgetCount = budgets.where((b) => b.spent > b.amount).length;
    final nearLimitCount = budgets.where((b) => b.spent > b.amount * 0.8 && b.spent <= b.amount).length;
    final onTrackCount = budgets.length - overBudgetCount - nearLimitCount;

    if (budgets.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Alert Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                child: _buildAlertSummaryItem(
                  icon: Icons.check_circle,
                  color: colorScheme.primary,
                  count: onTrackCount,
                  label: 'On Track',
                ),
              ),
              Flexible(
                child: _buildAlertSummaryItem(
                  icon: Icons.warning,
                  color: colorScheme.tertiary,
                  count: nearLimitCount,
                  label: 'Near Limit',
                ),
              ),
              Flexible(
                child: _buildAlertSummaryItem(
                  icon: Icons.error,
                  color: colorScheme.error,
                  count: overBudgetCount,
                  label: 'Over Budget',
                ),
              ),
            ],
          ),
          if (overBudgetCount > 0 || nearLimitCount > 0) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                NavigationService.navigateTo(AppConstants.budgetsRoute);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Review Budget Details →',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
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
