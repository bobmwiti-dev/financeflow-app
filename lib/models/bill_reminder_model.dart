import 'package:flutter/material.dart';

class BillReminder {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isPaid;
  final bool isRecurring;
  final String? frequency;  // monthly, weekly, etc.
  final String? notes;

  const BillReminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    this.isPaid = false,
    this.isRecurring = false,
    this.frequency,
    this.notes,
  });

  // Create a copy of this bill with updated fields
  BillReminder copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? category,
    bool? isPaid,
    bool? isRecurring,
    String? frequency,
    String? notes,
  }) {
    return BillReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      isPaid: isPaid ?? this.isPaid,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      notes: notes ?? this.notes,
    );
  }

  // Get days until due
  int get daysUntilDue {
    final now = DateTime.now();
    return dueDate.difference(now).inDays;
  }

  // Is this bill overdue?
  bool get isOverdue {
    return !isPaid && daysUntilDue < 0;
  }

  // Is this bill due soon? (within 5 days)
  bool get isDueSoon {
    return !isPaid && daysUntilDue >= 0 && daysUntilDue <= 5;
  }

  // Is this bill due later? (more than 5 days)
  bool get isDueLater {
    return !isPaid && daysUntilDue > 5;
  }
  
  // Get a color representing the bill status
  Color get statusColor {
    if (isPaid) {
      return Colors.green;
    } else if (isOverdue) {
      return Colors.red;
    } else if (isDueSoon) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
  
  // Get a description of when the bill is due
  String get dueDescription {
    if (isPaid) {
      return 'Paid';
    } else if (isOverdue) {
      final days = -daysUntilDue;
      return days == 1 ? 'Overdue by 1 day' : 'Overdue by $days days';
    } else if (daysUntilDue == 0) {
      return 'Due today';
    } else if (daysUntilDue == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $daysUntilDue days';
    }
  }
  
  // Convert to a map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'category': category,
      'isPaid': isPaid,
      'isRecurring': isRecurring,
      'frequency': frequency,
      'notes': notes,
    };
  }
  
  // Create from a Firestore map
  factory BillReminder.fromMap(Map<String, dynamic> map) {
    return BillReminder(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] ?? 0),
      category: map['category'] ?? '',
      isPaid: map['isPaid'] ?? false,
      isRecurring: map['isRecurring'] ?? false,
      frequency: map['frequency'],
      notes: map['notes'],
    );
  }
}
