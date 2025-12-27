import 'dart:math' as math;
import '../models/time_period_model.dart';
import '../models/transaction_model.dart';
import '../models/income_source_model.dart';

class PeriodComparisonData {
  final double currentValue;
  final double previousValue;
  final double changeAmount;
  final double changePercentage;
  final bool isIncrease;
  final String trend;

  PeriodComparisonData({
    required this.currentValue,
    required this.previousValue,
    required this.changeAmount,
    required this.changePercentage,
    required this.isIncrease,
    required this.trend,
  });
}

class TrendAnalysisData {
  final List<double> values;
  final List<TimePeriod> periods;
  final double averageValue;
  final double trendSlope;
  final String trendDirection;
  final double volatility;
  final Map<String, double> seasonalPatterns;

  TrendAnalysisData({
    required this.values,
    required this.periods,
    required this.averageValue,
    required this.trendSlope,
    required this.trendDirection,
    required this.volatility,
    required this.seasonalPatterns,
  });
}

class CategoryTrendData {
  final String category;
  final List<double> values;
  final double totalSpent;
  final double averageSpent;
  final PeriodComparisonData comparison;
  final String insight;

  CategoryTrendData({
    required this.category,
    required this.values,
    required this.totalSpent,
    required this.averageSpent,
    required this.comparison,
    required this.insight,
  });
}

class PeriodAnalysisService {
  // Calculate period-over-period comparison
  static PeriodComparisonData calculateComparison({
    required double currentValue,
    required double previousValue,
  }) {
    final changeAmount = currentValue - previousValue;
    final changePercentage = previousValue != 0 
        ? (changeAmount / previousValue) * 100 
        : (currentValue > 0 ? 100.0 : 0.0);
    
    final isIncrease = changeAmount > 0;
    
    String trend;
    if (changePercentage.abs() < 5) {
      trend = 'stable';
    } else if (changePercentage > 20) {
      trend = 'significant_increase';
    } else if (changePercentage < -20) {
      trend = 'significant_decrease';
    } else if (changePercentage > 0) {
      trend = 'moderate_increase';
    } else {
      trend = 'moderate_decrease';
    }

    return PeriodComparisonData(
      currentValue: currentValue,
      previousValue: previousValue,
      changeAmount: changeAmount,
      changePercentage: changePercentage,
      isIncrease: isIncrease,
      trend: trend,
    );
  }

  // Analyze spending trends across multiple periods
  static TrendAnalysisData analyzeTrend({
    required TimePeriod currentPeriod,
    required List<Transaction> allTransactions,
    required List<IncomeSource> allIncomeSources,
    int periodsToAnalyze = 6,
    bool analyzeIncome = false,
  }) {
    final periods = [currentPeriod, ...currentPeriod.getPreviousPeriods(periodsToAnalyze - 1)];
    final values = <double>[];
    
    for (final period in periods) {
      double periodValue = 0;
      
      if (analyzeIncome) {
        // Analyze income trends
        final periodIncome = allIncomeSources.where((income) => 
          period.containsDate(income.date)).toList();
        periodValue = periodIncome.fold(0.0, (sum, income) => sum + income.amount);
      } else {
        // Analyze expense trends
        final periodExpenses = allTransactions.where((tx) => 
          tx.type == TransactionType.expense && period.containsDate(tx.date)).toList();
        periodValue = periodExpenses.fold(0.0, (sum, tx) => sum + tx.amount.abs());
      }
      
      values.add(periodValue);
    }
    
    final averageValue = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0.0;
    final trendSlope = _calculateTrendSlope(values);
    final trendDirection = _getTrendDirection(trendSlope);
    final volatility = _calculateVolatility(values, averageValue.toDouble());
    final seasonalPatterns = _analyzeSeasonalPatterns(periods, values);
    
    return TrendAnalysisData(
      values: values,
      periods: periods,
      averageValue: averageValue.toDouble(),
      trendSlope: trendSlope,
      trendDirection: trendDirection,
      volatility: volatility,
      seasonalPatterns: seasonalPatterns,
    );
  }

