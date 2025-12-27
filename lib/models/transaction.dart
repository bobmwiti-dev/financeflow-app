import 'package:flutter/material.dart';

/// Transaction model representing a financial transaction
class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String type; // income, expense, transfer
  final String? description;
  final String? payee;
  final String? accountId;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.description,
    this.payee,
    this.accountId,
  });

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? type,
    String? description,
    String? payee,
    String? accountId,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      description: description ?? this.description,
      payee: payee ?? this.payee,
      accountId: accountId ?? this.accountId,
    );
  }

  IconData getIcon() {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
      case 'travel':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'utilities':
      case 'bills':
        return Icons.receipt_long;
      case 'housing':
      case 'rent':
      case 'mortgage':
        return Icons.home;
      case 'entertainment':
        return Icons.movie;
      case 'health':
      case 'medical':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'salary':
      case 'income':
      case 'wage':
        return Icons.monetization_on;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.category;
    }
  }

  Color getColor() {
    if (type.toLowerCase() == 'income') {
      return Colors.green;
    } else if (type.toLowerCase() == 'expense') {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  @override
  String toString() {
    return 'Transaction(id: $id, title: $title, amount: $amount, date: $date, category: $category, type: $type)';
  }
}
