import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/allowance_request_model.dart';
import '../services/allowance_request_service.dart';

class AllowanceRequestViewModel extends ChangeNotifier {
  final AllowanceRequestService _service = AllowanceRequestService();
  final _logger = Logger('AllowanceRequestViewModel');

  final String primaryUserId;
  String memberId;

  AllowanceRequestViewModel({required this.primaryUserId, required this.memberId});

  List<AllowanceRequest> _requests = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;
  StreamSubscription? _sub;

  // Getters
  List<AllowanceRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;
  
  // Filtered requests
  List<AllowanceRequest> get pendingRequests => _requests.where((r) => r.status == 'pending').toList();
  List<AllowanceRequest> get approvedRequests => _requests.where((r) => r.status == 'approved').toList();
  List<AllowanceRequest> get declinedRequests => _requests.where((r) => r.status == 'declined').toList();

  void startListening() {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _sub?.cancel();
      
      _sub = _service.getAllowanceRequestsStream(memberId).listen(
        (requests) {
          _requests = requests;
          _isLoading = false;
          _error = null;
          notifyListeners();
          
          // Update stats
          _updateStats();
          
          _logger.info('Allowance requests updated: ${requests.length} requests');
        },
        onError: (error) {
          _logger.severe('Error in allowance requests stream: $error');
          _error = 'Failed to load allowance requests: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _logger.severe('Error starting allowance requests listener: $e');
      _error = 'Failed to start listening: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void loadRequests(String memberId) {
    this.memberId = memberId;
    startListening();
  }

  Future<bool> requestAllowance({required double amount, required String reason, required String memberName}) async {
    try {
      _logger.info('Starting allowance request creation: amount=\$$amount, reason="$reason", member="$memberName"');
      
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final request = AllowanceRequest(
        memberId: memberId,
        memberName: memberName,
        amount: amount,
        reason: reason,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      
      _logger.info('Created AllowanceRequest object: ${request.toMap()}');
      
      final requestId = await _service.createAllowanceRequest(request);
      _logger.info('Allowance request created successfully with ID: $requestId');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Error creating allowance request: $e', e, stackTrace);
      _error = 'Failed to create request: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveRequest(String requestId) async {
    return await _updateStatus(requestId, 'approved');
  }

  Future<bool> declineRequest(String requestId) async {
    return await _updateStatus(requestId, 'declined');
  }

  Future<bool> deleteRequest(String requestId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _service.deleteAllowanceRequest(requestId);
      _logger.info('Allowance request deleted successfully');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _logger.severe('Error deleting allowance request: $e');
      _error = 'Failed to delete request: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _updateStatus(String requestId, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _service.updateRequestStatus(requestId, status);
      _logger.info('Allowance request status updated to: $status');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _logger.severe('Error updating allowance request status: $e');
      _error = 'Failed to update status: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _updateStats() async {
    try {
      _stats = await _service.getAllowanceRequestStats(memberId);
      notifyListeners();
    } catch (e) {
      _logger.warning('Failed to update allowance request stats: $e');
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    startListening();
  }

  // Load requests for a different member
  void switchMember(String newMemberId) {
    if (newMemberId != memberId) {
      memberId = newMemberId;
      startListening();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
