import 'package:flutter/material.dart';

/// Comprehensive AI insights data models
class PredictiveInsights {
  final List<double> nextWeekSpending;
  final double monthlyBudgetNeeds;
  final Map<String, double> categoryPredictions;
  final double confidenceScore;
  final List<RiskFactor> riskFactors;

  PredictiveInsights({
    required this.nextWeekSpending,
    required this.monthlyBudgetNeeds,
    required this.categoryPredictions,
    required this.confidenceScore,
    required this.riskFactors,
  });

  static PredictiveInsights empty() => PredictiveInsights(
    nextWeekSpending: List.filled(7, 0.0),
    monthlyBudgetNeeds: 0.0,
    categoryPredictions: {},
    confidenceScore: 0.0,
    riskFactors: [],
  );
}

class MpesaUsagePattern {
  final int totalTransactions;
  final double totalAmount;
  final double averageAmount;
  final int sendMoneyCount;
  final int payBillCount;
  final int buyGoodsCount;
  final MpesaFrequency usageFrequency;

  MpesaUsagePattern({
    required this.totalTransactions,
    required this.totalAmount,
    required this.averageAmount,
    required this.sendMoneyCount,
    required this.payBillCount,
    required this.buyGoodsCount,
    required this.usageFrequency,
  });

  static MpesaUsagePattern empty() => MpesaUsagePattern(
    totalTransactions: 0,
    totalAmount: 0.0,
    averageAmount: 0.0,
    sendMoneyCount: 0,
    payBillCount: 0,
    buyGoodsCount: 0,
    usageFrequency: MpesaFrequency.none,
  );

  double get efficiencyScore {
    if (totalTransactions == 0) return 0.0;
    
    // Higher score for more paybill/buy goods vs send money
    final digitalPaymentRatio = (payBillCount + buyGoodsCount) / totalTransactions;
    return (digitalPaymentRatio * 100).clamp(0.0, 100.0);
  }

  String get usageInsight {
    if (totalTransactions == 0) return 'No M-Pesa usage detected';
    
    if (efficiencyScore > 70) {
      return 'Excellent M-Pesa usage! You\'re maximizing digital payments.';
    } else if (efficiencyScore > 40) {
      return 'Good M-Pesa usage. Consider using more PayBill and Buy Goods services.';
    } else {
      return 'Consider using M-Pesa PayBill and Buy Goods for better financial tracking.';
    }
  }
}

class TransportOptimization {
  final double totalSpending;
  final double uberSpending;
  final double matatuSpending;
  final double bodaSpending;
  final double potentialSavings;
  final String recommendation;

  TransportOptimization({
    required this.totalSpending,
    required this.uberSpending,
    required this.matatuSpending,
    required this.bodaSpending,
    required this.potentialSavings,
    required this.recommendation,
  });

  static TransportOptimization empty() => TransportOptimization(
    totalSpending: 0.0,
    uberSpending: 0.0,
    matatuSpending: 0.0,
    bodaSpending: 0.0,
    potentialSavings: 0.0,
    recommendation: 'No transport spending detected',
  );

  double get savingsPercentage {
    if (totalSpending == 0) return 0.0;
    return (potentialSavings / totalSpending) * 100;
  }

  TransportEfficiency get efficiency {
    if (totalSpending == 0) return TransportEfficiency.unknown;
    
    final matatuRatio = matatuSpending / totalSpending;
    if (matatuRatio > 0.7) return TransportEfficiency.excellent;
    if (matatuRatio > 0.4) return TransportEfficiency.good;
    if (matatuRatio > 0.2) return TransportEfficiency.fair;
    return TransportEfficiency.poor;
  }
}

class LocalFoodSpending {
  final double totalFoodSpending;
  final double localFoodRatio;
  final double averageMealCost;
  final Map<String, double> foodCategoryBreakdown;
  final List<String> recommendations;

  LocalFoodSpending({
    required this.totalFoodSpending,
    required this.localFoodRatio,
    required this.averageMealCost,
    required this.foodCategoryBreakdown,
    required this.recommendations,
  });

