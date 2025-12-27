import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class Contribution {
  final String id;
  final String goalId;
  final double amount;
  final DateTime date;

  Contribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
  });

  // Convert a Contribution object into a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
    };
  }

  // Create a Contribution object from a Map (typically from Firestore)
  factory Contribution.fromMap(Map<String, dynamic> map, String documentId) {
    try {
      // Handle potential null or invalid values
      final goalId = map['goalId']?.toString() ?? '';
      if (goalId.isEmpty) {
        throw ArgumentError('goalId cannot be empty');
      }

      // Parse amount with null safety
      final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
      
      // Parse date with null safety and fallback to now
      DateTime date;
      if (map['date'] is Timestamp) {
        date = (map['date'] as Timestamp).toDate();
      } else if (map['date'] is DateTime) {
        date = map['date'] as DateTime;
      } else {
        date = DateTime.now();
      }

      return Contribution(
        id: documentId,
        goalId: goalId,
        amount: amount,
        date: date,
      );
    } catch (e, stackTrace) {
      Logger('Contribution').severe('Error creating Contribution from map', e, stackTrace);
      // Return a default contribution instead of throwing
      return Contribution(
        id: documentId,
        goalId: 'unknown',
        amount: 0.0,
        date: DateTime.now(),
      );
    }
  }
}
