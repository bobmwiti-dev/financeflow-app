import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeSource {
  final dynamic id; // Can be int (SQLite) or String (Firestore)
  final String name;
  final String type; // Salary, Side Hustle, Loan, Grant, etc.
  final double amount;
  final DateTime date;
  final String accountId; // Account this income belongs to
  final bool isRecurring;
  final String frequency; // Monthly, Weekly, One-time, etc.
  final String? notes;

  IncomeSource({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.date,
    required this.accountId,
    this.isRecurring = false,
    this.frequency = 'One-time',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'accountId': accountId,
      'isRecurring': isRecurring ? 1 : 0,
      'frequency': frequency,
      'notes': notes,
    };
  }

  factory IncomeSource.fromMap(Map<String, dynamic> map) {
    // SQLite stores dates as ISO strings. Firestore may already have converted
    // Timestamp -> DateTime when .data() is called, but depending on config, it
    // could still be a Timestamp. Handle all possibilities.
    DateTime parsedDate;
    final rawDate = map['date'];
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else {
      throw ArgumentError('Unsupported date format: $rawDate');
    }

    return IncomeSource(
      id: map['id'],
      name: map['name'] ?? '',
      type: map['type'] ?? 'Other',
      amount: (map['amount'] as num).toDouble(),
      date: parsedDate,
      accountId: map['accountId'] ?? '',
      isRecurring: (map['isRecurring'] is int)
          ? map['isRecurring'] == 1
          : (map['isRecurring'] ?? false),
      frequency: map['frequency'] ?? 'One-time',
      notes: map['notes'],
    );
  }

  // For Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      // Store DateTime as Firestore Timestamp for full query support
      'date': Timestamp.fromDate(date),
      'accountId': accountId,
      'isRecurring': isRecurring,
      'frequency': frequency,
      'notes': notes,
    };
  }

  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    // Firestore can return a Timestamp for date, or an ISO8601 string if coming from
    // other sources. Handle both cases gracefully.
    DateTime parsedDate;
    final rawDate = json['date'];
    if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else {
      throw ArgumentError('Unsupported date format: $rawDate');
    }

    return IncomeSource(
      id: json['id'], // Keep as dynamic to handle both int and String
      name: json['name'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      date: parsedDate,
      accountId: json['accountId'] ?? '',
      isRecurring: json['isRecurring'] ?? false,
      frequency: json['frequency'] ?? 'One-time',
      notes: json['notes'],
    );
  }
}
