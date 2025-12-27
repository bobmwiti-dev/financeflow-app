import 'package:flutter/material.dart';

enum AnomalyType {
  spendingSpike,
  spendingDrop,
  missingPattern,
  duplicateTransaction,
  unusualMerchant,
  categoryShift,
  frequencyChange,
  amountAnomaly,
}

enum AnomalySeverity {
  low,
  medium,
  high,
  critical,
}

class Anomaly {
  final String id;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String title;
  final String message;
  final String? category;
  final String? merchant;
  final double? amount;
  final DateTime detectedAt;
  final DateTime? relatedDate;
  final Map<String, dynamic> metadata;
  final List<String> recommendations;

  Anomaly({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.category,
    this.merchant,
    this.amount,
    required this.detectedAt,
    this.relatedDate,
    this.metadata = const {},
    this.recommendations = const [],
  });

  // Get icon based on anomaly type
  IconData get icon {
    switch (type) {
      case AnomalyType.spendingSpike:
        return Icons.trending_up;
      case AnomalyType.spendingDrop:
        return Icons.trending_down;
      case AnomalyType.missingPattern:
        return Icons.schedule;
      case AnomalyType.duplicateTransaction:
        return Icons.content_copy;
      case AnomalyType.unusualMerchant:
        return Icons.store;
      case AnomalyType.categoryShift:
        return Icons.swap_horiz;
      case AnomalyType.frequencyChange:
        return Icons.repeat;
      case AnomalyType.amountAnomaly:
        return Icons.attach_money;
    }
  }

  // Get color based on severity
  Color get color {
    switch (severity) {
      case AnomalySeverity.low:
        return Colors.blue;
      case AnomalySeverity.medium:
        return Colors.orange;
      case AnomalySeverity.high:
        return Colors.red;
      case AnomalySeverity.critical:
        return Colors.purple;
    }
  }

  // Get severity label
  String get severityLabel {
    switch (severity) {
      case AnomalySeverity.low:
        return 'Info';
      case AnomalySeverity.medium:
        return 'Notice';
      case AnomalySeverity.high:
        return 'Alert';
      case AnomalySeverity.critical:
        return 'Critical';
    }
  }

  // Get type description
  String get typeDescription {
    switch (type) {
      case AnomalyType.spendingSpike:
        return 'Spending Spike';
      case AnomalyType.spendingDrop:
        return 'Spending Drop';
      case AnomalyType.missingPattern:
        return 'Missing Pattern';
      case AnomalyType.duplicateTransaction:
        return 'Duplicate Transaction';
      case AnomalyType.unusualMerchant:
        return 'New Merchant';
      case AnomalyType.categoryShift:
        return 'Category Shift';
      case AnomalyType.frequencyChange:
        return 'Frequency Change';
      case AnomalyType.amountAnomaly:
        return 'Amount Anomaly';
    }
  }

  @override
  String toString() {
    return 'Anomaly{type: $type, severity: $severity, title: $title}';
  }
}

class CategoryStats {
  final String category;
  final double averageAmount;
  final double standardDeviation;
  final int transactionCount;
  final double totalAmount;
  final DateTime firstTransaction;
  final DateTime lastTransaction;
  final List<String> commonMerchants;
  final double averageFrequency; // days between transactions

  CategoryStats({
    required this.category,
    required this.averageAmount,
    required this.standardDeviation,
    required this.transactionCount,
    required this.totalAmount,
    required this.firstTransaction,
    required this.lastTransaction,
    required this.commonMerchants,
    required this.averageFrequency,
  });
}

class MerchantStats {
  final String merchant;
  final double averageAmount;
  final int transactionCount;
  final double totalAmount;
  final DateTime firstTransaction;
  final DateTime lastTransaction;
  final List<String> categories;
  final double averageFrequency;

  MerchantStats({
    required this.merchant,
    required this.averageAmount,
    required this.transactionCount,
    required this.totalAmount,
    required this.firstTransaction,
    required this.lastTransaction,
    required this.categories,
    required this.averageFrequency,
  });
}

class AnomalyDetectionConfig {
  final double spikeSensitivity; // multiplier for detecting spikes (e.g., 2.0 = 200% above average)
  final double dropSensitivity; // multiplier for detecting drops (e.g., 0.5 = 50% below average)
  final int missingPatternDays; // days to consider a pattern missing
  final double duplicateThreshold; // hours within which to consider duplicates
  final int minimumTransactionsForStats; // minimum transactions needed for statistical analysis
  final double standardDeviationThreshold; // standard deviations for anomaly detection

  const AnomalyDetectionConfig({
    this.spikeSensitivity = 2.0,
    this.dropSensitivity = 0.3,
    this.missingPatternDays = 7,
    this.duplicateThreshold = 24.0,
    this.minimumTransactionsForStats = 5,
    this.standardDeviationThreshold = 2.0,
  });
}