  // Analyze category-specific trends
  static List<CategoryTrendData> analyzeCategoryTrends({
    required TimePeriod currentPeriod,
    required List<Transaction> allTransactions,
    int periodsToAnalyze = 6,
  }) {
    final periods = [currentPeriod, ...currentPeriod.getPreviousPeriods(periodsToAnalyze - 1)];
    final categoryData = <String, CategoryTrendData>{};
    
    // Get all unique categories
    final categories = allTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .map((tx) => tx.category)
        .toSet()
        .toList();
    
    for (final category in categories) {
      final values = <double>[];
      
      for (final period in periods) {
        final periodExpenses = allTransactions.where((tx) => 
          tx.type == TransactionType.expense && 
          tx.category == category && 
          period.containsDate(tx.date)).toList();
        
        final periodTotal = periodExpenses.fold(0.0, (sum, tx) => sum + tx.amount.abs());
        values.add(periodTotal);
      }
      
      final totalSpent = values.reduce((a, b) => a + b).toDouble();
      final averageSpent = (totalSpent / values.length).toDouble();
      
      // Calculate comparison with previous period
      final currentValue = values.isNotEmpty ? values.first : 0.0;
      final previousValue = values.length > 1 ? values[1] : 0.0;
      final comparison = calculateComparison(
        currentValue: currentValue.toDouble(),
        previousValue: previousValue.toDouble(),
      );
      
      final insight = _generateCategoryInsight(category, comparison, averageSpent);
      
      categoryData[category] = CategoryTrendData(
        category: category,
        values: values,
        totalSpent: totalSpent,
        averageSpent: averageSpent,
        comparison: comparison,
        insight: insight,
      );
    }
    
    // Sort by total spending (highest first)
    final sortedCategories = categoryData.values.toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    
    return sortedCategories;
  }

  // Calculate financial velocity (rate of change)
  static Map<String, dynamic> calculateFinancialVelocity({
    required TimePeriod currentPeriod,
    required List<Transaction> allTransactions,
    required List<IncomeSource> allIncomeSources,
  }) {
    final previousPeriod = currentPeriod.getPreviousPeriod();
    
    // Current period data
    final currentExpenses = allTransactions.where((tx) => 
      tx.type == TransactionType.expense && currentPeriod.containsDate(tx.date)).toList();
    final currentIncome = allIncomeSources.where((income) => 
      currentPeriod.containsDate(income.date)).toList();
    
    // Previous period data
    final previousExpenses = allTransactions.where((tx) => 
      tx.type == TransactionType.expense && previousPeriod.containsDate(tx.date)).toList();
    final previousIncome = allIncomeSources.where((income) => 
      previousPeriod.containsDate(income.date)).toList();
    
    // Calculate totals
    final currentExpenseTotal = currentExpenses.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    final currentIncomeTotal = currentIncome.fold(0.0, (sum, income) => sum + income.amount);
    final previousExpenseTotal = previousExpenses.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    final previousIncomeTotal = previousIncome.fold(0.0, (sum, income) => sum + income.amount);
    
    // Calculate velocities
    final expenseVelocity = calculateComparison(
      currentValue: currentExpenseTotal,
      previousValue: previousExpenseTotal,
    );
    
    final incomeVelocity = calculateComparison(
      currentValue: currentIncomeTotal,
      previousValue: previousIncomeTotal,
    );
    
    final currentSavings = currentIncomeTotal - currentExpenseTotal;
    final previousSavings = previousIncomeTotal - previousExpenseTotal;
    
    final savingsVelocity = calculateComparison(
      currentValue: currentSavings,
      previousValue: previousSavings,
    );
    
    return {
      'expense_velocity': expenseVelocity,
      'income_velocity': incomeVelocity,
      'savings_velocity': savingsVelocity,
      'burn_rate': _calculateBurnRate(currentPeriod, currentExpenseTotal),
      'runway': _calculateRunway(currentSavings, currentExpenseTotal),
    };
  }

