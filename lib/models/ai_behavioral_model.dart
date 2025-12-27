import 'package:cloud_firestore/cloud_firestore.dart';

/// Spending behavior pattern analysis
class SpendingBehaviorPattern {
  final String patternId;
  final String patternType; // weekend_overspend, payday_splurge, stress_spending, etc.
  final String description;
  final double confidence; // 0.0 to 1.0
  final Map<String, dynamic> metrics;
  final DateTime detectedAt;
  final List<String> triggerConditions;
  final String recommendation;
  final double potentialSavings;

  SpendingBehaviorPattern({
    required this.patternId,
    required this.patternType,
    required this.description,
    required this.confidence,
    required this.metrics,
    required this.detectedAt,
    required this.triggerConditions,
    required this.recommendation,
    required this.potentialSavings,
  });

  factory SpendingBehaviorPattern.fromMap(Map<String, dynamic> map) {
    return SpendingBehaviorPattern(
      patternId: map['patternId'] as String,
      patternType: map['patternType'] as String,
      description: map['description'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      metrics: Map<String, dynamic>.from(map['metrics']),
      detectedAt: (map['detectedAt'] as Timestamp).toDate(),
      triggerConditions: List<String>.from(map['triggerConditions']),
      recommendation: map['recommendation'] as String,
      potentialSavings: (map['potentialSavings'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patternId': patternId,
      'patternType': patternType,
      'description': description,
      'confidence': confidence,
      'metrics': metrics,
      'detectedAt': Timestamp.fromDate(detectedAt),
      'triggerConditions': triggerConditions,
      'recommendation': recommendation,
      'potentialSavings': potentialSavings,
    };
  }

  /// Get severity level based on confidence and impact
  String get severityLevel {
    if (confidence > 0.8 && potentialSavings > 5000) return 'Critical';
    if (confidence > 0.6 && potentialSavings > 2000) return 'High';
    if (confidence > 0.4 && potentialSavings > 500) return 'Medium';
    return 'Low';
  }

  /// Get color for UI display
  String get colorCode {
    switch (severityLevel) {
      case 'Critical': return '#FF5252';
      case 'High': return '#FF9800';
      case 'Medium': return '#FFC107';
      case 'Low': return '#4CAF50';
      default: return '#9E9E9E';
    }
  }
}

/// Fraud detection alert
class FraudAlert {
  final String alertId;
  final String alertType; // unusual_amount, unusual_time, unusual_location, etc.
  final String description;
  final double riskScore; // 0.0 to 1.0
  final DateTime detectedAt;
  final Map<String, dynamic> transactionDetails;
  final List<String> riskFactors;
  final String recommendedAction;
  final bool isResolved;

  FraudAlert({
    required this.alertId,
    required this.alertType,
    required this.description,
    required this.riskScore,
    required this.detectedAt,
    required this.transactionDetails,
    required this.riskFactors,
    required this.recommendedAction,
    this.isResolved = false,
  });

  factory FraudAlert.fromMap(Map<String, dynamic> map) {
    return FraudAlert(
      alertId: map['alertId'] as String,
      alertType: map['alertType'] as String,
      description: map['description'] as String,
      riskScore: (map['riskScore'] as num).toDouble(),
      detectedAt: (map['detectedAt'] as Timestamp).toDate(),
      transactionDetails: Map<String, dynamic>.from(map['transactionDetails']),
      riskFactors: List<String>.from(map['riskFactors']),
      recommendedAction: map['recommendedAction'] as String,
      isResolved: map['isResolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'alertType': alertType,
      'description': description,
      'riskScore': riskScore,
      'detectedAt': Timestamp.fromDate(detectedAt),
      'transactionDetails': transactionDetails,
      'riskFactors': riskFactors,
      'recommendedAction': recommendedAction,
      'isResolved': isResolved,
    };
  }

  /// Get risk level based on score
  String get riskLevel {
    if (riskScore > 0.8) return 'Critical';
    if (riskScore > 0.6) return 'High';
    if (riskScore > 0.4) return 'Medium';
    return 'Low';
  }
}

/// Budget prediction and warning
class BudgetPrediction {
  final String predictionId;
  final String category;
  final double currentSpent;
  final double budgetLimit;
  final double predictedSpent;
  final double overageAmount;
  final int daysRemaining;
  final double confidence;
  final DateTime generatedAt;
  final List<String> contributingFactors;
  final String recommendation;

  BudgetPrediction({
    required this.predictionId,
    required this.category,
    required this.currentSpent,
    required this.budgetLimit,
    required this.predictedSpent,
    required this.overageAmount,
    required this.daysRemaining,
    required this.confidence,
    required this.generatedAt,
    required this.contributingFactors,
    required this.recommendation,
  });

  factory BudgetPrediction.fromMap(Map<String, dynamic> map) {
    return BudgetPrediction(
      predictionId: map['predictionId'] as String,
      category: map['category'] as String,
      currentSpent: (map['currentSpent'] as num).toDouble(),
      budgetLimit: (map['budgetLimit'] as num).toDouble(),
      predictedSpent: (map['predictedSpent'] as num).toDouble(),
      overageAmount: (map['overageAmount'] as num).toDouble(),
      daysRemaining: map['daysRemaining'] as int,
      confidence: (map['confidence'] as num).toDouble(),
      generatedAt: (map['generatedAt'] as Timestamp).toDate(),
      contributingFactors: List<String>.from(map['contributingFactors']),
      recommendation: map['recommendation'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'predictionId': predictionId,
      'category': category,
      'currentSpent': currentSpent,
      'budgetLimit': budgetLimit,
      'predictedSpent': predictedSpent,
      'overageAmount': overageAmount,
      'daysRemaining': daysRemaining,
      'confidence': confidence,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'contributingFactors': contributingFactors,
      'recommendation': recommendation,
    };
  }

  /// Get warning level
  String get warningLevel {
    final overagePercentage = overageAmount / budgetLimit;
    if (overagePercentage > 0.5) return 'Critical';
    if (overagePercentage > 0.2) return 'High';
    if (overagePercentage > 0.1) return 'Medium';
    return 'Low';
  }

  /// Check if budget will be exceeded
  bool get willExceedBudget => predictedSpent > budgetLimit;

  /// Get percentage of budget used
  double get budgetUsagePercentage => (currentSpent / budgetLimit) * 100;

  /// Get predicted percentage of budget
  double get predictedUsagePercentage => (predictedSpent / budgetLimit) * 100;
}

/// Savings opportunity identification
class SavingsOpportunity {
  final String opportunityId;
  final String opportunityType; // agent_switch, merchant_alternative, timing_optimization, etc.
  final String title;
  final String description;
  final double potentialMonthlySavings;
  final double potentialYearlySavings;
  final double confidence;
  final String actionRequired;
  final Map<String, dynamic> details;
  final DateTime identifiedAt;
  final bool isActionable;

  SavingsOpportunity({
    required this.opportunityId,
    required this.opportunityType,
    required this.title,
    required this.description,
    required this.potentialMonthlySavings,
    required this.potentialYearlySavings,
    required this.confidence,
    required this.actionRequired,
    required this.details,
    required this.identifiedAt,
    required this.isActionable,
  });

  factory SavingsOpportunity.fromMap(Map<String, dynamic> map) {
    return SavingsOpportunity(
      opportunityId: map['opportunityId'] as String,
      opportunityType: map['opportunityType'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      potentialMonthlySavings: (map['potentialMonthlySavings'] as num).toDouble(),
      potentialYearlySavings: (map['potentialYearlySavings'] as num).toDouble(),
      confidence: (map['confidence'] as num).toDouble(),
      actionRequired: map['actionRequired'] as String,
      details: Map<String, dynamic>.from(map['details']),
      identifiedAt: (map['identifiedAt'] as Timestamp).toDate(),
      isActionable: map['isActionable'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'opportunityId': opportunityId,
      'opportunityType': opportunityType,
      'title': title,
      'description': description,
      'potentialMonthlySavings': potentialMonthlySavings,
      'potentialYearlySavings': potentialYearlySavings,
      'confidence': confidence,
      'actionRequired': actionRequired,
      'details': details,
      'identifiedAt': Timestamp.fromDate(identifiedAt),
      'isActionable': isActionable,
    };
  }

  /// Get priority level based on savings potential and confidence
  String get priorityLevel {
    final score = (potentialMonthlySavings / 1000) * confidence;
    if (score > 2.0) return 'High';
    if (score > 1.0) return 'Medium';
    return 'Low';
  }
}

/// Comprehensive AI behavioral analysis summary
class AIBehavioralAnalysis {
  final String analysisId;
  final String userId;
  final DateTime generatedAt;
  final List<SpendingBehaviorPattern> behaviorPatterns;
  final List<FraudAlert> fraudAlerts;
  final List<BudgetPrediction> budgetPredictions;
  final List<SavingsOpportunity> savingsOpportunities;
  final Map<String, dynamic> overallMetrics;
  final double financialHealthScore; // 0-100
  final List<String> keyInsights;
  final List<String> actionableRecommendations;

  AIBehavioralAnalysis({
    required this.analysisId,
    required this.userId,
    required this.generatedAt,
    required this.behaviorPatterns,
    required this.fraudAlerts,
    required this.budgetPredictions,
    required this.savingsOpportunities,
    required this.overallMetrics,
    required this.financialHealthScore,
    required this.keyInsights,
    required this.actionableRecommendations,
  });

  /// Get total potential monthly savings
  double get totalPotentialMonthlySavings {
    return savingsOpportunities
        .map((opp) => opp.potentialMonthlySavings)
        .fold(0.0, (total, amount) => total + amount);
  }

  /// Get number of critical alerts
  int get criticalAlertsCount {
    return fraudAlerts.where((alert) => alert.riskLevel == 'Critical').length +
           budgetPredictions.where((pred) => pred.warningLevel == 'Critical').length;
  }

  /// Get financial health status
  String get financialHealthStatus {
    if (financialHealthScore >= 80) return 'Excellent';
    if (financialHealthScore >= 60) return 'Good';
    if (financialHealthScore >= 40) return 'Fair';
    if (financialHealthScore >= 20) return 'Poor';
    return 'Critical';
  }

  /// Get top priority recommendation
  String? get topRecommendation {
    if (actionableRecommendations.isNotEmpty) {
      return actionableRecommendations.first;
    }
    return null;
  }

  /// Check if immediate action is needed
  bool get needsImmediateAction {
    return criticalAlertsCount > 0 || 
           behaviorPatterns.any((pattern) => pattern.severityLevel == 'Critical');
  }
}
