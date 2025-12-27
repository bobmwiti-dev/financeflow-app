import 'dart:math' as math;
import 'package:logging/logging.dart';
import '../models/transaction_model.dart';
import '../models/income_source_model.dart';
import '../models/ai_insights_model.dart';
import 'ai_intelligence_helper.dart';

class LocalAIIntelligenceService {
  static final LocalAIIntelligenceService _instance = LocalAIIntelligenceService._internal();
  factory LocalAIIntelligenceService() => _instance;
  LocalAIIntelligenceService._internal();

  final Logger _logger = Logger('LocalAIIntelligenceService');

  /// Comprehensive financial intelligence analysis
  Future<FinancialIntelligence> analyzeFinancialData({
    required List<Transaction> transactions,
    required List<IncomeSource> incomeSources,
    DateTime? analysisDate,
  }) async {
    final date = analysisDate ?? DateTime.now();
    
    _logger.info('Analyzing ${transactions.length} transactions and ${incomeSources.length} income sources');

    return FinancialIntelligence(
      spendingPatterns: _analyzeSpendingPatterns(transactions),
      kenyaSpecificInsights: _analyzeKenyaPatterns(transactions),
      predictiveInsights: _generatePredictions(transactions, incomeSources),
      anomalies: _detectAnomalies(transactions),
      recommendations: _generateRecommendations(transactions, incomeSources),
      budgetOptimization: _analyzeBudgetOptimization(transactions, incomeSources),
      seasonalInsights: _analyzeSeasonalPatterns(transactions, date),
      behaviorInsights: _analyzeBehaviorPatterns(transactions),
    );
  }

