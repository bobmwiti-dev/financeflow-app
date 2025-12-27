import 'dart:math' as math;
import '../models/transaction_model.dart';
import '../models/income_source_model.dart';
import '../models/ai_insights_model.dart';

/// Helper class for AI intelligence calculations and analysis
class AIIntelligenceHelper {
  
  /// Calculate M-Pesa usage frequency based on transaction count
  static MpesaFrequency calculateMpesaFrequency(int transactionCount, int daysPeriod) {
    if (daysPeriod == 0) return MpesaFrequency.none;
    
    final transactionsPerDay = transactionCount / daysPeriod;
    
    if (transactionsPerDay >= 3) return MpesaFrequency.veryHigh;
    if (transactionsPerDay >= 1.5) return MpesaFrequency.high;
    if (transactionsPerDay >= 0.5) return MpesaFrequency.medium;
    if (transactionsPerDay > 0) return MpesaFrequency.low;
    return MpesaFrequency.none;
  }

  /// Generate transport recommendation text
  static String generateTransportRecommendationText(double uberSpending, double matatuSpending) {
    if (uberSpending == 0 && matatuSpending == 0) {
      return 'No transport spending detected';
    }
    
    if (uberSpending > matatuSpending * 2) {
      return 'Consider using matatu more often. You could save up to 60% on transport costs.';
    } else if (matatuSpending > uberSpending) {
      return 'Great job using affordable transport! Keep using matatu for daily commutes.';
    } else {
      return 'Good balance between convenience and cost. Consider matatu for routine trips.';
    }
  }

  /// Calculate potential savings from category optimization
  static double calculatePotentialSavings(Map<String, double> categorySpending) {
    double potentialSavings = 0.0;
    
    for (final entry in categorySpending.entries) {
      switch (entry.key.toLowerCase()) {
        case 'transport':
          potentialSavings += entry.value * 0.3; // 30% savings potential
          break;
        case 'food':
        case 'dining':
          potentialSavings += entry.value * 0.2; // 20% savings potential
          break;
        case 'entertainment':
          potentialSavings += entry.value * 0.4; // 40% savings potential
          break;
        case 'shopping':
          potentialSavings += entry.value * 0.25; // 25% savings potential
          break;
        default:
          potentialSavings += entry.value * 0.1; // 10% general savings
      }
    }
    
    return potentialSavings;
  }

  /// Suggest budget reallocation based on spending patterns
  static Map<String, double> suggestBudgetReallocation(
    Map<String, double> categorySpending, 
    double totalIncome
  ) {
    final reallocation = <String, double>{};
    final totalSpending = categorySpending.values.fold(0.0, (sum, amount) => sum + amount);
    
    if (totalIncome <= 0 || totalSpending <= 0) return reallocation;
    
    // Recommended budget percentages for Kenya
    final recommendedPercentages = {
      'Housing': 0.30,
      'Food': 0.20,
      'Transport': 0.15,
      'Savings': 0.20,
      'Entertainment': 0.05,
      'Utilities': 0.10,
    };
    
    for (final entry in recommendedPercentages.entries) {
      final currentSpending = categorySpending[entry.key] ?? 0.0;
      final recommendedAmount = totalIncome * entry.value;
      final difference = recommendedAmount - currentSpending;
      
      if (difference.abs() > totalIncome * 0.02) { // 2% threshold
        reallocation[entry.key] = difference;
      }
    }
    
    return reallocation;
  }

  /// Analyze seasonal patterns for Kenya
  static Map<String, String> getKenyaSeasonalAdjustments() {
    return {
      'January': 'Post-holiday recovery period. Focus on rebuilding savings.',
      'February': 'Valentine\'s season. Budget for relationship expenses.',
      'March': 'School fees season. Prepare for education expenses.',
      'April': 'Long rains begin. Budget for transport delays and food price changes.',
      'May': 'Rainy season continues. Indoor activities may increase entertainment spending.',
      'June': 'Mid-year review. Good time for budget adjustments.',
      'July': 'School holidays. Plan for family activities and travel.',
      'August': 'Back to school. Prepare for education-related expenses.',
      'September': 'Short rains preparation. Stock up on essentials.',
      'October': 'Short rains season. Transport costs may increase.',
      'November': 'Harvest season. Food prices typically decrease.',
      'December': 'Holiday season. Plan for increased social and gift expenses.',
    };
  }

