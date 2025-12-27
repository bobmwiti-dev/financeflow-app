import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ai_behavioral_model.dart';
import '../models/mpesa_analytics_model.dart';
import '../models/transaction_model.dart' as app_models;
import 'mpesa_analytics_service.dart';

/// Advanced AI service for behavioral analysis and intelligent insights
class AIBehavioralService {
  static const String _logName = 'AIBehavioralService';
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate comprehensive behavioral analysis
  static Future<AIBehavioralAnalysis> generateBehavioralAnalysis() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      developer.log('Generating AI behavioral analysis', name: _logName);

      // Get user's financial data
      final mpesaAnalytics = await MpesaAnalyticsService.generateAnalytics();
      final transactions = await _getRecentTransactions(userId);
      
      // Generate different types of analysis
      final behaviorPatterns = await _analyzeBehaviorPatterns(transactions, mpesaAnalytics);
      final fraudAlerts = await _detectFraudPatterns(transactions);
      final budgetPredictions = await _generateBudgetPredictions(transactions);
      final savingsOpportunities = await _identifySavingsOpportunities(mpesaAnalytics);
      
      // Calculate overall metrics
      final overallMetrics = _calculateOverallMetrics(transactions, mpesaAnalytics);
      final financialHealthScore = _calculateFinancialHealthScore(
        behaviorPatterns, fraudAlerts, budgetPredictions, overallMetrics
      );
      
      // Generate insights and recommendations
      final keyInsights = _generateKeyInsights(
        behaviorPatterns, budgetPredictions, savingsOpportunities
      );
      final recommendations = _generateRecommendations(
        behaviorPatterns, savingsOpportunities, budgetPredictions
      );

