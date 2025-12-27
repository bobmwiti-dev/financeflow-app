import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/mpesa_sms_model.dart';
import '../models/mpesa_analytics_model.dart';

/// Service for analyzing M-Pesa transaction data and generating insights
class MpesaAnalyticsService {
  static const String _logName = 'MpesaAnalyticsService';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate complete M-Pesa analytics summary
  static Future<MpesaAnalyticsSummary> generateAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Default to last 6 months if no date range specified
      endDate ??= DateTime.now();
      startDate ??= DateTime(endDate.year, endDate.month - 6, endDate.day);
      
      final analysisRange = DateRange(start: startDate, end: endDate);

      developer.log('Generating M-Pesa analytics for $analysisRange', name: _logName);

      // Get M-Pesa transactions from Firestore
      final transactions = await _getMpesaTransactions(userId, startDate, endDate);
      
      if (transactions.isEmpty) {
        return _createEmptyAnalytics(analysisRange);
      }

      developer.log('Analyzing ${transactions.length} M-Pesa transactions', name: _logName);

      // Generate different types of analysis
      final balanceTrend = await _analyzeBalanceTrend(transactions);
      final merchantAnalysis = await _analyzeMerchantSpending(transactions);
      final agentAnalysis = await _analyzeAgentUsage(transactions);
      final patternAnalysis = await _analyzeTransactionPatterns(transactions);

