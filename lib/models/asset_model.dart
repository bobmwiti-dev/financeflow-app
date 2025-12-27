import 'package:cloud_firestore/cloud_firestore.dart';

enum AssetType {
  cash,
  investment,
  property,
  other,
}

class Asset {
  final String id;
  final String userId;
  final String name;
  final AssetType type;
  final double value;
  final DateTime createdAt;

  Asset({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.value,
    required this.createdAt,
  });

  factory Asset.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Asset(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: AssetType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => AssetType.other,
      ),
      value: (data['value'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type.toString(),
      'value': value,
      'createdAt': createdAt,
    };
  }
}
