import 'dart:math' as math;
import '../models/anomaly_model.dart';
import '../models/transaction_model.dart';
import '../models/income_source_model.dart';
import '../models/time_period_model.dart';

class AnomalyDetectionService {
  static const AnomalyDetectionConfig _config = AnomalyDetectionConfig();

  /// Main method to detect all types of anomalies
  static List<Anomaly> detectAnomalies({
    required List<Transaction> allTransactions,
    required List<IncomeSource> allIncomeSources,
    required TimePeriod currentPeriod,
    AnomalyDetectionConfig? config,
  }) {
    final detectionConfig = config ?? _config;
    final anomalies = <Anomaly>[];
    final now = DateTime.now();

    // Filter transactions for analysis period (last 90 days for context)
    final analysisStartDate = now.subtract(const Duration(days: 90));
    final recentTransactions = allTransactions
        .where((tx) => tx.date.isAfter(analysisStartDate))
        .toList();

    if (recentTransactions.length < detectionConfig.minimumTransactionsForStats) {
      return anomalies; // Not enough data for meaningful analysis
    }

    // 1. Detect spending spikes and drops
    anomalies.addAll(_detectSpendingAnomalies(
      recentTransactions, 
      currentPeriod, 
      detectionConfig,
    ));

    // 2. Detect missing spending patterns
    anomalies.addAll(_detectMissingPatterns(
      recentTransactions, 
      currentPeriod, 
      detectionConfig,
    ));

    // 3. Detect duplicate transactions
    anomalies.addAll(_detectDuplicateTransactions(
      recentTransactions, 
      detectionConfig,
    ));

    // 4. Detect unusual merchants
    anomalies.addAll(_detectUnusualMerchants(
      recentTransactions, 
      currentPeriod, 
      detectionConfig,
    ));

    // 5. Detect category shifts
    anomalies.addAll(_detectCategoryShifts(
      recentTransactions, 
      currentPeriod, 
      detectionConfig,
    ));

    // 6. Detect frequency changes
    anomalies.addAll(_detectFrequencyChanges(
      recentTransactions, 
      currentPeriod, 
      detectionConfig,
    ));

    // 7. Detect amount anomalies
    anomalies.addAll(_detectAmountAnomalies(
      recentTransactions, 
      currentPeriod, 
      detectionConfig,
    ));

    // Sort by severity and detection time
    anomalies.sort((a, b) {
      final severityComparison = b.severity.index.compareTo(a.severity.index);
      if (severityComparison != 0) return severityComparison;
      return b.detectedAt.compareTo(a.detectedAt);
    });

    return anomalies;
  }

  /// Detect spending spikes and drops by category
  static List<Anomaly> _detectSpendingAnomalies(
    List<Transaction> transactions,
    TimePeriod currentPeriod,
    AnomalyDetectionConfig config,
  ) {
    final anomalies = <Anomaly>[];
    final categoryStats = _calculateCategoryStats(transactions);

    // Get current period expenses
    final currentPeriodExpenses = transactions
        .where((tx) => 
            tx.type == TransactionType.expense && 
            currentPeriod.containsDate(tx.date))
        .toList();

    // Group current period expenses by category
    final currentCategoryTotals = <String, double>{};
    for (final tx in currentPeriodExpenses) {
      currentCategoryTotals.update(
        tx.category,
        (value) => value + tx.amount.abs(),
        ifAbsent: () => tx.amount.abs(),
      );
    }

    // Compare with historical averages
    for (final entry in currentCategoryTotals.entries) {
      final category = entry.key;
      final currentAmount = entry.value;
      final stats = categoryStats[category];

      if (stats == null || stats.transactionCount < config.minimumTransactionsForStats) {
        continue;
      }

      final averageAmount = stats.averageAmount;
      final ratio = currentAmount / averageAmount;

      // Detect spending spike
      if (ratio >= config.spikeSensitivity) {
        final percentageIncrease = ((ratio - 1) * 100).round();
        anomalies.add(Anomaly(
          id: 'spike_${category}_${DateTime.now().millisecondsSinceEpoch}',
          type: AnomalyType.spendingSpike,
          severity: ratio >= 3.0 ? AnomalySeverity.critical : AnomalySeverity.high,
          title: '$category Spending Spike',
          message: '$category spending is up $percentageIncrease% from your average of \$${averageAmount.toStringAsFixed(0)}',
          category: category,
          amount: currentAmount,
          detectedAt: DateTime.now(),
          relatedDate: currentPeriod.startDate,
          metadata: {
            'current_amount': currentAmount,
            'average_amount': averageAmount,
            'ratio': ratio,
            'period': currentPeriod.displayName,
          },
          recommendations: [
            'Review recent $category transactions for unusual purchases',
            'Consider if this increase is planned or unexpected',
            'Set up a budget alert for $category if you don\'t have one',
          ],
        ));
      }

      // Detect spending drop (might indicate missing transactions)
      if (ratio <= config.dropSensitivity && currentAmount > 0) {
        final percentageDecrease = ((1 - ratio) * 100).round();
        anomalies.add(Anomaly(
          id: 'drop_${category}_${DateTime.now().millisecondsSinceEpoch}',
          type: AnomalyType.spendingDrop,
          severity: AnomalySeverity.medium,
          title: '$category Spending Drop',
          message: '$category spending is down $percentageDecrease% from your average of \$${averageAmount.toStringAsFixed(0)}',
          category: category,
          amount: currentAmount,
          detectedAt: DateTime.now(),
          relatedDate: currentPeriod.startDate,
          metadata: {
            'current_amount': currentAmount,
            'average_amount': averageAmount,
            'ratio': ratio,
            'period': currentPeriod.displayName,
          },
          recommendations: [
            'Check if you\'ve missed recording some $category transactions',
            'Verify if this decrease is intentional',
            'Review your recent $category spending habits',
          ],
        ));
      }
    }

    return anomalies;
  }

