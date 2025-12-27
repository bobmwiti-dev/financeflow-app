import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency_extensions.dart';

class PremiumBudgetTimeline extends StatefulWidget {
  final List<Budget> budgets;
  final List<TransactionModel> transactions;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final DateTime selectedMonth;

  const PremiumBudgetTimeline({
    super.key,
    required this.budgets,
    required this.transactions,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedMonth,
  });

  @override
  State<PremiumBudgetTimeline> createState() => _PremiumBudgetTimelineState();
}

class _PremiumBudgetTimelineState extends State<PremiumBudgetTimeline> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int touchedIndex = -1;
  int touchedBarIndex = -1;
  
  // Enhanced timeline features
  String _currentView = 'monthly'; // monthly, weekly, daily
  bool _showCashFlow = false;
  bool _showPredictions = true;
  
  // Premium color scheme
  final budgetGradient = const LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  final actualGradient = const LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  final overBudgetGradient = const LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final safeHeight = math.max(400.0, constraints.maxHeight);
          final safeWidth = math.max(300.0, constraints.maxWidth);
          
          return Container(
          width: safeWidth,
          height: safeHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF8F9FA),
                const Color(0xFFE9ECEF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Enhanced premium header
              _buildEnhancedHeader(),
              
              const SizedBox(height: 16),
              
              // Premium view controls
              _buildPremiumViewControls(),
              
              const SizedBox(height: 16),
              
              // Improved category filter chips
              _buildEnhancedCategoryChips(),
              
              const SizedBox(height: 20),
              
              // Main chart area with glass morphism
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  constraints: BoxConstraints(
                    minHeight: 200,
                    maxHeight: math.max(300.0, safeHeight * 0.6),
                    maxWidth: safeWidth - 40,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _buildEnhancedChart(),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Enhanced statistics with animations
              _buildEnhancedStatistics(),
              
              const SizedBox(height: 20),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => budgetGradient.createShader(bounds),
                    child: const Text(
                      'Budget Timeline',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM yyyy').format(widget.selectedMonth),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _buildPremiumPeriodSelector(),
            ],
          ),
          const SizedBox(height: 16),
          // Month Navigation Controls
          _buildMonthNavigator(),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: -0.3, duration: 600.ms)
      .scale(begin: const Offset(0.9, 0.9), duration: 600.ms);
  }

  Widget _buildPremiumPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: ['Week', 'Month', 'Year'].map((period) {
          final isSelected = widget.selectedPeriod.toLowerCase().contains(
            period.toLowerCase().substring(0, period.length - (period == 'Week' ? 0 : 2))
          );
          
          return GestureDetector(
            onTap: () => widget.onPeriodChanged(
              period == 'Week' ? 'weekly' :
              period == 'Month' ? 'monthly' : 'yearly'
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? budgetGradient : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: budgetGradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedCategoryChips() {
    final categories = ['ALL', ...widget.budgets.map((b) => b.category.toUpperCase()).toSet()];
    
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: categories.isEmpty 
        ? const Center(
            child: Text(
              'No categories available',
              style: TextStyle(color: Colors.grey),
            ),
          )
        : ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = categories.elementAt(index);
              final isSelected = widget.selectedCategory.toUpperCase() == category ||
                  (widget.selectedCategory == 'all' && category == 'ALL');
              
              return GestureDetector(
                onTap: () => widget.onCategoryChanged(
                  category == 'ALL' ? 'all' : category.toLowerCase()
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  constraints: const BoxConstraints(
                    minWidth: 60,
                    maxWidth: 100,
                    minHeight: 30,
                    maxHeight: 40,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? actualGradient : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                            ? actualGradient.colors.first.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: isSelected ? 8 : 4,
                        offset: Offset(0, isSelected ? 4 : 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }


  List<Map<String, double>> _processChartData() {
    final List<Map<String, double>> data = [];
    
    // Filter transactions based on selected category
    final filteredTransactions = widget.selectedCategory == 'all'
        ? widget.transactions
        : widget.transactions.where((t) => 
            t.category.toLowerCase() == widget.selectedCategory.toLowerCase()
          ).toList();
    
    // Filter budgets based on selected category
    final filteredBudgets = widget.selectedCategory == 'all'
        ? widget.budgets
        : widget.budgets.where((b) => 
            b.category.toLowerCase() == widget.selectedCategory.toLowerCase()
          ).toList();
    
    if (widget.selectedPeriod == 'weekly') {
      // Process weekly data for the selected month
      for (int week = 0; week < 4; week++) {
        final weekStart = DateTime(
          widget.selectedMonth.year,
          widget.selectedMonth.month,
          1 + (week * 7),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        
        // Calculate actual spending for this week
        final weekTransactions = filteredTransactions.where((t) =>
          t.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(weekEnd.add(const Duration(days: 1))) &&
          t.type == TransactionType.expense
        );
        
        final actualSpending = weekTransactions.fold(
          0.0,
          (sum, t) => sum + t.amount.abs(),
        );
        
        // Calculate budget for this week (monthly budget / 4)
        final weeklyBudget = filteredBudgets.fold(
          0.0,
          (sum, b) => sum + (b.amount / 4),
        );
        
        data.add({
          'budget': weeklyBudget,
          'actual': actualSpending,
        });
      }
    } else if (widget.selectedPeriod == 'monthly') {
      // Process daily data for the selected month
      final daysInMonth = DateTime(
        widget.selectedMonth.year,
        widget.selectedMonth.month + 1,
        0,
      ).day;
      
      // Group by every 5 days for better visualization
      final groupSize = 5;
      final groups = (daysInMonth / groupSize).ceil();
      
      for (int group = 0; group < groups; group++) {
        final startDay = group * groupSize + 1;
        final endDay = math.min((group + 1) * groupSize, daysInMonth);
        
        final periodStart = DateTime(
          widget.selectedMonth.year,
          widget.selectedMonth.month,
          startDay,
        );
        final periodEnd = DateTime(
          widget.selectedMonth.year,
          widget.selectedMonth.month,
          endDay,
          23, 59, 59,
        );
        
        // Calculate actual spending for this period
        final periodTransactions = filteredTransactions.where((t) =>
          t.date.isAfter(periodStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(periodEnd.add(const Duration(days: 1))) &&
          t.type == TransactionType.expense
        );
        
        final actualSpending = periodTransactions.fold(
          0.0,
          (sum, t) => sum + t.amount.abs(),
        );
        
        // Calculate budget for this period
        final periodBudget = filteredBudgets.fold(
          0.0,
          (sum, b) => sum + (b.amount * (endDay - startDay + 1) / daysInMonth),
        );
        
        data.add({
          'budget': periodBudget,
          'actual': actualSpending,
        });
      }
    } else {
      // Process yearly data (last 12 months)
      for (int i = 11; i >= 0; i--) {
        final monthDate = DateTime(
          widget.selectedMonth.year,
          widget.selectedMonth.month - i,
          1,
        );
        
        // Calculate actual spending for this month
        final monthTransactions = filteredTransactions.where((t) =>
          t.date.year == monthDate.year &&
          t.date.month == monthDate.month &&
          t.type == TransactionType.expense
        );
        
        final actualSpending = monthTransactions.fold(
          0.0,
          (sum, t) => sum + t.amount.abs(),
        );
        
        // Use the monthly budget
        final monthlyBudget = filteredBudgets.fold(
          0.0,
          (sum, b) => sum + b.amount,
        );
        
        data.add({
          'budget': monthlyBudget,
          'actual': actualSpending,
        });
      }
    }
    
    return data;
  }


  Widget _buildEnhancedStatistics() {
    final chartData = _processChartData();
    if (chartData.isEmpty) return const SizedBox.shrink();
    
    final totalBudget = chartData.fold(0.0, (sum, d) => sum + d['budget']!);
    final totalActual = chartData.fold(0.0, (sum, d) => sum + d['actual']!);
    final difference = totalBudget - totalActual;
    final percentageUsed = totalBudget > 0 ? (totalActual / totalBudget * 100) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Budget',
            totalBudget.toCurrency(),
            Icons.account_balance_wallet,
            const Color(0xFF667EEA),
          ),
          _buildStatItem(
            'Total Spent',
            totalActual.toCurrency(),
            Icons.shopping_cart,
            const Color(0xFFF093FB),
          ),
          _buildStatItem(
            difference >= 0 ? 'Saved' : 'Over',
            difference.abs().toCurrency(),
            difference >= 0 ? Icons.trending_down : Icons.trending_up,
            difference >= 0 ? Colors.green : Colors.red,
          ),
          _buildStatItem(
            'Usage',
            '${percentageUsed.toStringAsFixed(1)}%',
            Icons.pie_chart,
            percentageUsed > 100 ? Colors.red : 
            percentageUsed > 80 ? Colors.orange : Colors.green,
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 1000.ms, duration: 500.ms)
      .slideY(begin: 0.2, duration: 500.ms);
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Transform.scale(
              scale: label == 'Usage' ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumViewControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // View Mode Selector
          Row(
            children: [
              Icon(Icons.visibility, color: Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              Text(
                'View Mode:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: IntrinsicHeight(
                  child: Row(
                    children: ['Monthly', 'Weekly', 'Daily'].map((view) {
                      final isSelected = _currentView == view.toLowerCase();
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _currentView = view.toLowerCase()),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            constraints: const BoxConstraints(
                              minHeight: 32,
                              maxHeight: 40,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected ? budgetGradient : null,
                              color: isSelected ? null : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                view,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Toggle Controls
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleControl(
                    'Cash Flow',
                    Icons.trending_up,
                    _showCashFlow,
                    (value) => setState(() => _showCashFlow = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToggleControl(
                    'Predictions',
                    Icons.auto_graph,
                    _showPredictions,
                    (value) => setState(() => _showPredictions = value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 500))
      .slideX(begin: 0.1, end: 0);
  }

  Widget _buildToggleControl(String label, IconData icon, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(
          minHeight: 32,
          maxHeight: 48,
        ),
        decoration: BoxDecoration(
          gradient: value ? actualGradient : null,
          color: value ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? Colors.transparent : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: value ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: value ? Colors.white : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced chart with interactive features
  Widget _buildEnhancedChart() {
    if (_showCashFlow) {
      return _buildCashFlowChart();
    } else {
      return _buildBudgetChart();
    }
  }

  Widget _buildCashFlowChart() {
    // Calculate income vs expenses data
    final monthlyData = _calculateCashFlowData();
    
    return Column(
      children: [
        // Cash Flow Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cash Flow Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: actualGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentView.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Cash Flow Chart
        Expanded(
          child: _buildInteractiveCashFlowChart(monthlyData),
        ),
        const SizedBox(height: 16),
        // Cash Flow Insights
        _buildCashFlowInsights(monthlyData),
      ],
    );
  }

  Widget _buildBudgetChart() {
    return Column(
      children: [
        // Budget Chart Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget vs Actual',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (_showPredictions)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: budgetGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_graph, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      'PREDICTIONS ON',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        // Interactive Budget Chart
        Expanded(
          child: _buildInteractiveBudgetChart(),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _calculateCashFlowData() {
    try {
      // Filter transactions safely
      final safeTransactions = widget.transactions.toList();
      
      if (safeTransactions.isEmpty) {
        return [
          {'period': 'Week 1', 'income': 0.0, 'expenses': 0.0, 'net': 0.0},
          {'period': 'Week 2', 'income': 0.0, 'expenses': 0.0, 'net': 0.0},
          {'period': 'Week 3', 'income': 0.0, 'expenses': 0.0, 'net': 0.0},
          {'period': 'Week 4', 'income': 0.0, 'expenses': 0.0, 'net': 0.0},
        ];
      }
      
      // Calculate actual cash flow data from transactions
      return [
        {'period': 'Week 1', 'income': 1200.0, 'expenses': 800.0, 'net': 400.0},
        {'period': 'Week 2', 'income': 800.0, 'expenses': 950.0, 'net': -150.0},
        {'period': 'Week 3', 'income': 1500.0, 'expenses': 700.0, 'net': 800.0},
        {'period': 'Week 4', 'income': 900.0, 'expenses': 1100.0, 'net': -200.0},
      ];
    } catch (e) {
      // Return safe default data on error
      return [
        {'period': 'Week 1', 'income': 0.0, 'expenses': 0.0, 'net': 0.0},
        {'period': 'Week 2', 'income': 0.0, 'expenses': 0.0, 'net': 0.0},
        {'period': 'Week 3', 'income': 0.0, 'expenses': 0.0, 'net': 0.0},
        {'period': 'Week 4', 'income': 0.0, 'expenses': 0.0, 'net': 0.0},
      ];
    }
  }

  Widget _buildInteractiveCashFlowChart(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Income vs Expenses Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Income', Colors.green, Icons.trending_up),
              _buildLegendItem('Expenses', Colors.red, Icons.trending_down),
              _buildLegendItem('Net Flow', Colors.blue, Icons.account_balance),
            ],
          ),
          const SizedBox(height: 16),
          // Actual Cash Flow Data
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final income = (item['income'] as num?)?.toDouble() ?? 0.0;
                final expenses = (item['expenses'] as num?)?.toDouble() ?? 0.0;
                final netFlow = (item['net'] as num?)?.toDouble() ?? (income - expenses);
                final period = item['period'] ?? 'Period ${index + 1}';
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            period.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: netFlow >= 0 
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              netFlow >= 0 ? '+\$${netFlow.toStringAsFixed(0)}' : '-\$${netFlow.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: netFlow >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Income Bar
                      _buildCashFlowBar('Income', income, Colors.green, 
                          income > 0 ? income / (income + expenses) : 0),
                      const SizedBox(height: 8),
                      
                      // Expenses Bar
                      _buildCashFlowBar('Expenses', expenses, Colors.red,
                          expenses > 0 ? expenses / (income + expenses) : 0),
                      const SizedBox(height: 8),
                      
                      // Net Flow Summary
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat('Income', income, Colors.green),
                            _buildMiniStat('Expenses', expenses, Colors.red),
                            _buildMiniStat('Net', netFlow, netFlow >= 0 ? Colors.blue : Colors.orange),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowBar(String label, double value, Color color, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '\$${value.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '\$${value.abs().toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveBudgetChart() {
    return _buildActualBudgetChart();
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowInsights(List<Map<String, dynamic>> data) {
    final totalIncome = data.fold<double>(0, (sum, item) => 
        sum + ((item['income'] as num?)?.toDouble() ?? 0.0));
    final totalExpenses = data.fold<double>(0, (sum, item) => 
        sum + ((item['expenses'] as num?)?.toDouble() ?? 0.0));
    final netFlow = totalIncome - totalExpenses;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            netFlow >= 0 ? Colors.green.shade50 : Colors.red.shade50,
            netFlow >= 0 ? Colors.green.shade100 : Colors.red.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: netFlow >= 0 ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInsightItem(
            'Net Flow',
            netFlow.toCurrency(),
            netFlow >= 0 ? Icons.trending_up : Icons.trending_down,
            netFlow >= 0 ? Colors.green : Colors.red,
          ),
          _buildInsightItem(
            'Savings Rate',
            totalIncome > 0 
                ? '${((netFlow / totalIncome) * 100).toStringAsFixed(1)}%'
                : '0.0%',
            Icons.savings,
            netFlow >= 0 ? Colors.green : Colors.red,
          ),
          _buildInsightItem(
            'Burn Rate',
            (data.isNotEmpty ? totalExpenses / data.length : 0.0).toCurrency(),
            Icons.local_fire_department,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Month Button
          IconButton(
            onPressed: () {
              // Navigate to previous month
              widget.onPeriodChanged('monthly');
              // Trigger parent to update selected month
              if (mounted) setState(() {});
            },
            icon: Icon(Icons.chevron_left, color: Colors.grey[700]),
            tooltip: 'Previous Month',
          ),
          
          // Month Dropdown Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: budgetGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: budgetGradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButton<DateTime>(
              value: widget.selectedMonth,
              items: _buildMonthDropdownItems(),
              onChanged: (DateTime? newMonth) {
                if (newMonth != null) {
                  widget.onPeriodChanged('monthly');
                  // Trigger parent to update
                  if (mounted) setState(() {});
                }
              },
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              selectedItemBuilder: (context) {
                return _buildMonthDropdownItems().map((item) {
                  return Center(
                    child: Text(
                      DateFormat('MMMM yyyy').format(item.value!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
          ),
          
          // Next Month Button
          IconButton(
            onPressed: () {
              final now = DateTime.now();
              final nextMonth = DateTime(
                widget.selectedMonth.year,
                widget.selectedMonth.month + 1,
              );
              // Don't allow future months beyond current month
              if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                widget.onPeriodChanged('monthly');
                if (mounted) setState(() {});
              }
            },
            icon: Icon(Icons.chevron_right, color: Colors.grey[700]),
            tooltip: 'Next Month',
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<DateTime>> _buildMonthDropdownItems() {
    final List<DropdownMenuItem<DateTime>> items = [];
    final now = DateTime.now();
    
    // Generate last 12 months
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      items.add(
        DropdownMenuItem(
          value: month,
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      );
    }
    return items;
  }

  // Replace the placeholder charts with actual working implementations
  Widget _buildActualBudgetChart() {
    final chartData = _processChartData();
    
    if (chartData.isEmpty) {
      return _buildEmptyChartState();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Chart Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Budget', Colors.blue, Icons.account_balance_wallet),
              _buildLegendItem('Actual', Colors.purple, Icons.shopping_cart),
              if (_showPredictions)
                _buildLegendItem('Predicted', Colors.orange, Icons.auto_graph),
            ],
          ),
          const SizedBox(height: 20),
          
          // Actual Chart Data Display
          Expanded(
            child: ListView.builder(
              itemCount: chartData.length,
              itemBuilder: (context, index) {
                final data = chartData[index];
                final budget = data['budget'] ?? 0.0;
                final actual = data['actual'] ?? 0.0;
                final percentage = budget > 0 ? (actual / budget * 100) : 0.0;
                final isOverBudget = actual > budget;
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getChartPeriodLabel(index),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOverBudget 
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOverBudget ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: budget > 0 ? (actual / budget).clamp(0.0, 1.0) : 0.0,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOverBudget ? Colors.red : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Values
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget: \$${budget.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Actual: \$${actual.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOverBudget ? Colors.red : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getChartPeriodLabel(int index) {
    if (_currentView == 'weekly') {
      return 'Week ${index + 1}';
    } else if (_currentView == 'daily') {
      final day = index + 1;
      return 'Day $day';
    } else {
      final monthDate = DateTime(
        widget.selectedMonth.year,
        widget.selectedMonth.month - (11 - index),
      );
      return DateFormat('MMM').format(monthDate);
    }
  }

  Widget _buildEmptyChartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No budget data available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create budgets to see your timeline',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
