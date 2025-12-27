import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String? id;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final double spent;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.spent = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'spent': spent,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    final logger = Logger('BudgetModel');
    logger.info('Parsing budget from map: $map');
    try {
      // Safely parse ID; allow null/invalid IDs to pass through so they can be filtered later
      final rawId = map['id'];
      String? budgetId;
      if (rawId == null || rawId.toString() == 'null' || (rawId is String && rawId.isEmpty)) {
        logger.warning('Budget has null or invalid ID; continuing with null ID (will be filtered downstream)');
        budgetId = null;
      } else {
        budgetId = rawId.toString();
      }
      
      return Budget(
        id: budgetId,
        category: map['category'],
        amount: (map['amount'] as num).toDouble(),
        startDate: _parseDateTime(map['startDate']),
        endDate: _parseDateTime(map['endDate']),
        spent: (map['spent'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      logger.severe('Error parsing budget from map: $e');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    } else {
      throw ArgumentError('Invalid date format: $value');
    }
  }

  double get remainingAmount => amount - spent;
  double get percentUsed => (spent / amount) * 100;
  
  Budget copyWith({
    String? id,
    String? category,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      spent: spent ?? this.spent,
    );
  }
}
