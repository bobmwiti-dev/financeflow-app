import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../viewmodels/income_viewmodel.dart';
import '../../../viewmodels/bill_viewmodel.dart';
import '../../../viewmodels/account_viewmodel.dart';
import '../../../models/transaction_model.dart';
import '../../../services/balance_service.dart';
import '../../../utils/currency_extensions.dart';

// Toggle for verbose cash flow logging. Set to true only when actively
// debugging forecast behaviour to avoid console spam and slowdowns.
const bool _enableVerboseCashFlowLogging = false;

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
  bool _isLoading = false;
  double _currentBalance = 0;
  double _projectedBalance = 0;
  
  // Cached viewmodels so we can listen for data changes
  TransactionViewModel? _transactionVm;
  IncomeViewModel? _incomeVm;
  BillViewModel? _billVm;
  VoidCallback? _txListener;
  VoidCallback? _incomeListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cache providers and listen for data changes
      _transactionVm = Provider.of<TransactionViewModel>(context, listen: false);
      _incomeVm = Provider.of<IncomeViewModel>(context, listen: false);
      _billVm = Provider.of<BillViewModel>(context, listen: false);

      _txListener = _onSourceDataChanged;
      _incomeListener = _onSourceDataChanged;

      _transactionVm?.addListener(_txListener!);
      _incomeVm?.addListener(_incomeListener!);

      _loadCashFlowData();
    });
  }

  Future<void> _loadCashFlowData() async {
    if (!mounted) return;

    // Avoid overlapping computations
    if (_isLoading) return;

    final transactionVm = _transactionVm;
    final incomeVm = _incomeVm;
    final billVm = _billVm;

    if (transactionVm == null || incomeVm == null || billVm == null) return;

    final accountVm = Provider.of<AccountViewModel>(context, listen: false);

    setState(() => _isLoading = true);
    
    try {
      // Use the current in-memory data from the viewmodels. These are kept
      // up to date via their own Firestore listeners, so we don't need to
      // trigger additional queries here.
      _generateHistoricalData(transactionVm, incomeVm, accountVm);
      _generateForecastData(transactionVm, incomeVm, billVm);
      
    } catch (e) {
      debugPrint('Error loading cash flow data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSourceDataChanged() {
    if (!mounted) return;

    // Only recompute when we actually have some data; this avoids
    // doing work repeatedly while streams are still empty.
    final hasTransactions = _transactionVm?.transactions.isNotEmpty ?? false;
    final hasIncome = _incomeVm?.incomeSources.isNotEmpty ?? false;

    if (hasTransactions || hasIncome) {
      _loadCashFlowData();
    }
  }

  @override
  void dispose() {
    _transactionVm?.removeListener(_txListener ?? () {});
    _incomeVm?.removeListener(_incomeListener ?? () {});
    super.dispose();
  }

  String _formatAmount(double amount) => amount.toKenyaDualCurrency();

  void _generateHistoricalData(
    TransactionViewModel transactionVm,
    IncomeViewModel incomeVm,
    AccountViewModel accountVm,
  ) {
    final now = DateTime.now();
    final historicalPoints = <CashFlowPoint>[];
    
    // Debug: Check available data
    if (_enableVerboseCashFlowLogging) {
      debugPrint('Cash Flow Debug: Total transactions: ${transactionVm.transactions.length}');
      debugPrint('Cash Flow Debug: Total income sources: ${incomeVm.incomeSources.length}');
    }
    
    // Find the earliest data to determine how many months we actually have
    final allDates = [
      ...transactionVm.transactions.map((t) => t.date),
      ...incomeVm.incomeSources.map((i) => i.date),
    ];
    
    if (allDates.isEmpty) {
      if (_enableVerboseCashFlowLogging) {
        debugPrint('Cash Flow Debug: No historical data available');
      }
      _historicalData = [];
      _currentBalance = accountVm.getTotalBalance(
        transactionVm.transactions,
        incomeVm.incomeSources,
      );
      return;
    }
    
    allDates.sort();
    final earliestDate = allDates.first;
    final monthsAvailable = ((now.year - earliestDate.year) * 12 + now.month - earliestDate.month).clamp(0, 6);
    
    if (_enableVerboseCashFlowLogging) {
      debugPrint('Cash Flow Debug: Data available for $monthsAvailable months (from ${earliestDate.month}/${earliestDate.year})');
    }
    
    // Use available months (minimum 1, maximum 6)
    final monthsToProcess = (monthsAvailable == 0) ? 1 : monthsAvailable;

    final currentBalance = accountVm.getTotalBalance(
      transactionVm.transactions,
      incomeVm.incomeSources,
    );

    for (int i = monthsToProcess - 1; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final isCurrentMonth = monthStart.year == now.year && monthStart.month == now.month;

      final amount = isCurrentMonth
          ? currentBalance
          : accountVm.activeAccounts.fold<double>(0.0, (sum, account) {
              final endOfMonth = DateTime(
                monthStart.year,
                monthStart.month + 1,
                0,
                23,
                59,
                59,
              );
              return sum + BalanceService.calculateAccountBalanceUpToDate(
                account,
                transactionVm.transactions,
                incomeVm.incomeSources,
                endOfMonth,
              );
            });

      historicalPoints.add(
        CashFlowPoint(
          date: monthStart,
          amount: amount,
          isActual: true,
        ),
      );
    }

    _historicalData = historicalPoints;
    _currentBalance = currentBalance;
  }

  void _generateForecastData(TransactionViewModel transactionVm, IncomeViewModel incomeVm, BillViewModel billVm) {
    final now = DateTime.now();
    final forecastPoints = <CashFlowPoint>[];
    double projectedBalance = _currentBalance;
    
    // Enhanced forecast with seasonal patterns and recurring income
    final monthlyIncomePattern = _calculateMonthlyIncomePattern(incomeVm);
    final monthlyExpensePattern = _calculateMonthlyExpensePattern(transactionVm);
    final recurringIncome = _calculateRecurringIncome(incomeVm);
    
    if (_enableVerboseCashFlowLogging) {
      debugPrint('Cash Flow Debug: Monthly income pattern: $monthlyIncomePattern');
      debugPrint('Cash Flow Debug: Monthly expense pattern: $monthlyExpensePattern');
      debugPrint('Cash Flow Debug: Recurring income: \$${recurringIncome.toStringAsFixed(2)}');
    }
    
    for (int i = 1; i <= widget.monthsToForecast; i++) {
      final forecastMonth = DateTime(now.year, now.month + i, 1);
      final monthIndex = (forecastMonth.month - 1) % 12;
      
      // Use seasonal patterns if available, otherwise use averages
      double projectedIncome;
      if (monthlyIncomePattern.isNotEmpty) {
        projectedIncome = monthlyIncomePattern[monthIndex] + recurringIncome;
      } else {
        projectedIncome = _calculateAverageNonRecurringIncome(incomeVm) + recurringIncome;
      }
      
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
      
      if (_enableVerboseCashFlowLogging) {
        debugPrint('Cash Flow Debug: Month ${forecastMonth.month}/${forecastMonth.year} - Projected Income: \$${projectedIncome.toStringAsFixed(2)}, Expenses: \$${projectedExpenses.toStringAsFixed(2)}, Bills: \$${upcomingBills.toStringAsFixed(2)}, Balance: \$${projectedBalance.toStringAsFixed(2)}');
      }
      
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
      if (_enableVerboseCashFlowLogging) {
        debugPrint('Cash Flow Debug: No income data for averaging, using fallback');
      }
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
    
    if (_enableVerboseCashFlowLogging) {
      debugPrint('Cash Flow Debug: Weighted average income calculated from ${incomeByMonth.length} months: \$${avgIncome.toStringAsFixed(2)}');
    }
    return avgIncome;
  }

  double _calculateAverageNonRecurringIncome(IncomeViewModel incomeVm) {
    final incomeByMonth = <DateTime, double>{};

    for (final income in incomeVm.incomeSources) {
      if (income.isRecurring == true) continue;
      final monthKey = DateTime(income.date.year, income.date.month, 1);
      incomeByMonth[monthKey] = (incomeByMonth[monthKey] ?? 0) + income.amount;
    }

    if (incomeByMonth.isEmpty) {
      return 0;
    }

    final now = DateTime.now();
    final sortedMonths = incomeByMonth.keys.toList()..sort();
    double weightedSum = 0;
    double totalWeight = 0;

    for (final month in sortedMonths) {
      final monthsAgo = ((now.year - month.year) * 12 + now.month - month.month);
      final weight = 1.0 / (1.0 + monthsAgo * 0.1);
      weightedSum += incomeByMonth[month]! * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0;
  }

  double _calculateAverageExpenses(TransactionViewModel transactionVm) {
    // Find available expense data by month
    final expensesByMonth = <DateTime, double>{};
    
    for (final transaction in transactionVm.transactions) {
      if (transaction.type == TransactionType.expense) {
        final monthKey = DateTime(transaction.date.year, transaction.date.month, 1);
        // Store expenses as positive magnitudes per month
        expensesByMonth[monthKey] = (expensesByMonth[monthKey] ?? 0) + transaction.amount.abs();
      }
    }
    
    if (expensesByMonth.isEmpty) {
      if (_enableVerboseCashFlowLogging) {
        debugPrint('Cash Flow Debug: No expense data for averaging, using fallback');
      }
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
    
    if (_enableVerboseCashFlowLogging) {
      debugPrint('Cash Flow Debug: Weighted average expenses calculated from ${expensesByMonth.length} months: \$${avgExpenses.toStringAsFixed(2)}');
    }
    return avgExpenses;
  }

  /// Calculate monthly income patterns for seasonal forecasting
  List<double> _calculateMonthlyIncomePattern(IncomeViewModel incomeVm) {
    final monthlyPattern = List<double>.filled(12, 0.0);
    final monthlyCount = List<int>.filled(12, 0);
    
    for (final income in incomeVm.incomeSources) {
      if (income.isRecurring == true) continue;
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
        // Use absolute values so expenses are treated as positive outflows
        monthlyPattern[monthIndex] += transaction.amount.abs();
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
          // Use absolute values to measure spending trend
          expensesByMonth[monthKey] = (expensesByMonth[monthKey] ?? 0) + transaction.amount.abs();
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
      final frequency = (bill.frequency ?? '').toLowerCase();
      final isRecurring = bill.isRecurring == true && frequency.isNotEmpty;

      if (!isRecurring) {
        if (bill.dueDate.year == forecastMonth.year && bill.dueDate.month == forecastMonth.month) {
          upcomingBills += bill.amount;
        }
        continue;
      }

      final monthsSinceBill = ((forecastMonth.year - bill.dueDate.year) * 12 +
              forecastMonth.month - bill.dueDate.month);

      if (monthsSinceBill < 0) {
        continue;
      }

      if (frequency.contains('monthly')) {
        upcomingBills += bill.amount;
      } else if (frequency.contains('biweekly') || frequency.contains('bi-weekly')) {
        upcomingBills += bill.amount * 2.17;
      } else if (frequency.contains('weekly')) {
        upcomingBills += bill.amount * 4.33;
      } else if (frequency.contains('bimonthly') || frequency.contains('bi-monthly')) {
        if (monthsSinceBill % 2 == 0) {
          upcomingBills += bill.amount;
        }
      } else if (frequency.contains('quarterly')) {
        if (monthsSinceBill % 3 == 0) {
          upcomingBills += bill.amount;
        }
      } else if (frequency.contains('yearly') || frequency.contains('annual')) {
        if (forecastMonth.month == bill.dueDate.month) {
          upcomingBills += bill.amount;
        }
      }
    }
    
    if (_enableVerboseCashFlowLogging) {
      debugPrint('Cash Flow Debug: Calculated upcoming bills for ${DateFormat('MMM yyyy').format(forecastMonth)}: \$${upcomingBills.toStringAsFixed(2)}');
    }
    return upcomingBills;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.98),
            colorScheme.surface.withValues(alpha: 0.98),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    ),
                  )
                else if (_historicalData.isEmpty && _forecastData.isEmpty)
                  _buildEmptyState(context)
                else ...[
                  _buildSummaryCards(context),
                  const SizedBox(height: 14),
                  _buildChart(context),
                  const SizedBox(height: 14),
                  _buildInsights(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dataMonths = _historicalData.length;
    final String confidenceLabel = dataMonths >= 6
        ? 'High confidence'
        : dataMonths >= 3
            ? 'Medium confidence'
            : 'Low confidence';
    final Color confidenceBg = dataMonths >= 6
        ? colorScheme.secondaryContainer
        : dataMonths >= 3
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHighest;
    final Color confidenceFg = dataMonths >= 6
        ? colorScheme.onSecondaryContainer
        : dataMonths >= 3
            ? colorScheme.onTertiaryContainer
            : colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            Icons.trending_up,
            color: colorScheme.onPrimaryContainer,
            size: 20,
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: confidenceBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          confidenceLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: confidenceFg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '${widget.monthsToForecast}mo',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.onViewDetails != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onViewDetails?.call();
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View details',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final balanceChange = _projectedBalance - _currentBalance;
    final isPositive = balanceChange >= 0;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surfaceContainerHigh,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current balance',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Text(
                    _formatAmount(_currentBalance),
                    key: ValueKey(_currentBalance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: colorScheme.onSurface,
                    ),
                  ),
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
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (isPositive ? colorScheme.primary : colorScheme.error)
                      .withValues(alpha: 0.10),
                  colorScheme.surfaceContainerHigh,
                ],
              ),
              border: Border.all(
                color: (isPositive ? colorScheme.primary : colorScheme.error)
                    .withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projected (${widget.monthsToForecast}mo)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Text(
                    _formatAmount(_projectedBalance),
                    key: ValueKey(_projectedBalance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: isPositive ? colorScheme.primary : colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 16,
                      color: isPositive ? colorScheme.primary : colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${isPositive ? '+' : '-'}${_formatAmount(balanceChange.abs())}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            _buildLegendItem(colorScheme.primary, 'Historical', false),
            const SizedBox(width: 16),
            _buildLegendItem(colorScheme.tertiary, 'Forecast', true),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes
                      .map(
                        (index) => TouchedSpotIndicatorData(
                          FlLine(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                            strokeWidth: 1,
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, idx) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: bar.gradient?.colors.last ?? colorScheme.primary,
                                strokeWidth: 2,
                                strokeColor: colorScheme.surface,
                              );
                            },
                          ),
                        ),
                      )
                      .toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 12,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (spot) => colorScheme.surface,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final idx = spot.x.toInt().clamp(0, allData.length - 1);
                      final point = allData[idx];
                      final month = DateFormat('MMM yyyy').format(point.date);
                      final isForecast = !point.isActual;

                      return LineTooltipItem(
                        '$month\n${_formatAmount(point.amount)}',
                        theme.textTheme.labelMedium!.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: isForecast ? '\nForecast' : '\nActual',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: safeHorizontalInterval,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  strokeWidth: 1,
                ),
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
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
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
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.80),
                        colorScheme.primary,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: colorScheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.20),
                          colorScheme.primary.withValues(alpha: 0.04),
                        ],
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
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.tertiary.withValues(alpha: 0.80),
                        colorScheme.tertiary,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dashArray: [8, 4],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: colorScheme.tertiary,
                          strokeWidth: 2,
                          strokeColor: colorScheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.tertiary.withValues(alpha: 0.16),
                          colorScheme.tertiary.withValues(alpha: 0.04),
                        ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInsights(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final balanceChange = _projectedBalance - _currentBalance;
    final isPositive = balanceChange >= 0;
    final monthlyChange = balanceChange / widget.monthsToForecast;
    
    // Calculate confidence level based on data availability
    final dataMonths = _historicalData.length;
    final confidenceLevel = dataMonths >= 6 ? 'High' : dataMonths >= 3 ? 'Medium' : 'Low';
    final confidenceColor = dataMonths >= 6
        ? colorScheme.secondary
        : dataMonths >= 3
            ? colorScheme.tertiary
            : colorScheme.error;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Forecast insights',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$confidenceLevel Confidence',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
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
                color: isPositive ? colorScheme.primary : colorScheme.error,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isPositive 
                    ? 'Projected to gain ${_formatAmount(balanceChange.abs())} (${_formatAmount(monthlyChange.abs())}/month)'
                    : 'Projected to lose ${_formatAmount(balanceChange.abs())} (${_formatAmount(monthlyChange.abs())}/month)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Additional insights based on data
          if (!isPositive) ...[
            Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: colorScheme.tertiary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Consider reducing expenses or finding additional income sources',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
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
                  color: isPositive ? colorScheme.primary : colorScheme.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isPositive 
                        ? 'Strong cash flow - consider investing surplus funds'
                        : 'Significant cash outflow - review major expenses',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
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
                Icon(Icons.info_outline, color: colorScheme.primary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Add more transaction history for improved forecast accuracy',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(
                Icons.show_chart_rounded,
                size: 30,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No cash flow data available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some transactions and income to see your cash flow forecast',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
