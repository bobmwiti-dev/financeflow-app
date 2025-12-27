import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/family_member_model.dart';
import '../services/family_service.dart';

class FamilyViewModel extends ChangeNotifier {
  final FamilyService _familyService = FamilyService();
  final Logger logger = Logger('FamilyViewModel');
  
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _spendingSummary;
  List<Map<String, dynamic>> _budgetAlerts = [];

  // Getters
  List<FamilyMember> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  String? get error => _error;
  String? get primaryUserId => _familyService.currentUserId;
  bool get hasFamilyMembers => _familyMembers.isNotEmpty;
  Map<String, dynamic>? get spendingSummary => _spendingSummary;
  List<Map<String, dynamic>> get budgetAlerts => _budgetAlerts;

  // Computed properties
  double get totalFamilyBudget => _familyMembers.fold(0.0, (sum, member) => sum + member.budget);
  double get totalFamilySpent => _familyMembers.fold(0.0, (sum, member) => sum + member.spent);
  double get totalFamilyRemaining => totalFamilyBudget - totalFamilySpent;
  double get familyBudgetPercentage => totalFamilyBudget > 0 ? (totalFamilySpent / totalFamilyBudget) * 100 : 0.0;
  
  // Get members by role
  List<FamilyMember> get parents => _familyMembers.where((m) => m.role == FamilyRole.parent).toList();
  List<FamilyMember> get children => _familyMembers.where((m) => m.role == FamilyRole.child).toList();
  List<FamilyMember> get teens => _familyMembers.where((m) => m.role == FamilyRole.teen).toList();
  List<FamilyMember> get guardians => _familyMembers.where((m) => m.role == FamilyRole.guardian).toList();
  
  // Get members with budget issues
  List<FamilyMember> get overBudgetMembers => _familyMembers.where((m) => m.isOverBudget).toList();
  List<FamilyMember> get warningMembers => _familyMembers.where((m) => m.budgetStatus == BudgetStatus.warning || m.budgetStatus == BudgetStatus.danger).toList();

  StreamSubscription? _sub;
  
  void _logError(String method, dynamic error, [StackTrace? stackTrace]) {
    logger.severe('Error in $method: $error');
    if (stackTrace != null) {
      logger.severe(stackTrace.toString());
    }
    _error = 'Error in $method: ${error.toString()}';
  }

  void startListening() {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _sub?.cancel();
      
      _sub = _familyService.getFamilyMembersStream().listen(
        (members) {
          _familyMembers = members;
          _isLoading = false;
          _error = null;
          notifyListeners();
          
          // Update spending summary and alerts
          _updateSpendingSummary();
          _updateBudgetAlerts();
          
          logger.info('Family members updated: ${members.length} members');
        },
        onError: (error, stackTrace) {
          _logError('familyMembersStream', error, stackTrace);
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _logError('startListening', e);
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<bool> addFamilyMember(FamilyMember member) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final memberId = await _familyService.addFamilyMember(member);
      logger.info('Family member added successfully with ID: $memberId');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _logError('addFamilyMember', e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFamilyMember(FamilyMember member) async {
    try {
      if (member.id == null) {
        throw Exception('Member ID is required');
      }
      
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _familyService.updateFamilyMember(member);
      logger.info('Family member updated successfully');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _logError('updateFamilyMember', e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFamilyMemberSpending(String memberId, double amount) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _familyService.updateMemberSpending(memberId, amount);
      logger.info('Member spending updated successfully');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _logError('updateFamilyMemberSpending', e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSpendingToMember(String memberId, double amount, String description) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _familyService.addSpendingToMember(memberId, amount, description);
      logger.info('Spending added to member successfully');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _logError('addSpendingToMember', e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFamilyMember(String memberId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _familyService.deleteFamilyMember(memberId);
      logger.info('Family member deleted successfully');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _logError('deleteFamilyMember', e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> resetAllMemberSpending() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _familyService.resetAllMemberSpending();
      logger.info('All member spending reset successfully');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logError('resetAllMemberSpending', e);
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateSpendingSummary() async {
    try {
      _spendingSummary = await _familyService.getFamilySpendingSummary();
      notifyListeners();
    } catch (e) {
      logger.warning('Failed to update spending summary: $e');
    }
  }

  void _updateBudgetAlerts() async {
    try {
      _budgetAlerts = await _familyService.getFamilyBudgetAlerts();
      notifyListeners();
    } catch (e) {
      logger.warning('Failed to update budget alerts: $e');
    }
  }

  // Get member spending history
  Stream<List<Map<String, dynamic>>> getMemberSpendingHistory(String memberId) {
    return _familyService.getMemberSpendingHistory(memberId);
  }

  // Refresh data
  Future<void> refreshData() async {
    startListening();
  }

  double getTotalFamilyBudget() {
    return _familyMembers.fold(0, (sum, member) => sum + member.budget);
  }

  double getTotalFamilySpent() {
    return _familyMembers.fold(0, (sum, member) => sum + member.spent);
  }

  double getRemainingFamilyBudget() {
    return getTotalFamilyBudget() - getTotalFamilySpent();
  }
}