  /// Detect missing spending patterns
  static List<Anomaly> _detectMissingPatterns(
    List<Transaction> transactions,
    TimePeriod currentPeriod,
    AnomalyDetectionConfig config,
  ) {
    final anomalies = <Anomaly>[];
    final categoryStats = _calculateCategoryStats(transactions);
    final now = DateTime.now();

    for (final stats in categoryStats.values) {
      if (stats.transactionCount < config.minimumTransactionsForStats) {
        continue;
      }

      // Check if we haven't seen this category in the expected timeframe
      final daysSinceLastTransaction = now.difference(stats.lastTransaction).inDays;
      final expectedFrequency = stats.averageFrequency;

      if (daysSinceLastTransaction > expectedFrequency * 2 && 
          daysSinceLastTransaction >= config.missingPatternDays) {
        anomalies.add(Anomaly(
          id: 'missing_${stats.category}_${DateTime.now().millisecondsSinceEpoch}',
          type: AnomalyType.missingPattern,
          severity: daysSinceLastTransaction > expectedFrequency * 3 
              ? AnomalySeverity.high 
              : AnomalySeverity.medium,
          title: 'Missing ${stats.category} Spending',
          message: 'No ${stats.category} spending detected for $daysSinceLastTransaction days (usually every ${expectedFrequency.round()} days)',
          category: stats.category,
          detectedAt: DateTime.now(),
          relatedDate: stats.lastTransaction,
          metadata: {
            'days_since_last': daysSinceLastTransaction,
            'expected_frequency': expectedFrequency,
            'last_transaction_date': stats.lastTransaction.toIso8601String(),
          },
          recommendations: [
            'Check if you\'ve missed recording ${stats.category} transactions',
            'Verify if you\'ve changed your ${stats.category} spending habits',
            'Consider setting up automatic transaction import',
          ],
        ));
      }
    }

    return anomalies;
  }

