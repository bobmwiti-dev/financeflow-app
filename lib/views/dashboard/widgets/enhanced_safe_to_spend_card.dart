import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<IncomeViewModel, fixed.TransactionViewModel, BillViewModel, BudgetViewModel>(
      builder: (context, incomeVM, transactionVM, billVM, budgetVM, child) {
        final safeToSpendData = _calculateSafeToSpend(incomeVM, transactionVM, billVM, budgetVM);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _showBreakdown = !_showBreakdown;
            });
            if (_showBreakdown) {
              _slideController.forward();
            } else {
              _slideController.reverse();
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
                  safeToSpendData['color'].withValues(alpha: 0.8),
                  safeToSpendData['color'].withValues(alpha: 0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: safeToSpendData['color'].withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              constraints: BoxConstraints(
                minHeight: 140,
                maxHeight: _showBreakdown ? 380 : 140,
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
        ).animate()
          .fadeIn(duration: 600.ms)
          .slideX(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safe to Spend',
              style: TextStyle(
                color: Colors.white.withValues(alpha:0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              data['subtitle'],
              style: TextStyle(
                color: Colors.white.withValues(alpha:0.7),
                fontSize: 12,
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
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.05),
              child: Text(
                currencyFormat.format(data['amount']),
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
      ],
    );
  }

  Widget _buildProgressBar(Map<String, dynamic> data) {
    final totalIncome = data['income'] as double;
    final safeAmount = data['amount'] as double;
    final progressValue = totalIncome > 0 ? (safeAmount / totalIncome).clamp(0.0, 1.0) : 0.0;
    
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
        AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            return Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressValue * _progressController.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
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
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
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
    String tip;
    IconData tipIcon;
    Color tipColor;

    if (safeAmount > 1000) {
      tip = "Great! You have plenty of room for discretionary spending.";
      tipIcon = Icons.thumb_up;
      tipColor = Colors.green.shade300;
    } else if (safeAmount > 500) {
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
      
      // Determine color and messaging based on amount
      Color cardColor;
      IconData cardIcon;
      IconData trendIcon;
      String subtitle;
      String trendText;
      
      if (safeToSpend > 1000) {
        cardColor = Colors.green;
        cardIcon = Icons.account_balance_wallet;
        trendIcon = Icons.trending_up;
        subtitle = 'You\'re doing great!';
        trendText = 'Healthy spending room';
      } else if (safeToSpend > 0) {
        cardColor = Colors.orange;
        cardIcon = Icons.warning_amber;
        trendIcon = Icons.trending_flat;
        subtitle = 'Watch your spending';
        trendText = 'Limited funds remaining';
      } else {
        cardColor = Colors.red;
        cardIcon = Icons.error_outline;
        trendIcon = Icons.trending_down;
        subtitle = 'Over budget this month';
        trendText = 'Consider reducing expenses';
      }
      
      // Trigger animations for visual feedback
      if (safeToSpend != 0) {
        _pulseController.forward(from: 0);
        _progressController.forward(from: 0);
      }
      
      return {
        'amount': safeToSpend,
        'income': monthlyIncome,
        'emergencyFund': emergencyFundAllocation,
        'savingsGoals': savingsGoalsAllocation,
        'debtPayments': debtPaymentsAllocation,
        'bills': upcomingBills,
        'spent': variableExpenses,
        'color': cardColor,
        'icon': cardIcon,
        'trendIcon': trendIcon,
        'subtitle': subtitle,
        'trendText': trendText,
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
      };
    }
  }
}