  /// Analyze spending patterns and trends
  SpendingPatterns _analyzeSpendingPatterns(List<Transaction> transactions) {
    final expenseTransactions = transactions.where((t) => t.type == TransactionType.expense).toList();
    
    if (expenseTransactions.isEmpty) {
      return SpendingPatterns.empty();
    }

    // Weekly pattern analysis
    final weekdaySpending = <int, List<double>>{};
    for (int i = 1; i <= 7; i++) {
      weekdaySpending[i] = [];
    }

    for (final tx in expenseTransactions) {
      weekdaySpending[tx.date.weekday]!.add(tx.amount.abs());
    }

    final weekdayAverages = weekdaySpending.map((day, amounts) => 
      MapEntry(day, amounts.isEmpty ? 0.0 : amounts.reduce((a, b) => a + b) / amounts.length));

    // Category analysis
    final categorySpending = <String, double>{};
    for (final tx in expenseTransactions) {
      categorySpending[tx.category] = (categorySpending[tx.category] ?? 0) + tx.amount.abs();
    }

    // Time-based patterns
    final hourlySpending = <int, double>{};
    for (final tx in expenseTransactions) {
      final hour = tx.date.hour;
      hourlySpending[hour] = (hourlySpending[hour] ?? 0) + tx.amount.abs();
    }

    return SpendingPatterns(
      weekdayAverages: weekdayAverages,
      categoryBreakdown: categorySpending,
      hourlyPatterns: hourlySpending,
      totalSpending: expenseTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs()),
      averageTransactionAmount: expenseTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs()) / expenseTransactions.length,
      mostActiveDay: _getMostActiveDay(weekdayAverages),
      peakSpendingHour: _getPeakSpendingHour(hourlySpending),
    );
  }

  /// Kenya-specific financial pattern analysis
  KenyaSpecificInsights _analyzeKenyaPatterns(List<Transaction> transactions) {
    final mpesaTransactions = transactions.where((t) => 
      t.title.toLowerCase().contains('mpesa') || 
      t.title.toLowerCase().contains('m-pesa') ||
      t.title.toLowerCase().contains('safaricom')).toList();

    final transportTransactions = transactions.where((t) => 
      t.category.toLowerCase().contains('transport') ||
      t.title.toLowerCase().contains('matatu') ||
      t.title.toLowerCase().contains('boda') ||
      t.title.toLowerCase().contains('uber') ||
      t.title.toLowerCase().contains('taxi')).toList();

    final foodTransactions = transactions.where((t) => 
      t.category.toLowerCase().contains('food') ||
      t.title.toLowerCase().contains('sukuma') ||
      t.title.toLowerCase().contains('ugali') ||
      t.title.toLowerCase().contains('nyama')).toList();

    return KenyaSpecificInsights(
      mpesaUsagePattern: _analyzeMpesaUsage(mpesaTransactions),
      transportOptimization: _analyzeTransportSpending(transportTransactions),
      localFoodSpending: _analyzeLocalFoodSpending(foodTransactions),
      seasonalAdjustments: AIIntelligenceHelper.getKenyaSeasonalAdjustments(),
      currencyInsights: _analyzeCurrencyPatterns(transactions),
    );
  }

  /// Generate predictive insights based on historical data
  PredictiveInsights _generatePredictions(List<Transaction> transactions, List<IncomeSource> incomeSources) {
    final recentTransactions = transactions.where((t) => 
      t.date.isAfter(DateTime.now().subtract(const Duration(days: 90)))).toList();

    if (recentTransactions.isEmpty) {
      return PredictiveInsights.empty();
    }

    // Predict next week spending
    final nextWeekPrediction = _predictNextWeekSpending(recentTransactions);
    
    // Predict monthly budget needs
    final monthlyBudgetPrediction = _predictMonthlyBudget(recentTransactions, incomeSources);
    
    // Predict category spending
    final categoryPredictions = _predictCategorySpending(recentTransactions);

    return PredictiveInsights(
      nextWeekSpending: nextWeekPrediction,
      monthlyBudgetNeeds: monthlyBudgetPrediction,
      categoryPredictions: categoryPredictions,
      confidenceScore: _calculatePredictionConfidence(recentTransactions),
      riskFactors: _identifyRiskFactors(recentTransactions, incomeSources),
    );
  }

  /// Detect spending anomalies and unusual patterns
  List<SpendingAnomaly> _detectAnomalies(List<Transaction> transactions) {
    final anomalies = <SpendingAnomaly>[];
    final expenseTransactions = transactions.where((t) => t.type == TransactionType.expense).toList();
    
    if (expenseTransactions.length < 10) return anomalies;

    // Calculate statistical thresholds
    final amounts = expenseTransactions.map((t) => t.amount.abs()).toList();
    amounts.sort();
    
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    final q3 = amounts[(amounts.length * 0.75).round()];
    final iqr = q3 - amounts[(amounts.length * 0.25).round()];
    final outlierThreshold = q3 + (1.5 * iqr);

    // Detect amount anomalies
    for (final tx in expenseTransactions) {
      if (tx.amount.abs() > outlierThreshold) {
        anomalies.add(SpendingAnomaly(
          transaction: tx,
          type: AnomalyType.unusualAmount,
          severity: _calculateSeverity(tx.amount.abs(), mean),
          description: 'Unusually high ${tx.category} expense: ${tx.amount.abs().toStringAsFixed(0)} KES',
          suggestion: 'This is ${(tx.amount.abs() / mean).toStringAsFixed(1)}x your average expense',
        ));
      }
    }

    // Detect frequency anomalies
    final categoryFrequency = <String, int>{};
    for (final tx in expenseTransactions) {
      categoryFrequency[tx.category] = (categoryFrequency[tx.category] ?? 0) + 1;
    }

    // Detect time-based anomalies
    final recentTransactions = expenseTransactions.where((t) => 
      t.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
    
    if (recentTransactions.length > expenseTransactions.length * 0.5) {
      anomalies.add(SpendingAnomaly(
        transaction: recentTransactions.first,
        type: AnomalyType.unusualFrequency,
        severity: AnomalySeverity.medium,
        description: 'Increased spending frequency detected',
        suggestion: 'You\'ve made ${recentTransactions.length} transactions this week, which is above your usual pattern',
      ));
    }

    return anomalies;
  }

  /// Generate actionable financial recommendations
  List<FinancialRecommendation> _generateRecommendations(List<Transaction> transactions, List<IncomeSource> incomeSources) {
    final recommendations = <FinancialRecommendation>[];
    
    // Transport optimization
    final transportRecommendation = _generateTransportRecommendation(transactions);
    if (transportRecommendation != null) recommendations.add(transportRecommendation);
    
    // Category optimization
    recommendations.addAll(_generateCategoryOptimizations(transactions));
    
    // Savings recommendations
    final savingsRecommendation = _generateSavingsRecommendation(transactions, incomeSources);
    if (savingsRecommendation != null) recommendations.add(savingsRecommendation);
    
    // Budget rebalancing
    recommendations.addAll(_generateBudgetRebalancing(transactions));

    return recommendations;
  }

  /// Analyze budget optimization opportunities
  BudgetOptimization _analyzeBudgetOptimization(List<Transaction> transactions, List<IncomeSource> incomeSources) {
    final totalIncome = incomeSources.fold(0.0, (sum, income) => sum + income.amount);
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());

    final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0.0;
    
    // Category-wise budget analysis
    final categorySpending = <String, double>{};
    for (final tx in transactions.where((t) => t.type == TransactionType.expense)) {
      categorySpending[tx.category] = (categorySpending[tx.category] ?? 0) + tx.amount.abs();
    }

    final optimizationOpportunities = <String, double>{};
    for (final entry in categorySpending.entries) {
      final percentage = (entry.value / totalExpenses) * 100;
      if (percentage > 30) { // Categories taking more than 30% of budget
        optimizationOpportunities[entry.key] = percentage;
      }
    }

    return BudgetOptimization(
      currentSavingsRate: savingsRate,
      recommendedSavingsRate: 20.0, // 20% savings rate target
      optimizationOpportunities: optimizationOpportunities,
      potentialSavings: _calculatePotentialSavings(categorySpending),
      budgetReallocation: _suggestBudgetReallocation(categorySpending, totalIncome),
    );
  }

  /// Helper methods for specific analyses
  MpesaUsagePattern _analyzeMpesaUsage(List<Transaction> mpesaTransactions) {
    if (mpesaTransactions.isEmpty) {
      return MpesaUsagePattern.empty();
    }

    final totalMpesaAmount = mpesaTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    final averageTransaction = totalMpesaAmount / mpesaTransactions.length;
    
    // Analyze transaction types
    final sendMoney = mpesaTransactions.where((t) => t.title.toLowerCase().contains('send')).length;
    final payBill = mpesaTransactions.where((t) => t.title.toLowerCase().contains('paybill')).length;
    final buyGoods = mpesaTransactions.where((t) => t.title.toLowerCase().contains('buy goods')).length;

    return MpesaUsagePattern(
      totalTransactions: mpesaTransactions.length,
      totalAmount: totalMpesaAmount,
      averageAmount: averageTransaction,
      sendMoneyCount: sendMoney,
      payBillCount: payBill,
      buyGoodsCount: buyGoods,
      usageFrequency: _calculateMpesaFrequency(mpesaTransactions),
    );
  }

  TransportOptimization _analyzeTransportSpending(List<Transaction> transportTransactions) {
    if (transportTransactions.isEmpty) {
      return TransportOptimization.empty();
    }

    final totalTransportSpending = transportTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    
    // Categorize transport types
    final uberSpending = transportTransactions
        .where((t) => t.title.toLowerCase().contains('uber'))
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
    
    final matatuSpending = transportTransactions
        .where((t) => t.title.toLowerCase().contains('matatu'))
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
    
    final bodaSpending = transportTransactions
        .where((t) => t.title.toLowerCase().contains('boda'))
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());

    // Calculate potential savings
    final potentialSavings = uberSpending * 0.6; // 60% savings by switching to matatu

    return TransportOptimization(
      totalSpending: totalTransportSpending,
      uberSpending: uberSpending,
      matatuSpending: matatuSpending,
      bodaSpending: bodaSpending,
      potentialSavings: potentialSavings,
      recommendation: _generateTransportRecommendationText(uberSpending, matatuSpending),
    );
  }

  List<double> _predictNextWeekSpending(List<Transaction> recentTransactions) {
    final weeklyPredictions = <double>[];
    
    // Group transactions by day of week
    final weekdaySpending = <int, List<double>>{};
    for (int i = 1; i <= 7; i++) {
      weekdaySpending[i] = [];
    }

    for (final tx in recentTransactions.where((t) => t.type == TransactionType.expense)) {
      weekdaySpending[tx.date.weekday]!.add(tx.amount.abs());
    }

    // Predict each day based on historical average with trend adjustment
    for (int day = 1; day <= 7; day++) {
      final dayAmounts = weekdaySpending[day]!;
      if (dayAmounts.isNotEmpty) {
        final average = dayAmounts.reduce((a, b) => a + b) / dayAmounts.length;
        final trend = _calculateTrend(dayAmounts);
        weeklyPredictions.add(math.max(0, average + trend));
      } else {
        weeklyPredictions.add(0.0);
      }
    }

    return weeklyPredictions;
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 3) return 0.0;
    
    final recent = values.sublist(math.max(0, values.length - 3));
    final older = values.sublist(0, math.min(3, values.length));
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    return (recentAvg - olderAvg) * 0.1; // 10% trend adjustment
  }

  int _getMostActiveDay(Map<int, double> weekdayAverages) {
    return weekdayAverages.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int _getPeakSpendingHour(Map<int, double> hourlySpending) {
    if (hourlySpending.isEmpty) return 12;
    return hourlySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  AnomalySeverity _calculateSeverity(double amount, double average) {
    final ratio = amount / average;
    if (ratio > 5) return AnomalySeverity.high;
    if (ratio > 3) return AnomalySeverity.medium;
    return AnomalySeverity.low;
  }

  /// Analyze seasonal spending patterns
  SeasonalInsights _analyzeSeasonalPatterns(List<Transaction> transactions, DateTime analysisDate) {
    final monthlyTrends = <String, double>{};
    final patterns = <SeasonalPattern>[];
    
    // Group transactions by month
    final monthlySpending = <int, double>{};
    for (final tx in transactions.where((t) => t.type == TransactionType.expense)) {
      monthlySpending[tx.date.month] = (monthlySpending[tx.date.month] ?? 0) + tx.amount.abs();
    }
    
    // Calculate trends
    for (final entry in monthlySpending.entries) {
      final monthName = _getMonthName(entry.key);
      monthlyTrends[monthName] = entry.value;
    }
    
    return SeasonalInsights(
      monthlyTrends: monthlyTrends,
      patterns: patterns,
      seasonalRecommendations: AIIntelligenceHelper.getKenyaSeasonalAdjustments(),
      seasonalityScore: _calculateSeasonalityScore(monthlySpending),
    );
  }

  /// Analyze user behavior patterns
  BehaviorInsights _analyzeBehaviorPatterns(List<Transaction> transactions) {
    final triggers = <SpendingTrigger>[];
    final emotionalPatterns = <String, double>{};
    
    // Analyze time-based triggers
    final weekendSpending = transactions.where((t) => 
      t.date.weekday >= 6 && t.type == TransactionType.expense).length;
    final weekdaySpending = transactions.where((t) => 
      t.date.weekday < 6 && t.type == TransactionType.expense).length;
    
    if (weekendSpending > weekdaySpending * 1.5) {
      triggers.add(SpendingTrigger(
        type: TriggerType.dayOfWeek,
        description: 'Higher spending on weekends',
        frequency: weekendSpending.toDouble(),
        averageAmount: 0.0,
        suggestions: ['Plan weekend activities with set budgets', 'Use cash for weekend spending'],
      ));
    }
    
    return BehaviorInsights(
      personality: _determineSpendingPersonality(transactions),
      triggers: triggers,
      emotionalSpendingPatterns: emotionalPatterns,
      recommendations: [],
    );
  }

  /// Analyze local food spending patterns
  LocalFoodSpending _analyzeLocalFoodSpending(List<Transaction> foodTransactions) {
    if (foodTransactions.isEmpty) {
      return LocalFoodSpending.empty();
    }
    
    final totalFoodSpending = foodTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    final averageMealCost = totalFoodSpending / foodTransactions.length;
    
    // Categorize food types
    final foodCategoryBreakdown = <String, double>{};
    for (final tx in foodTransactions) {
      if (tx.title.toLowerCase().contains('restaurant') || tx.title.toLowerCase().contains('hotel')) {
        foodCategoryBreakdown['Restaurant'] = (foodCategoryBreakdown['Restaurant'] ?? 0) + tx.amount.abs();
      } else if (tx.title.toLowerCase().contains('grocery') || tx.title.toLowerCase().contains('supermarket')) {
        foodCategoryBreakdown['Grocery'] = (foodCategoryBreakdown['Grocery'] ?? 0) + tx.amount.abs();
      } else {
        foodCategoryBreakdown['Other'] = (foodCategoryBreakdown['Other'] ?? 0) + tx.amount.abs();
      }
    }
    
    final localFoodRatio = (foodCategoryBreakdown['Grocery'] ?? 0) / totalFoodSpending;
    
    return LocalFoodSpending(
      totalFoodSpending: totalFoodSpending,
      localFoodRatio: localFoodRatio,
      averageMealCost: averageMealCost,
      foodCategoryBreakdown: foodCategoryBreakdown,
      recommendations: _generateFoodRecommendations(localFoodRatio, averageMealCost),
    );
  }

  /// Analyze currency usage patterns
  CurrencyInsights _analyzeCurrencyPatterns(List<Transaction> transactions) {
    double kesSpending = 0.0;
    double foreignSpending = 0.0;
    final currencyBreakdown = <String, double>{};
    
    for (final tx in transactions.where((t) => t.type == TransactionType.expense)) {
      // Assume KES if no currency specified or amount is typical KES range
      if (tx.amount.abs() > 10) { // Typical KES amounts
        kesSpending += tx.amount.abs();
        currencyBreakdown['KES'] = (currencyBreakdown['KES'] ?? 0) + tx.amount.abs();
      } else {
        foreignSpending += tx.amount.abs();
        currencyBreakdown['USD'] = (currencyBreakdown['USD'] ?? 0) + tx.amount.abs();
      }
    }
    
    return CurrencyInsights(
      kesSpending: kesSpending,
      foreignCurrencySpending: foreignSpending,
      currencyBreakdown: currencyBreakdown,
      exchangeRateAlerts: [],
    );
  }

  /// Predict monthly budget needs
  double _predictMonthlyBudget(List<Transaction> recentTransactions, List<IncomeSource> incomeSources) {
    if (recentTransactions.isEmpty) return 0.0;
    
    final monthlyExpenses = recentTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
    
    final totalIncome = incomeSources.fold(0.0, (sum, income) => sum + income.amount);
    
    // Predict based on trend and income
    final trend = _calculateTrend(recentTransactions.map((t) => t.amount.abs()).toList());
    return math.min(monthlyExpenses + trend, totalIncome * 0.8); // Cap at 80% of income
  }

  /// Predict category spending
  Map<String, double> _predictCategorySpending(List<Transaction> recentTransactions) {
    final categoryPredictions = <String, double>{};
    final categorySpending = <String, List<double>>{};
    
    // Group by category
    for (final tx in recentTransactions.where((t) => t.type == TransactionType.expense)) {
      categorySpending[tx.category] = (categorySpending[tx.category] ?? [])..add(tx.amount.abs());
    }
    
    // Predict each category
    for (final entry in categorySpending.entries) {
      final amounts = entry.value;
      if (amounts.isNotEmpty) {
        final average = amounts.reduce((a, b) => a + b) / amounts.length;
        final trend = _calculateTrend(amounts);
        categoryPredictions[entry.key] = math.max(0, average + trend);
      }
    }
    
    return categoryPredictions;
  }

  /// Helper methods
  String _getMonthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return month >= 1 && month <= 12 ? months[month] : 'Unknown';
  }

  double _calculateSeasonalityScore(Map<int, double> monthlySpending) {
    if (monthlySpending.length < 3) return 0.0;
    
    final values = monthlySpending.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    
    return math.min((variance / mean) * 100, 100.0); // Normalize to 0-100
  }

  SpendingPersonality _determineSpendingPersonality(List<Transaction> transactions) {
    if (transactions.isEmpty) return SpendingPersonality.balanced;
    
    final expenseTransactions = transactions.where((t) => t.type == TransactionType.expense).toList();
    if (expenseTransactions.isEmpty) return SpendingPersonality.conservative;
    
    final amounts = expenseTransactions.map((t) => t.amount.abs()).toList();
    amounts.sort();
    
    final q3 = amounts[(amounts.length * 0.75).round()];
    
    final highSpendingRatio = amounts.where((a) => a > q3).length / amounts.length;
    
    if (highSpendingRatio > 0.3) return SpendingPersonality.aggressive;
    if (highSpendingRatio > 0.15) return SpendingPersonality.balanced;
    return SpendingPersonality.conservative;
  }

  List<String> _generateFoodRecommendations(double localFoodRatio, double averageMealCost) {
    final recommendations = <String>[];
    
    if (localFoodRatio < 0.6) {
      recommendations.add('Consider cooking at home more often to save money');
    }
    
    if (averageMealCost > 500) { // KES 500 per meal
      recommendations.add('Look for more affordable dining options');
    }
    
    recommendations.add('Try local markets for fresh, affordable ingredients');
    
    return recommendations;
  }

  /// Use helper methods from AIIntelligenceHelper
  double _calculatePredictionConfidence(List<Transaction> transactions) {
    return AIIntelligenceHelper.calculatePredictionConfidence(transactions);
  }

  List<RiskFactor> _identifyRiskFactors(List<Transaction> transactions, List<IncomeSource> incomeSources) {
    return AIIntelligenceHelper.identifyRiskFactors(transactions, incomeSources);
  }

  FinancialRecommendation? _generateTransportRecommendation(List<Transaction> transactions) {
    return AIIntelligenceHelper.generateTransportRecommendation(transactions);
  }

  List<FinancialRecommendation> _generateCategoryOptimizations(List<Transaction> transactions) {
    return AIIntelligenceHelper.generateCategoryOptimizations(transactions);
  }

  FinancialRecommendation? _generateSavingsRecommendation(List<Transaction> transactions, List<IncomeSource> incomeSources) {
    return AIIntelligenceHelper.generateSavingsRecommendation(transactions, incomeSources);
  }

  List<FinancialRecommendation> _generateBudgetRebalancing(List<Transaction> transactions) {
    return AIIntelligenceHelper.generateBudgetRebalancing(transactions);
  }

  double _calculatePotentialSavings(Map<String, double> categorySpending) {
    return AIIntelligenceHelper.calculatePotentialSavings(categorySpending);
  }

  Map<String, double> _suggestBudgetReallocation(Map<String, double> categorySpending, double totalIncome) {
    return AIIntelligenceHelper.suggestBudgetReallocation(categorySpending, totalIncome);
  }

  String _generateTransportRecommendationText(double uberSpending, double matatuSpending) {
    return AIIntelligenceHelper.generateTransportRecommendationText(uberSpending, matatuSpending);
  }

  MpesaFrequency _calculateMpesaFrequency(List<Transaction> mpesaTransactions) {
    final daysPeriod = 30; // Assume 30-day analysis period
    return AIIntelligenceHelper.calculateMpesaFrequency(mpesaTransactions.length, daysPeriod);
  }
}