  /// Detect potential duplicate transactions
  static List<Anomaly> _detectDuplicateTransactions(
    List<Transaction> transactions,
    AnomalyDetectionConfig config,
  ) {
    final anomalies = <Anomaly>[];
    final recentTransactions = transactions
        .where((tx) => tx.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();

    for (int i = 0; i < recentTransactions.length; i++) {
      final tx1 = recentTransactions[i];
      
      for (int j = i + 1; j < recentTransactions.length; j++) {
        final tx2 = recentTransactions[j];
        
        // Check for potential duplicates
        final timeDifference = tx1.date.difference(tx2.date).inHours.abs();
        final amountMatch = (tx1.amount - tx2.amount).abs() < 0.01;
        final categoryMatch = tx1.category == tx2.category;
        final merchantSimilar = tx1.title.toLowerCase().contains(tx2.title.toLowerCase()) ||
                               tx2.title.toLowerCase().contains(tx1.title.toLowerCase());

        if (timeDifference <= config.duplicateThreshold && 
            amountMatch && 
            categoryMatch && 
            merchantSimilar) {
          anomalies.add(Anomaly(
            id: 'duplicate_${tx1.id}_${tx2.id}',
            type: AnomalyType.duplicateTransaction,
            severity: AnomalySeverity.medium,
            title: 'Possible Duplicate Transaction',
            message: 'Found similar transactions: ${tx1.title} (\$${tx1.amount.abs().toStringAsFixed(2)}) on ${tx1.date.day}/${tx1.date.month}',
            category: tx1.category,
            merchant: tx1.title,
            amount: tx1.amount.abs(),
            detectedAt: DateTime.now(),
            relatedDate: tx1.date,
            metadata: {
              'transaction1_id': tx1.id,
              'transaction2_id': tx2.id,
              'time_difference_hours': timeDifference,
            },
            recommendations: [
              'Review these transactions to confirm they\'re not duplicates',
              'Delete duplicate transaction if confirmed',
              'Check your transaction import settings',
            ],
          ));
        }
      }
    }

    return anomalies;
  }

  /// Detect unusual merchants
  static List<Anomaly> _detectUnusualMerchants(
    List<Transaction> transactions,
    TimePeriod currentPeriod,
    AnomalyDetectionConfig config,
  ) {
    final anomalies = <Anomaly>[];
    final merchantStats = _calculateMerchantStats(transactions);
    
    // Get current period transactions
    final currentPeriodTransactions = transactions
        .where((tx) => currentPeriod.containsDate(tx.date))
        .toList();

    // Find new merchants in current period
    final currentMerchants = currentPeriodTransactions
        .map((tx) => tx.title.toLowerCase())
        .toSet();

    final historicalMerchants = merchantStats.keys
        .map((merchant) => merchant.toLowerCase())
        .toSet();

    for (final merchant in currentMerchants) {
      if (!historicalMerchants.contains(merchant)) {
        final merchantTransactions = currentPeriodTransactions
            .where((tx) => tx.title.toLowerCase() == merchant)
            .toList();

        if (merchantTransactions.isNotEmpty) {
          final totalAmount = merchantTransactions
              .fold(0.0, (sum, tx) => sum + tx.amount.abs());

          anomalies.add(Anomaly(
            id: 'merchant_${merchant.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
            type: AnomalyType.unusualMerchant,
            severity: totalAmount > 100 ? AnomalySeverity.medium : AnomalySeverity.low,
            title: 'New Merchant Detected',
            message: 'First time spending at ${merchantTransactions.first.title} (\$${totalAmount.toStringAsFixed(2)})',
            category: merchantTransactions.first.category,
            merchant: merchantTransactions.first.title,
            amount: totalAmount,
            detectedAt: DateTime.now(),
            relatedDate: merchantTransactions.first.date,
            metadata: {
              'transaction_count': merchantTransactions.length,
              'total_amount': totalAmount,
            },
            recommendations: [
              'Verify this is a legitimate transaction',
              'Consider adding this merchant to your regular spending if appropriate',
              'Review the transaction details for accuracy',
            ],
          ));
        }
      }
    }

    return anomalies;
  }

  /// Detect category shifts
  static List<Anomaly> _detectCategoryShifts(
    List<Transaction> transactions,
    TimePeriod currentPeriod,
    AnomalyDetectionConfig config,
  ) {
    final anomalies = <Anomaly>[];
    
    // Compare current period category distribution with historical
    final previousPeriod = currentPeriod.getPreviousPeriod();
    
    final currentCategoryTotals = _getCategoryTotals(
      transactions.where((tx) => currentPeriod.containsDate(tx.date)).toList()
    );
    
    final previousCategoryTotals = _getCategoryTotals(
      transactions.where((tx) => previousPeriod.containsDate(tx.date)).toList()
    );

    final currentTotal = currentCategoryTotals.values.fold(0.0, (a, b) => a + b);
    final previousTotal = previousCategoryTotals.values.fold(0.0, (a, b) => a + b);

    if (currentTotal == 0 || previousTotal == 0) return anomalies;

    // Calculate percentage shifts
    for (final category in {...currentCategoryTotals.keys, ...previousCategoryTotals.keys}) {
      final currentAmount = currentCategoryTotals[category] ?? 0;
      final previousAmount = previousCategoryTotals[category] ?? 0;
      
      final currentPercentage = (currentAmount / currentTotal) * 100;
      final previousPercentage = (previousAmount / previousTotal) * 100;
      
      final shift = currentPercentage - previousPercentage;

      if (shift.abs() > 15 && currentAmount > 50) { // Significant shift
        anomalies.add(Anomaly(
          id: 'shift_${category}_${DateTime.now().millisecondsSinceEpoch}',
          type: AnomalyType.categoryShift,
          severity: shift.abs() > 25 ? AnomalySeverity.high : AnomalySeverity.medium,
          title: '$category Spending Shift',
          message: '$category spending ${shift > 0 ? 'increased' : 'decreased'} by ${shift.abs().toStringAsFixed(1)}% of total spending',
          category: category,
          amount: currentAmount,
          detectedAt: DateTime.now(),
          relatedDate: currentPeriod.startDate,
          metadata: {
            'current_percentage': currentPercentage,
            'previous_percentage': previousPercentage,
            'shift_percentage': shift,
            'current_amount': currentAmount,
            'previous_amount': previousAmount,
          },
          recommendations: [
            'Review if this shift in $category spending is intentional',
            'Consider adjusting your budget if this is a permanent change',
            'Check if expenses moved between categories incorrectly',
          ],
        ));
      }
    }

    return anomalies;
  }

  /// Detect frequency changes
  static List<Anomaly> _detectFrequencyChanges(
    List<Transaction> transactions,
    TimePeriod currentPeriod,
    AnomalyDetectionConfig config,
  ) {
    final anomalies = <Anomaly>[];
    final categoryStats = _calculateCategoryStats(transactions);

    // Analyze frequency changes for each category
    for (final stats in categoryStats.values) {
      if (stats.transactionCount < config.minimumTransactionsForStats) continue;

      final currentPeriodTransactions = transactions
          .where((tx) => 
              tx.category == stats.category && 
              currentPeriod.containsDate(tx.date))
          .toList();

      if (currentPeriodTransactions.length < 2) continue;

      // Calculate current period frequency
      final periodDays = currentPeriod.endDate.difference(currentPeriod.startDate).inDays;
      final currentFrequency = periodDays / currentPeriodTransactions.length;
      
      final frequencyRatio = currentFrequency / stats.averageFrequency;

      // Detect significant frequency changes
      if (frequencyRatio > 2.0 || frequencyRatio < 0.5) {
        final isIncrease = frequencyRatio > 1.0;
        anomalies.add(Anomaly(
          id: 'freq_${stats.category}_${DateTime.now().millisecondsSinceEpoch}',
          type: AnomalyType.frequencyChange,
          severity: AnomalySeverity.medium,
          title: '${stats.category} Frequency Change',
          message: '${stats.category} transaction frequency ${isIncrease ? 'decreased' : 'increased'} significantly',
          category: stats.category,
          detectedAt: DateTime.now(),
          relatedDate: currentPeriod.startDate,
          metadata: {
            'current_frequency': currentFrequency,
            'historical_frequency': stats.averageFrequency,
            'frequency_ratio': frequencyRatio,
            'current_transaction_count': currentPeriodTransactions.length,
          },
          recommendations: [
            'Review if this change in ${stats.category} spending frequency is expected',
            'Check if you\'ve changed your ${stats.category} habits',
            'Verify all transactions are properly categorized',
          ],
        ));
      }
    }

    return anomalies;
  }

  /// Detect amount anomalies within categories
  static List<Anomaly> _detectAmountAnomalies(
    List<Transaction> transactions,
    TimePeriod currentPeriod,
    AnomalyDetectionConfig config,
  ) {
    final anomalies = <Anomaly>[];
    final categoryStats = _calculateCategoryStats(transactions);

    final currentPeriodTransactions = transactions
        .where((tx) => currentPeriod.containsDate(tx.date))
        .toList();

    for (final tx in currentPeriodTransactions) {
      final stats = categoryStats[tx.category];
      if (stats == null || stats.transactionCount < config.minimumTransactionsForStats) {
        continue;
      }

      final txAmount = tx.amount.abs();
      final zScore = (txAmount - stats.averageAmount) / stats.standardDeviation;

      if (zScore.abs() > config.standardDeviationThreshold) {
        final isHighAmount = zScore > 0;
        anomalies.add(Anomaly(
          id: 'amount_${tx.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: AnomalyType.amountAnomaly,
          severity: zScore.abs() > 3.0 ? AnomalySeverity.high : AnomalySeverity.medium,
          title: '${isHighAmount ? 'High' : 'Low'} ${tx.category} Amount',
          message: '${tx.title} (\$${txAmount.toStringAsFixed(2)}) is ${isHighAmount ? 'much higher' : 'much lower'} than your usual ${tx.category} spending',
          category: tx.category,
          merchant: tx.title,
          amount: txAmount,
          detectedAt: DateTime.now(),
          relatedDate: tx.date,
          metadata: {
            'z_score': zScore,
            'average_amount': stats.averageAmount,
            'standard_deviation': stats.standardDeviation,
            'transaction_id': tx.id,
          },
          recommendations: [
            'Verify this transaction amount is correct',
            'Check if this was a one-time purchase or recurring change',
            'Consider if this transaction should be in a different category',
          ],
        ));
      }
    }

    return anomalies;
  }

  /// Calculate statistical data for each category
  static Map<String, CategoryStats> _calculateCategoryStats(List<Transaction> transactions) {
    final categoryGroups = <String, List<Transaction>>{};
    
    // Group transactions by category
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        categoryGroups.putIfAbsent(tx.category, () => []).add(tx);
      }
    }

