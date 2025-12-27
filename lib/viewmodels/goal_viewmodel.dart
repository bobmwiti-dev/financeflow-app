import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/contribution_model.dart';
import '../models/goal_model.dart';
import '../services/goal_service.dart';
import '../services/database_service.dart'; // Assuming this handles SQLite goals

class GoalViewModel extends ChangeNotifier {
  final GoalService _goalService = GoalService.instance;
  final DatabaseService _databaseService = DatabaseService.instance;
  final Logger _logger = Logger('GoalViewModel');

  List<Goal> _goals = [];
  List<Contribution> _contributions = [];
  bool _isLoading = false;
  String? _errorMessage;
  final bool _useFirestore = true; // Default to Firestore as GoalService is available
  StreamSubscription<List<Goal>>? _goalSubscription;
  StreamSubscription<List<Contribution>>? _contributionSubscription;

  List<Goal> get goals => _goals;
  List<Contribution> get contributions => _contributions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  GoalViewModel() {
    loadGoals();
  }

  void loadGoals() {
    _setLoading(true);
    _goalSubscription?.cancel(); // Cancel any existing subscription

    try {
      if (_useFirestore) {
        _goalSubscription = _goalService.getGoalsStream().listen((goals) {
          _goals = goals;
          _setError(null, null); // Clear previous errors
          _setLoading(false);
        }, onError: (e, s) {
          _setError('Failed to load goals from stream: $e', s);
          _setLoading(false);
        });
      } else {
        // Fallback to SQLite if needed
        _databaseService.getGoals().then((goals) {
          _goals = goals;
          _setLoading(false);
        }).catchError((e, s) {
          _setError('Failed to load goals from SQLite: $e', s);
          _setLoading(false);
        });
      }
    } catch (e, s) {
      _setError('Error setting up goal loading: $e', s);
      _setLoading(false);
    }
  }

  Future<bool> addGoal(Goal goal) async {
    try {
      if (_useFirestore) {
        await _goalService.addGoal(
          title: goal.name,
          targetAmount: goal.targetAmount,
          targetDate: goal.targetDate ?? DateTime.now().add(const Duration(days: 365)), // Default to 1 year
          category: goal.category ?? 'General',
          currentAmount: goal.currentAmount,
          priority: goal.priority,
          description: goal.description,
          icon: goal.icon,
          targetMonthlyContribution: goal.targetMonthlyContribution,
        );
        // Stream will update the list automatically
        return true;
      } else {
        await _databaseService.insertGoal(goal);
        loadGoals(); // Manual refresh for SQLite
        return true;
      }
    } catch (e, s) {
      _setError('Failed to add goal: $e', s);
      return false;
    }
  }

  Future<bool> updateGoal(Goal goal) async {
    try {
      if (_useFirestore) {
        await _goalService.updateGoal(
          goalId: goal.id!,
          title: goal.name,
          targetAmount: goal.targetAmount,
          targetDate: goal.targetDate ?? DateTime.now().add(const Duration(days: 365)),
          category: goal.category ?? 'General',
          currentAmount: goal.currentAmount,
          priority: goal.priority,
          description: goal.description,
          icon: goal.icon,
          targetMonthlyContribution: goal.targetMonthlyContribution,
        );
        return true;
      } else {
        await _databaseService.updateGoal(goal);
        return true;
      }
    } catch (e, s) {
      _setError('Failed to update goal: $e', s);
      return false;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      if (_useFirestore) {
        await _goalService.deleteGoal(id);
        // Stream will handle UI update
      } else {
        final intId = int.tryParse(id);
        if (intId != null) {
          await _databaseService.deleteGoal(intId);
          loadGoals(); // Manual refresh for SQLite

        } else {
          throw Exception('Invalid ID format for SQLite deletion');
        }
      }
    } catch (e, s) {
      _setError('Failed to delete goal: $e', s);
    }
  }

  Future<bool> updateGoalProgress(Goal goal, double amount) async {
    final newAmount = goal.currentAmount + amount;
    if (newAmount > goal.targetAmount) {
      _logger.warning('Contribution exceeds target amount. Ignoring.');
      return false;
    }

    try {
      if (_useFirestore) {
        await _goalService.updateGoalProgress(goal.id!, newAmount);
        await _addContribution(goal.id!, amount);
        return true;
      } else {
        final updatedGoal = goal.copyWith(currentAmount: newAmount);
        await _databaseService.updateGoal(updatedGoal);
        await _addContribution(goal.id!, amount);
        loadGoals(); // Manual refresh for SQLite
        return true;
      }
    } catch (e, s) {
      _setError('Failed to update goal progress: $e', s);
      return false;
    }
  }

  Future<void> _addContribution(String goalId, double amount) async {
    final contribution = Contribution(
      id: DateTime.now().toIso8601String(),
      goalId: goalId,
      amount: amount,
      date: DateTime.now(),
    );

    try {
      if (_useFirestore) {
        final saved = await _goalService.addContribution(goalId, amount);
        if (saved != null) {
          _contributions.insert(0, saved);
        }
      } else {
        await _databaseService.insertContribution(contribution);
        _contributions.insert(0, contribution);
      }
      notifyListeners();
      _logger.info('Contribution of $amount added to goal $goalId');
    } catch (e, s) {
      _setError('Failed to save contribution: $e', s);
      rethrow;
    }
  }

  Future<void> fetchContributions(String? goalId) async {
    if (goalId == null) return;

    _contributionSubscription?.cancel();

    if (_useFirestore) {
      _contributionSubscription = _goalService
          .getContributionsStream(goalId)
          .listen((contribs) {
        _contributions = contribs;
        notifyListeners();
      }, onError: (e, s) {
        _setError('Failed to load contributions: $e', s);
      });
    } else {
      _contributions = await _databaseService.getContributionsByGoal(goalId);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message, StackTrace? stackTrace) {
    _errorMessage = message;
    if (message != null) {
      _logger.severe(message, null, stackTrace);
    }
    notifyListeners();
  }

  double getTotalSavingsGoals() {
    return _goals.fold(0, (sum, goal) => sum + goal.targetAmount);
  }

  double getTotalCurrentSavings() {
    return _goals.fold(0, (sum, goal) => sum + goal.currentAmount);
  }

  double getOverallProgress() {
    final totalTarget = getTotalSavingsGoals();
    if (totalTarget == 0) return 0.0;
    final totalCurrent = getTotalCurrentSavings();
    return totalCurrent / totalTarget;
  }

  @override
  void dispose() {
    _goalSubscription?.cancel();
    _contributionSubscription?.cancel();
    _logger.info('Disposing GoalViewModel');
    super.dispose();
  }
}
