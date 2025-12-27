import 'package:cloud_firestore/cloud_firestore.dart';
import 'mpesa_sms_model.dart';

/// M-Pesa Balance Point for tracking balance over time
class MpesaBalancePoint {
  final DateTime date;
  final double balance;
  final String transactionCode;
  final MpesaTransactionType transactionType;

  MpesaBalancePoint({
    required this.date,
    required this.balance,
    required this.transactionCode,
    required this.transactionType,
  });

  factory MpesaBalancePoint.fromMpesaTransaction(MpesaSmsTransaction transaction) {
    return MpesaBalancePoint(
      date: transaction.transactionDate,
      balance: transaction.balance,
      transactionCode: transaction.mpesaCode,
      transactionType: transaction.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'balance': balance,
      'transactionCode': transactionCode,
      'transactionType': transactionType.toString(),
    };
  }

  factory MpesaBalancePoint.fromMap(Map<String, dynamic> map) {
    return MpesaBalancePoint(
      date: (map['date'] as Timestamp).toDate(),
      balance: (map['balance'] as num).toDouble(),
      transactionCode: map['transactionCode'] as String,
      transactionType: MpesaTransactionType.values.firstWhere(
        (e) => e.toString() == map['transactionType'],
        orElse: () => MpesaTransactionType.unknown,
      ),
    );
  }
}

/// Merchant spending analysis
class MerchantSpendingAnalysis {
  final String merchantName;
  final double totalSpent;
  final int transactionCount;
  final double averageTransaction;
  final DateTime firstTransaction;
  final DateTime lastTransaction;
  final List<double> monthlySpending; // Last 12 months
  final MpesaTransactionType primaryTransactionType;

  MerchantSpendingAnalysis({
    required this.merchantName,
    required this.totalSpent,
    required this.transactionCount,
    required this.averageTransaction,
    required this.firstTransaction,
    required this.lastTransaction,
    required this.monthlySpending,
    required this.primaryTransactionType,
  });

  /// Calculate spending trend (positive = increasing, negative = decreasing)
  double get spendingTrend {
    if (monthlySpending.length < 2) return 0.0;
    final recent = monthlySpending.take(3).fold(0.0, (a, b) => a + b) / 3;
    final older = monthlySpending.skip(3).take(3).fold(0.0, (a, b) => a + b) / 3;
    if (older == 0) return recent > 0 ? 1.0 : 0.0;
    return (recent - older) / older;
  }

  /// Get spending frequency (transactions per month)
  double get monthlyFrequency {
    final months = DateTime.now().difference(firstTransaction).inDays / 30.44;
    return months > 0 ? transactionCount / months : 0.0;
  }
}

/// Agent usage analysis
class AgentAnalysis {
  final String agentName;
  final String? agentNumber;
  final int withdrawalCount;
  final int depositCount;
  final double totalWithdrawn;
  final double totalDeposited;
  final double averageWithdrawal;
  final double averageDeposit;
  final DateTime firstUsed;
  final DateTime lastUsed;
  final List<double> monthlyUsage; // Transaction counts per month

  AgentAnalysis({
    required this.agentName,
    this.agentNumber,
    required this.withdrawalCount,
    required this.depositCount,
    required this.totalWithdrawn,
    required this.totalDeposited,
    required this.averageWithdrawal,
    required this.averageDeposit,
    required this.firstUsed,
    required this.lastUsed,
    required this.monthlyUsage,
  });

  /// Total transactions with this agent
  int get totalTransactions => withdrawalCount + depositCount;

  /// Total amount handled by this agent
  double get totalAmount => totalWithdrawn + totalDeposited;

  /// Usage frequency (transactions per month)
  double get monthlyFrequency {
    final months = DateTime.now().difference(firstUsed).inDays / 30.44;
    return months > 0 ? totalTransactions / months : 0.0;
  }

  /// Primary usage type
  String get primaryUsage {
    if (withdrawalCount > depositCount * 2) return 'Withdrawal';
    if (depositCount > withdrawalCount * 2) return 'Deposit';
    return 'Mixed';
  }
}

/// M-Pesa transaction pattern analysis
class TransactionPatternAnalysis {
  final Map<int, double> hourlyPattern; // Hour of day -> average amount
  final Map<int, int> dailyPattern; // Day of week -> transaction count
  final Map<String, double> categorySpending; // Category -> total amount
  final double averageTransactionAmount;
  final double largestTransaction;
  final double smallestTransaction;
  final int totalTransactions;
  final DateTime analysisStartDate;
  final DateTime analysisEndDate;

  TransactionPatternAnalysis({
    required this.hourlyPattern,
    required this.dailyPattern,
    required this.categorySpending,
    required this.averageTransactionAmount,
    required this.largestTransaction,
    required this.smallestTransaction,
    required this.totalTransactions,
    required this.analysisStartDate,
    required this.analysisEndDate,
  });

