import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../../viewmodels/income_viewmodel.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart' as fixed;
import '../../../viewmodels/bill_viewmodel.dart';
import '../../../viewmodels/budget_viewmodel.dart';

/// Enhanced Safe-to-Spend card inspired by Simplifi's "Always know what's left to spend"
/// Shows available money after bills, budgets, and savings goals with detailed breakdown
class EnhancedSafeToSpendCard extends StatefulWidget {
  final DateTime? selectedMonth;
  
  const EnhancedSafeToSpendCard({super.key, this.selectedMonth});

  @override
  State<EnhancedSafeToSpendCard> createState() => _EnhancedSafeToSpendCardState();
}

class _EnhancedSafeToSpendCardState extends State<EnhancedSafeToSpendCard> 
    with TickerProviderStateMixin {
  final Logger _logger = Logger('EnhancedSafeToSpendCard');
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late AnimationController _amountController;
  late AnimationController _sheenController;
  Animation<double>? _amountAnimation;
  double _displayAmount = 0.0;
  double? _lastTargetAmount;
  bool _showBreakdown = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _amountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _amountController.addListener(() {
      final anim = _amountAnimation;
      if (anim == null) return;
      if (!mounted) return;
      setState(() {
        _displayAmount = anim.value;
      });
    });

    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    _amountController.dispose();
    _sheenController.dispose();
    super.dispose();
  }

  void _toggleBreakdown({bool? show}) {
    setState(() {
      _showBreakdown = show ?? !_showBreakdown;
    });
    HapticFeedback.selectionClick();
    if (_showBreakdown) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
  }

  void _scheduleAnimations(Map<String, dynamic> safeToSpendData) {
    final amount = (safeToSpendData['amount'] as double?) ?? 0.0;
    final income = (safeToSpendData['income'] as double?) ?? 0.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_lastTargetAmount != null && (_lastTargetAmount! - amount).abs() < 0.01) {
        return;
      }

      final previous = _displayAmount;
      _lastTargetAmount = amount;

      _amountAnimation = Tween<double>(
        begin: previous,
        end: amount,
      ).animate(CurvedAnimation(
        parent: _amountController,
        curve: Curves.easeOutCubic,
      ));
      _amountController.forward(from: 0);

      _pulseController.forward(from: 0);
      _progressController.forward(from: 0);

      final prevRatio = income > 0 ? (previous / income) : 0.0;
      final nextRatio = income > 0 ? (amount / income) : 0.0;
      final crossedTightThreshold = (prevRatio >= 0.10 && nextRatio < 0.10) ||
          (prevRatio < 0.10 && nextRatio >= 0.10);
      final crossedZero = (previous >= 0 && amount < 0) || (previous < 0 && amount >= 0);
      if (crossedTightThreshold || crossedZero) {
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<IncomeViewModel, fixed.TransactionViewModel, BillViewModel, BudgetViewModel>(
      builder: (context, incomeVM, transactionVM, billVM, budgetVM, child) {
        final safeToSpendData = _calculateSafeToSpend(incomeVM, transactionVM, billVM, budgetVM);
        _scheduleAnimations(safeToSpendData);

        final colorScheme = Theme.of(context).colorScheme;
        final baseColor = safeToSpendData['color'] as Color;
        final topColor = Color.lerp(baseColor, Colors.black, 0.10) ?? baseColor;
        final bottomColor = Color.lerp(baseColor, Colors.black, 0.28) ?? baseColor;
        
        return GestureDetector(
          onVerticalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -100) {
              _toggleBreakdown(show: true);
            } else if (v > 100) {
              _toggleBreakdown(show: false);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            constraints: const BoxConstraints(
              maxWidth: 400,
              minHeight: 140,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  topColor.withValues(alpha: 0.95),
                  bottomColor.withValues(alpha: 0.92),
                ],
              ),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withValues(alpha: 0.10),
                highlightColor: Colors.white.withValues(alpha: 0.06),
                onTap: () => _toggleBreakdown(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  constraints: BoxConstraints(
                    minHeight: 140,
                    maxHeight: _showBreakdown ? 420 : 140,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(safeToSpendData),
                        const SizedBox(height: 12),
                        _buildMainAmount(safeToSpendData),
                        const SizedBox(height: 8),
                        _buildProgressBar(safeToSpendData),
                        if (_showBreakdown) ...[
                          const SizedBox(height: 16),
                          _buildEnhancedBreakdown(safeToSpendData),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ).animate()
          .fadeIn(duration: 600.ms)
          .slideX(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final label = (data['statusLabel'] as String?) ?? '';
    final statusColor = (data['statusColor'] as Color?) ?? Colors.white;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Safe to Spend',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              data['subtitle'],
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            data['icon'],
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildMainAmount(Map<String, dynamic> data) {
    final currencyFormat = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    final insightLine = (data['insightLine'] as String?) ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.05),
              child: Text(
                currencyFormat.format(_displayAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              data['trendIcon'],
              color: Colors.white.withValues(alpha:0.8),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              data['trendText'],
              style: TextStyle(
                color: Colors.white.withValues(alpha:0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (insightLine.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            insightLine,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(Map<String, dynamic> data) {
    final totalIncome = data['income'] as double;
    final safeAmount = data['amount'] as double;
    final progressValue = totalIncome > 0 ? (safeAmount / totalIncome).clamp(0.0, 1.0) : 0.0;
    final currencyFormat = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progressValue * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Tooltip(
          message:
              '${currencyFormat.format(safeAmount)} of ${currencyFormat.format(totalIncome)} income',
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressValue * _progressController.value,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: Colors.white),
                            if (progressValue > 0.05)
                              AnimatedBuilder(
                                animation: _sheenController,
                                builder: (context, _) {
                                  final w = constraints.maxWidth;
                                  const sheenWidth = 22.0;
                                  final x = (w + sheenWidth) * _sheenController.value - sheenWidth;
                                  return Transform.translate(
                                    offset: Offset(x, 0),
                                    child: Container(
                                      width: sheenWidth,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.0),
                                            Colors.white.withValues(alpha: 0.55),
                                            Colors.white.withValues(alpha: 0.0),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedBreakdown(Map<String, dynamic> data) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideController.value) * 10),
          child: Opacity(
            opacity: _slideController.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Breakdown',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEnhancedBreakdownItem(
                    'Total Income',
                    data['income'],
                    Icons.trending_up,
                    Colors.green.shade300,
                    isPositive: true,
                  ),
                  const SizedBox(height: 8),
                  _buildEnhancedBreakdownItem(
                    'Emergency Fund',
                    data['emergencyFund'] ?? 0.0,
                    Icons.security,
                    Colors.blue.shade300,
                    isPositive: false,
                  ),
                  const SizedBox(height: 8),
                  _buildEnhancedBreakdownItem(
                    'Savings Goals',
                    data['savingsGoals'] ?? 0.0,
                    Icons.savings,
                    Colors.teal.shade300,
                    isPositive: false,
                  ),
                  const SizedBox(height: 8),
                  _buildEnhancedBreakdownItem(
                    'Debt Payments',
                    data['debtPayments'] ?? 0.0,
                    Icons.credit_card_off,
                    Colors.deepOrange.shade300,
                    isPositive: false,
                  ),
                  const SizedBox(height: 8),
                  _buildEnhancedBreakdownItem(
                    'Fixed Bills',
                    data['bills'],
                    Icons.receipt_long,
                    Colors.red.shade300,
                    isPositive: false,
                  ),
                  const SizedBox(height: 8),
                  _buildEnhancedBreakdownItem(
                    'Variable Expenses',
                    data['spent'],
                    Icons.shopping_cart,
                    Colors.purple.shade300,
                    isPositive: false,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  _buildEnhancedBreakdownItem(
                    'Available to Spend',
                    data['amount'],
                    Icons.account_balance_wallet,
                    Colors.white,
                    isPositive: true,
                    isTotal: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSpendingTips(data),
                  const SizedBox(height: 8),
                  _buildBreakdownActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedBreakdownItem(
    String label,
    double amount,
    IconData icon,
    Color color, {
    bool isPositive = false,
    bool isTotal = false,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: isTotal ? 14 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${currencyFormat.format(amount)}',
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.white.withValues(alpha: 0.8),
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTips(Map<String, dynamic> data) {
    final safeAmount = data['amount'] as double;
    final totalIncome = (data['income'] as double?) ?? 0.0;
    final ratio = totalIncome > 0 ? (safeAmount / totalIncome) : 0.0;
    String tip;
    IconData tipIcon;
    Color tipColor;

    if (ratio >= 0.20) {
      tip = "Great! You have plenty of room for discretionary spending.";
      tipIcon = Icons.thumb_up;
      tipColor = Colors.green.shade300;
    } else if (ratio >= 0.10) {
      tip = "Good position. Consider setting aside some for savings.";
      tipIcon = Icons.savings;
      tipColor = Colors.blue.shade300;
    } else if (safeAmount > 0) {
      tip = "Be mindful of spending. You're close to your limit.";
      tipIcon = Icons.warning_amber;
      tipColor = Colors.orange.shade300;
    } else {
      tip = "You've exceeded your safe spending limit this month.";
      tipIcon = Icons.error_outline;
      tipColor = Colors.red.shade300;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tipColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            tipIcon,
            color: tipColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/bills'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.9),
          ),
          child: const Text('Review bills'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/budgets'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.9),
          ),
          child: const Text('Adjust budgets'),
        ),
      ],
    );
  }


  Map<String, dynamic> _calculateSafeToSpend(
    IncomeViewModel incomeVM,
    fixed.TransactionViewModel transactionVM,
    BillViewModel billVM,
    BudgetViewModel budgetVM,
  ) {
    try {
      // Use selected month or current month
      final targetMonth = widget.selectedMonth ?? DateTime.now();
      
      // Calculate income for selected month
      final monthlyIncome = incomeVM.incomeSources
          .where((income) => income.date.year == targetMonth.year && 
                           income.date.month == targetMonth.month)
          .fold(0.0, (sum, income) => sum + income.amount);
      
      // Calculate variable expenses (excluding fixed bills and planned allocations)
      final variableExpenses = transactionVM.transactions
          .where((transaction) => 
              transaction.type.toString().contains('expense') &&
              transaction.date.year == targetMonth.year &&
              transaction.date.month == targetMonth.month)
          .fold(0.0, (sum, transaction) => sum + transaction.amount.abs());
      
      // Calculate upcoming bills for selected month
      final upcomingBills = billVM.bills
          .where((bill) => bill.dueDate.year == targetMonth.year && 
                 bill.dueDate.month == targetMonth.month)
          .fold(0.0, (sum, bill) => sum + bill.amount);
      
      // Calculate planned allocations as optional goals (not mandatory deductions)
      // These represent recommended allocations, not required expenses
      final emergencyFundAllocation = monthlyIncome * 0.10; // 10% recommended for emergency fund
      final savingsGoalsAllocation = monthlyIncome * 0.15; // 15% recommended for savings goals
      final debtPaymentsAllocation = monthlyIncome * 0.05; // 5% recommended for debt payments
      
      // Corrected calculation: Income - Only actual committed expenses (bills + variable expenses)
      // Safe to spend = what's left after real expenses, before optional allocations
      final committedExpenses = upcomingBills + variableExpenses;
      final safeToSpend = monthlyIncome - committedExpenses;

      final prevMonth = DateTime(targetMonth.year, targetMonth.month - 1, 1);
      final prevIncome = incomeVM.incomeSources
          .where((income) => income.date.year == prevMonth.year && income.date.month == prevMonth.month)
          .fold(0.0, (sum, income) => sum + income.amount);
      final prevVariableExpenses = transactionVM.transactions
          .where((transaction) =>
              transaction.type.toString().contains('expense') &&
              transaction.date.year == prevMonth.year &&
              transaction.date.month == prevMonth.month)
          .fold(0.0, (sum, transaction) => sum + transaction.amount.abs());
      final prevBills = billVM.bills
          .where((bill) => bill.dueDate.year == prevMonth.year && bill.dueDate.month == prevMonth.month)
          .fold(0.0, (sum, bill) => sum + bill.amount);
      final prevSafeToSpend = prevIncome - (prevBills + prevVariableExpenses);
      final delta = safeToSpend - prevSafeToSpend;
      
      // Determine color and messaging based on amount
      Color cardColor;
      IconData cardIcon;
      IconData trendIcon;
      String subtitle;
      String trendText;

      final currencyFormat = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
      if (delta.abs() < 1) {
        trendText = 'Same as last month';
        trendIcon = Icons.trending_flat;
      } else if (delta > 0) {
        trendText = 'Up ${currencyFormat.format(delta.abs())} vs last month';
        trendIcon = Icons.trending_up;
      } else {
        trendText = 'Down ${currencyFormat.format(delta.abs())} vs last month';
        trendIcon = Icons.trending_down;
      }
      
      if (safeToSpend > 1000) {
        cardColor = Colors.green;
        cardIcon = Icons.account_balance_wallet;
        subtitle = 'You\'re doing great!';
      } else if (safeToSpend > 0) {
        cardColor = Colors.orange;
        cardIcon = Icons.warning_amber;
        subtitle = 'Watch your spending';
      } else {
        cardColor = Colors.red;
        cardIcon = Icons.error_outline;
        subtitle = 'Over budget this month';
      }

      final ratio = monthlyIncome > 0 ? (safeToSpend / monthlyIncome) : 0.0;
      final statusLabel = safeToSpend <= 0
          ? 'Overspending risk'
          : (ratio < 0.10 ? 'Tight' : 'On track');
      final statusColor = safeToSpend <= 0
          ? Colors.red.shade200
          : (ratio < 0.10 ? Colors.orange.shade200 : Colors.green.shade200);

      final goalsSavings = emergencyFundAllocation + savingsGoalsAllocation + debtPaymentsAllocation;
      final avgDailySpend = variableExpenses > 0 ? (variableExpenses / 30.0) : 0.0;
      final daysCover = (avgDailySpend > 0 && safeToSpend > 0) ? (safeToSpend / avgDailySpend) : 0.0;
      final insightLine = safeToSpend <= 0
          ? 'Tight month — prioritize essentials and bills.'
          : (daysCover > 0 ? 'Covers about ${daysCover.toStringAsFixed(0)} days of typical spending.' : 'You\'re on track for the month.');
      
      return {
        'amount': safeToSpend,
        'income': monthlyIncome,
        'emergencyFund': emergencyFundAllocation,
        'savingsGoals': savingsGoalsAllocation,
        'debtPayments': debtPaymentsAllocation,
        'goalsSavings': goalsSavings,
        'bills': upcomingBills,
        'spent': variableExpenses,
        'color': cardColor,
        'icon': cardIcon,
        'trendIcon': trendIcon,
        'subtitle': subtitle,
        'trendText': trendText,
        'statusLabel': statusLabel,
        'statusColor': statusColor,
        'insightLine': insightLine,
      };
    } catch (e) {
      _logger.severe('Error calculating safe to spend: $e');
      return {
        'amount': 0.0,
        'income': 0.0,
        'bills': 0.0,
        'budgets': 0.0,
        'spent': 0.0,
        'color': Colors.grey,
        'icon': Icons.error,
        'trendIcon': Icons.help,
        'subtitle': 'Unable to calculate',
        'trendText': 'Data unavailable',
        'statusLabel': '',
        'statusColor': Colors.white,
        'insightLine': '',
      };
    }
  }
}
