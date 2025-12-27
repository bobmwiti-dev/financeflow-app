import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum TransactionFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
  custom
}

enum TransactionType {
  income,
  expense,
  transfer
}

class ScheduledTransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String category;
  final String? description;
  final bool isActive;
  final int? customDays;
  final String? accountId;
  final String? toAccountId;
  final DateTime lastExecuted;
  final DateTime nextDue;
  final bool autoExecute;

  ScheduledTransactionModel({
    String? id,
    required this.title,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.category,
    this.description,
    this.isActive = true,
    this.customDays,
    this.accountId,
    this.toAccountId,
    DateTime? lastExecuted,
    DateTime? nextDue,
    this.autoExecute = true,
  }) : 
    id = id ?? const Uuid().v4(),
    lastExecuted = lastExecuted ?? DateTime.now().subtract(const Duration(days: 1)),
    nextDue = nextDue ?? _calculateNextDueDate(
      startDate, 
      frequency, 
      customDays,
      DateTime.now().subtract(const Duration(days: 1))
    );

  ScheduledTransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    TransactionFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? description,
    bool? isActive,
    int? customDays,
    String? accountId,
    String? toAccountId,
    DateTime? lastExecuted,
    DateTime? nextDue,
    bool? autoExecute,
  }) {
    return ScheduledTransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      customDays: customDays ?? this.customDays,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      nextDue: nextDue ?? this.nextDue,
      autoExecute: autoExecute ?? this.autoExecute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.toString(),
      'frequency': frequency.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'category': category,
      'description': description,
      'isActive': isActive,
      'customDays': customDays,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'lastExecuted': lastExecuted.toIso8601String(),
      'nextDue': nextDue.toIso8601String(),
      'autoExecute': autoExecute,
    };
  }

  factory ScheduledTransactionModel.fromJson(Map<String, dynamic> json) {
    return ScheduledTransactionModel(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      type: TransactionType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => TransactionType.expense),
      frequency: TransactionFrequency.values.firstWhere(
          (e) => e.toString() == json['frequency'],
          orElse: () => TransactionFrequency.monthly),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      category: json['category'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      customDays: json['customDays'],
      accountId: json['accountId'],
      toAccountId: json['toAccountId'],
      lastExecuted: DateTime.parse(json['lastExecuted']),
      nextDue: DateTime.parse(json['nextDue']),
      autoExecute: json['autoExecute'] ?? true,
    );
  }

  static DateTime _calculateNextDueDate(
    DateTime startDate,
    TransactionFrequency frequency,
    int? customDays,
    DateTime lastExecuted,
  ) {
    if (startDate.isAfter(DateTime.now())) {
      return startDate;
    }

    DateTime nextDate = lastExecuted;
    
    switch (frequency) {
      case TransactionFrequency.daily:
        nextDate = nextDate.add(const Duration(days: 1));
        break;
      case TransactionFrequency.weekly:
        nextDate = nextDate.add(const Duration(days: 7));
        break;
      case TransactionFrequency.biweekly:
        nextDate = nextDate.add(const Duration(days: 14));
        break;
      case TransactionFrequency.monthly:
        nextDate = DateTime(
          nextDate.year,
          nextDate.month + 1,
          startDate.day,
        );
        break;
      case TransactionFrequency.quarterly:
        nextDate = DateTime(
          nextDate.year,
          nextDate.month + 3,
          startDate.day,
        );
        break;
      case TransactionFrequency.yearly:
        nextDate = DateTime(
          nextDate.year + 1,
          startDate.month,
          startDate.day,
        );
        break;
      case TransactionFrequency.custom:
        if (customDays != null && customDays > 0) {
          nextDate = nextDate.add(Duration(days: customDays));
        } else {
          nextDate = nextDate.add(const Duration(days: 30)); // Default to monthly
        }
        break;
    }
    
    // Ensure the next date is in the future
    if (nextDate.isBefore(DateTime.now())) {
      return _calculateNextDueDate(startDate, frequency, customDays, nextDate);
    }
    
    return nextDate;
  }

  DateTime calculateNextDueDate() {
    return _calculateNextDueDate(startDate, frequency, customDays, lastExecuted);
  }

  int get daysUntilDue {
    return nextDue.difference(DateTime.now()).inDays;
  }

  String getFrequencyText() {
    switch (frequency) {
      case TransactionFrequency.daily:
        return 'Daily';
      case TransactionFrequency.weekly:
        return 'Weekly';
      case TransactionFrequency.biweekly:
        return 'Every 2 weeks';
      case TransactionFrequency.monthly:
        return 'Monthly';
      case TransactionFrequency.quarterly:
        return 'Every 3 months';
      case TransactionFrequency.yearly:
        return 'Yearly';
      case TransactionFrequency.custom:
        if (customDays != null && customDays! > 0) {
          return 'Every $customDays days';
        } else {
          return 'Custom';
        }
    }
  }

  IconData getTypeIcon() {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  Color getTypeColor() {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  // Generate sample data for testing
  static List<ScheduledTransactionModel> getSampleData() {
    return [
      ScheduledTransactionModel(
        title: 'Rent Payment',
        amount: 1200.00,
        type: TransactionType.expense,
        frequency: TransactionFrequency.monthly,
        startDate: DateTime(2025, 5, 1),
        category: 'Housing',
        description: 'Monthly apartment rent',
      ),
      ScheduledTransactionModel(
        title: 'Salary Deposit',
        amount: 3500.00,
        type: TransactionType.income,
        frequency: TransactionFrequency.biweekly,
        startDate: DateTime(2025, 4, 15),
        category: 'Income',
        description: 'Bi-weekly salary payment',
      ),
      ScheduledTransactionModel(
        title: 'Netflix Subscription',
        amount: 15.99,
        type: TransactionType.expense,
        frequency: TransactionFrequency.monthly,
        startDate: DateTime(2025, 4, 20),
        category: 'Entertainment',
        description: 'Standard HD plan',
      ),
      ScheduledTransactionModel(
        title: 'Gym Membership',
        amount: 49.99,
        type: TransactionType.expense,
        frequency: TransactionFrequency.monthly,
        startDate: DateTime(2025, 4, 5),
        category: 'Health & Fitness',
      ),
      ScheduledTransactionModel(
        title: 'Savings Transfer',
        amount: 500.00,
        type: TransactionType.transfer,
        frequency: TransactionFrequency.monthly,
        startDate: DateTime(2025, 4, 30),
        category: 'Savings',
        description: 'Monthly transfer to savings account',
        accountId: 'checking123',
        toAccountId: 'savings456',
      ),
      ScheduledTransactionModel(
        title: 'Car Insurance',
        amount: 175.00,
        type: TransactionType.expense,
        frequency: TransactionFrequency.quarterly,
        startDate: DateTime(2025, 6, 15),
        category: 'Insurance',
        description: 'Quarterly premium payment',
      ),
    ];
  }
}