  // Detect seasonal spending patterns
  static Map<String, double> detectSeasonalPatterns({
    required List<Transaction> allTransactions,
    required List<IncomeSource> allIncomeSources,
    bool analyzeIncome = false,
  }) {
    final monthlyTotals = <int, List<double>>{};
    
    // Initialize monthly lists
    for (int month = 1; month <= 12; month++) {
      monthlyTotals[month] = [];
    }
    
    if (analyzeIncome) {
      // Group income by month
      for (final income in allIncomeSources) {
        monthlyTotals[income.date.month]!.add(income.amount);
      }
    } else {
      // Group expenses by month
      final expenses = allTransactions.where((tx) => tx.type == TransactionType.expense);
      for (final expense in expenses) {
        monthlyTotals[expense.date.month]!.add(expense.amount.abs());
      }
    }
    
    // Calculate average for each month
    final seasonalPattern = <String, double>{};
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    for (int month = 1; month <= 12; month++) {
      final monthData = monthlyTotals[month]!;
      final average = monthData.isNotEmpty 
          ? monthData.reduce((a, b) => a + b) / monthData.length 
          : 0.0;
      seasonalPattern[monthNames[month - 1]] = average;
    }
    
    return seasonalPattern;
  }

  // Private helper methods
  static double _calculateTrendSlope(List<double> values) {
    if (values.length < 2) return 0;
    
    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = values;
    
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumXX = x.map((xi) => xi * xi).reduce((a, b) => a + b);
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope;
  }

  static String _getTrendDirection(double slope) {
    if (slope.abs() < 0.1) return 'stable';
    if (slope > 0.5) return 'strong_upward';
    if (slope > 0) return 'upward';
    if (slope < -0.5) return 'strong_downward';
    return 'downward';
  }

  static double _calculateVolatility(List<double> values, double average) {
    if (values.length < 2) return 0;
    
    final variance = values
        .map((value) => math.pow(value - average, 2))
        .reduce((a, b) => a + b) / values.length;
    
    return math.sqrt(variance);
  }

  static Map<String, double> _analyzeSeasonalPatterns(List<TimePeriod> periods, List<double> values) {
    final patterns = <String, double>{};
    
    if (periods.length != values.length) return patterns;
    
    // Group by month for seasonal analysis
    final monthlyData = <int, List<double>>{};
    
    for (int i = 0; i < periods.length; i++) {
      final month = periods[i].startDate.month;
      monthlyData.putIfAbsent(month, () => []);
      monthlyData[month]!.add(values[i]);
    }
    
    // Calculate averages for each month that has data
    monthlyData.forEach((month, monthValues) {
      final average = monthValues.reduce((a, b) => a + b) / monthValues.length;
      final monthName = TimePeriod.getMonthName(month);
      patterns[monthName] = average;
    });
    
    return patterns;
  }

  static String _generateCategoryInsight(String category, PeriodComparisonData comparison, double average) {
    if (comparison.trend == 'significant_increase') {
      return '$category spending increased significantly by ${comparison.changePercentage.toStringAsFixed(1)}%';
    } else if (comparison.trend == 'significant_decrease') {
      return '$category spending decreased significantly by ${comparison.changePercentage.abs().toStringAsFixed(1)}%';
    } else if (comparison.trend == 'moderate_increase') {
      return '$category spending up ${comparison.changePercentage.toStringAsFixed(1)}%';
    } else if (comparison.trend == 'moderate_decrease') {
      return '$category spending down ${comparison.changePercentage.abs().toStringAsFixed(1)}%';
    } else {
      return '$category spending remains stable';
    }
  }

  static double _calculateBurnRate(TimePeriod period, double totalExpenses) {
    final daysInPeriod = period.endDate.difference(period.startDate).inDays + 1;
    return totalExpenses / daysInPeriod;
  }

  static double _calculateRunway(double currentSavings, double monthlyExpenses) {
    if (monthlyExpenses <= 0) return double.infinity;
    return currentSavings / monthlyExpenses;
  }
}