      return AIBehavioralAnalysis(
        analysisId: _generateAnalysisId(),
        userId: userId,
        generatedAt: DateTime.now(),
        behaviorPatterns: behaviorPatterns,
        fraudAlerts: fraudAlerts,
        budgetPredictions: budgetPredictions,
        savingsOpportunities: savingsOpportunities,
        overallMetrics: overallMetrics,
        financialHealthScore: financialHealthScore,
        keyInsights: keyInsights,
        actionableRecommendations: recommendations,
      );

    } catch (e) {
      developer.log('Error generating behavioral analysis: $e', name: _logName);
      rethrow;
    }
  }

  /// Analyze spending behavior patterns
  static Future<List<SpendingBehaviorPattern>> _analyzeBehaviorPatterns(
    List<app_models.Transaction> transactions,
    MpesaAnalyticsSummary mpesaAnalytics,
  ) async {
    final patterns = <SpendingBehaviorPattern>[];

    // Weekend overspending pattern
    final weekendPattern = _analyzeWeekendSpending(transactions);
    if (weekendPattern != null) patterns.add(weekendPattern);

    // Payday splurge pattern
    final paydayPattern = _analyzePaydaySpending(transactions);
    if (paydayPattern != null) patterns.add(paydayPattern);

    // Stress spending pattern
    final stressPattern = _analyzeStressSpending(transactions);
    if (stressPattern != null) patterns.add(stressPattern);

    // M-Pesa specific patterns
    final mpesaPatterns = _analyzeMpesaPatterns(mpesaAnalytics);
    patterns.addAll(mpesaPatterns);

    return patterns;
  }

  /// Detect potential fraud patterns
  static Future<List<FraudAlert>> _detectFraudPatterns(
    List<app_models.Transaction> transactions,
  ) async {
    final alerts = <FraudAlert>[];

    // Unusual amount detection
    final unusualAmounts = _detectUnusualAmounts(transactions);
    alerts.addAll(unusualAmounts);

    // Unusual timing detection
    final unusualTiming = _detectUnusualTiming(transactions);
    alerts.addAll(unusualTiming);

    // Rapid succession transactions
    final rapidTransactions = _detectRapidTransactions(transactions);
    alerts.addAll(rapidTransactions);

    return alerts;
  }

  /// Generate budget predictions and warnings
  static Future<List<BudgetPrediction>> _generateBudgetPredictions(
    List<app_models.Transaction> transactions,
  ) async {
    final predictions = <BudgetPrediction>[];

    // Group transactions by category
    final categorySpending = <String, List<app_models.Transaction>>{};
    for (final tx in transactions) {
      categorySpending.putIfAbsent(tx.category, () => []).add(tx);
    }

    // Generate predictions for each category
    for (final entry in categorySpending.entries) {
      final prediction = _predictCategoryBudget(entry.key, entry.value);
      if (prediction != null) predictions.add(prediction);
    }

    return predictions;
  }

  /// Identify savings opportunities
  static Future<List<SavingsOpportunity>> _identifySavingsOpportunities(
    MpesaAnalyticsSummary mpesaAnalytics,
  ) async {
    final opportunities = <SavingsOpportunity>[];

    // Agent switching opportunities
    final agentOpportunities = _identifyAgentSwitchingOpportunities(mpesaAnalytics);
    opportunities.addAll(agentOpportunities);

    // Merchant alternatives
    final merchantOpportunities = _identifyMerchantAlternatives(mpesaAnalytics);
    opportunities.addAll(merchantOpportunities);

    // Timing optimization
    final timingOpportunities = _identifyTimingOptimizations(mpesaAnalytics);
    opportunities.addAll(timingOpportunities);

    return opportunities;
  }

  /// Analyze weekend spending patterns
  static SpendingBehaviorPattern? _analyzeWeekendSpending(List<app_models.Transaction> transactions) {
    final weekdaySpending = <double>[];
    final weekendSpending = <double>[];

    for (final tx in transactions) {
      if (tx.date.weekday >= 6) { // Saturday = 6, Sunday = 7
        weekendSpending.add(tx.amount);
      } else {
        weekdaySpending.add(tx.amount);
      }
    }

    if (weekendSpending.isEmpty || weekdaySpending.isEmpty) return null;

    final avgWeekend = weekendSpending.reduce((a, b) => a + b) / weekendSpending.length;
    final avgWeekday = weekdaySpending.reduce((a, b) => a + b) / weekdaySpending.length;
    final overspendPercentage = (avgWeekend - avgWeekday) / avgWeekday;

    if (overspendPercentage > 0.3) { // 30% more spending on weekends
      return SpendingBehaviorPattern(
        patternId: 'weekend_overspend_${DateTime.now().millisecondsSinceEpoch}',
        patternType: 'weekend_overspend',
        description: 'You typically overspend on weekends by ${(overspendPercentage * 100).toStringAsFixed(0)}%',
        confidence: math.min(overspendPercentage, 1.0),
        metrics: {
          'avgWeekendSpending': avgWeekend,
          'avgWeekdaySpending': avgWeekday,
          'overspendPercentage': overspendPercentage,
        },
        detectedAt: DateTime.now(),
        triggerConditions: ['Weekend days (Saturday, Sunday)'],
        recommendation: 'Set a weekend spending limit of KSh ${(avgWeekday * 1.2).toStringAsFixed(0)} to control overspending',
        potentialSavings: (avgWeekend - avgWeekday) * 8, // 8 weekend days per month
      );
    }

    return null;
  }

  /// Analyze payday spending patterns
  static SpendingBehaviorPattern? _analyzePaydaySpending(List<app_models.Transaction> transactions) {
    // Assume payday is around 25th-30th of month
    final paydaySpending = <double>[];
    final regularSpending = <double>[];

    for (final tx in transactions) {
      if (tx.date.day >= 25 || tx.date.day <= 5) { // Payday period
        paydaySpending.add(tx.amount);
      } else {
        regularSpending.add(tx.amount);
      }
    }

    if (paydaySpending.isEmpty || regularSpending.isEmpty) return null;

    final avgPayday = paydaySpending.reduce((a, b) => a + b) / paydaySpending.length;
    final avgRegular = regularSpending.reduce((a, b) => a + b) / regularSpending.length;
    final splurgePercentage = (avgPayday - avgRegular) / avgRegular;

    if (splurgePercentage > 0.5) { // 50% more spending around payday
      return SpendingBehaviorPattern(
        patternId: 'payday_splurge_${DateTime.now().millisecondsSinceEpoch}',
        patternType: 'payday_splurge',
        description: 'You tend to splurge around payday, spending ${(splurgePercentage * 100).toStringAsFixed(0)}% more',
        confidence: math.min(splurgePercentage / 2, 1.0),
        metrics: {
          'avgPaydaySpending': avgPayday,
          'avgRegularSpending': avgRegular,
          'splurgePercentage': splurgePercentage,
        },
        detectedAt: DateTime.now(),
        triggerConditions: ['Days 25-30 and 1-5 of month'],
        recommendation: 'Create a payday budget plan to avoid impulse spending after salary',
        potentialSavings: (avgPayday - avgRegular) * 2, // 2 payday periods per month
      );
    }

    return null;
  }

  /// Analyze M-Pesa specific patterns
  static List<SpendingBehaviorPattern> _analyzeMpesaPatterns(MpesaAnalyticsSummary analytics) {
    final patterns = <SpendingBehaviorPattern>[];

    // High agent fee pattern
    if (analytics.frequentAgents.isNotEmpty) {
      final agents = analytics.frequentAgents;
      if (agents.length > 1) {
        final mostExpensive = agents.reduce((a, b) => 
          a.averageWithdrawal > b.averageWithdrawal ? a : b);
        final cheapest = agents.reduce((a, b) => 
          a.averageWithdrawal < b.averageWithdrawal ? a : b);
        
        final feeDifference = mostExpensive.averageWithdrawal - cheapest.averageWithdrawal;
        if (feeDifference > 50) { // KSh 50 difference
          patterns.add(SpendingBehaviorPattern(
            patternId: 'high_agent_fees_${DateTime.now().millisecondsSinceEpoch}',
            patternType: 'high_agent_fees',
            description: 'You\'re using expensive M-Pesa agents, paying KSh ${feeDifference.toStringAsFixed(0)} more per transaction',
            confidence: 0.9,
            metrics: {
              'expensiveAgent': mostExpensive.agentName,
              'cheapAgent': cheapest.agentName,
              'feeDifference': feeDifference,
            },
            detectedAt: DateTime.now(),
            triggerConditions: ['Using multiple M-Pesa agents'],
            recommendation: 'Switch to ${cheapest.agentName} to save KSh ${feeDifference.toStringAsFixed(0)} per transaction',
            potentialSavings: feeDifference * mostExpensive.monthlyFrequency,
          ));
        }
      }
    }

    return patterns;
  }

  /// Calculate financial health score
  static double _calculateFinancialHealthScore(
    List<SpendingBehaviorPattern> patterns,
    List<FraudAlert> alerts,
    List<BudgetPrediction> predictions,
    Map<String, dynamic> metrics,
  ) {
    double score = 100.0;

    // Deduct for behavior patterns
    for (final pattern in patterns) {
      switch (pattern.severityLevel) {
        case 'Critical': score -= 20;
        case 'High': score -= 15;
        case 'Medium': score -= 10;
        case 'Low': score -= 5;
      }
    }

    // Deduct for fraud alerts
    for (final alert in alerts) {
      switch (alert.riskLevel) {
        case 'Critical': score -= 25;
        case 'High': score -= 15;
        case 'Medium': score -= 10;
        case 'Low': score -= 5;
      }
    }

    // Deduct for budget overages
    for (final prediction in predictions) {
      if (prediction.willExceedBudget) {
        switch (prediction.warningLevel) {
          case 'Critical': score -= 15;
          case 'High': score -= 10;
          case 'Medium': score -= 5;
          case 'Low': score -= 2;
        }
      }
    }

    return math.max(score, 0.0);
  }

  /// Generate key insights
  static List<String> _generateKeyInsights(
    List<SpendingBehaviorPattern> patterns,
    List<BudgetPrediction> predictions,
    List<SavingsOpportunity> opportunities,
  ) {
    final insights = <String>[];

    // Add pattern insights
    for (final pattern in patterns.take(3)) {
      insights.add(pattern.description);
    }

    // Add budget insights
    for (final prediction in predictions.where((p) => p.willExceedBudget).take(2)) {
      insights.add('You\'ll likely exceed your ${prediction.category} budget by KSh ${prediction.overageAmount.toStringAsFixed(0)}');
    }

    // Add savings insights
    for (final opportunity in opportunities.take(2)) {
      insights.add('${opportunity.title}: Save KSh ${opportunity.potentialMonthlySavings.toStringAsFixed(0)}/month');
    }

    return insights;
  }

  /// Generate actionable recommendations
  static List<String> _generateRecommendations(
    List<SpendingBehaviorPattern> patterns,
    List<SavingsOpportunity> opportunities,
    List<BudgetPrediction> predictions,
  ) {
    final recommendations = <String>[];

    // Add pattern recommendations
    for (final pattern in patterns.take(2)) {
      recommendations.add(pattern.recommendation);
    }

    // Add savings recommendations
    for (final opportunity in opportunities.where((o) => o.isActionable).take(2)) {
      recommendations.add(opportunity.actionRequired);
    }

    // Add budget recommendations
    for (final prediction in predictions.where((p) => p.willExceedBudget).take(1)) {
      recommendations.add(prediction.recommendation);
    }

    return recommendations;
  }

  /// Helper methods for fraud detection, budget prediction, etc.
  static List<FraudAlert> _detectUnusualAmounts(List<app_models.Transaction> transactions) {
    // Implementation for unusual amount detection
    return [];
  }

  static List<FraudAlert> _detectUnusualTiming(List<app_models.Transaction> transactions) {
    // Implementation for unusual timing detection
    return [];
  }

  static List<FraudAlert> _detectRapidTransactions(List<app_models.Transaction> transactions) {
    // Implementation for rapid transaction detection
    return [];
  }

  static BudgetPrediction? _predictCategoryBudget(String category, List<app_models.Transaction> transactions) {
    // Implementation for budget prediction
    return null;
  }

  static List<SavingsOpportunity> _identifyAgentSwitchingOpportunities(MpesaAnalyticsSummary analytics) {
    // Implementation for agent switching opportunities
    return [];
  }

  static List<SavingsOpportunity> _identifyMerchantAlternatives(MpesaAnalyticsSummary analytics) {
    // Implementation for merchant alternatives
    return [];
  }

  static List<SavingsOpportunity> _identifyTimingOptimizations(MpesaAnalyticsSummary analytics) {
    // Implementation for timing optimizations
    return [];
  }

  static SpendingBehaviorPattern? _analyzeStressSpending(List<app_models.Transaction> transactions) {
    // Implementation for stress spending analysis
    return null;
  }

  static Future<List<app_models.Transaction>> _getRecentTransactions(String userId) async {
    // Implementation to get recent transactions
    return [];
  }

  static Map<String, dynamic> _calculateOverallMetrics(
    List<app_models.Transaction> transactions,
    MpesaAnalyticsSummary analytics,
  ) {
    return {
      'totalTransactions': transactions.length,
      'totalMpesaTransactions': analytics.totalTransactionsAnalyzed,
      'analysisDate': DateTime.now().toIso8601String(),
    };
  }

  static String _generateAnalysisId() {
    return 'ai_analysis_${DateTime.now().millisecondsSinceEpoch}';
  }
}