  /// Calculate prediction confidence based on data quality
  static double calculatePredictionConfidence(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    // Factors affecting confidence
    double confidence = 0.0;
    
    // Data volume (30% weight)
    final dataVolumeScore = math.min(transactions.length / 100.0, 1.0) * 30;
    confidence += dataVolumeScore;
    
    // Data recency (25% weight)
    final now = DateTime.now();
    final recentTransactions = transactions.where((t) => 
      now.difference(t.date).inDays <= 30).length;
    final recencyScore = math.min(recentTransactions / 30.0, 1.0) * 25;
    confidence += recencyScore;
    
    // Data consistency (25% weight)
    final categoryConsistency = _calculateCategoryConsistency(transactions);
    confidence += categoryConsistency * 25;
    
    // Data completeness (20% weight)
    final completenessScore = _calculateDataCompleteness(transactions);
    confidence += completenessScore * 20;
    
    return math.min(confidence, 100.0);
  }

  /// Identify financial risk factors
  static List<RiskFactor> identifyRiskFactors(
    List<Transaction> transactions, 
    List<IncomeSource> incomeSources
  ) {
    final risks = <RiskFactor>[];
    
    final totalIncome = incomeSources.fold(0.0, (sum, income) => sum + income.amount);
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
    
    // Overspending risk
    if (totalExpenses > totalIncome * 0.9) {
      risks.add(RiskFactor(
        type: RiskType.overspending,
        level: totalExpenses > totalIncome ? RiskLevel.high : RiskLevel.medium,
        description: 'Spending ${(totalExpenses / totalIncome * 100).toStringAsFixed(1)}% of income',
        impact: totalExpenses - totalIncome,
        mitigationSteps: [
          'Review and cut non-essential expenses',
          'Set up automatic savings',
          'Create a strict monthly budget',
        ],
      ));
    }
    
    // Category imbalance risk
    final categorySpending = <String, double>{};
    for (final tx in transactions.where((t) => t.type == TransactionType.expense)) {
      categorySpending[tx.category] = (categorySpending[tx.category] ?? 0) + tx.amount.abs();
    }
    
    for (final entry in categorySpending.entries) {
      final percentage = (entry.value / totalExpenses) * 100;
      if (percentage > 50) { // Single category > 50% of spending
        risks.add(RiskFactor(
          type: RiskType.categoryImbalance,
          level: RiskLevel.medium,
          description: '${entry.key} represents ${percentage.toStringAsFixed(1)}% of spending',
          impact: entry.value - (totalExpenses * 0.3), // Ideal max 30%
          mitigationSteps: [
            'Diversify spending across categories',
            'Set category-specific budgets',
            'Find alternatives in the ${entry.key} category',
          ],
        ));
      }
    }
    
    // Emergency fund risk
    final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) : 0.0;
    if (savingsRate < 0.1) { // Less than 10% savings rate
      risks.add(RiskFactor(
        type: RiskType.emergencyFundLack,
        level: savingsRate < 0 ? RiskLevel.high : RiskLevel.medium,
        description: 'Low savings rate: ${(savingsRate * 100).toStringAsFixed(1)}%',
        impact: (totalIncome * 0.2) - (totalIncome - totalExpenses), // Target 20% savings
        mitigationSteps: [
          'Automate savings transfers',
          'Build emergency fund (3-6 months expenses)',
          'Reduce discretionary spending',
        ],
      ));
    }
    
