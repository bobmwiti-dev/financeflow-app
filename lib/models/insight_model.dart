class Insight {
  final int? id;
  final String title;
  final String description;
  final String type; // From AppConstants.insightTypes
  final DateTime date;
  final bool isRead;
  final bool isDismissed;
  final double? relevanceScore; // 0.0 to 1.0, higher means more relevant
  final Map<String, dynamic>? data; // Additional data for the insight

  Insight({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    this.isRead = false,
    this.isDismissed = false,
    this.relevanceScore = 0.5,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'date': date.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'isDismissed': isDismissed ? 1 : 0,
      'relevanceScore': relevanceScore,
      'data': data != null ? _encodeMap(data!) : null,
    };
  }

  factory Insight.fromMap(Map<String, dynamic> map) {
    return Insight(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      isRead: map['isRead'] == 1,
      isDismissed: map['isDismissed'] == 1,
      relevanceScore: map['relevanceScore'],
      data: map['data'] != null ? _decodeMap(map['data']) : null,
    );
  }

  // Helper method to encode Map to String for storage
  static String _encodeMap(Map<String, dynamic> map) {
    return map.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  // Helper method to decode String back to Map
  static Map<String, dynamic> _decodeMap(String encodedMap) {
    Map<String, dynamic> result = {};
    encodedMap.split('&').forEach((element) {
      var parts = element.split('=');
      if (parts.length == 2) {
        result[Uri.decodeComponent(parts[0])] = Uri.decodeComponent(parts[1]);
      }
    });
    return result;
  }

  // Create a copy with updated values
  Insight copyWith({
    int? id,
    String? title,
    String? description,
    String? type,
    DateTime? date,
    bool? isRead,
    bool? isDismissed,
    double? relevanceScore,
    Map<String, dynamic>? data,
  }) {
    return Insight(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      data: data ?? this.data,
    );
  }
}

// Specialized insight models for different types of insights

class SpendingPatternInsight extends Insight {
  final String category;
  final double percentageChange;
  final double previousAmount;
  final double currentAmount;
  final String timeFrame; // 'week', 'month', 'quarter', etc.

  SpendingPatternInsight({
    super.id,
    required super.title,
    required super.description,
    required super.date,
    super.isRead,
    super.isDismissed,
    super.relevanceScore = null,
    required this.category,
    required this.percentageChange,
    required this.previousAmount,
    required this.currentAmount,
    required this.timeFrame,
  }) : super(
          type: 'Spending Pattern',
          data: {
            'category': category,
            'percentageChange': percentageChange.toString(),
            'previousAmount': previousAmount.toString(),
            'currentAmount': currentAmount.toString(),
            'timeFrame': timeFrame,
          },
        );

  factory SpendingPatternInsight.fromInsight(Insight insight) {
    final data = insight.data!;
    return SpendingPatternInsight(
      id: insight.id,
      title: insight.title,
      description: insight.description,
      date: insight.date,
      isRead: insight.isRead,
      isDismissed: insight.isDismissed,
      relevanceScore: insight.relevanceScore,
      category: data['category'],
      percentageChange: double.parse(data['percentageChange']),
      previousAmount: double.parse(data['previousAmount']),
      currentAmount: double.parse(data['currentAmount']),
      timeFrame: data['timeFrame'],
    );
  }
}

class BudgetAlertInsight extends Insight {
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final double percentageUsed;

  BudgetAlertInsight({
    super.id,
    required super.title,
    required super.description,
    required super.date,
    super.isRead,
    super.isDismissed,
    super.relevanceScore = null,
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.percentageUsed,
  }) : super(
          type: 'Budget Alert',
          data: {
            'category': category,
            'budgetAmount': budgetAmount.toString(),
            'spentAmount': spentAmount.toString(),
            'percentageUsed': percentageUsed.toString(),
          },
        );

  factory BudgetAlertInsight.fromInsight(Insight insight) {
    final data = insight.data!;
    return BudgetAlertInsight(
      id: insight.id,
      title: insight.title,
      description: insight.description,
      date: insight.date,
      isRead: insight.isRead,
      isDismissed: insight.isDismissed,
      relevanceScore: insight.relevanceScore,
      category: data['category'],
      budgetAmount: double.parse(data['budgetAmount']),
      spentAmount: double.parse(data['spentAmount']),
      percentageUsed: double.parse(data['percentageUsed']),
    );
  }
}

class SavingOpportunityInsight extends Insight {
  final String category;
  final double potentialSavings;
  final String suggestion;

  SavingOpportunityInsight({
    super.id,
    required super.title,
    required super.description,
    required super.date,
    super.isRead,
    super.isDismissed,
    super.relevanceScore = null,
    required this.category,
    required this.potentialSavings,
    required this.suggestion,
  }) : super(
          type: 'Saving Opportunity',
          data: {
            'category': category,
            'potentialSavings': potentialSavings.toString(),
            'suggestion': suggestion,
          },
        );

  factory SavingOpportunityInsight.fromInsight(Insight insight) {
    final data = insight.data!;
    return SavingOpportunityInsight(
      id: insight.id,
      title: insight.title,
      description: insight.description,
      date: insight.date,
      isRead: insight.isRead,
      isDismissed: insight.isDismissed,
      relevanceScore: insight.relevanceScore,
      category: data['category'],
      potentialSavings: double.parse(data['potentialSavings']),
      suggestion: data['suggestion'],
    );
  }
}

class FinancialHealthInsight extends Insight {
  final double savingsRate;
  final double debtToIncomeRatio;
  final double emergencyFundMonths;
  final String overallHealth; // 'good', 'moderate', 'poor'
  final List<String> recommendations;

  FinancialHealthInsight({
    super.id,
    required super.title,
    required super.description,
    required super.date,
    super.isRead,
    super.isDismissed,
    super.relevanceScore = null,
    required this.savingsRate,
    required this.debtToIncomeRatio,
    required this.emergencyFundMonths,
    required this.overallHealth,
    required this.recommendations,
  }) : super(
          type: 'Financial Health',
          data: {
            'savingsRate': savingsRate.toString(),
            'debtToIncomeRatio': debtToIncomeRatio.toString(),
            'emergencyFundMonths': emergencyFundMonths.toString(),
            'overallHealth': overallHealth,
            'recommendations': recommendations.join('|'),
          },
        );

  factory FinancialHealthInsight.fromInsight(Insight insight) {
    final data = insight.data!;
    return FinancialHealthInsight(
      id: insight.id,
      title: insight.title,
      description: insight.description,
      date: insight.date,
      isRead: insight.isRead,
      isDismissed: insight.isDismissed,
      relevanceScore: insight.relevanceScore,
      savingsRate: double.parse(data['savingsRate']),
      debtToIncomeRatio: double.parse(data['debtToIncomeRatio']),
      emergencyFundMonths: double.parse(data['emergencyFundMonths']),
      overallHealth: data['overallHealth'],
      recommendations: data['recommendations'].split('|'),
    );
  }
}
