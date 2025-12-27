import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

/// A service to manage bill reminders and upcoming payments
class BillService {
  static final BillService instance = BillService._internal();
  
  BillService._internal();
  
  final _logger = Logger('BillService');
  final _billsCollection = FirebaseFirestore.instance.collection('bills');
  final _auth = FirebaseAuth.instance;
  
  /// Get all upcoming bills that are due within the next 30 days
  Stream<List<Map<String, dynamic>>> getUpcomingBills() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found');
        return Stream.value(<Map<String, dynamic>>[]);
      }
      
      _logger.info('Querying bills for user: ${user.uid}');
      
      // For now, let's get all bills for the user to debug the issue
      // We can add date filtering back later
      return _billsCollection
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
            _logger.info('Bills query returned ${snapshot.docs.length} documents');
            
            if (snapshot.docs.isEmpty) {
              _logger.info('No bills found for user');
              return <Map<String, dynamic>>[];
            }
            
            final bills = snapshot.docs.map((doc) {
              try {
                final data = doc.data();
                data['id'] = doc.id;
                _logger.info('Bill data: $data');
                return data;
              } catch (e) {
                _logger.severe('Error parsing bill document ${doc.id}: $e');
                return <String, dynamic>{};
              }
            }).toList();
            
            _logger.info('Returning ${bills.length} bills to UI');
            return bills;
          });
    } catch (e) {
      _logger.severe('Error getting upcoming bills: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }
  
  /// Mark a bill as paid
  Future<bool> markBillAsPaid(String billId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when marking bill as paid');
        return false;
      }
      
      // Verify the bill belongs to the current user
      final billDoc = await _billsCollection.doc(billId).get();
      if (!billDoc.exists || billDoc.data()?['userId'] != user.uid) {
        _logger.warning('Bill $billId not found or does not belong to user ${user.uid}');
        return false;
      }
      
      await _billsCollection.doc(billId).update({
        'isPaid': true,
        'paidDate': Timestamp.fromDate(DateTime.now()),
      });
      
      _logger.info('Bill $billId marked as paid');
      return true;
    } catch (e) {
      _logger.severe('Error marking bill $billId as paid: $e');
      return false;
    }
  }
  
  /// Add a new bill reminder
  Future<String?> addBill({
    required String title,
    required double amount,
    required DateTime dueDate,
    required String category,
  }) async {
    try {
      _logger.info('Attempting to add bill: $title, amount: $amount, category: $category');
      
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when adding bill');
        return null;
      }
      
      _logger.info('User authenticated: ${user.uid}');
      
      final billData = {
        'name': title,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'category': category,
        'userId': user.uid,
        'isPaid': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };
      
      _logger.info('Adding bill data to Firestore: $billData');
      
      final docRef = await _billsCollection.add(billData);
      
      _logger.info('Successfully added new bill with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.severe('Error adding bill: $e');
      return null;
    }
  }
  
  /// Update an existing bill
  Future<bool> updateBill({
    required String billId,
    required String title,
    required double amount,
    required DateTime dueDate,
    required String category,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when updating bill');
        return false;
      }
      
      // Verify the bill belongs to the current user
      final billDoc = await _billsCollection.doc(billId).get();
      if (!billDoc.exists || billDoc.data()?['userId'] != user.uid) {
        _logger.warning('Bill $billId not found or does not belong to user ${user.uid}');
        return false;
      }
      
      final updateData = {
        'name': title,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'category': category,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      await _billsCollection.doc(billId).update(updateData);
      
      _logger.info('Successfully updated bill $billId');
      return true;
    } catch (e) {
      _logger.severe('Error updating bill $billId: $e');
      return false;
    }
  }
  
  /// Delete a bill
  Future<bool> deleteBill(String billId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when deleting bill');
        return false;
      }
      
      // Verify the bill belongs to the current user
      final billDoc = await _billsCollection.doc(billId).get();
      if (!billDoc.exists || billDoc.data()?['userId'] != user.uid) {
        _logger.warning('Bill $billId not found or does not belong to user ${user.uid}');
        return false;
      }
      
      await _billsCollection.doc(billId).delete();
      
      _logger.info('Successfully deleted bill $billId');
      return true;
    } catch (e) {
      _logger.severe('Error deleting bill $billId: $e');
      return false;
    }
  }
  
  /// Get a specific bill by ID
  Future<Map<String, dynamic>?> getBillById(String billId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found when getting bill');
        return null;
      }
      
      final billDoc = await _billsCollection.doc(billId).get();
      if (!billDoc.exists || billDoc.data()?['userId'] != user.uid) {
        _logger.warning('Bill $billId not found or does not belong to user ${user.uid}');
        return null;
      }
      
      final data = billDoc.data()!;
      data['id'] = billDoc.id;
      return data;
    } catch (e) {
      _logger.severe('Error getting bill $billId: $e');
      return null;
    }
  }
  
  /// Get sample bill reminders for new users
  List<Map<String, dynamic>> getSampleBills() {
    final now = DateTime.now();
    
    return [
      {
        'id': '1',
        'title': 'Rent',
        'amount': 12000.0,
        'dueDate': DateTime(now.year, now.month, 1),
        'category': 'Housing',
        'isPaid': false,
      },
      {
        'id': '2',
        'title': 'Electricity Bill',
        'amount': 2500.0,
        'dueDate': DateTime(now.year, now.month, 15),
        'category': 'Utilities',
        'isPaid': false,
      },
      {
        'id': '3',
        'title': 'Internet',
        'amount': 3000.0,
        'dueDate': DateTime(now.year, now.month, 20),
        'category': 'Utilities',
        'isPaid': false,
      },
      {
        'id': '4',
        'title': 'Car Insurance',
        'amount': 7500.0,
        'dueDate': DateTime(now.year, now.month, 10),
        'category': 'Insurance',
        'isPaid': false,
      },
    ];
  }
}