    return risks;
  }

  /// Generate category-specific optimization recommendations
  static List<FinancialRecommendation> generateCategoryOptimizations(List<Transaction> transactions) {
    final recommendations = <FinancialRecommendation>[];
    
    // Group by category
    final categorySpending = <String, double>{};
    final categoryTransactions = <String, List<Transaction>>{};
    
    for (final tx in transactions.where((t) => t.type == TransactionType.expense)) {
      categorySpending[tx.category] = (categorySpending[tx.category] ?? 0) + tx.amount.abs();
      categoryTransactions[tx.category] = (categoryTransactions[tx.category] ?? [])..add(tx);
    }
    
    final totalSpending = categorySpending.values.fold(0.0, (sum, amount) => sum + amount);
    
    for (final entry in categorySpending.entries) {
      final percentage = (entry.value / totalSpending) * 100;
      final transactions = categoryTransactions[entry.key]!;
      
      if (percentage > 30 && entry.value > 5000) { // High spending category
        recommendations.add(FinancialRecommendation(
          id: 'category_opt_${entry.key.toLowerCase()}',
          type: RecommendationType.categoryReduction,
          title: 'Optimize ${entry.key} Spending',
          description: '${entry.key} represents ${percentage.toStringAsFixed(1)}% of your spending (KES ${entry.value.toStringAsFixed(0)})',
          potentialSavings: entry.value * 0.2, // 20% reduction potential
          priority: percentage > 40 ? Priority.high : Priority.medium,
          actionSteps: _generateCategoryActionSteps(entry.key, transactions),
          createdAt: DateTime.now(),
        ));
      }
    }
    
    return recommendations;
  }

  /// Generate transport-specific recommendation
  static FinancialRecommendation? generateTransportRecommendation(List<Transaction> transactions) {
    final transportTransactions = transactions.where((t) => 
      t.category.toLowerCase().contains('transport')).toList();
    
    if (transportTransactions.isEmpty) return null;
    
    final totalTransportSpending = transportTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    
    if (totalTransportSpending < 2000) return null; // Below KES 2,000, not worth optimizing
    
    final uberCount = transportTransactions.where((t) => 
      t.title.toLowerCase().contains('uber')).length;
    
    final matatuCount = transportTransactions.where((t) => 
      t.title.toLowerCase().contains('matatu')).length;
    
    if (uberCount > matatuCount && totalTransportSpending > 5000) {
      return FinancialRecommendation(
        id: 'transport_optimization',
        type: RecommendationType.transportOptimization,
        title: 'Optimize Transport Costs',
        description: 'You could save significantly by using matatu more often for daily commutes',
        potentialSavings: totalTransportSpending * 0.4, // 40% savings potential
        priority: Priority.high,
        actionSteps: [
          'Use matatu for regular commutes (save 60% vs Uber)',
          'Reserve Uber for late nights or urgent trips',
          'Consider boda boda for short distances',
          'Plan routes to minimize transport costs',
        ],
        createdAt: DateTime.now(),
      );
    }
    
    return null;
  }

  /// Generate savings recommendation
  static FinancialRecommendation? generateSavingsRecommendation(
    List<Transaction> transactions, 
    List<IncomeSource> incomeSources
  ) {
    final totalIncome = incomeSources.fold(0.0, (sum, income) => sum + income.amount);
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
    
    if (totalIncome <= 0) return null;
    
    final currentSavingsRate = ((totalIncome - totalExpenses) / totalIncome) * 100;
    
    if (currentSavingsRate < 15) { // Below 15% savings rate
      return FinancialRecommendation(
        id: 'increase_savings',
        type: RecommendationType.savingsIncrease,
        title: 'Increase Your Savings Rate',
        description: 'Current savings rate: ${currentSavingsRate.toStringAsFixed(1)}%. Target: 20%',
        potentialSavings: totalIncome * 0.05, // 5% improvement
        priority: currentSavingsRate < 5 ? Priority.high : Priority.medium,
        actionSteps: [
          'Set up automatic savings transfer',
          'Use the 50/30/20 rule (needs/wants/savings)',
          'Review and cut unnecessary subscriptions',
          'Cook at home more often',
        ],
        createdAt: DateTime.now(),
      );
    }
    
    return null;
  }

  /// Generate budget rebalancing recommendations
  static List<FinancialRecommendation> generateBudgetRebalancing(List<Transaction> transactions) {
    final recommendations = <FinancialRecommendation>[];
    
    // This would analyze spending patterns and suggest rebalancing
    // Implementation would be similar to category optimizations
    
    return recommendations;
  }

  // Private helper methods
  static double _calculateCategoryConsistency(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    final categories = transactions.map((t) => t.category).toSet();
    final expectedCategories = ['Food', 'Transport', 'Housing', 'Entertainment', 'Utilities'];
    
    final matchingCategories = categories.where((c) => 
      expectedCategories.any((expected) => 
        c.toLowerCase().contains(expected.toLowerCase()))).length;
    
    return matchingCategories / expectedCategories.length;
  }

  static double _calculateDataCompleteness(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;
    
    final completeTransactions = transactions.where((t) => 
      t.title.isNotEmpty && 
      t.category.isNotEmpty && 
      t.amount != 0).length;
    
    return completeTransactions / transactions.length;
  }

  static List<String> _generateCategoryActionSteps(String category, List<Transaction> transactions) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
        return [
          'Cook at home more often',
          'Plan meals and create shopping lists',
          'Look for local market deals',
          'Reduce restaurant visits to weekends only',
        ];
      case 'transport':
        return [
          'Use matatu instead of Uber for daily commutes',
          'Walk or cycle for short distances',
          'Plan trips to reduce multiple journeys',
          'Consider carpooling with colleagues',
        ];
      case 'entertainment':
        return [
          'Look for free community events',
          'Host gatherings at home instead of going out',
          'Take advantage of happy hour deals',
          'Explore outdoor activities like hiking',
        ];
      case 'shopping':
        return [
          'Create a shopping list and stick to it',
          'Wait 24 hours before making non-essential purchases',
          'Compare prices across different stores',
          'Buy generic brands when possible',
        ];
      default:
        return [
          'Review all transactions in this category',
          'Identify the largest expenses',
          'Look for alternatives or substitutes',
          'Set a monthly limit for this category',
        ];
    }
  }
}