      return MpesaAnalyticsSummary(
        balanceTrend: balanceTrend,
        topMerchants: merchantAnalysis,
        frequentAgents: agentAnalysis,
        patterns: patternAnalysis,
        generatedAt: DateTime.now(),
        totalTransactionsAnalyzed: transactions.length,
        analysisRange: analysisRange,
      );

    } catch (e) {
      developer.log('Error generating M-Pesa analytics: $e', name: _logName);
      rethrow;
    }
  }

  /// Get M-Pesa transactions from Firestore
  static Future<List<MpesaSmsTransaction>> _getMpesaTransactions(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mpesa_transactions')
          .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('transactionDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MpesaSmsTransaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      developer.log('Error fetching M-Pesa transactions: $e', name: _logName);
      return [];
    }
  }

  /// Analyze M-Pesa balance trends over time
  static Future<BalanceTrendAnalysis> _analyzeBalanceTrend(
    List<MpesaSmsTransaction> transactions,
  ) async {
    try {
      // Create balance points from transactions
      final balanceHistory = transactions
          .map((tx) => MpesaBalancePoint.fromMpesaTransaction(tx))
          .toList();

      if (balanceHistory.isEmpty) {
        return BalanceTrendAnalysis(
          balanceHistory: [],
          currentBalance: 0.0,
          averageBalance: 0.0,
          highestBalance: 0.0,
          lowestBalance: 0.0,
          balanceVolatility: 0.0,
          monthlyBalanceChange: 0.0,
          monthlyAverages: [],
        );
      }

      // Sort by date
      balanceHistory.sort((a, b) => a.date.compareTo(b.date));

      final currentBalance = balanceHistory.last.balance;
      final balances = balanceHistory.map((bp) => bp.balance).toList();
      
      final averageBalance = balances.reduce((a, b) => a + b) / balances.length;
      final highestBalance = balances.reduce(math.max);
      final lowestBalance = balances.reduce(math.min);

      // Calculate volatility (standard deviation / mean)
      final variance = balances
          .map((b) => math.pow(b - averageBalance, 2))
          .reduce((a, b) => a + b) / balances.length;
      final balanceVolatility = averageBalance > 0 
          ? math.sqrt(variance) / averageBalance 
          : 0.0;

      // Calculate monthly averages for last 12 months
      final monthlyAverages = _calculateMonthlyAverages(balanceHistory);

      // Calculate monthly balance change
      final monthlyBalanceChange = monthlyAverages.length >= 2
          ? (monthlyAverages[0] - monthlyAverages[1]) / monthlyAverages[1]
          : 0.0;

      return BalanceTrendAnalysis(
        balanceHistory: balanceHistory,
        currentBalance: currentBalance,
        averageBalance: averageBalance,
        highestBalance: highestBalance,
        lowestBalance: lowestBalance,
        balanceVolatility: balanceVolatility,
        monthlyBalanceChange: monthlyBalanceChange,
        monthlyAverages: monthlyAverages,
      );

    } catch (e) {
      developer.log('Error analyzing balance trend: $e', name: _logName);
      rethrow;
    }
  }

  /// Analyze merchant spending patterns
  static Future<List<MerchantSpendingAnalysis>> _analyzeMerchantSpending(
    List<MpesaSmsTransaction> transactions,
  ) async {
    try {
      // Group transactions by merchant/recipient
      final merchantGroups = <String, List<MpesaSmsTransaction>>{};
      
      for (final tx in transactions) {
        if (tx.isExpense && tx.recipient != null) {
          final merchant = _normalizeMerchantName(tx.recipient!);
          merchantGroups.putIfAbsent(merchant, () => []).add(tx);
        }
      }

      // Analyze each merchant
      final merchantAnalyses = <MerchantSpendingAnalysis>[];
      
      for (final entry in merchantGroups.entries) {
        final merchantName = entry.key;
        final merchantTransactions = entry.value;
        
        if (merchantTransactions.length < 2) continue; // Skip single transactions
        
        merchantTransactions.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
        
        final totalSpent = merchantTransactions
            .map((tx) => tx.amount)
            .reduce((a, b) => a + b);
        
        final transactionCount = merchantTransactions.length;
        final averageTransaction = totalSpent / transactionCount;
        final firstTransaction = merchantTransactions.first.transactionDate;
        final lastTransaction = merchantTransactions.last.transactionDate;
        
        // Calculate monthly spending for last 12 months
        final monthlySpending = _calculateMerchantMonthlySpending(merchantTransactions);
        
        // Determine primary transaction type
        final typeGroups = <MpesaTransactionType, int>{};
        for (final tx in merchantTransactions) {
          typeGroups[tx.type] = (typeGroups[tx.type] ?? 0) + 1;
        }
        final primaryTransactionType = typeGroups.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        merchantAnalyses.add(MerchantSpendingAnalysis(
          merchantName: merchantName,
          totalSpent: totalSpent,
          transactionCount: transactionCount,
          averageTransaction: averageTransaction,
          firstTransaction: firstTransaction,
          lastTransaction: lastTransaction,
          monthlySpending: monthlySpending,
          primaryTransactionType: primaryTransactionType,
        ));
      }

      // Sort by total spent (descending)
      merchantAnalyses.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
      
      return merchantAnalyses.take(10).toList(); // Top 10 merchants

    } catch (e) {
      developer.log('Error analyzing merchant spending: $e', name: _logName);
      return [];
    }
  }

  /// Analyze agent usage patterns
  static Future<List<AgentAnalysis>> _analyzeAgentUsage(
    List<MpesaSmsTransaction> transactions,
  ) async {
    try {
      // Group transactions by agent
      final agentGroups = <String, List<MpesaSmsTransaction>>{};
      
      for (final tx in transactions) {
        if ((tx.type == MpesaTransactionType.withdrawal || 
             tx.type == MpesaTransactionType.deposit) && 
            tx.recipient != null) {
          final agentKey = '${tx.recipient}|${tx.agentNumber ?? ''}';
          agentGroups.putIfAbsent(agentKey, () => []).add(tx);
        }
      }

      // Analyze each agent
      final agentAnalyses = <AgentAnalysis>[];
      
      for (final entry in agentGroups.entries) {
        final agentTransactions = entry.value;
        if (agentTransactions.length < 2) continue; // Skip single transactions
        
        final agentName = agentTransactions.first.recipient!;
        final agentNumber = agentTransactions.first.agentNumber;
        
        final withdrawals = agentTransactions
            .where((tx) => tx.type == MpesaTransactionType.withdrawal)
            .toList();
        final deposits = agentTransactions
            .where((tx) => tx.type == MpesaTransactionType.deposit)
            .toList();
        
        final totalWithdrawn = withdrawals.isEmpty ? 0.0 :
            withdrawals.map((tx) => tx.amount).reduce((a, b) => a + b);
        final totalDeposited = deposits.isEmpty ? 0.0 :
            deposits.map((tx) => tx.amount).reduce((a, b) => a + b);
        
        final averageWithdrawal = withdrawals.isEmpty ? 0.0 : totalWithdrawn / withdrawals.length;
        final averageDeposit = deposits.isEmpty ? 0.0 : totalDeposited / deposits.length;
        
        agentTransactions.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
        final firstUsed = agentTransactions.first.transactionDate;
        final lastUsed = agentTransactions.last.transactionDate;
        
        // Calculate monthly usage
        final monthlyUsage = _calculateAgentMonthlyUsage(agentTransactions);

        agentAnalyses.add(AgentAnalysis(
          agentName: agentName,
          agentNumber: agentNumber,
          withdrawalCount: withdrawals.length,
          depositCount: deposits.length,
          totalWithdrawn: totalWithdrawn,
          totalDeposited: totalDeposited,
          averageWithdrawal: averageWithdrawal,
          averageDeposit: averageDeposit,
          firstUsed: firstUsed,
          lastUsed: lastUsed,
          monthlyUsage: monthlyUsage,
        ));
      }

      // Sort by total transactions (descending)
      agentAnalyses.sort((a, b) => b.totalTransactions.compareTo(a.totalTransactions));
      
      return agentAnalyses.take(5).toList(); // Top 5 agents

    } catch (e) {
      developer.log('Error analyzing agent usage: $e', name: _logName);
      return [];
    }
  }

  /// Analyze transaction patterns
  static Future<TransactionPatternAnalysis> _analyzeTransactionPatterns(
    List<MpesaSmsTransaction> transactions,
  ) async {
    try {
      if (transactions.isEmpty) {
        return TransactionPatternAnalysis(
          hourlyPattern: {},
          dailyPattern: {},
          categorySpending: {},
          averageTransactionAmount: 0.0,
          largestTransaction: 0.0,
          smallestTransaction: 0.0,
          totalTransactions: 0,
          analysisStartDate: DateTime.now(),
          analysisEndDate: DateTime.now(),
        );
      }

      // Hourly pattern analysis
      final hourlyPattern = <int, double>{};
      final hourlyAmounts = <int, List<double>>{};
      
      for (final tx in transactions) {
        final hour = tx.transactionDate.hour;
        hourlyAmounts.putIfAbsent(hour, () => []).add(tx.amount);
      }
      
      for (final entry in hourlyAmounts.entries) {
        final amounts = entry.value;
        hourlyPattern[entry.key] = amounts.reduce((a, b) => a + b) / amounts.length;
      }

      // Daily pattern analysis
      final dailyPattern = <int, int>{};
      for (final tx in transactions) {
        final dayOfWeek = tx.transactionDate.weekday % 7; // 0 = Sunday
        dailyPattern[dayOfWeek] = (dailyPattern[dayOfWeek] ?? 0) + 1;
      }

      // Category spending analysis
      final categorySpending = <String, double>{};
      for (final tx in transactions) {
        if (tx.isExpense) {
          final category = tx.category ?? 'Other';
          categorySpending[category] = (categorySpending[category] ?? 0.0) + tx.amount;
        }
      }

      // Transaction amount statistics
      final amounts = transactions.map((tx) => tx.amount).toList();
      final averageTransactionAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final largestTransaction = amounts.reduce(math.max);
      final smallestTransaction = amounts.reduce(math.min);

      transactions.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

      return TransactionPatternAnalysis(
        hourlyPattern: hourlyPattern,
        dailyPattern: dailyPattern,
        categorySpending: categorySpending,
        averageTransactionAmount: averageTransactionAmount,
        largestTransaction: largestTransaction,
        smallestTransaction: smallestTransaction,
        totalTransactions: transactions.length,
        analysisStartDate: transactions.first.transactionDate,
        analysisEndDate: transactions.last.transactionDate,
      );

    } catch (e) {
      developer.log('Error analyzing transaction patterns: $e', name: _logName);
      rethrow;
    }
  }

  /// Helper: Calculate monthly averages for balance history
  static List<double> _calculateMonthlyAverages(List<MpesaBalancePoint> balanceHistory) {
    final monthlyGroups = <String, List<double>>{};
    
    for (final point in balanceHistory) {
      final monthKey = '${point.date.year}-${point.date.month.toString().padLeft(2, '0')}';
      monthlyGroups.putIfAbsent(monthKey, () => []).add(point.balance);
    }
    
    final monthlyAverages = <double>[];
    final sortedMonths = monthlyGroups.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final month in sortedMonths.take(12)) {
      final balances = monthlyGroups[month]!;
      final average = balances.reduce((a, b) => a + b) / balances.length;
      monthlyAverages.add(average);
    }
    
    return monthlyAverages;
  }

  /// Helper: Calculate monthly spending for a merchant
  static List<double> _calculateMerchantMonthlySpending(List<MpesaSmsTransaction> transactions) {
    final monthlyGroups = <String, double>{};
    
    for (final tx in transactions) {
      final monthKey = '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}';
      monthlyGroups[monthKey] = (monthlyGroups[monthKey] ?? 0.0) + tx.amount;
    }
    
    final monthlySpending = <double>[];
    final sortedMonths = monthlyGroups.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final month in sortedMonths.take(12)) {
      monthlySpending.add(monthlyGroups[month] ?? 0.0);
    }
    
    // Fill remaining months with 0
    while (monthlySpending.length < 12) {
      monthlySpending.add(0.0);
    }
    
    return monthlySpending;
  }

  /// Helper: Calculate monthly usage for an agent
  static List<double> _calculateAgentMonthlyUsage(List<MpesaSmsTransaction> transactions) {
    final monthlyGroups = <String, int>{};
    
    for (final tx in transactions) {
      final monthKey = '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}';
      monthlyGroups[monthKey] = (monthlyGroups[monthKey] ?? 0) + 1;
    }
    
    final monthlyUsage = <double>[];
    final sortedMonths = monthlyGroups.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final month in sortedMonths.take(12)) {
      monthlyUsage.add((monthlyGroups[month] ?? 0).toDouble());
    }
    
    // Fill remaining months with 0
    while (monthlyUsage.length < 12) {
      monthlyUsage.add(0.0);
    }
    
    return monthlyUsage;
  }

  /// Helper: Normalize merchant names for better grouping
  static String _normalizeMerchantName(String merchantName) {
    final normalized = merchantName.toUpperCase().trim();
    
    // Group similar merchant names
    if (normalized.contains('JAVA')) return 'Java House';
    if (normalized.contains('NAIVAS')) return 'Naivas';
    if (normalized.contains('TUSKYS')) return 'Tuskys';
    if (normalized.contains('SHELL')) return 'Shell';
    if (normalized.contains('TOTAL')) return 'Total';
    if (normalized.contains('KPLC') || normalized.contains('KENYA POWER')) return 'KPLC';
    if (normalized.contains('WATER') || normalized.contains('NAIROBI WATER')) return 'Nairobi Water';
    if (normalized.contains('UBER')) return 'Uber';
    if (normalized.contains('BOLT')) return 'Bolt';
    
    return merchantName; // Return original if no match
  }

  /// Helper: Create empty analytics for when no data is available
  static MpesaAnalyticsSummary _createEmptyAnalytics(DateRange analysisRange) {
    return MpesaAnalyticsSummary(
      balanceTrend: BalanceTrendAnalysis(
        balanceHistory: [],
        currentBalance: 0.0,
        averageBalance: 0.0,
        highestBalance: 0.0,
        lowestBalance: 0.0,
        balanceVolatility: 0.0,
        monthlyBalanceChange: 0.0,
        monthlyAverages: [],
      ),
      topMerchants: [],
      frequentAgents: [],
      patterns: TransactionPatternAnalysis(
        hourlyPattern: {},
        dailyPattern: {},
        categorySpending: {},
        averageTransactionAmount: 0.0,
        largestTransaction: 0.0,
        smallestTransaction: 0.0,
        totalTransactions: 0,
        analysisStartDate: analysisRange.start,
        analysisEndDate: analysisRange.end,
      ),
      generatedAt: DateTime.now(),
      totalTransactionsAnalyzed: 0,
      analysisRange: analysisRange,
    );
  }

  /// Get quick analytics summary for dashboard
  static Future<Map<String, dynamic>> getQuickAnalytics() async {
    try {
      final analytics = await generateAnalytics(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      return {
        'currentBalance': analytics.balanceTrend.currentBalance,
        'balanceChange': analytics.balanceTrend.monthlyBalanceChange,
        'topMerchant': analytics.topMerchants.isNotEmpty 
            ? analytics.topMerchants.first.merchantName 
            : null,
        'topMerchantSpending': analytics.topMerchants.isNotEmpty 
            ? analytics.topMerchants.first.totalSpent 
            : 0.0,
        'totalTransactions': analytics.totalTransactionsAnalyzed,
        'keyInsights': analytics.keyInsights,
      };
    } catch (e) {
      developer.log('Error getting quick analytics: $e', name: _logName);
      return {};
    }
  }
}
