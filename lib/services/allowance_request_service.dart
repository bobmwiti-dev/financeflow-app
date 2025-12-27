import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../models/allowance_request_model.dart';

class AllowanceRequestService {
  static final AllowanceRequestService _instance = AllowanceRequestService._internal();
  factory AllowanceRequestService() => _instance;
  AllowanceRequestService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('AllowanceRequestService');

  String? get currentUserId => _auth.currentUser?.uid;

  // Allowance Requests Collection Reference
  CollectionReference get _allowanceRequestsCollection {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('allowance_requests');
  }

  // Stream of allowance requests for a specific member
  Stream<List<AllowanceRequest>> getAllowanceRequestsStream(String memberId) {
    try {
      _logger.info('Starting allowance requests stream for member: $memberId');
      return _allowanceRequestsCollection
          .where('memberId', isEqualTo: memberId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        _logger.info('Received ${snapshot.docs.length} allowance requests from Firestore');
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return AllowanceRequest.fromMap(data, id: doc.id);
        }).toList();
      });
    } catch (e, stackTrace) {
      _logger.severe('Error getting allowance requests stream: $e', e, stackTrace);
      return Stream.error(e);
    }
  }

  // Stream of all allowance requests (for parents/guardians)
  Stream<List<AllowanceRequest>> getAllAllowanceRequestsStream() {
    try {
      _logger.info('Starting all allowance requests stream for user: $currentUserId');
      return _allowanceRequestsCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        _logger.info('Received ${snapshot.docs.length} total allowance requests from Firestore');
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return AllowanceRequest.fromMap(data, id: doc.id);
        }).toList();
      });
    } catch (e, stackTrace) {
      _logger.severe('Error getting all allowance requests stream: $e', e, stackTrace);
      return Stream.error(e);
    }
  }

  // Create allowance request
  Future<String> createAllowanceRequest(AllowanceRequest request) async {
    try {
      _logger.info('Creating allowance request for member: ${request.memberId}, amount: \$${request.amount}');
      
      // Check authentication
      if (currentUserId == null) {
        _logger.severe('User not authenticated - currentUserId is null');
        throw Exception('User not authenticated');
      }
      
      _logger.info('Current user ID: $currentUserId');
      
      final requestData = request.toMap();
      requestData['createdAt'] = FieldValue.serverTimestamp();
      requestData['userId'] = currentUserId;
      
      _logger.info('Request data to be saved: $requestData');
      
      final docRef = await _allowanceRequestsCollection.add(requestData);
      
      _logger.info('Allowance request created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      _logger.severe('Error creating allowance request: $e', e, stackTrace);
      rethrow;
    }
  }

  // Update allowance request status
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      _logger.info('Updating allowance request $requestId status to: $status');
      
      await _allowanceRequestsCollection.doc(requestId).update({
        'status': status,
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Allowance request status updated successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error updating allowance request status: $e', e, stackTrace);
      rethrow;
    }
  }

  // Delete allowance request
  Future<void> deleteAllowanceRequest(String requestId) async {
    try {
      _logger.info('Deleting allowance request: $requestId');
      
      await _allowanceRequestsCollection.doc(requestId).delete();
      
      _logger.info('Allowance request deleted successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error deleting allowance request: $e', e, stackTrace);
      rethrow;
    }
  }

  // Get allowance request statistics
  Future<Map<String, dynamic>> getAllowanceRequestStats(String memberId) async {
    try {
      final snapshot = await _allowanceRequestsCollection
          .where('memberId', isEqualTo: memberId)
          .get();
      
      int totalRequests = snapshot.docs.length;
      int approvedRequests = 0;
      int declinedRequests = 0;
      int pendingRequests = 0;
      double totalAmountRequested = 0;
      double totalAmountApproved = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';
        final amount = (data['amount'] ?? 0).toDouble();
        
        totalAmountRequested += amount;
        
        switch (status) {
          case 'approved':
            approvedRequests++;
            totalAmountApproved += amount;
            break;
          case 'declined':
            declinedRequests++;
            break;
          case 'pending':
          default:
            pendingRequests++;
            break;
        }
      }
      
      return {
        'totalRequests': totalRequests,
        'approvedRequests': approvedRequests,
        'declinedRequests': declinedRequests,
        'pendingRequests': pendingRequests,
        'totalAmountRequested': totalAmountRequested,
        'totalAmountApproved': totalAmountApproved,
        'approvalRate': totalRequests > 0 ? (approvedRequests / totalRequests) * 100 : 0.0,
      };
    } catch (e, stackTrace) {
      _logger.severe('Error getting allowance request stats: $e', e, stackTrace);
      rethrow;
    }
  }

  // Get pending requests count
  Future<int> getPendingRequestsCount() async {
    try {
      final snapshot = await _allowanceRequestsCollection
          .where('status', isEqualTo: 'pending')
          .get();
      
      return snapshot.docs.length;
    } catch (e, stackTrace) {
      _logger.severe('Error getting pending requests count: $e', e, stackTrace);
      return 0;
    }
  }
}
