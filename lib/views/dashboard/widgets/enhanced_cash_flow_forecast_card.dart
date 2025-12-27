import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../viewmodels/income_viewmodel.dart';
import '../../../viewmodels/bill_viewmodel.dart';
import '../../../models/transaction_model.dart';

/// Data model for cash flow points
class CashFlowPoint {
  final DateTime date;
  final double amount;
  final bool isActual;
  final String? category;

  CashFlowPoint({
    required this.date,
    required this.amount,
    required this.isActual,
    this.category,
  });
}

/// Enhanced Cash Flow Forecast Card with real data integration
class EnhancedCashFlowForecastCard extends StatefulWidget {
  const EnhancedCashFlowForecastCard({
    super.key,
    this.onViewDetails,
    this.monthsToForecast = 3,
  });

  final VoidCallback? onViewDetails;
  final int monthsToForecast;

  @override
  State<EnhancedCashFlowForecastCard> createState() => _EnhancedCashFlowForecastCardState();
}

class _EnhancedCashFlowForecastCardState extends State<EnhancedCashFlowForecastCard> {
  List<CashFlowPoint> _historicalData = [];
  List<CashFlowPoint> _forecastData = [];
  bool _isLoading = true;
  double _currentBalance = 0;
  double _projectedBalance = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCashFlowData();
    });
  }

  Future<void> _loadCashFlowData() async {
    setState(() => _isLoading = true);
    
    try {
      final transactionVm = Provider.of<TransactionViewModel>(context, listen: false);
      final incomeVm = Provider.of<IncomeViewModel>(context, listen: false);
      final billVm = Provider.of<BillViewModel>(context, listen: false);
      
      await transactionVm.loadAllTransactions();
      
      _generateHistoricalData(transactionVm, incomeVm);
      _generateForecastData(transactionVm, incomeVm, billVm);
      
    } catch (e) {
      debugPrint('Error loading cash flow data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateHistoricalData(TransactionViewModel transactionVm, IncomeViewModel incomeVm) {
    final now = DateTime.now();
    final historicalPoints = <CashFlowPoint>[];
    
    // Debug: Check available data
    debugPrint('Cash Flow Debug: Total transactions: ${transactionVm.transactions.length}');
    debugPrint('Cash Flow Debug: Total income sources: ${incomeVm.incomeSources.length}');
    
    // Find the earliest data to determine how many months we actually have
    final allDates = [
      ...transactionVm.transactions.map((t) => t.date),
      ...incomeVm.incomeSources.map((i) => i.date),
    ];
    
    if (allDates.isEmpty) {
      debugPrint('Cash Flow Debug: No historical data available');
      _historicalData = [];
      _currentBalance = 0;
      return;
    }
    
    allDates.sort();
    final earliestDate = allDates.first;
    final monthsAvailable = ((now.year - earliestDate.year) * 12 + now.month - earliestDate.month).clamp(0, 6);
    
    debugPrint('Cash Flow Debug: Data available for $monthsAvailable months (from ${earliestDate.month}/${earliestDate.year})');
    
    // Use available months (minimum 1, maximum 6)
    final monthsToProcess = (monthsAvailable == 0) ? 1 : monthsAvailable;
    double runningBalance = 0;
    
    for (int i = monthsToProcess - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      
      final monthlyIncome = incomeVm.incomeSources
          .where((income) => 
              income.date.isAfter(month.subtract(const Duration(days: 1))) &&
              income.date.isBefore(nextMonth))
          .fold<double>(0, (sum, income) => sum + income.amount);
      
      final monthlyExpenses = transactionVm.transactions
          .where((transaction) => 
              transaction.type == TransactionType.expense &&
              transaction.date.isAfter(month.subtract(const Duration(days: 1))) &&
              transaction.date.isBefore(nextMonth))
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      
      runningBalance += monthlyIncome - monthlyExpenses;
      
      debugPrint('Cash Flow Debug: Month ${month.month}/${month.year} - Income: \$$monthlyIncome, Expenses: \$$monthlyExpenses, Balance: \$$runningBalance');
      
      historicalPoints.add(CashFlowPoint(
        date: month,
        amount: runningBalance,
        isActual: true,
      ));
    }
    
    _historicalData = historicalPoints;
    _currentBalance = historicalPoints.isNotEmpty ? historicalPoints.last.amount : 0;
  }

  void _generateForecastData(TransactionViewModel transactionVm, IncomeViewModel incomeVm, BillViewModel billVm) {
    final now = DateTime.now();
    final forecastPoints = <CashFlowPoint>[];
    double projectedBalance = _currentBalance;
    
    // Enhanced forecast with seasonal patterns and recurring income
    final monthlyIncomePattern = _calculateMonthlyIncomePattern(incomeVm);
    final monthlyExpensePattern = _calculateMonthlyExpensePattern(transactionVm);
    final recurringIncome = _calculateRecurringIncome(incomeVm);
    
    debugPrint('Cash Flow Debug: Monthly income pattern: $monthlyIncomePattern');
    debugPrint('Cash Flow Debug: Monthly expense pattern: $monthlyExpensePattern');
    debugPrint('Cash Flow Debug: Recurring income: \$${recurringIncome.toStringAsFixed(2)}');
    
    for (int i = 1; i <= widget.monthsToForecast; i++) {
      final forecastMonth = DateTime(now.year, now.month + i, 1);
      final monthIndex = (forecastMonth.month - 1) % 12;
      
      // Use seasonal patterns if available, otherwise use averages
      double projectedIncome = monthlyIncomePattern.isNotEmpty 
          ? monthlyIncomePattern[monthIndex] + recurringIncome
          : _calculateAverageIncome(incomeVm);
      
      double projectedExpenses = monthlyExpensePattern.isNotEmpty
          ? monthlyExpensePattern[monthIndex]
          : _calculateAverageExpenses(transactionVm);
      
      // Add trend adjustment based on recent months
      final trendAdjustment = _calculateTrendAdjustment(transactionVm, incomeVm, i);
      projectedIncome += trendAdjustment['income'] ?? 0;
      projectedExpenses += trendAdjustment['expenses'] ?? 0;
      
      projectedBalance += projectedIncome;
      projectedBalance -= projectedExpenses;
      
      // Include scheduled bills and recurring payments
      final upcomingBills = _calculateUpcomingBills(billVm, forecastMonth);
      projectedBalance -= upcomingBills;
      
      debugPrint('Cash Flow Debug: Month ${forecastMonth.month}/${forecastMonth.year} - Projected Income: \$${projectedIncome.toStringAsFixed(2)}, Expenses: \$${projectedExpenses.toStringAsFixed(2)}, Bills: \$${upcomingBills.toStringAsFixed(2)}, Balance: \$${projectedBalance.toStringAsFixed(2)}');
      
      forecastPoints.add(CashFlowPoint(
        date: forecastMonth,
        amount: projectedBalance,
        isActual: false,
      ));
    }
    
    _forecastData = forecastPoints;
    _projectedBalance = forecastPoints.isNotEmpty ? forecastPoints.last.amount : _currentBalance;
  }

  double _calculateAverageIncome(IncomeViewModel incomeVm) {
    // Find available income data
    final incomeByMonth = <DateTime, double>{};
    
    for (final income in incomeVm.incomeSources) {
      final monthKey = DateTime(income.date.year, income.date.month, 1);
      incomeByMonth[monthKey] = (incomeByMonth[monthKey] ?? 0) + income.amount;
    }
    
    if (incomeByMonth.isEmpty) {
      debugPrint('Cash Flow Debug: No income data for averaging, using fallback');
      return 2500; // Fallback average income
    }
    
    // Weight recent months more heavily
    final now = DateTime.now();
    final sortedMonths = incomeByMonth.keys.toList()..sort();
    double weightedSum = 0;
    double totalWeight = 0;
    
    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final monthsAgo = ((now.year - month.year) * 12 + now.month - month.month);
      final weight = 1.0 / (1.0 + monthsAgo * 0.1); // Recent months get higher weight
      
      weightedSum += incomeByMonth[month]! * weight;
      totalWeight += weight;
    }
    
    final avgIncome = totalWeight > 0 ? weightedSum / totalWeight : incomeByMonth.values.reduce((a, b) => a + b) / incomeByMonth.length;
    
    debugPrint('Cash Flow Debug: Weighted average income calculated from ${incomeByMonth.length} months: \$${avgIncome.toStringAsFixed(2)}');
    return avgIncome;
  }

  double _calculateAverageExpenses(TransactionViewModel transactionVm) {
    // Find available expense data by month
    final expensesByMonth = <DateTime, double>{};
    
    for (final transaction in transactionVm.transactions) {
      if (transaction.type == TransactionType.expense) {
        final monthKey = DateTime(transaction.date.year, transaction.date.month, 1);
        expensesByMonth[monthKey] = (expensesByMonth[monthKey] ?? 0) + transaction.amount;
      }
    }
    
    if (expensesByMonth.isEmpty) {
      debugPrint('Cash Flow Debug: No expense data for averaging, using fallback');
      return 2000; // Fallback average expenses
    }
    
    // Weight recent months more heavily and exclude outliers
    final now = DateTime.now();
    final sortedMonths = expensesByMonth.keys.toList()..sort();
    final expenseValues = expensesByMonth.values.toList()..sort();
    
    // Remove outliers (top and bottom 10% if we have enough data)
    if (expenseValues.length >= 5) {
      final removeCount = (expenseValues.length * 0.1).round();
      for (int i = 0; i < removeCount; i++) {
        expenseValues.removeAt(0); // Remove lowest
        expenseValues.removeLast(); // Remove highest
      }
    }
    
    double weightedSum = 0;
    double totalWeight = 0;
    
    for (final month in sortedMonths) {
      final expense = expensesByMonth[month]!;
      if (expenseValues.contains(expense)) {
        final monthsAgo = ((now.year - month.year) * 12 + now.month - month.month);
        final weight = 1.0 / (1.0 + monthsAgo * 0.1); // Recent months get higher weight
        
        weightedSum += expense * weight;
        totalWeight += weight;
      }
    }
    
    final avgExpenses = totalWeight > 0 ? weightedSum / totalWeight : expensesByMonth.values.reduce((a, b) => a + b) / expensesByMonth.length;
    
    debugPrint('Cash Flow Debug: Weighted average expenses calculated from ${expensesByMonth.length} months: \$${avgExpenses.toStringAsFixed(2)}');
    return avgExpenses;
  }

  /// Calculate monthly income patterns for seasonal forecasting
  List<double> _calculateMonthlyIncomePattern(IncomeViewModel incomeVm) {
    final monthlyPattern = List<double>.filled(12, 0.0);
    final monthlyCount = List<int>.filled(12, 0);
    
    for (final income in incomeVm.incomeSources) {
      final monthIndex = income.date.month - 1;
      monthlyPattern[monthIndex] += income.amount;
      monthlyCount[monthIndex]++;
    }
    
    // Calculate averages for each month
    for (int i = 0; i < 12; i++) {
      if (monthlyCount[i] > 0) {
        monthlyPattern[i] = monthlyPattern[i] / monthlyCount[i];
      }
    }
    
    // If no data for certain months, use overall average
    final overallAvg = monthlyPattern.where((amount) => amount > 0).isNotEmpty
        ? monthlyPattern.where((amount) => amount > 0).reduce((a, b) => a + b) / monthlyPattern.where((amount) => amount > 0).length
        : 0.0;
    
    for (int i = 0; i < 12; i++) {
      if (monthlyPattern[i] == 0) {
        monthlyPattern[i] = overallAvg;
      }
    }
    
    return monthlyPattern;
  }

  /// Calculate monthly expense patterns for seasonal forecasting
  List<double> _calculateMonthlyExpensePattern(TransactionViewModel transactionVm) {
    final monthlyPattern = List<double>.filled(12, 0.0);
    final monthlyCount = List<int>.filled(12, 0);
    
    for (final transaction in transactionVm.transactions) {
      if (transaction.type == TransactionType.expense) {
        final monthIndex = transaction.date.month - 1;
        monthlyPattern[monthIndex] += transaction.amount;
        monthlyCount[monthIndex]++;
      }
    }
    
    // Calculate averages for each month
    for (int i = 0; i < 12; i++) {
      if (monthlyCount[i] > 0) {
        monthlyPattern[i] = monthlyPattern[i] / monthlyCount[i];
      }
    }
    
    // If no data for certain months, use overall average
    final overallAvg = monthlyPattern.where((amount) => amount > 0).isNotEmpty
        ? monthlyPattern.where((amount) => amount > 0).reduce((a, b) => a + b) / monthlyPattern.where((amount) => amount > 0).length
        : 0.0;
    
    for (int i = 0; i < 12; i++) {
      if (monthlyPattern[i] == 0) {
        monthlyPattern[i] = overallAvg;
      }
    }
    
    return monthlyPattern;
  }

  /// Calculate recurring income from salary and regular sources
  double _calculateRecurringIncome(IncomeViewModel incomeVm) {
    double recurringAmount = 0.0;
    
    for (final income in incomeVm.incomeSources) {
      if (income.isRecurring && income.frequency.toLowerCase().contains('monthly')) {
        recurringAmount += income.amount;
      } else if (income.isRecurring && income.frequency.toLowerCase().contains('weekly')) {
        recurringAmount += income.amount * 4.33; // Average weeks per month
      }
    }
    
    return recurringAmount;
  }

  /// Calculate trend adjustments based on recent performance
  Map<String, double> _calculateTrendAdjustment(TransactionViewModel transactionVm, IncomeViewModel incomeVm, int monthsAhead) {
    final now = DateTime.now();
    final recentMonths = 3; // Look at last 3 months for trend
    
    double incomeGrowth = 0.0;
    double expenseGrowth = 0.0;
    
    // Calculate income trend
    final incomeByMonth = <DateTime, double>{};
    for (final income in incomeVm.incomeSources) {
      final monthKey = DateTime(income.date.year, income.date.month, 1);
      if (monthKey.isAfter(DateTime(now.year, now.month - recentMonths, 1))) {
        incomeByMonth[monthKey] = (incomeByMonth[monthKey] ?? 0) + income.amount;
      }
    }
    
    if (incomeByMonth.length >= 2) {
      final sortedIncomeMonths = incomeByMonth.keys.toList()..sort();
      final firstMonth = incomeByMonth[sortedIncomeMonths.first]!;
      final lastMonth = incomeByMonth[sortedIncomeMonths.last]!;
      incomeGrowth = firstMonth > 0 ? (lastMonth - firstMonth) / firstMonth / sortedIncomeMonths.length : 0.0;
    }
    
    // Calculate expense trend
    final expensesByMonth = <DateTime, double>{};
    for (final transaction in transactionVm.transactions) {
      if (transaction.type == TransactionType.expense) {
        final monthKey = DateTime(transaction.date.year, transaction.date.month, 1);
        if (monthKey.isAfter(DateTime(now.year, now.month - recentMonths, 1))) {
          expensesByMonth[monthKey] = (expensesByMonth[monthKey] ?? 0) + transaction.amount;
        }
      }
    }
    
    if (expensesByMonth.length >= 2) {
      final sortedExpenseMonths = expensesByMonth.keys.toList()..sort();
      final firstMonth = expensesByMonth[sortedExpenseMonths.first]!;
      final lastMonth = expensesByMonth[sortedExpenseMonths.last]!;
      expenseGrowth = firstMonth > 0 ? (lastMonth - firstMonth) / firstMonth / sortedExpenseMonths.length : 0.0;
    }
    
    // Apply trend with diminishing effect over time
    final trendFactor = 1.0 / (1.0 + monthsAhead * 0.2);
    
    return {
      'income': _calculateAverageIncome(incomeVm) * incomeGrowth * trendFactor,
      'expenses': _calculateAverageExpenses(transactionVm) * expenseGrowth * trendFactor,
    };
  }

  /// Calculate upcoming bills and recurring payments
  double _calculateUpcomingBills(BillViewModel billVm, DateTime forecastMonth) {
    double upcomingBills = 0.0;
    
    for (final bill in billVm.bills) {
      // Check if bill is due in the forecast month
      if (bill.dueDate.year == forecastMonth.year && bill.dueDate.month == forecastMonth.month) {
        upcomingBills += bill.amount;
      }
      
      // Handle recurring bills using the frequency field
      if (bill.frequency != null && bill.frequency!.isNotEmpty) {
        final frequency = bill.frequency!.toLowerCase();
        
        if (frequency.contains('monthly')) {
          // Monthly recurring bill - add to every forecast month
          upcomingBills += bill.amount;
        } else if (frequency.contains('weekly')) {
          // Weekly recurring bill - multiply by ~4.33 weeks per month
          upcomingBills += bill.amount * 4.33;
        } else if (frequency.contains('quarterly')) {
          // Quarterly bill - check if forecast month aligns with quarterly cycle
          final monthsSinceBill = ((forecastMonth.year - bill.dueDate.year) * 12 + 
                                  forecastMonth.month - bill.dueDate.month);
          if (monthsSinceBill >= 0 && monthsSinceBill % 3 == 0) {
            upcomingBills += bill.amount;
          }
        } else if (frequency.contains('yearly') || frequency.contains('annual')) {
          // Yearly bill - check if forecast month matches the bill's due month
          if (forecastMonth.month == bill.dueDate.month) {
            upcomingBills += bill.amount;
          }
        } else if (frequency.contains('biweekly') || frequency.contains('bi-weekly')) {
          // Biweekly recurring bill - multiply by ~2.17 periods per month
          upcomingBills += bill.amount * 2.17;
        } else if (frequency.contains('bimonthly') || frequency.contains('bi-monthly')) {
          // Bimonthly (every 2 months) - check if forecast month aligns
          final monthsSinceBill = ((forecastMonth.year - bill.dueDate.year) * 12 + 
                                  forecastMonth.month - bill.dueDate.month);
          if (monthsSinceBill >= 0 && monthsSinceBill % 2 == 0) {
            upcomingBills += bill.amount;
          }
        }
      }
    }
    
    debugPrint('Cash Flow Debug: Calculated upcoming bills for ${DateFormat('MMM yyyy').format(forecastMonth)}: \$${upcomingBills.toStringAsFixed(2)}');
    return upcomingBills;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_historicalData.isEmpty && _forecastData.isEmpty)
              _buildEmptyState()
            else ...[
              _buildSummaryCards(),
              const SizedBox(height: 16),
              _buildChart(context),
              const SizedBox(height: 16),
              _buildInsights(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.trending_up,
            color: Colors.blue.shade700,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Cash Flow Forecast',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _historicalData.length >= 3 
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_historicalData.length}M',
                      style: TextStyle(
                        fontSize: 11,
                        color: _historicalData.length >= 3 
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.onViewDetails != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onViewDetails,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final currency = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);
    final balanceChange = _projectedBalance - _currentBalance;
    final isPositive = balanceChange >= 0;
    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(_currentBalance),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projected (${widget.monthsToForecast}mo)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(_projectedBalance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final allData = [..._historicalData, ..._forecastData];
    if (allData.isEmpty) return const SizedBox.shrink();

    final minY = allData.map((e) => e.amount).reduce((a, b) => a < b ? a : b);
    final maxY = allData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;
    
    // Ensure safe horizontal interval calculation
    final double range = maxY - minY;
    final double safeHorizontalInterval = range > 0 ? range / 4 : 1000;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.blue, 'Historical', false),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.orange, 'Forecast', true),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: safeHorizontalInterval,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
                getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < allData.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            DateFormat('MMM').format(allData[index].date),
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 11),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: safeHorizontalInterval,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 11),
                      );
                    },
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
              minX: 0,
              maxX: (allData.length - 1).toDouble(),
              minY: minY - padding,
              maxY: maxY + padding,
              lineBarsData: [
                if (_historicalData.isNotEmpty)
                  LineChartBarData(
                    spots: _historicalData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.amount);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(radius: 3, color: Colors.blue.shade600, strokeWidth: 2, strokeColor: Colors.white);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400.withValues(alpha: 0.3), Colors.blue.shade600.withValues(alpha: 0.1)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                if (_forecastData.isNotEmpty)
                  LineChartBarData(
                    spots: _forecastData.asMap().entries.map((entry) {
                      final xIndex = _historicalData.length + entry.key;
                      return FlSpot(xIndex.toDouble(), entry.value.amount);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dashArray: [8, 4],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(radius: 3, color: Colors.orange.shade600, strokeWidth: 2, strokeColor: Colors.white);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400.withValues(alpha: 0.2), Colors.orange.shade600.withValues(alpha: 0.1)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDashed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildInsights() {
    final currency = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0);
    final balanceChange = _projectedBalance - _currentBalance;
    final isPositive = balanceChange >= 0;
    final monthlyChange = balanceChange / widget.monthsToForecast;
    
    // Calculate confidence level based on data availability
    final dataMonths = _historicalData.length;
    final confidenceLevel = dataMonths >= 6 ? 'High' : dataMonths >= 3 ? 'Medium' : 'Low';
    final confidenceColor = dataMonths >= 6 ? Colors.green : dataMonths >= 3 ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Forecast Insights', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$confidenceLevel Confidence',
                  style: TextStyle(
                    fontSize: 10,
                    color: confidenceColor.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Primary insight
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isPositive 
                    ? 'Projected to gain ${currency.format(balanceChange.abs())} (${currency.format(monthlyChange.abs())}/month)'
                    : 'Projected to lose ${currency.format(balanceChange.abs())} (${currency.format(monthlyChange.abs())}/month)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Additional insights based on data
          if (!isPositive) ...[
            Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Consider reducing expenses or finding additional income sources',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          
          if (balanceChange.abs() > 1000) ...[
            Row(
              children: [
                Icon(
                  isPositive ? Icons.savings_outlined : Icons.account_balance_wallet_outlined,
                  color: isPositive ? Colors.blue : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isPositive 
                        ? 'Strong cash flow - consider investing surplus funds'
                        : 'Significant cash outflow - review major expenses',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          
          // Data quality note
          if (dataMonths < 3) ...[
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Add more transaction history for improved forecast accuracy',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No cash flow data available',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some transactions and income to see your cash flow forecast',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
