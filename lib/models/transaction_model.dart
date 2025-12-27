import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// For easier access to the UUID generator
final _uuid = const Uuid();

// Type alias for backward compatibility
typedef Transaction = TransactionModel;

enum TransactionType { income, expense, transfer }

enum TransactionStatus {
  pending,
  completed,
  failed,
  partial,
  scheduled,
  recurring
}

class TransactionModel {
  final String? id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? description;
  final TransactionType type;
  final String accountId; // Primary account for this transaction
  final String? fromAccount; // For transfers - source account
  final String? toAccount; // For transfers - destination account
  final String userId;
  final String? notes;
  final bool isSynced;
  final String? smsReference;
  final TransactionStatus status;
  final double? paidAmount;
  final bool isCarriedForward;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.description,
    required this.type,
    required this.accountId,
    this.fromAccount,
    this.toAccount,
    required this.userId,
    this.notes,
    this.isSynced = false,
    this.smsReference,
    this.status = TransactionStatus.pending,
    double? paidAmount,
    this.isCarriedForward = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        paidAmount = paidAmount ?? amount;

  // Convert TransactionModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'description': description,
      'type': type.toString(),
      'accountId': accountId,
      'fromAccount': fromAccount,
      'toAccount': toAccount,
      'userId': userId,
      'notes': notes,
      'isSynced': isSynced,
      'smsReference': smsReference,
      'status': status.toString(),
      'paidAmount': paidAmount,
      'isCarriedForward': isCarriedForward,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create TransactionModel from a Map (e.g., from Firestore)
  factory TransactionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return TransactionModel(
      id: id ?? map['id'],
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num).toDouble(),
      date: (() {
        final rawDate = map['date'];
        if (rawDate is Timestamp) {
          return rawDate.toDate();
        } else if (rawDate is int) {
          // Firestore integer (epoch milliseconds or seconds) → DateTime
          // Heuristic: if value looks like seconds (10 digits), multiply by 1000.
          final ms = rawDate > 1000000000000 ? rawDate : rawDate * 1000;
          return DateTime.fromMillisecondsSinceEpoch(ms);
        } else {
          return DateTime.parse(rawDate.toString());
        }
      })(),
      category: map['category']?.toString() ?? '',
      description: map['description']?.toString(),
      type: _transactionTypeFromString(map['type']?.toString()),
      accountId: map['accountId']?.toString() ?? '',
      fromAccount: map['fromAccount']?.toString(),
      toAccount: map['toAccount']?.toString(),
      userId: map['userId']?.toString() ?? '',
      notes: map['notes']?.toString(),
      isSynced: map['isSynced'] as bool? ?? true,
      smsReference: map['smsReference']?.toString(),
      status: map['status'] is TransactionStatus
          ? map['status'] as TransactionStatus
          : _transactionStatusFromString(map['status']?.toString()),
      paidAmount: (map['paidAmount'] as num?)?.toDouble(),
      isCarriedForward: map['isCarriedForward'] as bool? ?? false,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : (map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now()),
    );
  }

  // Helper method to convert string to TransactionType
  static TransactionType _transactionTypeFromString(String? type) {
    if (type == null) return TransactionType.expense;
    
    // Handle both enum name and full enum string
    final typeName = type.contains('.') 
        ? type.split('.').last 
        : type;
        
    return TransactionType.values.firstWhere(
      (e) => e.toString().split('.').last == typeName,
      orElse: () => TransactionType.expense,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $amount, type: $type, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.date == date &&
        other.category == category &&
        other.description == description &&
        other.type == type &&
        other.fromAccount == fromAccount &&
        other.toAccount == toAccount &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      amount,
      date,
      category,
      description,
      type,
      fromAccount,
      toAccount,
      userId,
    );
  }

  // Convert Firestore document to TransactionModel
  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data()!;
    return TransactionModel.fromMap(data, id: doc.id);
  }

  // Convert TransactionModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'description': description,
      'type': type.toString(),
      'fromAccount': fromAccount,
      'toAccount': toAccount,
      'userId': userId,
      'notes': notes,
      'isSynced': isSynced,
      'smsReference': smsReference,
      'status': status.toString(),
      'paidAmount': paidAmount,
      'isCarriedForward': isCarriedForward,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Getters for compatibility
  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => type == TransactionType.transfer;
  bool get isPartiallyPaid => status == TransactionStatus.partial;
  
  double get remainingAmount => amount - (paidAmount ?? 0);
  
  // For backward compatibility
  String? get firestoreId => id;
  
  // Helper to get the appropriate account based on transaction type
  String? get displayAccount => isIncome ? fromAccount : toAccount;

  // Helper method to parse TransactionStatus from string
  static TransactionStatus _transactionStatusFromString(String? status) {
    if (status == null) return TransactionStatus.completed;
    
    // Handle both enum name and full enum string
    final statusName = status.contains('.') 
        ? status.split('.').last 
        : status;
        
    return TransactionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusName,
      orElse: () => TransactionStatus.completed,
    );
  }

  // Create a copy of the transaction with updated fields
  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? description,
    TransactionType? type,
    String? fromAccount,
    String? toAccount,
    String? userId,
    String? notes,
    bool? isSynced,
    String? smsReference,
    TransactionStatus? status,
    double? paidAmount,
    bool? isCarriedForward,
    String? accountId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      type: type ?? this.type,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      smsReference: smsReference ?? this.smsReference,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      isCarriedForward: isCarriedForward ?? this.isCarriedForward,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