    final categoryStats = <String, CategoryStats>{};

    for (final entry in categoryGroups.entries) {
      final category = entry.key;
      final txList = entry.value;
      
      if (txList.isEmpty) continue;

      // Sort by date
      txList.sort((a, b) => a.date.compareTo(b.date));

      // Calculate statistics
      final amounts = txList.map((tx) => tx.amount.abs()).toList();
      final totalAmount = amounts.fold(0.0, (a, b) => a + b);
      final averageAmount = totalAmount / amounts.length;
      
      // Calculate standard deviation
      final variance = amounts
          .map((amount) => math.pow(amount - averageAmount, 2))
          .fold(0.0, (a, b) => a + b) / amounts.length;
      final standardDeviation = math.sqrt(variance);

      // Calculate frequency
      final daysBetween = txList.last.date.difference(txList.first.date).inDays;
      final averageFrequency = daysBetween > 0 ? daysBetween / txList.length : 1.0;

      // Get common merchants
      final merchantCounts = <String, int>{};
      for (final tx in txList) {
        merchantCounts.update(tx.title, (count) => count + 1, ifAbsent: () => 1);
      }
      final commonMerchants = merchantCounts.entries
          .where((entry) => entry.value > 1)
          .map((entry) => entry.key)
          .toList();

      categoryStats[category] = CategoryStats(
        category: category,
        averageAmount: averageAmount,
        standardDeviation: standardDeviation,
        transactionCount: txList.length,
        totalAmount: totalAmount,
        firstTransaction: txList.first.date,
        lastTransaction: txList.last.date,
        commonMerchants: commonMerchants,
        averageFrequency: averageFrequency,
      );
    }

