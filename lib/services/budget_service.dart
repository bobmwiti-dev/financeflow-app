import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

/// Complete CRUD service for managing user budgets.
///
/// Budgets are stored in a `budgets` collection with fields:
///   - userId  (String)
///   - month   (int 1-12)
///   - year    (int full year)
///   - amount  (double)
///   - categories (Map&lt;String, double&gt;) - category-wise budget breakdown
///   - createdAt (Timestamp)
///   - updatedAt (Timestamp)
class BudgetService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Logger _logger = Logger('BudgetService');
  
  BudgetService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _budgetsCollection => _firestore.collection('budgets');

  /// Returns the budget amount for the given [month] (first day of month supplies year & month).
  Future<double> getMonthlyBudget(DateTime month) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _logger.warning('No authenticated user found when getting monthly budget');
      return 0.0;
    }

    try {
      final snapshot = await _budgetsCollection
          .where('userId', isEqualTo: uid)
          .where('month', isEqualTo: month.month)
          .where('year', isEqualTo: month.year)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        _logger.info('No budget found for ${month.year}-${month.month}');
        return 0.0;
      }
      final data = snapshot.docs.first.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      _logger.info('Retrieved budget amount $amount for ${month.year}-${month.month}');
      return amount;
    } catch (e) {
      _logger.severe('Error getting monthly budget for ${month.year}-${month.month}: $e');
      return 0.0;
    }
  }
  
  /// Create or update a budget for a specific month
  Future<String?> setBudget({
    required DateTime month,
    required double amount,
    Map<String, double>? categories,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when setting budget');
        return null;
      }
      
      // Check if budget already exists for this month
      final existingSnapshot = await _budgetsCollection
          .where('userId', isEqualTo: user.uid)
          .where('month', isEqualTo: month.month)
          .where('year', isEqualTo: month.year)
          .limit(1)
          .get();
      
      final budgetData = {
        'userId': user.uid,
        'month': month.month,
        'year': month.year,
        'amount': amount,
        'categories': categories ?? {},
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      if (existingSnapshot.docs.isNotEmpty) {
        // Update existing budget
        final docId = existingSnapshot.docs.first.id;
        await _budgetsCollection.doc(docId).update(budgetData);
        _logger.info('Successfully updated budget for ${month.year}-${month.month}');
        return docId;
      } else {
        // Create new budget
        budgetData['createdAt'] = Timestamp.fromDate(DateTime.now());
        final docRef = await _budgetsCollection.add(budgetData);
        _logger.info('Successfully created budget for ${month.year}-${month.month}');
        return docRef.id;
      }
    } catch (e) {
      _logger.severe('Error setting budget for ${month.year}-${month.month}: $e');
      return null;
    }
  }
  
  /// Delete a budget for a specific month
  Future<bool> deleteBudget(DateTime month) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when deleting budget');
        return false;
      }
      
      final snapshot = await _budgetsCollection
          .where('userId', isEqualTo: user.uid)
          .where('month', isEqualTo: month.month)
          .where('year', isEqualTo: month.year)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        _logger.warning('No budget found to delete for ${month.year}-${month.month}');
        return false;
      }
      
      await _budgetsCollection.doc(snapshot.docs.first.id).delete();
      _logger.info('Successfully deleted budget for ${month.year}-${month.month}');
      return true;
    } catch (e) {
      _logger.severe('Error deleting budget for ${month.year}-${month.month}: $e');
      return false;
    }
  }
  
  /// Get all budgets for the authenticated user
  Stream<List<Map<String, dynamic>>> getBudgetsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      _logger.warning('No authenticated user found when getting budgets stream');
      return Stream.value(<Map<String, dynamic>>[]);
    }
    
    return _budgetsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    }).handleError((error) {
      _logger.severe('Error in budgets stream: $error');
      return <Map<String, dynamic>>[];
    });
  }
  
  /// Get budget details by ID
  Future<Map<String, dynamic>?> getBudgetById(String budgetId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when getting budget by ID');
        return null;
      }
      
      final budgetDoc = await _budgetsCollection.doc(budgetId).get();
      if (!budgetDoc.exists || budgetDoc.data()?['userId'] != user.uid) {
        _logger.warning('Budget $budgetId not found or does not belong to user ${user.uid}');
        return null;
      }
      
      final data = budgetDoc.data()!;
      data['id'] = budgetDoc.id;
      return data;
    } catch (e) {
      _logger.severe('Error getting budget $budgetId: $e');
      return null;
    }
  }
  
  /// Get category-wise budget breakdown for a specific month
  Future<Map<String, double>> getCategoryBudgets(DateTime month) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when getting category budgets');
        return {};
      }
      
      final snapshot = await _budgetsCollection
          .where('userId', isEqualTo: user.uid)
          .where('month', isEqualTo: month.month)
          .where('year', isEqualTo: month.year)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        _logger.info('No category budgets found for ${month.year}-${month.month}');
        return {};
      }
      
      final data = snapshot.docs.first.data();
      final categories = data['categories'] as Map<String, dynamic>? ?? {};
      
      // Convert to Map<String, double>
      final result = <String, double>{};
      categories.forEach((key, value) {
        result[key] = (value as num?)?.toDouble() ?? 0.0;
      });
      
      _logger.info('Retrieved ${result.length} category budgets for ${month.year}-${month.month}');
      return result;
    } catch (e) {
      _logger.severe('Error getting category budgets for ${month.year}-${month.month}: $e');
      return {};
    }
  }
}
