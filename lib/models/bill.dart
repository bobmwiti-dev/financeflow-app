import 'package:flutter/material.dart';

/// Bill model for bill reminders and recurring payments
class Bill {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isPaid;
  final String? recurrence; // monthly, weekly, etc.
  final String? description;
  final String? payee;

  Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.isPaid,
    this.recurrence,
    this.description,
    this.payee,
  });

  /// Days remaining until the bill is due
  int get daysRemaining {
    final today = DateTime.now();
    return dueDate.difference(today).inDays;
  }
  
  /// Status of the bill based on payment status and due date
  String get status {
    if (isPaid) return 'Paid';
    if (daysRemaining < 0) return 'Overdue';
    if (daysRemaining == 0) return 'Due Today';
    if (daysRemaining <= 3) return 'Due Soon';
    return 'Upcoming';
  }

  /// Check if the bill is overdue
  bool get isOverdue => !isPaid && daysRemaining < 0;

  /// Copy with new values
  Bill copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? category,
    bool? isPaid,
    String? recurrence,
    String? description,
    String? payee,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      isPaid: isPaid ?? this.isPaid,
      recurrence: recurrence ?? this.recurrence,
      description: description ?? this.description,
      payee: payee ?? this.payee,
    );
  }

  /// Get icon based on bill category
  IconData getIcon() {
    switch (category.toLowerCase()) {
      case 'utilities':
        return Icons.power;
      case 'rent':
      case 'mortgage':
        return Icons.home;
      case 'phone':
        return Icons.phone;
      case 'internet':
        return Icons.wifi;
      case 'water':
        return Icons.water_drop;
      case 'electricity':
        return Icons.electric_bolt;
      case 'streaming':
        return Icons.tv;
      case 'subscription':
        return Icons.subscriptions;
      case 'insurance':
        return Icons.health_and_safety;
      case 'loan':
      case 'credit':
        return Icons.credit_card;
      case 'tax':
        return Icons.receipt_long;
      default:
        return Icons.receipt;
    }
  }

  /// Get color based on bill status
  Color getColor() {
    if (isPaid) return Colors.green;
    if (isOverdue) return Colors.red;
    if (daysRemaining <= 3) return Colors.orange;
    return Colors.blue;
  }

  @override
  String toString() {
    return 'Bill(id: $id, title: $title, amount: $amount, dueDate: $dueDate, isPaid: $isPaid, status: $status)';
  }
}

/// Bill reminder simplified model specifically for the dashboard
class BillReminder {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isPaid;

  BillReminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.isPaid,
  });

  int get daysRemaining {
    final today = DateTime.now();
    return dueDate.difference(today).inDays;
  }

  String get status {
    if (isPaid) return 'Paid';
    if (daysRemaining < 0) return 'Overdue';
    if (daysRemaining == 0) return 'Due Today';
    if (daysRemaining <= 3) return 'Due Soon';
    return 'Upcoming';
  }

  bool get isOverdue => !isPaid && daysRemaining < 0;

  BillReminder copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? category,
    bool? isPaid,
  }) {
    return BillReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}
