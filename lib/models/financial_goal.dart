import 'package:flutter/material.dart';

/// Model class for financial goals
class FinancialGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String category;
  final String? description;

  FinancialGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.category,
    this.description,
  });

  double get progressPercentage => 
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => currentAmount >= targetAmount;

  int get daysRemaining {
    final today = DateTime.now();
    return targetDate.difference(today).inDays;
  }

  FinancialGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    String? description,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  Color getColor() {
    if (progressPercentage >= 1.0) {
      return Colors.green;
    } else if (progressPercentage > 0.7) {
      return Colors.lightGreen;
    } else if (progressPercentage > 0.4) {
      return Colors.amber;
    } else {
      return Colors.redAccent;
    }
  }

  IconData getIcon() {
    switch (category.toLowerCase()) {
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      case 'home':
      case 'house':
        return Icons.home;
      case 'car':
      case 'vehicle':
        return Icons.directions_car;
      case 'emergency':
        return Icons.emergency;
      case 'retirement':
        return Icons.beach_access;
      default:
        return Icons.flag;
    }
  }

  @override
  String toString() {
    return 'FinancialGoal(id: $id, title: $title, targetAmount: $targetAmount, '
        'currentAmount: $currentAmount, progressPercentage: $progressPercentage)';
  }
}
