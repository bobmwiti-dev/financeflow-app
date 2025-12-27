import 'package:cloud_firestore/cloud_firestore.dart';

enum LiabilityType {
  loan,
  creditCard,
  mortgage,
  other,
}

class Liability {
  final String id;
  final String userId;
  final String name;
  final LiabilityType type;
  final double amount;
  final DateTime createdAt;

  Liability({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.amount,
    required this.createdAt,
  });

  factory Liability.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Liability(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: LiabilityType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => LiabilityType.other,
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type.toString(),
      'amount': amount,
      'createdAt': createdAt,
    };
  }
}
