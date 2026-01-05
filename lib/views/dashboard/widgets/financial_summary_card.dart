import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../../services/monthly_comparison_service.dart';

class FinancialSummaryCard extends StatefulWidget {
  final double income;
  final double expenses;
  final double balance;
  final Map<String, double> categoryTotals;
  final bool isRefreshing;
  final double? budget;
  final double? previousIncome;
  final double? previousExpenses;
  // New analytics inputs
  final Map<String, double> spendingVelocity;
  final List<double> monthlyIncomeHistory;
  // Dynamic data for trend analysis
  final List<Map<String, dynamic>> transactionHistory;
  final List<Map<String, dynamic>> incomeHistory;
  final DateTime? selectedMonth;
  
  const FinancialSummaryCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.balance,
    required this.categoryTotals,
    this.isRefreshing = false,
    this.budget,
    this.previousIncome,
    this.previousExpenses,
    this.spendingVelocity = const {'trend': 0.0},
    this.monthlyIncomeHistory = const [],
    this.transactionHistory = const [],
    this.incomeHistory = const [],
    this.selectedMonth,
  });

  @override
  State<FinancialSummaryCard> createState() => _FinancialSummaryCardState();
}

class _FinancialSummaryCardState extends State<FinancialSummaryCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isExpanded = false;
  int _selectedView = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  DateTime _anchorMonth() {
    final m = widget.selectedMonth ?? DateTime.now();
    return DateTime(m.year, m.month, 1);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savingsRate = widget.income > 0 ? (widget.balance / widget.income * 100) : 0.0; // ignore: unused_local_variable
    final expenseRatio = widget.income > 0 ? (widget.expenses / widget.income * 100) : 0.0; // ignore: unused_local_variable
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildTrendIndicators(),
                    const SizedBox(height: 24),
                    _buildAnalyticsSection(),
                    if (_isExpanded) ..._buildExpandedContent(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendIndicators() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final availableMonths = _calculateAvailableDataMonths();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Spending Trends',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: availableMonths == 0
                      ? colorScheme.error.withValues(alpha: 0.12)
                      : (availableMonths >= 3
                          ? colorScheme.primary.withValues(alpha: 0.12)
                          : colorScheme.tertiary.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  availableMonths == 0 ? 'Limited' : '${availableMonths}M',
                  style: TextStyle(
                    fontSize: 11,
                    color: availableMonths == 0
                        ? colorScheme.error
                        : (availableMonths >= 3
                            ? colorScheme.primary
                            : colorScheme.tertiary),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.clip,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDynamicTrendCard('Income', Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildDynamicTrendCard('Expenses', Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildSpendingVelocityCard()),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }


  int _calculateAvailableDataMonths() {
    final allDates = <DateTime>[];
    
    // Collect all transaction dates
    for (final transaction in widget.transactionHistory) {
      if (transaction['date'] is DateTime) {
        allDates.add(transaction['date']);
      }
    }
    
    // Collect all income dates
    for (final income in widget.incomeHistory) {
      if (income['date'] is DateTime) {
        allDates.add(income['date']);
      }
    }
    
    debugPrint('Financial Summary Debug: transactionHistory length: ${widget.transactionHistory.length}');
    debugPrint('Financial Summary Debug: incomeHistory length: ${widget.incomeHistory.length}');
    
    // Fallback: If no historical data provided, return 0 to show limited data
    if (allDates.isEmpty) {
      debugPrint('Financial Summary Debug: No historical data available, showing current month only');
      return 0;
    }
    
    allDates.sort();
    final now = _anchorMonth();
    final earliestDate = allDates.first;
    final monthsAvailable = ((now.year - earliestDate.year) * 12 + now.month - earliestDate.month + 1).clamp(0, 12);
    
    debugPrint('Financial Summary Debug: Data available for $monthsAvailable months (from ${earliestDate.month}/${earliestDate.year})');
    return monthsAvailable;
  }

  Widget _buildDynamicTrendCard(String title, Color color) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
    
    // Get current month data
    double current = 0.0;
    if (title == 'Income') {
      current = widget.income;
    } else {
      current = widget.expenses;
    }
        
        // Calculate trend if previous data available
        final previous = title == 'Income' ? widget.previousIncome : widget.previousExpenses;
        final hasData = previous != null && previous > 0 && current > 0;
        final changePercentage = hasData ? ((current - previous) / previous) * 100 : 0.0;
        final trend = hasData 
            ? (changePercentage >= 0 ? '+${changePercentage.toStringAsFixed(1)}%' : '${changePercentage.toStringAsFixed(1)}%')
            : 'No data';
        
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.04),
            color.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasData ? Icons.trending_up : Icons.info_outline, 
                size: 12, 
                color: hasData ? color : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currencyFormat.format(current),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: hasData 
                  ? (changePercentage >= 0 ? Colors.green : Colors.red)
                  : colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingVelocityCard() {
    final monthlyData = _calculateMonthlyTrends();
    final anchor = _anchorMonth();
    final previousMonth = MonthlyComparisonService.previousMonth(anchor);

    final current = monthlyData[anchor]?['expenses'] ?? 0.0;
    final previous = monthlyData[previousMonth]?['expenses'] ?? 0.0;
    final hasEnoughData = previous > 0;
    final velocity = hasEnoughData ? ((current - previous) / previous) * 100 : 0.0;
    
    final isAccelerating = velocity > 0;
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.04),
            Colors.orange.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAccelerating ? Icons.speed : Icons.trending_down,
                size: 14,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Velocity',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            !hasEnoughData ? 'Calc...' : (isAccelerating ? 'Up' : 'Down'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            !hasEnoughData ? 'Need 2mo' : '${velocity.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: !hasEnoughData
                  ? colorScheme.onSurfaceVariant
                  : (isAccelerating ? Colors.red : Colors.green),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Analytics View',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewButton('Trends', 0, Icons.show_chart),
                _buildViewButton('Compare', 1, Icons.compare_arrows),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String label, int index, IconData icon) {
    final isSelected = _selectedView == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedView = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedView) {
      case 0:
        return _buildTrendChart();
      case 1:
        return _buildComparisonChart();
      default:
        return _buildTrendChart();
    }
  }

  Widget _buildTrendChart() {
    // Check if we have any historical data from transaction or income history
    final hasTransactionData = widget.transactionHistory.isNotEmpty;
    final hasIncomeData = widget.incomeHistory.isNotEmpty;
    final hasMonthlyData = widget.monthlyIncomeHistory.isNotEmpty;
    
    if (!hasTransactionData && !hasIncomeData && !hasMonthlyData) {
      return const Center(
        child: Text(
          'No historical data available for trend analysis',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return _buildMultiMonthTrendChart();
  }

  Widget _buildComparisonChart() {
    final monthlyData = _calculateMonthlyTrends();
    
    if (monthlyData.length < 2) {
      return const Center(
        child: Text(
          'Need at least 2 months of data for comparison',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return _buildInteractiveComparisonChart(monthlyData);
  }


  Widget _buildAnalyticsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildViewSelector(),
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSelectedView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveComparisonChart(Map<DateTime, Map<String, double>> monthlyData) {
    final months = monthlyData.keys.toList()..sort();
    final maxValue = monthlyData.values
        .expand((data) => [data['income'] as double, data['expenses'] as double])
        .reduce((a, b) => a > b ? a : b);

    final maxNetAbs = monthlyData.values
        .map((data) => ((data['income'] as double) - (data['expenses'] as double)).abs())
        .fold<double>(0.0, (m, v) => v > m ? v : m);

    final maxAbs = math.max(maxValue, maxNetAbs);
    final safeMaxY = maxAbs == 0 ? 1000 : maxAbs * 1.2;
    final safeMinY = -safeMaxY;
    
    return Column(
      children: [
        // Interactive comparison header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.indigo.shade50],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComparisonLegend('Income', Colors.green, Icons.trending_up),
              Container(
                width: 1,
                height: 20,
                color: Colors.grey.shade300,
              ),
              _buildComparisonLegend('Expenses', Colors.red, Icons.trending_down),
              Container(
                width: 1,
                height: 20,
                color: Colors.grey.shade300,
              ),
              _buildComparisonLegend('Net Flow', Colors.blue, Icons.account_balance),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: safeMaxY.toDouble(),
              minY: safeMinY.toDouble(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.indigo.shade900,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final monthKey = months[groupIndex];
                    final data = monthlyData[monthKey]!;
                    final monthName = DateFormat('MMM yyyy').format(monthKey);
                    final income = data['income'] as double;
                    final expenses = data['expenses'] as double;
                    final netFlow = income - expenses;
                    
                    return BarTooltipItem(
                      '$monthName\nIncome: KES ${income.toStringAsFixed(0)}\nExpenses: KES ${expenses.toStringAsFixed(0)}\nNet: KES ${netFlow.toStringAsFixed(0)}',
                      const TextStyle(
                        color: Colors.white, 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= months.length) return const Text('');
                      final monthKey = months[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MMM').format(monthKey),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('KES 0');
                      return Text(
                        'KES ${(value / 1000).toStringAsFixed(0)}K',
                        style: const TextStyle(color: Colors.grey, fontSize: 9),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: safeMaxY / 4,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.2),
                  strokeWidth: 0.8,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: months.asMap().entries.map((entry) {
                final index = entry.key;
                final monthKey = entry.value;
                final data = monthlyData[monthKey]!;
                final income = data['income'] as double;
                final expenses = data['expenses'] as double;
                final netFlow = income - expenses;
                
                // Highlight selected month with different styling
                final anchorMonth = _anchorMonth();
                final isSelectedMonth = monthKey.year == anchorMonth.year && 
                                     monthKey.month == anchorMonth.month;
                
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    // Income bar
                    BarChartRodData(
                      toY: income,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isSelectedMonth 
                            ? [Colors.green.shade400, Colors.green.shade700]
                            : [Colors.green.shade200, Colors.green.shade500],
                      ),
                      width: 6,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                      ),
                    ),
                    // Expenses bar
                    BarChartRodData(
                      toY: expenses,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isSelectedMonth 
                            ? [Colors.red.shade400, Colors.red.shade700]
                            : [Colors.red.shade200, Colors.red.shade500],
                      ),
                      width: 6,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                      ),
                    ),
                    // Net flow indicator (small bar)
                    BarChartRodData(
                      fromY: 0,
                      toY: netFlow,
                      color: netFlow >= 0
                          ? (isSelectedMonth ? Colors.blue.shade600 : Colors.blue.shade400)
                          : (isSelectedMonth ? Colors.red.shade600 : Colors.red.shade400),
                      width: 3,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(2),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
        ),
      ],
    );
  }

  Widget _buildComparisonLegend(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildMultiMonthTrendChart() {
    final monthlyData = _calculateMonthlyTrends();
    
    if (monthlyData.isEmpty) {
      return const Center(
        child: Text(
          'No historical data available for trend analysis',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    final maxValue = monthlyData.values
        .expand((data) => [data['income'] as double, data['expenses'] as double])
        .reduce((a, b) => a > b ? a : b);
    final safeMaxY = maxValue == 0 ? 1000 : maxValue * 1.2;
    
    return Column(
      children: [
        // Month range indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade100, Colors.purple.shade100],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${monthlyData.length} months of data',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.indigo.shade800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: safeMaxY.toDouble(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.indigo.shade800,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final monthKey = monthlyData.keys.elementAt(groupIndex);
                    final data = monthlyData[monthKey]!;
                    final monthName = DateFormat('MMM yyyy').format(monthKey);
                    
                    if (rodIndex == 0) {
                      return BarTooltipItem(
                        '$monthName\nIncome: KES ${(data['income'] as double).toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      );
                    } else {
                      return BarTooltipItem(
                        '$monthName\nExpenses: KES ${(data['expenses'] as double).toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      );
                    }
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= monthlyData.length) return const Text('');
                      final monthKey = monthlyData.keys.elementAt(value.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MMM').format(monthKey),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('KES 0');
                      return Text(
                        'KES ${(value / 1000).toStringAsFixed(0)}K',
                        style: const TextStyle(color: Colors.grey, fontSize: 9),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: safeMaxY / 4,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.3),
                  strokeWidth: 0.8,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: monthlyData.entries.map((entry) {
                final index = monthlyData.keys.toList().indexOf(entry.key);
                final data = entry.value;
                final income = data['income'] as double;
                final expenses = data['expenses'] as double;
                
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: income,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.green.shade300, Colors.green.shade600],
                      ),
                      width: 8,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: expenses,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.red.shade300, Colors.red.shade600],
                      ),
                      width: 8,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 800.ms),
        ),
      ],
    );
  }

  Map<DateTime, Map<String, double>> _calculateMonthlyTrends() {
    final monthlyTotals = <DateTime, Map<String, double>>{};
    
    // Pre-fill last 8 months with zero data to ensure all months show up (including February)
    final now = _anchorMonth();
    for (int i = 7; i >= 0; i--) {
      final monthKey = DateTime(now.year, now.month - i, 1);
      monthlyTotals[monthKey] = {'income': 0.0, 'expenses': 0.0};
    }
    
    // Process transaction history for expenses
    for (final transaction in widget.transactionHistory) {
      if (transaction['date'] is DateTime && 
          transaction['amount'] is double && 
          transaction['type'] == 'expense') {
        final date = transaction['date'] as DateTime;
        final monthKey = DateTime(date.year, date.month, 1);
        
        if (monthlyTotals.containsKey(monthKey)) {
          monthlyTotals[monthKey]!['expenses'] = 
              (monthlyTotals[monthKey]!['expenses']! + (transaction['amount'] as double).abs());
        }
      }
    }
    
    // Process income history
    for (final income in widget.incomeHistory) {
      if (income['date'] is DateTime && income['amount'] is double) {
        final date = income['date'] as DateTime;
        final monthKey = DateTime(date.year, date.month, 1);
        
        if (monthlyTotals.containsKey(monthKey)) {
          monthlyTotals[monthKey]!['income'] = 
              (monthlyTotals[monthKey]!['income']! + (income['amount'] as double));
        }
      }
    }
    
    // Sort by month and return (already sorted due to pre-filling)
    final sortedMonths = monthlyTotals.keys.toList()..sort();
    final result = <DateTime, Map<String, double>>{};
    for (final month in sortedMonths) {
      result[month] = monthlyTotals[month]!;
    }
    
    return result;
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
              'Financial Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(widget.selectedMonth ?? DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: colorScheme.primary,
              ),
              tooltip: _isExpanded ? 'Collapse' : 'Expand',
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'export':
                    _showExportDialog();
                    break;
                  case 'settings':
                    _showSettingsDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'export', child: Text('Export')),
                const PopupMenuItem(value: 'settings', child: Text('Settings')),
              ],
            ),
          ],
        ),
      ],
    );
  }




  List<Widget> _buildExpandedContent() {
    return [
      const SizedBox(height: 20),
      _buildOptimizationSuggestions(),
      const SizedBox(height: 16),
      _buildBudgetRebalancing(),
    ];
  }

  Widget _buildOptimizationSuggestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.teal.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Optimization Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Static suggestions for now - will be dynamic when optimizationSuggestions is implemented
            _buildSuggestionItem(
              'Switch to Annual Subscriptions',
              'Save money by switching monthly subscriptions to annual plans',
              240.0,
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms);
  }

  Widget _buildSuggestionItem(String title, String description, double savings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.savings, size: 16, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Save KES ${savings.toStringAsFixed(0)}/year',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBudgetRebalancing() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Budget Rebalancing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRebalanceItem(
            'Dining Out',
            'Reduce by 15% to stay within budget',
            -120.0,
          ),
          _buildRebalanceItem(
            'Entertainment',
            'Increase allocation based on recent spending',
            80.0,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildRebalanceItem(String category, String suggestion, double adjustment) {
    final isIncrease = adjustment > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isIncrease ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isIncrease ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: isIncrease ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  suggestion,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncrease ? '+' : ''}KES ${adjustment.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isIncrease ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }

  void _showSettingsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings feature coming soon!')),
    );
  }
}