    return categoryStats;
  }

  /// Calculate merchant statistics
  static Map<String, MerchantStats> _calculateMerchantStats(List<Transaction> transactions) {
    final merchantGroups = <String, List<Transaction>>{};
    
    // Group transactions by merchant
    for (final tx in transactions) {
      merchantGroups.putIfAbsent(tx.title, () => []).add(tx);
    }

    final merchantStats = <String, MerchantStats>{};

    for (final entry in merchantGroups.entries) {
      final merchant = entry.key;
      final txList = entry.value;
      
      if (txList.isEmpty) continue;

      // Sort by date
      txList.sort((a, b) => a.date.compareTo(b.date));

      // Calculate statistics
      final amounts = txList.map((tx) => tx.amount.abs()).toList();
      final totalAmount = amounts.fold(0.0, (a, b) => a + b);
      final averageAmount = totalAmount / amounts.length;

      // Calculate frequency
      final daysBetween = txList.last.date.difference(txList.first.date).inDays;
      final averageFrequency = daysBetween > 0 ? daysBetween / txList.length : 1.0;

      // Get categories
      final categories = txList.map((tx) => tx.category).toSet().toList();

      merchantStats[merchant] = MerchantStats(
        merchant: merchant,
        averageAmount: averageAmount,
        transactionCount: txList.length,
        totalAmount: totalAmount,
        firstTransaction: txList.first.date,
        lastTransaction: txList.last.date,
        categories: categories,
        averageFrequency: averageFrequency,
      );
    }

    return merchantStats;
  }

  /// Get category totals for a list of transactions
  static Map<String, double> _getCategoryTotals(List<Transaction> transactions) {
    final categoryTotals = <String, double>{};
    
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        categoryTotals.update(
          tx.category,
          (value) => value + tx.amount.abs(),
          ifAbsent: () => tx.amount.abs(),
        );
      }
    }
    
    return categoryTotals;
  }
}
