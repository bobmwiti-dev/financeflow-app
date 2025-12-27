import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

/// Complete CRUD service for managing user income sources.
///
/// Income sources are stored in an `income_sources` collection with fields:
///   - userId (String)
///   - name (String) - income source name
///   - amount (double) - monthly income amount
///   - frequency (String) - 'monthly', 'weekly', 'bi-weekly', 'yearly'
///   - category (String) - 'salary', 'freelance', 'business', 'investment', etc.
///   - isActive (bool) - whether this income source is currently active
///   - startDate (Timestamp) - when this income source started
///   - endDate (Timestamp?) - when this income source ended (null if ongoing)
///   - createdAt (Timestamp)
///   - updatedAt (Timestamp)
class IncomeService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Logger _logger = Logger('IncomeService');
  
  IncomeService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _incomeCollection => 
      _firestore.collection('income_sources');

  /// Add a new income source
  Future<String?> addIncomeSource({
    required String name,
    required double amount,
    required String frequency,
    required String category,
    DateTime? startDate,
    bool isActive = true,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when adding income source');
        return null;
      }
      
      final incomeData = {
        'userId': user.uid,
        'name': name,
        'amount': amount,
        'frequency': frequency,
        'category': category,
        'isActive': isActive,
        'startDate': Timestamp.fromDate(startDate ?? DateTime.now()),
        'endDate': null,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      final docRef = await _incomeCollection.add(incomeData);
      
      _logger.info('Successfully added income source: $name with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.severe('Error adding income source: $e');
      return null;
    }
  }
  
  /// Update an existing income source
  Future<bool> updateIncomeSource({
    required String incomeId,
    required String name,
    required double amount,
    required String frequency,
    required String category,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when updating income source');
        return false;
      }
      
      // Verify the income source belongs to the current user
      final incomeDoc = await _incomeCollection.doc(incomeId).get();
      if (!incomeDoc.exists || incomeDoc.data()?['userId'] != user.uid) {
        _logger.warning('Income source $incomeId not found or does not belong to user ${user.uid}');
        return false;
      }
      
      final updateData = {
        'name': name,
        'amount': amount,
        'frequency': frequency,
        'category': category,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      if (startDate != null) {
        updateData['startDate'] = Timestamp.fromDate(startDate);
      }
      
      if (endDate != null) {
        updateData['endDate'] = Timestamp.fromDate(endDate);
      }
      
      if (isActive != null) {
        updateData['isActive'] = isActive;
      }
      
      await _incomeCollection.doc(incomeId).update(updateData);
      
      _logger.info('Successfully updated income source $incomeId');
      return true;
    } catch (e) {
      _logger.severe('Error updating income source $incomeId: $e');
      return false;
    }
  }
  
  /// Delete an income source
  Future<bool> deleteIncomeSource(String incomeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when deleting income source');
        return false;
      }
      
      // Verify the income source belongs to the current user
      final incomeDoc = await _incomeCollection.doc(incomeId).get();
      if (!incomeDoc.exists || incomeDoc.data()?['userId'] != user.uid) {
        _logger.warning('Income source $incomeId not found or does not belong to user ${user.uid}');
        return false;
      }
      
      await _incomeCollection.doc(incomeId).delete();
      
      _logger.info('Successfully deleted income source $incomeId');
      return true;
    } catch (e) {
      _logger.severe('Error deleting income source $incomeId: $e');
      return false;
    }
  }
  
  /// Get a specific income source by ID
  Future<Map<String, dynamic>?> getIncomeSourceById(String incomeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when getting income source');
        return null;
      }
      
      final incomeDoc = await _incomeCollection.doc(incomeId).get();
      if (!incomeDoc.exists || incomeDoc.data()?['userId'] != user.uid) {
        _logger.warning('Income source $incomeId not found or does not belong to user ${user.uid}');
        return null;
      }
      
      final data = incomeDoc.data()!;
      data['id'] = incomeDoc.id;
      return data;
    } catch (e) {
      _logger.severe('Error getting income source $incomeId: $e');
      return null;
    }
  }
  
  /// Get all income sources for the authenticated user
  Stream<List<Map<String, dynamic>>> getIncomeSourcesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      _logger.warning('No authenticated user found when getting income sources stream');
      return Stream.value(<Map<String, dynamic>>[]);
    }
    
    return _incomeCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    }).handleError((error) {
      _logger.severe('Error in income sources stream: $error');
      return <Map<String, dynamic>>[];
    });
  }
  
  /// Get active income sources only
  Stream<List<Map<String, dynamic>>> getActiveIncomeSourcesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      _logger.warning('No authenticated user found when getting active income sources');
      return Stream.value(<Map<String, dynamic>>[]);
    }
    
    return _incomeCollection
        .where('userId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .orderBy('amount', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    }).handleError((error) {
      _logger.severe('Error in active income sources stream: $error');
      return <Map<String, dynamic>>[];
    });
  }
  
  /// Calculate total monthly income from all active sources
  Future<double> getTotalMonthlyIncome() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when calculating total income');
        return 0.0;
      }
      
      final snapshot = await _incomeCollection
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();
      
      double totalIncome = 0.0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final frequency = data['frequency'] as String? ?? 'monthly';
        
        // Convert to monthly amount based on frequency
        switch (frequency.toLowerCase()) {
          case 'weekly':
            totalIncome += amount * 4.33; // Average weeks per month
            break;
          case 'bi-weekly':
            totalIncome += amount * 2.17; // Average bi-weeks per month
            break;
          case 'yearly':
            totalIncome += amount / 12;
            break;
          case 'monthly':
          default:
            totalIncome += amount;
            break;
        }
      }
      
      _logger.info('Calculated total monthly income: $totalIncome');
      return totalIncome;
    } catch (e) {
      _logger.severe('Error calculating total monthly income: $e');
      return 0.0;
    }
  }
  
  /// Deactivate an income source (soft delete)
  Future<bool> deactivateIncomeSource(String incomeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when deactivating income source');
        return false;
      }
      
      // Verify the income source belongs to the current user
      final incomeDoc = await _incomeCollection.doc(incomeId).get();
      if (!incomeDoc.exists || incomeDoc.data()?['userId'] != user.uid) {
        _logger.warning('Income source $incomeId not found or does not belong to user ${user.uid}');
        return false;
      }
      
      await _incomeCollection.doc(incomeId).update({
        'isActive': false,
        'endDate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      _logger.info('Successfully deactivated income source $incomeId');
      return true;
    } catch (e) {
      _logger.severe('Error deactivating income source $incomeId: $e');
      return false;
    }
  }
  
  /// Reactivate an income source
  Future<bool> reactivateIncomeSource(String incomeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when reactivating income source');
        return false;
      }
      
      // Verify the income source belongs to the current user
      final incomeDoc = await _incomeCollection.doc(incomeId).get();
      if (!incomeDoc.exists || incomeDoc.data()?['userId'] != user.uid) {
        _logger.warning('Income source $incomeId not found or does not belong to user ${user.uid}');
        return false;
      }
      
      await _incomeCollection.doc(incomeId).update({
        'isActive': true,
        'endDate': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      _logger.info('Successfully reactivated income source $incomeId');
      return true;
    } catch (e) {
      _logger.severe('Error reactivating income source $incomeId: $e');
      return false;
    }
  }
  
  /// Get income sources by category
  Future<List<Map<String, dynamic>>> getIncomeSourcesByCategory(String category) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when getting income sources by category');
        return [];
      }
      
      final snapshot = await _incomeCollection
          .where('userId', isEqualTo: user.uid)
          .where('category', isEqualTo: category)
          .orderBy('amount', descending: true)
          .get();
      
      final result = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      _logger.info('Retrieved ${result.length} income sources for category: $category');
      return result;
    } catch (e) {
      _logger.severe('Error getting income sources by category $category: $e');
      return [];
    }
  }
}
