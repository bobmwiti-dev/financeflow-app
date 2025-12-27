// Models and utilities
import 'package:uuid/uuid.dart';

enum SplitExpenseStatus {
  pending,
  partiallyPaid,
  fullyPaid,
  declined
}

class SplitExpenseModel {
  final String id;
  final String title;
  final String description;
  final double totalAmount;
  final DateTime createdAt;
  final String createdById;
  final String createdByName;
  final List<SplitParticipant> participants;
  final SplitExpenseStatus status;
  final String? receiptImagePath;
  final String? category;

  SplitExpenseModel({
    String? id,
    required this.title,
    this.description = '',
    required this.totalAmount,
    DateTime? createdAt,
    required this.createdById,
    required this.createdByName,
    required this.participants,
    this.status = SplitExpenseStatus.pending,
    this.receiptImagePath,
    this.category,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  double get amountPaid => participants
      .fold(0.0, (sum, participant) => sum + participant.amountPaid);

  double get amountRemaining => totalAmount - amountPaid;

  double get percentPaid => totalAmount > 0 
      ? (amountPaid / totalAmount * 100) 
      : 0.0;

  bool get isFullyPaid => percentPaid >= 99.9;

  SplitExpenseModel copyWith({
    String? id,
    String? title,
    String? description,
    double? totalAmount,
    DateTime? createdAt,
    String? createdById,
    String? createdByName,
    List<SplitParticipant>? participants,
    SplitExpenseStatus? status,
    String? receiptImagePath,
    String? category,
  }) {
    return SplitExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'createdById': createdById,
      'createdByName': createdByName,
      'participants': participants.map((p) => p.toJson()).toList(),
      'status': status.toString(),
      'receiptImagePath': receiptImagePath,
      'category': category,
    };
  }

  factory SplitExpenseModel.fromJson(Map<String, dynamic> json) {
    return SplitExpenseModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      totalAmount: json['totalAmount'],
      createdAt: DateTime.parse(json['createdAt']),
      createdById: json['createdById'],
      createdByName: json['createdByName'],
      participants: (json['participants'] as List)
          .map((p) => SplitParticipant.fromJson(p))
          .toList(),
      status: SplitExpenseStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => SplitExpenseStatus.pending),
      receiptImagePath: json['receiptImagePath'],
      category: json['category'],
    );
  }

  // Generate sample data for testing
  static List<SplitExpenseModel> getSampleData() {
    return [
      SplitExpenseModel(
        title: 'Dinner at Italian Restaurant',
        totalAmount: 120.50,
        createdById: 'user1',
        createdByName: 'John Doe',
        participants: [
          SplitParticipant(
            id: 'user1',
            name: 'John Doe',
            amountOwed: 40.17,
            amountPaid: 40.17,
            isPayer: true,
          ),
          SplitParticipant(
            id: 'user2',
            name: 'Jane Smith',
            amountOwed: 40.17,
            amountPaid: 40.17,
          ),
          SplitParticipant(
            id: 'user3',
            name: 'Mike Johnson',
            amountOwed: 40.16,
            amountPaid: 0,
          ),
        ],
        category: 'Food & Dining',
        status: SplitExpenseStatus.partiallyPaid,
      ),
      SplitExpenseModel(
        title: 'Apartment Rent - April',
        totalAmount: 1500.00,
        createdById: 'user2',
        createdByName: 'Jane Smith',
        participants: [
          SplitParticipant(
            id: 'user1',
            name: 'John Doe',
            amountOwed: 500.00,
            amountPaid: 500.00,
          ),
          SplitParticipant(
            id: 'user2',
            name: 'Jane Smith',
            amountOwed: 500.00,
            amountPaid: 500.00,
            isPayer: true,
          ),
          SplitParticipant(
            id: 'user3',
            name: 'Mike Johnson',
            amountOwed: 500.00,
            amountPaid: 500.00,
          ),
        ],
        category: 'Housing',
        status: SplitExpenseStatus.fullyPaid,
      ),
      SplitExpenseModel(
        title: 'Movie Night Tickets',
        totalAmount: 45.00,
        createdById: 'user3',
        createdByName: 'Mike Johnson',
        participants: [
          SplitParticipant(
            id: 'user1',
            name: 'John Doe',
            amountOwed: 15.00,
            amountPaid: 0,
          ),
          SplitParticipant(
            id: 'user2',
            name: 'Jane Smith',
            amountOwed: 15.00,
            amountPaid: 0,
          ),
          SplitParticipant(
            id: 'user3',
            name: 'Mike Johnson',
            amountOwed: 15.00,
            amountPaid: 15.00,
            isPayer: true,
          ),
        ],
        category: 'Entertainment',
        status: SplitExpenseStatus.pending,
      ),
    ];
  }
}

class SplitParticipant {
  final String id;
  final String name;
  final double amountOwed;
  final double amountPaid;
  final bool isPayer;
  final String? avatarUrl;
  final DateTime? lastReminderSent;

  SplitParticipant({
    required this.id,
    required this.name,
    required this.amountOwed,
    this.amountPaid = 0.0,
    this.isPayer = false,
    this.avatarUrl,
    this.lastReminderSent,
  });

  bool get hasPaid => amountPaid >= amountOwed;

  double get percentPaid => amountOwed > 0 
      ? (amountPaid / amountOwed * 100) 
      : 0.0;

  SplitParticipant copyWith({
    String? id,
    String? name,
    double? amountOwed,
    double? amountPaid,
    bool? isPayer,
    String? avatarUrl,
    DateTime? lastReminderSent,
  }) {
    return SplitParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      amountOwed: amountOwed ?? this.amountOwed,
      amountPaid: amountPaid ?? this.amountPaid,
      isPayer: isPayer ?? this.isPayer,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amountOwed': amountOwed,
      'amountPaid': amountPaid,
      'isPayer': isPayer,
      'avatarUrl': avatarUrl,
      'lastReminderSent': lastReminderSent?.toIso8601String(),
    };
  }

  factory SplitParticipant.fromJson(Map<String, dynamic> json) {
    return SplitParticipant(
      id: json['id'],
      name: json['name'],
      amountOwed: json['amountOwed'],
      amountPaid: json['amountPaid'] ?? 0.0,
      isPayer: json['isPayer'] ?? false,
      avatarUrl: json['avatarUrl'],
      lastReminderSent: json['lastReminderSent'] != null
          ? DateTime.parse(json['lastReminderSent'])
          : null,
    );
  }
}
