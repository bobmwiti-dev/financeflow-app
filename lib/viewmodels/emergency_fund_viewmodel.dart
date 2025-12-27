import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/emergency_fund_model.dart';
import '../services/emergency_fund_service.dart';

class EmergencyFundViewModel extends ChangeNotifier {
  final EmergencyFundService _emergencyFundService;
  final Logger logger = Logger('EmergencyFundViewModel');

  EmergencyFund? _emergencyFund;
  bool _isLoading = false;
  StreamSubscription<EmergencyFund?>? _emergencyFundSubscription;

  EmergencyFundViewModel({
    required EmergencyFundService emergencyFundService,
  }) : _emergencyFundService = emergencyFundService {
    _subscribeToEmergencyFund();
  }

  EmergencyFund? get emergencyFund => _emergencyFund;
  bool get isLoading => _isLoading;

  /// Subscribe to real-time emergency fund updates
  void _subscribeToEmergencyFund() {
    _emergencyFundSubscription?.cancel();
    _emergencyFundSubscription = _emergencyFundService.getEmergencyFundStream().listen(
      (fund) {
        _emergencyFund = fund;
        notifyListeners();
      },
      onError: (error) {
        logger.severe('Error subscribing to emergency fund: $error');
      },
    );
  }

  /// Load emergency fund (one-time fetch)
  Future<void> loadEmergencyFund() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _emergencyFund = await _emergencyFundService.getEmergencyFund();
    } catch (e) {
      logger.severe('Error loading emergency fund: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create or update emergency fund
  Future<bool> saveEmergencyFund(EmergencyFund fund) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _emergencyFundService.saveEmergencyFund(fund);
      return result != null;
    } catch (e) {
      logger.severe('Error saving emergency fund: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update emergency fund amount
  Future<bool> updateAmount(double newAmount) async {
    try {
      return await _emergencyFundService.updateAmount(newAmount);
    } catch (e) {
      logger.severe('Error updating emergency fund amount: $e');
      return false;
    }
  }

  /// Update target amount and months
  Future<bool> updateTarget(double targetAmount, int targetMonths) async {
    try {
      return await _emergencyFundService.updateTarget(targetAmount, targetMonths);
    } catch (e) {
      logger.severe('Error updating emergency fund target: $e');
      return false;
    }
  }

  /// Add money to emergency fund
  Future<bool> addAmount(double amount) async {
    if (amount <= 0) return false;
    
    try {
      return await _emergencyFundService.addAmount(amount);
    } catch (e) {
      logger.severe('Error adding to emergency fund: $e');
      return false;
    }
  }

  /// Withdraw money from emergency fund
  Future<bool> withdrawAmount(double amount) async {
    if (amount <= 0) return false;
    
    try {
      return await _emergencyFundService.withdrawAmount(amount);
    } catch (e) {
      logger.severe('Error withdrawing from emergency fund: $e');
      return false;
    }
  }

  /// Create emergency fund with estimated target
  Future<bool> createEmergencyFund({
    required double monthlyExpenses,
    int targetMonths = 6,
    double initialAmount = 0.0,
  }) async {
    final targetAmount = monthlyExpenses * targetMonths;
    
    final newFund = EmergencyFund(
      userId: '', // Will be set by service
      currentAmount: initialAmount,
      targetAmount: targetAmount,
      targetMonths: targetMonths,
    );
    
    return await saveEmergencyFund(newFund);
  }

  /// Get progress percentage
  double get progressPercentage {
    return _emergencyFund?.progressPercentage ?? 0.0;
  }

  /// Check if fund is complete
  bool get isComplete {
    return _emergencyFund?.isComplete ?? false;
  }

  /// Get remaining amount needed
  double get remainingAmount {
    return _emergencyFund?.remainingAmount ?? 0.0;
  }

  /// Get current amount
  double get currentAmount {
    return _emergencyFund?.currentAmount ?? 0.0;
  }

  /// Get target amount
  double get targetAmount {
    return _emergencyFund?.targetAmount ?? 0.0;
  }

  /// Get target months
  int get targetMonths {
    return _emergencyFund?.targetMonths ?? 6;
  }

  /// Delete emergency fund
  Future<bool> deleteEmergencyFund() async {
    try {
      return await _emergencyFundService.deleteEmergencyFund();
    } catch (e) {
      logger.severe('Error deleting emergency fund: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _emergencyFundSubscription?.cancel();
    logger.info('Disposing EmergencyFundViewModel');
    super.dispose();
  }
}