  static LocalFoodSpending empty() => LocalFoodSpending(
    totalFoodSpending: 0.0,
    localFoodRatio: 0.0,
    averageMealCost: 0.0,
    foodCategoryBreakdown: {},
    recommendations: [],
  );
}

class CurrencyInsights {
  final double kesSpending;
  final double foreignCurrencySpending;
  final Map<String, double> currencyBreakdown;
  final List<String> exchangeRateAlerts;

  CurrencyInsights({
    required this.kesSpending,
    required this.foreignCurrencySpending,
    required this.currencyBreakdown,
    required this.exchangeRateAlerts,
  });

  static CurrencyInsights empty() => CurrencyInsights(
    kesSpending: 0.0,
    foreignCurrencySpending: 0.0,
    currencyBreakdown: {},
    exchangeRateAlerts: [],
  );
}

class BudgetOptimization {
  final double currentSavingsRate;
  final double recommendedSavingsRate;
  final Map<String, double> optimizationOpportunities;
  final double potentialSavings;
  final Map<String, double> budgetReallocation;

  BudgetOptimization({
    required this.currentSavingsRate,
    required this.recommendedSavingsRate,
    required this.optimizationOpportunities,
    required this.potentialSavings,
    required this.budgetReallocation,
  });

  double get savingsGap => recommendedSavingsRate - currentSavingsRate;
  
  BudgetHealth get health {
    if (currentSavingsRate >= recommendedSavingsRate) return BudgetHealth.excellent;
    if (currentSavingsRate >= recommendedSavingsRate * 0.7) return BudgetHealth.good;
    if (currentSavingsRate >= 0) return BudgetHealth.fair;
    return BudgetHealth.poor;
  }
}

class SeasonalInsights {
  final Map<String, double> monthlyTrends;
  final List<SeasonalPattern> patterns;
  final Map<String, String> seasonalRecommendations;
  final double seasonalityScore;

  SeasonalInsights({
    required this.monthlyTrends,
    required this.patterns,
    required this.seasonalRecommendations,
    required this.seasonalityScore,
  });

  static SeasonalInsights empty() => SeasonalInsights(
    monthlyTrends: {},
    patterns: [],
    seasonalRecommendations: {},
    seasonalityScore: 0.0,
  );
}

class BehaviorInsights {
  final SpendingPersonality personality;
  final List<SpendingTrigger> triggers;
  final Map<String, double> emotionalSpendingPatterns;
  final List<BehaviorRecommendation> recommendations;

  BehaviorInsights({
    required this.personality,
    required this.triggers,
    required this.emotionalSpendingPatterns,
    required this.recommendations,
  });

  static BehaviorInsights empty() => BehaviorInsights(
    personality: SpendingPersonality.balanced,
    triggers: [],
    emotionalSpendingPatterns: {},
    recommendations: [],
  );
}

class FinancialRecommendation {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final double potentialSavings;
  final Priority priority;
  final List<String> actionSteps;
  final DateTime createdAt;
  final bool isImplemented;

  FinancialRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.priority,
    required this.actionSteps,
    required this.createdAt,
    this.isImplemented = false,
  });

  Color get priorityColor {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case RecommendationType.transportOptimization:
        return Icons.directions_bus;
      case RecommendationType.categoryReduction:
        return Icons.trending_down;
      case RecommendationType.savingsIncrease:
        return Icons.savings;
      case RecommendationType.budgetReallocation:
        return Icons.pie_chart;
      case RecommendationType.mpesaOptimization:
        return Icons.phone_android;
      case RecommendationType.seasonalAdjustment:
        return Icons.calendar_today;
    }
  }
}

class RiskFactor {
  final RiskType type;
  final RiskLevel level;
  final String description;
  final double impact;
  final List<String> mitigationSteps;

  RiskFactor({
    required this.type,
    required this.level,
    required this.description,
    required this.impact,
    required this.mitigationSteps,
  });

