import 'package:cloud_firestore/cloud_firestore.dart';

class Bill {
  final String? id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool isRecurring;
  final String? frequency; // monthly / quarterly / yearly
  final String? category;
  final bool autoPay;

  Bill({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isRecurring = false,
    this.frequency,
    this.category,
    this.autoPay = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'isRecurring': isRecurring,
      'frequency': frequency,
      'category': category,
      'autoPay': autoPay,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map, String docId) {
    return Bill(
      id: docId,
      name: map['name'],
      amount: (map['amount'] as num).toDouble(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      isRecurring: map['isRecurring'] ?? false,
      frequency: map['frequency'],
      category: map['category'],
      autoPay: map['autoPay'] ?? false,
    );
  }

  Bill copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    bool? isRecurring,
    String? frequency,
    String? category,
    bool? autoPay,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      autoPay: autoPay ?? this.autoPay,
    );
  }
}
