import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../income/income_screen.dart';
import '../../expenses/expenses_screen.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../viewmodels/income_viewmodel.dart';
import '../../../viewmodels/budget_viewmodel.dart';
import '../../../services/logger_service.dart';
import '../../../utils/currency_extensions.dart';

/// Enhanced dashboard financial summary widget with modern UI and interactions
class EnhancedMonthlySummary extends StatefulWidget {
  final DateTime selectedMonth;

  const EnhancedMonthlySummary({
    super.key,
    required this.selectedMonth,
  });

  @override
  State<EnhancedMonthlySummary> createState() => _EnhancedMonthlySummaryState();
}

class _EnhancedMonthlySummaryState extends State<EnhancedMonthlySummary>
    with TickerProviderStateMixin {
  late AnimationController _counterController;
  late AnimationController _progressController;
  late AnimationController _expandController;
  
  late Animation<double> _incomeAnimation;
  late Animation<double> _expenseAnimation;
  late Animation<double> _savingsAnimation;
  late Animation<double> _progressAnimation;
  
  bool _isExpanded = false;
  DateTime? _lastLoadedMonth;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _incomeAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _expenseAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));
    
    _savingsAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    
    // Start animations
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _counterController.forward();
        _progressController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _counterController.dispose();
    _progressController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  void didUpdateWidget(EnhancedMonthlySummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      _loadDataForMonth();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDataForMonth();
  }

  void _loadDataForMonth() {
    if (_lastLoadedMonth == null || 
        _lastLoadedMonth!.year != widget.selectedMonth.year ||
        _lastLoadedMonth!.month != widget.selectedMonth.month) {
      _lastLoadedMonth = widget.selectedMonth;
      
      final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
      final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
      final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
      
      // Defer stateful ViewModel updates to after the current frame
      // to avoid ChangeNotifier notifications during the build phase.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        incomeViewModel.setSelectedMonth(widget.selectedMonth);
        transactionViewModel.loadTransactionsByMonth(widget.selectedMonth);
        budgetViewModel.loadBudgetsForMonth(widget.selectedMonth);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<IncomeViewModel, TransactionViewModel, BudgetViewModel>(
      builder: (
        context,
        incomeViewModel,
        transactionViewModel,
        budgetViewModel,
        child,
      ) {
        // Get data for selected month
        final monthlyIncome = _getMonthlyIncome(incomeViewModel);
        final monthlyExpenses = _getMonthlyExpenses(transactionViewModel);
        final monthlyBudget = _getMonthlyBudget(budgetViewModel);
        final savings = monthlyIncome - monthlyExpenses;

        // Get previous month data for comparison
        final previousMonth = DateTime(
          widget.selectedMonth.year,
          widget.selectedMonth.month - 1,
        );
        final previousIncome =
            _getPreviousMonthIncome(incomeViewModel, previousMonth);
        final previousExpenses =
            _getPreviousMonthExpenses(transactionViewModel, previousMonth);

        currencyFormat(value) => value.toKenyaDualCurrency();
        final savingsRate =
            monthlyIncome > 0 ? (savings / monthlyIncome * 100) : 0.0;
        final daysInMonth = DateTime(
          widget.selectedMonth.year,
          widget.selectedMonth.month + 1,
          0,
        ).day;
        final dailyBurnRate = monthlyExpenses / daysInMonth;
        final projectedExpenses = dailyBurnRate * daysInMonth;

        // Update animations with real data
        _updateAnimations(monthlyIncome, monthlyExpenses, savings);

        return AnimatedBuilder(
          animation: Listenable.merge(
            [_counterController, _progressController, _expandController],
          ),
          builder: (context, child) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerHighest,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha:0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha:0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 8),
                    _buildStatusChips(
                      context,
                      monthlyIncome,
                      monthlyExpenses,
                      monthlyBudget,
                      savingsRate,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      context,
                      currencyFormat,
                      monthlyIncome,
                      monthlyExpenses,
                      savings,
                      previousIncome,
                      previousExpenses,
                      monthlyBudget,
                    ),
                    const SizedBox(height: 20),
                    _buildProgressBars(
                      context,
                      monthlyIncome,
                      monthlyExpenses,
                      savings,
                    ),
                    const SizedBox(height: 16),
                    _buildSpendingVelocityGauge(
                      context,
                      dailyBurnRate,
                      projectedExpenses,
                      monthlyBudget,
                    ),
                    const SizedBox(height: 16),
                    _buildInsightsSection(context, savingsRate),
                    if (_isExpanded)
                      ..._buildExpandedContent(
                        context,
                        monthlyIncome,
                        monthlyExpenses,
                        savings,
                        monthlyBudget,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This month at a glance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(widget.selectedMonth),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _toggleExpanded,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isExpanded
                  ? colorScheme.primary.withValues(alpha:0.12)
                  : colorScheme.surfaceContainerHighest.withValues(alpha:0.9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _isExpanded
                    ? colorScheme.primary.withValues(alpha:0.5)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips(
    BuildContext context,
    double income,
    double expenses,
    double? budget,
    double savingsRate,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<Widget> chips = [];

    if (budget != null && budget > 0) {
      final ratio = budget > 0 ? expenses / budget : 0.0;
      String label;
      Color background;
      Color foreground;
      IconData icon;

      if (ratio >= 1.0) {
        label = 'Over budget this month';
        background = colorScheme.errorContainer;
        foreground = colorScheme.onErrorContainer;
        icon = Icons.warning_amber_rounded;
      } else if (ratio >= 0.8) {
        label = 'Close to your budget';
        background = colorScheme.tertiaryContainer;
        foreground = colorScheme.onTertiaryContainer;
        icon = Icons.flag_rounded;
      } else {
        label = 'On track vs budget';
        background = colorScheme.secondaryContainer;
        foreground = colorScheme.onSecondaryContainer;
        icon = Icons.check_circle_rounded;
      }

      chips.add(
        _buildStatusChip(
          theme,
          label,
          icon,
          background,
          foreground,
        ),
      );
    }

    if (income > 0) {
      String label;
      Color background;
      Color foreground;
      IconData icon;

      if (savingsRate >= 20) {
        label = 'Strong savings this month';
        background = colorScheme.primaryContainer;
        foreground = colorScheme.onPrimaryContainer;
        icon = Icons.trending_up_rounded;
      } else if (savingsRate >= 10) {
        label = 'Good progress, keep going';
        background = colorScheme.secondaryContainer;
        foreground = colorScheme.onSecondaryContainer;
        icon = Icons.trending_up_rounded;
      } else if (savingsRate >= 0) {
        label = 'Low savings, review expenses';
        background = colorScheme.surfaceContainerHighest;
        foreground = colorScheme.onSurfaceVariant;
        icon = Icons.info_outline_rounded;
      } else {
        label = 'Spending more than you earn';
        background = colorScheme.errorContainer;
        foreground = colorScheme.onErrorContainer;
        icon = Icons.error_outline_rounded;
      }

      chips.add(
        _buildStatusChip(
          theme,
          label,
          icon,
          background,
          foreground,
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildStatusChip(
    ThemeData theme,
    String label,
    IconData icon,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, Function currencyFormat, double income, double expenses, double savings, double? previousIncome, double? previousExpenses, double? budget) {
    final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    final mpesaFees = _getMonthlyMpesaFees(transactionViewModel);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEnhancedSummaryItem(
                context,
                'Income',
                _incomeAnimation.value,
                Icons.trending_up,
                [Colors.green.shade400, Colors.green.shade600],
                previousIncome,
                0,
                () => _navigateToScreen(context, const IncomeScreen()),
                budget,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnhancedSummaryItem(
                context,
                'Expenses',
                _expenseAnimation.value,
                Icons.trending_down,
                [Colors.red.shade400, Colors.red.shade600],
                previousExpenses,
                1,
                () => _navigateToScreen(context, const ExpensesScreen()),
                budget,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEnhancedSummaryItem(
                context,
                'Net',
                _savingsAnimation.value,
                Icons.account_balance_wallet,
                [Colors.blue.shade400, Colors.blue.shade600],
                null,
                2,
                null,
                budget,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEnhancedSummaryItem(
                context,
                'M-Pesa fees',
                mpesaFees,
                Icons.receipt_long,
                [Colors.orange.shade400, Colors.orange.shade600],
                null,
                3,
                null,
                budget,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _getMonthlyMpesaFees(TransactionViewModel transactionViewModel) {
    final transactions = transactionViewModel.transactions;
    double total = 0.0;

    for (final t in transactions) {
      if (t.date.year != widget.selectedMonth.year ||
          t.date.month != widget.selectedMonth.month) {
        continue;
      }
      if (!t.isExpense) continue;

      final text = '${t.title} ${t.description ?? ''} ${t.category}'.toLowerCase();
      final isFee = text.contains('fee') ||
          text.contains('charges') ||
          text.contains('transaction cost') ||
          (text.contains('mpesa') && text.contains('charge'));
      if (!isFee) continue;

      total += t.amount.abs();
    }

    return total;
  }

  Widget _buildEnhancedSummaryItem(BuildContext context, String title, double amount, IconData icon, List<Color> gradientColors, double? previousAmount, int index, VoidCallback? onTap, double? budget) {
    final isSelected = _selectedIndex == index;
    final budgetPercentage = budget != null && budget > 0 ? (amount / budget) : 0.0;

    double changePercentage = 0.0;
    if (previousAmount != null && previousAmount > 0) {
      changePercentage = ((amount - previousAmount) / previousAmount) * 100;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedIndex = isSelected ? -1 : index;
        });
        if (onTap != null) onTap();
      },
      child: MouseRegion(
        onEnter: (_) {
          if (mounted) {
            setState(() => _selectedIndex = index);
          }
        },
        onExit: (_) {
          if (mounted) {
            setState(() => _selectedIndex = -1);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSelected ? gradientColors : [
                  gradientColors[0].withValues(alpha: 0.12),
                  gradientColors[1].withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? gradientColors[1].withValues(alpha: 0.4) : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: gradientColors[1].withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.24) : gradientColors[0].withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : gradientColors[1],
                        size: 20,
                      ),
                    ),
                    if (budget != null && title == 'Expenses') _buildMiniProgressRing(budgetPercentage, gradientColors[1]),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount.toKenyaDualCurrency(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                if (previousAmount != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        changePercentage >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isSelected ? Colors.white.withValues(alpha: 0.85) : (changePercentage >= 0 ? Colors.green : Colors.red),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${changePercentage.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white.withValues(alpha: 0.85) : (changePercentage >= 0 ? Colors.green : Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniProgressRing(double percentage, Color color) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        value: math.min(percentage, 1.0) * _progressAnimation.value,
        strokeWidth: 3,
        backgroundColor: color.withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(percentage > 1.0 ? Colors.red : color),
      ),
    );
  }

  Widget _buildProgressBars(BuildContext context, double income, double expenses, double savings) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalFlow = income;
    final expensePercentage = totalFlow > 0 ? (expenses / totalFlow) : 0.0;
    final savingsPercentage = totalFlow > 0 ? (savings / totalFlow) : 0.0;

    final adjustedExpensePercentage = math.min(expensePercentage, 1.0);
    final adjustedSavingsPercentage = savingsPercentage > 0 ? math.min(savingsPercentage, 1.0 - adjustedExpensePercentage) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Flow Breakdown',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          ),
          child: Row(
            children: [
              Expanded(
                flex: (adjustedExpensePercentage * 100 * _progressAnimation.value).round(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: (adjustedSavingsPercentage * 100 * _progressAnimation.value).round(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: math.max(0, (100 - (adjustedExpensePercentage + adjustedSavingsPercentage) * 100 * _progressAnimation.value).round()),
                child: Container(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem('Expenses', Colors.red.shade500, '${(adjustedExpensePercentage * 100).toStringAsFixed(1)}%'),
            _buildLegendItem('Savings', Colors.blue.shade500, '${(adjustedSavingsPercentage * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Row(
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
          '$label ($percentage)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingVelocityGauge(BuildContext context, double dailyBurnRate, double projectedExpenses, double? budget) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final velocityPercentage = budget != null && budget > 0 ? (projectedExpenses / budget) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiary.withValues(alpha: 0.05),
            colorScheme.tertiary.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.speed,
              color: colorScheme.tertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Burn Rate',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.tertiary,
                  ),
                ),
                Text(
                  '${dailyBurnRate.toKenyaDualCurrency()}/day',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (budget != null) Text(
                  'Projected: ${projectedExpenses.toKenyaDualCurrency()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (budget != null && budget > 0) SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: math.min(velocityPercentage, 1.0) * _progressAnimation.value,
              strokeWidth: 4,
              backgroundColor: colorScheme.tertiary.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(velocityPercentage > 1.0 ? colorScheme.error : colorScheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(BuildContext context, double savingsRate) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.05),
            colorScheme.primary.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Insight',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'Savings rate: ${savingsRate.toStringAsFixed(1)}%. ${savingsRate >= 20 ? 'Excellent financial discipline!' : savingsRate >= 10 ? 'Good progress, aim for 20%+' : 'Consider reducing expenses'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExpandedContent(BuildContext context, double income, double expenses, double savings, double? budget) {
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Total Income', income, Colors.green),
            _buildDetailRow('Total Expenses', expenses, Colors.red),
            _buildDetailRow('Net Savings', savings, Colors.blue),
            if (budget != null && budget > 0) ...[
              const Divider(),
              _buildDetailRow('Budget Remaining', budget - expenses, budget > expenses ? Colors.green : Colors.red),
              _buildDetailRow('Budget Utilization', (expenses / budget) * 100, Colors.purple, isPercentage: true),
              _buildDetailRow('Monthly Budget', budget, Colors.grey),
            ],
          ],
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.3, end: 0),
    ];
  }

  Widget _buildDetailRow(String label, double value, Color color, {bool isPercentage = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            isPercentage ? '${value.toStringAsFixed(1)}%' : value.toKenyaDualCurrency(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _updateAnimations(double income, double expenses, double savings) {
    _incomeAnimation = Tween<double>(
      begin: 0,
      end: income,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _expenseAnimation = Tween<double>(
      begin: 0,
      end: expenses,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));
    
    _savingsAnimation = Tween<double>(
      begin: 0,
      end: savings,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));
  }
  
  double _getMonthlyIncome(IncomeViewModel incomeViewModel) {
    // Get income for selected month from IncomeViewModel
    final incomeSources = incomeViewModel.getFilteredIncomeSources();
    return incomeSources.fold(0.0, (sum, source) => sum + source.amount);
  }
  
  double _getMonthlyExpenses(TransactionViewModel transactionViewModel) {
    // Get expenses for selected month from TransactionViewModel
    final transactions = transactionViewModel.transactions;
    return transactions
        .where((t) => t.type.toString().contains('expense') &&
                     t.date.year == widget.selectedMonth.year &&
                     t.date.month == widget.selectedMonth.month)
        .fold(0.0, (sum, transaction) => sum + transaction.amount.abs());
  }
  
  double? _getMonthlyBudget(BudgetViewModel budgetViewModel) {
    // Get all budgets for selected month from BudgetViewModel
    final budgets = budgetViewModel.budgets;
    final monthBudgets = budgets.where((budget) => 
        budget.startDate.month == widget.selectedMonth.month &&
        budget.startDate.year == widget.selectedMonth.year);
  
    // Sum all category budgets for the month to get total monthly budget
    final totalMonthlyBudget = monthBudgets.fold(0.0, (sum, budget) => sum + budget.amount);
  
    // Log budget calculation details
    final logger = Logger('EnhancedMonthlySummary');
    logger.info('Budget calculation: Found ${budgets.length} total budgets');
    logger.info('Budget calculation: Found ${monthBudgets.length} budgets for ${widget.selectedMonth.month}/${widget.selectedMonth.year}');
    logger.info('Budget calculation: Total monthly budget amount: $totalMonthlyBudget');
  
    return totalMonthlyBudget > 0 ? totalMonthlyBudget : null;
  }
  
  double? _getPreviousMonthIncome(IncomeViewModel incomeViewModel, DateTime previousMonth) {
    // This would need to be implemented based on how IncomeViewModel stores historical data
    // For now, return null to indicate no previous data available
    return null;
  }
  
  double? _getPreviousMonthExpenses(TransactionViewModel transactionViewModel, DateTime previousMonth) {
    // Get expenses for previous month from TransactionViewModel
    final transactions = transactionViewModel.transactions;
    final previousExpenses = transactions
        .where((t) => t.type.toString().contains('expense') &&
                     t.date.year == previousMonth.year &&
                     t.date.month == previousMonth.month)
        .fold(0.0, (sum, transaction) => sum + transaction.amount.abs());
    return previousExpenses > 0 ? previousExpenses : null;
  }
}