// Data classes for AI insights
class FinancialIntelligence {
  final SpendingPatterns spendingPatterns;
  final KenyaSpecificInsights kenyaSpecificInsights;
  final PredictiveInsights predictiveInsights;
  final List<SpendingAnomaly> anomalies;
  final List<FinancialRecommendation> recommendations;
  final BudgetOptimization budgetOptimization;
  final SeasonalInsights seasonalInsights;
  final BehaviorInsights behaviorInsights;

  FinancialIntelligence({
    required this.spendingPatterns,
    required this.kenyaSpecificInsights,
    required this.predictiveInsights,
    required this.anomalies,
    required this.recommendations,
    required this.budgetOptimization,
    required this.seasonalInsights,
    required this.behaviorInsights,
  });
}

class SpendingPatterns {
  final Map<int, double> weekdayAverages;
  final Map<String, double> categoryBreakdown;
  final Map<int, double> hourlyPatterns;
  final double totalSpending;
  final double averageTransactionAmount;
  final int mostActiveDay;
  final int peakSpendingHour;

  SpendingPatterns({
    required this.weekdayAverages,
    required this.categoryBreakdown,
    required this.hourlyPatterns,
    required this.totalSpending,
    required this.averageTransactionAmount,
    required this.mostActiveDay,
    required this.peakSpendingHour,
  });

  static SpendingPatterns empty() => SpendingPatterns(
    weekdayAverages: {},
    categoryBreakdown: {},
    hourlyPatterns: {},
    totalSpending: 0,
    averageTransactionAmount: 0,
    mostActiveDay: 1,
    peakSpendingHour: 12,
  );
}

class KenyaSpecificInsights {
  final MpesaUsagePattern mpesaUsagePattern;
  final TransportOptimization transportOptimization;
  final LocalFoodSpending localFoodSpending;
  final Map<String, String> seasonalAdjustments;
  final CurrencyInsights currencyInsights;

  KenyaSpecificInsights({
    required this.mpesaUsagePattern,
    required this.transportOptimization,
    required this.localFoodSpending,
    required this.seasonalAdjustments,
    required this.currencyInsights,
  });
}

class SpendingAnomaly {
  final Transaction transaction;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String description;
  final String suggestion;

  SpendingAnomaly({
    required this.transaction,
    required this.type,
    required this.severity,
    required this.description,
    required this.suggestion,
  });
}

enum AnomalyType { unusualAmount, unusualFrequency, unusualCategory, unusualTiming }
enum AnomalySeverity { low, medium, high }

// Additional data classes would be defined here...
