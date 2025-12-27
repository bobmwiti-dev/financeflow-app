import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../models/emergency_fund_model.dart';

class EmergencyFundService {
  static final EmergencyFundService _instance = EmergencyFundService._internal();
  static EmergencyFundService get instance => _instance;
  factory EmergencyFundService() => _instance;
  
  EmergencyFundService._internal();

  final Logger _logger = Logger('EmergencyFundService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? get _userId => _auth.currentUser?.uid;
  
  CollectionReference get _emergencyFundsCollection => 
      _firestore.collection('emergency_funds');

  /// Get emergency fund stream for real-time updates
  Stream<EmergencyFund?> getEmergencyFundStream() {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return Stream.value(null);
    }
    
    return _emergencyFundsCollection
        .where('userId', isEqualTo: _userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          try {
            if (snapshot.docs.isEmpty) {
              _logger.info('No emergency fund found for user');
              return null;
            }
            
            final doc = snapshot.docs.first;
            return EmergencyFund.fromFirestore(doc);
          } catch (e) {
            _logger.severe('Error processing emergency fund snapshot: $e');
            return null;
          }
        })
        .handleError((error) {
          _logger.severe('Stream error in getEmergencyFundStream: $error');
          return null;
        });
  }

  /// Get emergency fund (one-time fetch)
  Future<EmergencyFund?> getEmergencyFund() async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return null;
    }
    
    try {
      final snapshot = await _emergencyFundsCollection
          .where('userId', isEqualTo: _userId)
          .limit(1)
          .get();
          
      if (snapshot.docs.isEmpty) {
        _logger.info('No emergency fund found for user');
        return null;
      }
      
      return EmergencyFund.fromFirestore(snapshot.docs.first);
    } catch (e) {
      _logger.severe('Error getting emergency fund: $e');
      return null;
    }
  }

  /// Create or update emergency fund
  Future<String?> saveEmergencyFund(EmergencyFund emergencyFund) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return null;
    }
    
    try {
      // Check if emergency fund already exists
      final existingFund = await getEmergencyFund();
      
      if (existingFund != null) {
        // Update existing fund
        await _emergencyFundsCollection
            .doc(existingFund.id)
            .update(emergencyFund.copyWith(
              id: existingFund.id,
              userId: _userId!,
              createdAt: existingFund.createdAt,
              lastUpdated: DateTime.now(),
            ).toFirestore());
        
        _logger.info('Updated emergency fund with ID: ${existingFund.id}');
        return existingFund.id;
      } else {
        // Create new fund
        final docRef = await _emergencyFundsCollection.add(
          emergencyFund.copyWith(
            userId: _userId!,
            lastUpdated: DateTime.now(),
            createdAt: DateTime.now(),
          ).toFirestore()
        );
        
        _logger.info('Created emergency fund with ID: ${docRef.id}');
        return docRef.id;
      }
    } catch (e) {
      _logger.severe('Error saving emergency fund: $e');
      return null;
    }
  }

  /// Update emergency fund amount
  Future<bool> updateAmount(double newAmount) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return false;
    }
    
    try {
      final existingFund = await getEmergencyFund();
      
      if (existingFund != null) {
        await _emergencyFundsCollection
            .doc(existingFund.id)
            .update({
              'currentAmount': newAmount,
              'lastUpdated': Timestamp.fromDate(DateTime.now()),
            });
        
        _logger.info('Updated emergency fund amount to: $newAmount');
        return true;
      } else {
        _logger.warning('No existing emergency fund found to update');
        return false;
      }
    } catch (e) {
      _logger.severe('Error updating emergency fund amount: $e');
      return false;
    }
  }

  /// Update target amount and months
  Future<bool> updateTarget(double targetAmount, int targetMonths) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return false;
    }
    
    try {
      final existingFund = await getEmergencyFund();
      
      if (existingFund != null) {
        await _emergencyFundsCollection
            .doc(existingFund.id)
            .update({
              'targetAmount': targetAmount,
              'targetMonths': targetMonths,
              'lastUpdated': Timestamp.fromDate(DateTime.now()),
            });
        
        _logger.info('Updated emergency fund target to: $targetAmount ($targetMonths months)');
        return true;
      } else {
        _logger.warning('No existing emergency fund found to update');
        return false;
      }
    } catch (e) {
      _logger.severe('Error updating emergency fund target: $e');
      return false;
    }
  }

  /// Add money to emergency fund
  Future<bool> addAmount(double amount) async {
    if (_userId == null || amount <= 0) {
      _logger.warning('Invalid user or amount');
      return false;
    }
    
    try {
      final existingFund = await getEmergencyFund();
      
      if (existingFund != null) {
        final newAmount = existingFund.currentAmount + amount;
        return await updateAmount(newAmount);
      } else {
        _logger.warning('No existing emergency fund found to add to');
        return false;
      }
    } catch (e) {
      _logger.severe('Error adding to emergency fund: $e');
      return false;
    }
  }

  /// Withdraw money from emergency fund
  Future<bool> withdrawAmount(double amount) async {
    if (_userId == null || amount <= 0) {
      _logger.warning('Invalid user or amount');
      return false;
    }
    
    try {
      final existingFund = await getEmergencyFund();
      
      if (existingFund != null) {
        final newAmount = (existingFund.currentAmount - amount).clamp(0.0, double.infinity);
        return await updateAmount(newAmount);
      } else {
        _logger.warning('No existing emergency fund found to withdraw from');
        return false;
      }
    } catch (e) {
      _logger.severe('Error withdrawing from emergency fund: $e');
      return false;
    }
  }

  /// Delete emergency fund
  Future<bool> deleteEmergencyFund() async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return false;
    }
    
    try {
      final existingFund = await getEmergencyFund();
      
      if (existingFund != null) {
        await _emergencyFundsCollection.doc(existingFund.id).delete();
        _logger.info('Deleted emergency fund with ID: ${existingFund.id}');
        return true;
      } else {
        _logger.warning('No emergency fund found to delete');
        return false;
      }
    } catch (e) {
      _logger.severe('Error deleting emergency fund: $e');
      return false;
    }
  }
}
