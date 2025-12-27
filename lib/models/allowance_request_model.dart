import 'package:cloud_firestore/cloud_firestore.dart';

class AllowanceRequest {
  final String? id;
  final String memberId;
  final String memberName;
  final double amount;
  final String reason;
  final String status; // pending, approved, declined
  final DateTime createdAt;
  final DateTime? resolvedAt;

  AllowanceRequest({
    this.id,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.reason,
    this.status = 'pending',
    DateTime? createdAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'reason': reason,
      'status': status,
      'createdAt': createdAt,
      'resolvedAt': resolvedAt,
    };
  }

  factory AllowanceRequest.fromMap(Map<String, dynamic> map, {String? id}) {
    return AllowanceRequest(
      id: id ?? map['id'] as String?,
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
