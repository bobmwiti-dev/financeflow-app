import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../models/goal_model.dart';
import '../models/contribution_model.dart';

/// A service to manage financial goals and track progress
class GoalService {
  static final GoalService instance = GoalService._internal();
  
  GoalService._internal();
  
  final _logger = Logger('GoalService');
  final _goalsCollection = FirebaseFirestore.instance.collection('goals');
  
  /// Get a stream of all goals for the current user
  Stream<List<Goal>> getGoalsStream() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found');
        return Stream.value(<Goal>[]);
      }
      
      return _goalsCollection
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              _logger.info('No goals found in collection');
              return <Goal>[];
            }
            
            final goals = snapshot.docs.map((doc) {
              try {
                final data = doc.data();
                data['id'] = doc.id;
                return Goal.fromMap(data);
              } catch (e) {
                _logger.severe('Error parsing goal document ${doc.id}: $e');
                return null;
              }
            })
            .where((goal) => goal != null)
            .cast<Goal>()
            .toList();
            
            // Sort by priority (highest first)
            goals.sort((a, b) => b.priority.compareTo(a.priority));
            
            return goals;
          });
    } catch (e) {
      _logger.severe('Error processing goals snapshot: $e');
      return Stream.value(<Goal>[]);
    }
  }
  
  /// Add a new financial goal
  Future<String?> addGoal({
    required String title,
    required double targetAmount,
    required DateTime targetDate,
    required String category,
    double currentAmount = 0.0,
    int priority = 1,
    String? description,
    String? icon,
    double? targetMonthlyContribution,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found for adding goal');
        return null;
      }
      
      final goalData = {
        'userId': user.uid,
        'name': title, // Use 'name' to match Goal model
        'title': title, // Keep 'title' for backward compatibility
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate,
        'category': category,
        'priority': priority,
        'createdAt': DateTime.now(),
      };
      
      // Add optional fields if provided
      if (description != null && description.isNotEmpty) {
        goalData['description'] = description;
      }
      if (icon != null && icon.isNotEmpty) {
        goalData['icon'] = icon;
      }
      if (targetMonthlyContribution != null) {
        goalData['targetMonthlyContribution'] = targetMonthlyContribution;
      }
      
      final docRef = await _goalsCollection.add(goalData);
      
      _logger.info('Added new goal with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.severe('Error adding goal: $e');
      return null;
    }
  }
  
  /// Update goal progress amount
  Future<bool> updateGoalProgress(String goalId, double newAmount) async {
    try {
      await _goalsCollection.doc(goalId).update({
        'currentAmount': newAmount,
        'lastUpdated': DateTime.now(),
      });
      
      _logger.info('Updated goal $goalId progress to $newAmount');
      return true;
    } catch (e) {
      _logger.severe('Error updating goal $goalId: $e');
      return false;
    }
  }
  
  /// Update complete goal information
  Future<bool> updateGoal({
    required String goalId,
    required String title,
    required double targetAmount,
    required DateTime targetDate,
    required String category,
    required double currentAmount,
    required int priority,
    String? description,
    String? icon,
    double? targetMonthlyContribution,
  }) async {
    try {
      final updateData = {
        'name': title,
        'title': title, // Keep for backward compatibility
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate,
        'category': category,
        'priority': priority,
        'lastUpdated': DateTime.now(),
      };
      
      // Add optional fields if provided
      if (description != null) {
        updateData['description'] = description;
      }
      if (icon != null) {
        updateData['icon'] = icon;
      }
      if (targetMonthlyContribution != null) {
        updateData['targetMonthlyContribution'] = targetMonthlyContribution;
      }
      
      await _goalsCollection.doc(goalId).update(updateData);
      
      _logger.info('Updated goal $goalId completely');
      return true;
    } catch (e) {
      _logger.severe('Error updating goal $goalId: $e');
      return false;
    }
  }
  
    /// Add a contribution to a goal
  Future<Contribution?> addContribution(String goalId, double amount) async {
    try {
      final docRef = await _goalsCollection
          .doc(goalId)
          .collection('contributions')
          .add({
        'amount': amount,
        'date': DateTime.now(),
      });
      _logger.info('Added contribution ${docRef.id} to goal $goalId');
      return Contribution(
        id: docRef.id,
        goalId: goalId,
        amount: amount,
        date: DateTime.now(),
      );
    } catch (e) {
      _logger.severe('Error adding contribution to goal $goalId: $e');
      return null;
    }
  }

  /// Stream contributions for a goal
  Stream<List<Contribution>> getContributionsStream(String goalId) {
    return _goalsCollection
        .doc(goalId)
        .collection('contributions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Contribution.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Delete a goal
  Future<bool> deleteGoal(String goalId) async {
    try {
      await _goalsCollection.doc(goalId).delete();
      _logger.info('Deleted goal $goalId');
      return true;
    } catch (e) {
      _logger.severe('Error deleting goal $goalId: $e');
      return false;
    }
  }
  
  /// Get sample goals for new users
  List<Goal> getSampleGoals() {
    final now = DateTime.now();
    
    return [
      Goal(
        id: '1',
        name: 'Emergency Fund',
        targetAmount: 100000.0,
        currentAmount: 25000.0,
        targetDate: DateTime(now.year + 1, now.month, now.day),
        category: 'Savings',
        priority: 3,
        description: 'Build an emergency fund for unexpected expenses',
      ),
      Goal(
        id: '2',
        name: 'New Laptop',
        targetAmount: 65000.0,
        currentAmount: 15000.0,
        targetDate: DateTime(now.year, now.month + 4, now.day),
        category: 'Electronics',
        priority: 2,
        description: 'Save for a new laptop for work',
      ),
      Goal(
        id: '3',
        name: 'Holiday Trip',
        targetAmount: 150000.0,
        currentAmount: 30000.0,
        targetDate: DateTime(now.year, 12, 1),
        category: 'Travel',
        priority: 1,
        description: 'Save for end of year holiday trip',
      ),
    ];
  }
}