  /// Get peak spending hour
  int get peakSpendingHour {
    if (hourlyPattern.isEmpty) return 12;
    return hourlyPattern.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get most active day of week (0 = Sunday)
  int get mostActiveDay {
    if (dailyPattern.isEmpty) return 1;
    return dailyPattern.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get top spending category
  String get topSpendingCategory {
    if (categorySpending.isEmpty) return 'Other';
    return categorySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// M-Pesa balance trend analysis
class BalanceTrendAnalysis {
  final List<MpesaBalancePoint> balanceHistory;
  final double currentBalance;
  final double averageBalance;
  final double highestBalance;
  final double lowestBalance;
  final double balanceVolatility;
  final double monthlyBalanceChange;
  final List<double> monthlyAverages; // Last 12 months

  BalanceTrendAnalysis({
    required this.balanceHistory,
    required this.currentBalance,
    required this.averageBalance,
    required this.highestBalance,
    required this.lowestBalance,
    required this.balanceVolatility,
    required this.monthlyBalanceChange,
    required this.monthlyAverages,
  });

  /// Balance trend direction
  String get trendDirection {
    if (monthlyBalanceChange > 0.05) return 'Increasing';
    if (monthlyBalanceChange < -0.05) return 'Decreasing';
    return 'Stable';
  }

  /// Balance health score (0-100)
  double get balanceHealthScore {
    if (balanceHistory.isEmpty) return 50.0;
    
    double score = 50.0;
    
    // Positive trend adds points
    if (monthlyBalanceChange > 0) score += 20;
    
    // Low volatility adds points
    if (balanceVolatility < 0.3) score += 15;
    
    // Maintaining reasonable balance adds points
    if (currentBalance > averageBalance * 0.8) score += 15;
    
    return score.clamp(0.0, 100.0);
  }

  /// Get balance prediction for next month
  double get predictedNextMonthBalance {
    if (monthlyAverages.length < 3) return currentBalance;
    
    // Simple linear trend prediction
    final recentTrend = monthlyAverages.take(3).toList();
    final avgChange = (recentTrend[0] - recentTrend[2]) / 2;
    
    return (currentBalance + avgChange).clamp(0.0, double.infinity);
  }
}

/// Complete M-Pesa analytics summary
class MpesaAnalyticsSummary {
  final BalanceTrendAnalysis balanceTrend;
  final List<MerchantSpendingAnalysis> topMerchants;
  final List<AgentAnalysis> frequentAgents;
  final TransactionPatternAnalysis patterns;
  final DateTime generatedAt;
  final int totalTransactionsAnalyzed;
  final DateRange analysisRange;

  MpesaAnalyticsSummary({
    required this.balanceTrend,
    required this.topMerchants,
    required this.frequentAgents,
    required this.patterns,
    required this.generatedAt,
    required this.totalTransactionsAnalyzed,
    required this.analysisRange,
  });

  /// Get key insights as human-readable strings
  List<String> get keyInsights {
    List<String> insights = [];

    // Balance insights
    if (balanceTrend.monthlyBalanceChange > 0.1) {
      insights.add('Your M-Pesa balance increased by ${(balanceTrend.monthlyBalanceChange * 100).toStringAsFixed(1)}% this month');
    } else if (balanceTrend.monthlyBalanceChange < -0.1) {
      insights.add('Your M-Pesa balance decreased by ${(balanceTrend.monthlyBalanceChange.abs() * 100).toStringAsFixed(1)}% this month');
    }

    // Merchant insights
    if (topMerchants.isNotEmpty) {
      final topMerchant = topMerchants.first;
      insights.add('You spent KSh ${topMerchant.totalSpent.toStringAsFixed(0)} at ${topMerchant.merchantName} this period');
      
      if (topMerchant.spendingTrend > 0.2) {
        insights.add('Your spending at ${topMerchant.merchantName} increased by ${(topMerchant.spendingTrend * 100).toStringAsFixed(0)}%');
      }
    }

    // Agent insights
    if (frequentAgents.length > 1) {
      final agents = frequentAgents.take(2).toList();
      final costDiff = (agents[0].averageWithdrawal - agents[1].averageWithdrawal).abs();
      if (costDiff > 50) {
        insights.add('${agents[0].agentName} costs KSh ${costDiff.toStringAsFixed(0)} more per transaction than ${agents[1].agentName}');
      }
    }

    // Pattern insights
    final peakHour = patterns.peakSpendingHour;
    if (peakHour >= 9 && peakHour <= 17) {
      insights.add('You spend most during business hours ($peakHour:00)');
    } else if (peakHour >= 18 && peakHour <= 22) {
      insights.add('You spend most in the evening ($peakHour:00)');
    }

    return insights;
  }
}

/// Date range for analysis
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  /// Get number of days in range
  int get days => end.difference(start).inDays + 1;

  /// Get number of months in range
  double get months => days / 30.44;

  /// Check if date is in range
  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
           date.isBefore(end.add(const Duration(days: 1)));
  }

  @override
  String toString() {
    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }
}