  Color get levelColor {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }
}

class SeasonalPattern {
  final String name;
  final List<int> affectedMonths;
  final double averageImpact;
  final String description;
  final List<String> recommendations;

  SeasonalPattern({
    required this.name,
    required this.affectedMonths,
    required this.averageImpact,
    required this.description,
    required this.recommendations,
  });
}

class SpendingTrigger {
  final TriggerType type;
  final String description;
  final double frequency;
  final double averageAmount;
  final List<String> suggestions;

  SpendingTrigger({
    required this.type,
    required this.description,
    required this.frequency,
    required this.averageAmount,
    required this.suggestions,
  });
}

class BehaviorRecommendation {
  final String title;
  final String description;
  final BehaviorChangeType changeType;
  final double difficultyScore;
  final double impactScore;

  BehaviorRecommendation({
    required this.title,
    required this.description,
    required this.changeType,
    required this.difficultyScore,
    required this.impactScore,
  });
}

// Enums
enum MpesaFrequency { none, low, medium, high, veryHigh }
enum TransportEfficiency { unknown, poor, fair, good, excellent }
enum BudgetHealth { poor, fair, good, excellent }
enum SpendingPersonality { conservative, balanced, aggressive, impulsive }
enum RecommendationType { 
  transportOptimization, 
  categoryReduction, 
  savingsIncrease, 
  budgetReallocation,
  mpesaOptimization,
  seasonalAdjustment
}
enum Priority { low, medium, high }
enum RiskType { 
  overspending, 
  categoryImbalance, 
  seasonalRisk, 
  incomeVolatility,
  emergencyFundLack
}
enum RiskLevel { low, medium, high }
enum TriggerType { 
  timeOfDay, 
  dayOfWeek, 
  emotional, 
  social, 
  location,
  weather
}
enum BehaviorChangeType { 
  habitFormation, 
  mindsetShift, 
  systemChange, 
  environmentalChange
}

// Extension methods for better usability
extension MpesaFrequencyExtension on MpesaFrequency {
  String get displayName {
    switch (this) {
      case MpesaFrequency.none:
        return 'No Usage';
      case MpesaFrequency.low:
        return 'Low Usage';
      case MpesaFrequency.medium:
        return 'Medium Usage';
      case MpesaFrequency.high:
        return 'High Usage';
      case MpesaFrequency.veryHigh:
        return 'Very High Usage';
    }
  }
}

extension TransportEfficiencyExtension on TransportEfficiency {
  String get displayName {
    switch (this) {
      case TransportEfficiency.unknown:
        return 'Unknown';
      case TransportEfficiency.poor:
        return 'Needs Improvement';
      case TransportEfficiency.fair:
        return 'Fair';
      case TransportEfficiency.good:
        return 'Good';
      case TransportEfficiency.excellent:
        return 'Excellent';
    }
  }

  String get recommendation {
    switch (this) {
      case TransportEfficiency.unknown:
        return 'Add more transport transactions to get insights';
      case TransportEfficiency.poor:
        return 'Consider using matatu more often to reduce costs';
      case TransportEfficiency.fair:
        return 'Good balance, but room for improvement';
      case TransportEfficiency.good:
        return 'Great transport choices! Keep it up';
      case TransportEfficiency.excellent:
        return 'Optimal transport spending pattern';
    }
  }
}

extension BudgetHealthExtension on BudgetHealth {
  String get displayName {
    switch (this) {
      case BudgetHealth.poor:
        return 'Needs Attention';
      case BudgetHealth.fair:
        return 'Fair';
      case BudgetHealth.good:
        return 'Good';
      case BudgetHealth.excellent:
        return 'Excellent';
    }
  }

  Color get color {
    switch (this) {
      case BudgetHealth.poor:
        return Colors.red;
      case BudgetHealth.fair:
        return Colors.orange;
      case BudgetHealth.good:
        return Colors.blue;
      case BudgetHealth.excellent:
        return Colors.green;
    }
  }
}
