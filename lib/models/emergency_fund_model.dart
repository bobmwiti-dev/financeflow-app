import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyFund {
  final String? id;
  final String userId;
  final double currentAmount;
  final double targetAmount;
  final int targetMonths;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final String? notes;

  EmergencyFund({
    this.id,
    required this.userId,
    required this.currentAmount,
    required this.targetAmount,
    this.targetMonths = 6,
    DateTime? lastUpdated,
    DateTime? createdAt,
    this.notes,
  })  : lastUpdated = lastUpdated ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'currentAmount': currentAmount,
      'targetAmount': targetAmount,
      'targetMonths': targetMonths,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }

  // Create from Firestore document
  factory EmergencyFund.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyFund(
      id: doc.id,
      userId: data['userId'] ?? '',
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
      targetMonths: data['targetMonths'] ?? 6,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
    );
  }

  // Create from Map
  factory EmergencyFund.fromMap(Map<String, dynamic> map, {String? id}) {
    return EmergencyFund(
      id: id ?? map['id'],
      userId: map['userId'] ?? '',
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      targetMonths: map['targetMonths'] ?? 6,
      lastUpdated: map['lastUpdated'] is Timestamp 
          ? (map['lastUpdated'] as Timestamp).toDate() 
          : DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      notes: map['notes'],
    );
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  // Check if fund is complete
  bool get isComplete => progressPercentage >= 100.0;

  // Calculate remaining amount needed
  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  // Copy with new values
  EmergencyFund copyWith({
    String? id,
    String? userId,
    double? currentAmount,
    double? targetAmount,
    int? targetMonths,
    DateTime? lastUpdated,
    DateTime? createdAt,
    String? notes,
  }) {
    return EmergencyFund(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      targetMonths: targetMonths ?? this.targetMonths,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'EmergencyFund(id: $id, userId: $userId, currentAmount: $currentAmount, targetAmount: $targetAmount, progressPercentage: ${progressPercentage.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyFund &&
        other.id == id &&
        other.userId == userId &&
        other.currentAmount == currentAmount &&
        other.targetAmount == targetAmount &&
        other.targetMonths == targetMonths;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        currentAmount.hashCode ^
        targetAmount.hashCode ^
        targetMonths.hashCode;
  }
}
