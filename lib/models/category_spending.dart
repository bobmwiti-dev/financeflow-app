import 'package:flutter/material.dart';

/// Model class for category spending data visualization
class CategorySpending {
  final String category;
  final double amount;
  final double percentage;
  final Color color;

  CategorySpending({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  CategorySpending copyWith({
    String? category,
    double? amount,
    double? percentage,
    Color? color,
  }) {
    return CategorySpending(
      category: category ?? this.category,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'CategorySpending(category: $category, amount: $amount, percentage: $percentage)';
  }
}
