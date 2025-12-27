import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../models/family_member_model.dart';

class FamilyService {
  static final FamilyService _instance = FamilyService._internal();
  factory FamilyService() => _instance;
  FamilyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('FamilyService');

  String? get currentUserId => _auth.currentUser?.uid;

  // Family Members Collection Reference
  CollectionReference get _familyMembersCollection {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('family_members');
  }



  // Stream of family members
  Stream<List<FamilyMember>> getFamilyMembersStream() {
    try {
      _logger.info('Starting family members stream for user: $currentUserId');
      return _familyMembersCollection
          .orderBy('created_at', descending: false)
          .snapshots()
          .map((snapshot) {
        _logger.info('Received ${snapshot.docs.length} family members from Firestore');
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return FamilyMember.fromMap(data);
        }).toList();
      });
    } catch (e, stackTrace) {
      _logger.severe('Error getting family members stream: $e', e, stackTrace);
      return Stream.error(e);
    }
  }

  // Add family member
  Future<String> addFamilyMember(FamilyMember member) async {
    try {
      _logger.info('Adding family member: ${member.name}');
      
      final memberData = member.toMap();
      memberData['created_at'] = FieldValue.serverTimestamp();
      memberData['updated_at'] = FieldValue.serverTimestamp();
      memberData['created_by'] = currentUserId;
      
      final docRef = await _familyMembersCollection.add(memberData);
      
      _logger.info('Family member added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      _logger.severe('Error adding family member: $e', e, stackTrace);
      rethrow;
    }
  }

  // Update family member
  Future<void> updateFamilyMember(FamilyMember member) async {
    try {
      if (member.id == null) {
        throw Exception('Member ID is required for update');
      }
      
      _logger.info('Updating family member: ${member.id}');
      
      final memberData = member.toMap();
      memberData['updated_at'] = FieldValue.serverTimestamp();
      
      await _familyMembersCollection.doc(member.id).update(memberData);
      
      _logger.info('Family member updated successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error updating family member: $e', e, stackTrace);
      rethrow;
    }
  }

  // Delete family member
  Future<void> deleteFamilyMember(String memberId) async {
    try {
      _logger.info('Deleting family member: $memberId');
      
      await _familyMembersCollection.doc(memberId).delete();
      
      _logger.info('Family member deleted successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error deleting family member: $e', e, stackTrace);
      rethrow;
    }
  }

  // Update member spending
  Future<void> updateMemberSpending(String memberId, double amount) async {
    try {
      _logger.info('Updating spending for member $memberId: \$${amount.toStringAsFixed(2)}');
      
      await _familyMembersCollection.doc(memberId).update({
        'spent': amount,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Member spending updated successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error updating member spending: $e', e, stackTrace);
      rethrow;
    }
  }

  // Add spending to member
  Future<void> addSpendingToMember(String memberId, double amount, String description) async {
    try {
      _logger.info('Adding spending to member $memberId: \$${amount.toStringAsFixed(2)}');
      
      // Get current spending
      final memberDoc = await _familyMembersCollection.doc(memberId).get();
      if (!memberDoc.exists) {
        throw Exception('Family member not found');
      }
      
      final currentSpent = (memberDoc.data() as Map<String, dynamic>)['spent'] ?? 0.0;
      final newSpent = currentSpent + amount;
      
      // Update spending
      await _familyMembersCollection.doc(memberId).update({
        'spent': newSpent,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // Add spending record
      await _familyMembersCollection.doc(memberId).collection('spending_history').add({
        'amount': amount,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'added_by': currentUserId,
      });
      
      _logger.info('Spending added successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error adding spending to member: $e', e, stackTrace);
      rethrow;
    }
  }

  // Get family spending summary
  Future<Map<String, dynamic>> getFamilySpendingSummary() async {
    try {
      _logger.info('Getting family spending summary');
      
      final snapshot = await _familyMembersCollection.get();
      
      double totalBudget = 0;
      double totalSpent = 0;
      int memberCount = snapshot.docs.length;
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalBudget += (data['budget'] ?? 0.0);
        totalSpent += (data['spent'] ?? 0.0);
      }
      
      return {
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'totalRemaining': totalBudget - totalSpent,
        'memberCount': memberCount,
        'averageBudget': memberCount > 0 ? totalBudget / memberCount : 0.0,
        'averageSpent': memberCount > 0 ? totalSpent / memberCount : 0.0,
        'percentageUsed': totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0,
      };
    } catch (e, stackTrace) {
      _logger.severe('Error getting family spending summary: $e', e, stackTrace);
      rethrow;
    }
  }

  // Get member spending history
  Stream<List<Map<String, dynamic>>> getMemberSpendingHistory(String memberId) {
    try {
      return _familyMembersCollection
          .doc(memberId)
          .collection('spending_history')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e, stackTrace) {
      _logger.severe('Error getting member spending history: $e', e, stackTrace);
      return Stream.error(e);
    }
  }

  // Reset all member spending (new month/period)
  Future<void> resetAllMemberSpending() async {
    try {
      _logger.info('Resetting all member spending');
      
      final batch = _firestore.batch();
      final snapshot = await _familyMembersCollection.get();
      
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'spent': 0.0,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      _logger.info('All member spending reset successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error resetting member spending: $e', e, stackTrace);
      rethrow;
    }
  }

  // Get family budget alerts
  Future<List<Map<String, dynamic>>> getFamilyBudgetAlerts() async {
    try {
      final snapshot = await _familyMembersCollection.get();
      final alerts = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final member = FamilyMember.fromMap({...data, 'id': doc.id});
        
        final percentUsed = member.percentUsed;
        
        if (percentUsed >= 100) {
          alerts.add({
            'type': 'over_budget',
            'memberId': member.id,
            'memberName': member.name,
            'message': '${member.name} has exceeded their budget by \$${(member.spent - member.budget).toStringAsFixed(2)}',
            'severity': 'high',
            'percentUsed': percentUsed,
          });
        } else if (percentUsed >= 80) {
          alerts.add({
            'type': 'budget_warning',
            'memberId': member.id,
            'memberName': member.name,
            'message': '${member.name} has used ${percentUsed.toStringAsFixed(1)}% of their budget',
            'severity': 'medium',
            'percentUsed': percentUsed,
          });
        }
      }
      
      return alerts;
    } catch (e, stackTrace) {
      _logger.severe('Error getting family budget alerts: $e', e, stackTrace);
      rethrow;
    }
  }
}
