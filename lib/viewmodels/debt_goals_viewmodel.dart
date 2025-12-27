import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'dart:math' as math;
import '../models/debt_payment.dart';

import '../models/debt_payoff_goal.dart';
import '../services/debt_goal_service.dart';

/// ViewModel managing a list of [DebtPayoffGoal]s.
class DebtGoalsViewModel extends ChangeNotifier {
  final Logger _logger = Logger('DebtGoalsViewModel');
  final DebtGoalService _service = DebtGoalService.instance;

  List<DebtPayoffGoal> _goals = [];
  bool _isLoading = false;

  List<DebtPayoffGoal> get goals => _goals;
  bool get isLoading => _isLoading;

  // payments keyed by goalId
    final Map<int, List<DebtPayment>> _payments = {};
  Map<int, List<DebtPayment>> get payments => _payments;

  // Utility: estimate months to payoff using minimumPayment and interest (simple interest approx)
  int estimateMonthsToPayoff(DebtPayoffGoal goal) {
    final balance = goal.currentBalance;
    final ratePerMonth = goal.interestRate / 100 / 12;
    final payment = goal.minimumMonthlyPayment;
    if (payment <= balance * ratePerMonth) return -1; // impossible payoff
    // amortization formula n = -log(1 - r*B/P)/log(1+r)
        final n = (-(math.log(1 - ratePerMonth * balance / payment)) / math.log(1 + ratePerMonth)).ceil();
    return n;
  }

  Future<void> loadGoals() async {
    _isLoading = true;
    notifyListeners();
    try {
      _goals = await _service.fetchGoals();
    } catch (e) {
      _logger.severe('Failed to load debt goals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPayments(int goalId) async {
    try {
      _payments[goalId] = await _service.fetchPaymentsForGoal(goalId);
      notifyListeners();
    } catch (e) {
      _logger.severe('Failed to load payments: $e');
    }
  }

  Future<void> addGoal(DebtPayoffGoal goal) async {
    try {
      await _service.insertGoal(goal);
      await loadGoals();
    } catch (e) {
      _logger.severe('Failed to add debt goal: $e');
    }
  }

  Future<void> updateGoal(DebtPayoffGoal goal) async {
    try {
      await _service.updateGoal(goal);
      await loadGoals();
    } catch (e) {
      _logger.severe('Failed to update debt goal: $e');
    }
  }

  Future<void> addPayment(DebtPayment payment) async {
    try {
      await _service.insertPayment(payment);
      // Update goal balance locally and in DB
            final goal = _goals.firstWhere((g) => int.tryParse(g.id ?? '') == payment.goalId);
      final updatedGoal = goal.copyWith(
        currentBalance: (goal.currentBalance - payment.amount).clamp(0, goal.originalAmount),
      );
      await _service.updateGoal(updatedGoal);
      await loadGoals();
      await loadPayments(payment.goalId);
    } catch (e) {
      _logger.severe('Failed to add payment: $e');
    }
  }

  Future<void> deletePayment(int paymentId, int goalId) async {
    try {
      await _service.deletePayment(paymentId);
      await loadPayments(goalId);
      await loadGoals();
    } catch (e) {
      _logger.severe('Failed to delete payment: $e');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _service.deleteGoal(id);
      await loadGoals();
    } catch (e) {
      _logger.severe('Failed to delete debt goal: $e');
    }
  }
}
