import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/budget_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart' as app_models;
import '../services/realtime_data_service.dart';

class BudgetViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  final RealtimeDataService _realtimeDataService = RealtimeDataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Budget> _budgets = [];
  List<Budget> _allBudgets = []; // Store all budgets
  bool _isLoading = false;
  bool _useFirestore = false; // Flag to determine if we should use Firestore or SQLite
  StreamSubscription<List<Budget>>? _budgetSubscription;
  StreamSubscription<List<app_models.Transaction>>? _transactionsSubscription;
  DateTime _selectedMonth = DateTime.now(); // Current selected month
  Map<String, double> _spentByCategory = {};
  List<app_models.Transaction> _latestTransactions = [];
  final Logger logger = Logger('BudgetViewModel');

  List<Budget> get budgets => _budgets;
  List<Budget> get allBudgets => _allBudgets;
  bool get isLoading => _isLoading;
  bool get useFirestore => _useFirestore;
  DateTime get selectedMonth => _selectedMonth;
  
  BudgetViewModel() {
    // Check if user is authenticated to determine data source
    _checkDataSource();
  }
  
  /// Check if we should use Firestore or SQLite
  void _checkDataSource() {
    // Always use Firestore on web platform since SQLite is not available
    if (kIsWeb) {
      _useFirestore = true;
    } else {
      // On mobile platforms, use Firestore if user is authenticated
      final user = _auth.currentUser;
      _useFirestore = user != null;
    }
    
    logger.info('Platform: ${kIsWeb ? "Web" : "Mobile"}, Using Firestore: $_useFirestore');
    
    if (_useFirestore) {
      // Subscribe to real-time updates if using Firestore
      _subscribeToBudgets();
      _subscribeToTransactions();
    } else {
      // Load from SQLite if not using Firestore (mobile only)
      loadBudgets();
    }
  }

  void _subscribeToTransactions() {
    logger.info('Subscribing to transaction updates for budget spent computation');

    _transactionsSubscription?.cancel();
    _realtimeDataService.startTransactionsStream();

    _transactionsSubscription = _realtimeDataService.transactionsStream.listen(
      (transactions) {
        _latestTransactions = transactions;
        _recomputeSpentByCategoryFromTransactions(transactions);
        if (_allBudgets.isNotEmpty) {
          _filterBudgetsByMonth();
        }
      },
      onError: (error) {
        logger.severe('Error in transactions stream for budgets: $error');
      },
    );
  }

  void _recomputeSpentByCategoryFromTransactions(List<app_models.Transaction> transactions) {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startOfNextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

    final Map<String, double> spent = {};

    for (final tx in transactions) {
      if (tx.type != app_models.TransactionType.expense) continue;
      if (tx.date.isBefore(startOfMonth) || !tx.date.isBefore(startOfNextMonth)) continue;

      final category = tx.category;
      spent[category] = (spent[category] ?? 0.0) + tx.amount.abs();
    }

    _spentByCategory = spent;
  }
  
  /// Subscribe to real-time budget updates from Firestore
  void _subscribeToBudgets() {
    logger.info('Subscribing to budget updates');
    
    // Cancel any existing subscription
    _budgetSubscription?.cancel();
    
    // Start the budgets stream if not already started
    _realtimeDataService.startBudgetsStream();
    
    // Subscribe to the stream
    _budgetSubscription = _realtimeDataService.budgetsStream.listen(
      (budgets) {
        // Filter out budgets with null or invalid IDs
        _allBudgets = budgets.where((budget) => 
          budget.id != null && budget.id!.isNotEmpty && budget.id != 'null'
        ).toList();
        _filterBudgetsByMonth();
        _isLoading = false;
        logger.info('Received ${budgets.length} budgets from stream, filtered to ${_allBudgets.length} valid budgets');
        logger.info('Filtered to ${_budgets.length} budgets for current month');
        notifyListeners();
      },
      onError: (error) {
        logger.severe('Error in budget stream: $error');
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  Future<void> loadBudgets() async {
    if (_useFirestore) {
      // For Firestore, we're already subscribed to real-time updates
      // Just update the loading state
      _isLoading = true;
      notifyListeners();
      
      // The stream listener will handle updating budgets
      // Just set a timeout to ensure we don't stay in loading state indefinitely
      Future.delayed(const Duration(seconds: 2), () {
        if (_isLoading) {
          _isLoading = false;
          notifyListeners();
        }
      });
    } else {
      // For SQLite, load from the database
      _isLoading = true;
      notifyListeners();

      try {
        final budgets = await _databaseService.getBudgets();
        final Map<String, double> spent = {};
        for (var i = 0; i < budgets.length; i++) {
          final budget = budgets[i];
          final transactions = await _databaseService.getTransactionsByMonth(budget.startDate);
          final spentForCategory = transactions
              .where((t) => t.category == budget.category)
              .fold(0.0, (sum, t) => sum + t.amount.abs());

          spent[budget.category] = (spent[budget.category] ?? 0.0) + spentForCategory;
          budgets[i] = budget.copyWith(spent: spentForCategory);
        }
        _spentByCategory = spent;
        _allBudgets = budgets;
        _filterBudgetsByMonth();
      } catch (e) {
        logger.info('Error loading budgets: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addBudget(Budget budget) async {
    try {
      if (_useFirestore) {
        // For Firestore, save to cloud
        await _firestoreService.saveBudget(budget);
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, save to local database
        if (budget.id == null) {
          // New budget
          await _databaseService.insertBudget(budget);
        } else {
          // Update existing budget
          await _databaseService.updateBudget(budget);
        }
        await loadBudgets();
      }
      logger.info('Budget added: $budget');
      return true;
    } catch (e) {
      logger.warning('Failed to add/update budget: $e');
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    try {
      logger.info('Deleting budget with ID: $id, useFirestore: $_useFirestore');
      
      if (_useFirestore) {
        // For Firestore, delete from cloud
        logger.info('Deleting from Firestore');
        await _firestoreService.deleteBudget(id);
        // Manually trigger a refresh to ensure UI updates
        await loadBudgets();
      } else {
        // For SQLite, delete from local database
        logger.info('Deleting from SQLite');
        final result = await _databaseService.deleteBudget(int.parse(id));
        logger.info('SQLite delete result: $result');
        await loadBudgets();
      }
      logger.info('Budget deletion successful');
      return true;
    } catch (e) {
      logger.severe('Unexpected error deleting budget: $e');
      return false;
    }
  }

  /// Filter budgets by selected month
  void _filterBudgetsByMonth() {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    
    final filteredBudgets = _allBudgets.where((budget) {
      return budget.startDate.isBefore(endOfMonth.add(const Duration(days: 1))) &&
             budget.endDate.isAfter(startOfMonth.subtract(const Duration(days: 1)));
    }).toList();
    
    // Consolidate budgets with same category
    _budgets = _consolidateBudgetsByCategory(filteredBudgets);
    
    logger.info('Found ${_budgets.length} budgets for selected month ${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}.');
    
    // If no budgets found for current month, log available budget months for debugging
    if (_budgets.isEmpty && _allBudgets.isNotEmpty) {
      final availableMonths = _allBudgets.map((b) => 
        '${b.startDate.year}-${b.startDate.month.toString().padLeft(2, '0')}'
      ).toSet().toList()..sort();
      logger.info('No budgets found for current month. Available budget months: $availableMonths');
    }
    
    // Log budget details for debugging
    for (final budget in _budgets) {
      logger.info('Category: ${budget.category}, Spent: ${budget.spent}, Budget: ${budget.amount}');
    }
    
    notifyListeners();
  }

  /// Consolidate budgets with the same category by combining their amounts and spent values
  List<Budget> _consolidateBudgetsByCategory(List<Budget> budgets) {
    final Map<String, Budget> consolidatedBudgets = {};
    
    for (final budget in budgets) {
      final category = budget.category;
      
      if (consolidatedBudgets.containsKey(category)) {
        // Combine with existing budget
        final existing = consolidatedBudgets[category]!;
        consolidatedBudgets[category] = existing.copyWith(
          amount: existing.amount + budget.amount,
          spent: existing.spent,
        );
      } else {
        // Add new budget
        consolidatedBudgets[category] = budget.copyWith(
          spent: _spentByCategory[category] ?? budget.spent,
        );
      }
    }
    
    return consolidatedBudgets.values.toList();
  }

  /// Load budgets for a specific month
  Future<void> loadBudgetsForMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month, 1); // Normalize to first day of month
    logger.info('Loading budgets for month: ${_selectedMonth.year}-${_selectedMonth.month}');

    if (_latestTransactions.isNotEmpty) {
      _recomputeSpentByCategoryFromTransactions(_latestTransactions);
    }
    
    if (_allBudgets.isNotEmpty) {
      // If we already have budgets loaded, just filter them
      _filterBudgetsByMonth();
      notifyListeners();
    } else {
      // If no budgets loaded yet, load them first
      await loadBudgets();
    }
  }
  
  /// Get month/year string for display
  String getMonthYearString(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  Budget? getBudgetByCategory(String category) {
    try {
      return _budgets.firstWhere((budget) => budget.category == category);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    try {
      if (_useFirestore) {
        await _firestoreService.saveBudget(budget);
        // The stream listener will handle updating the UI
      } else {
        await _databaseService.updateBudget(budget);
        await loadBudgets();
      }
      return true;
    } catch (e) {
      logger.warning('Failed to update budget: $e');
      return false;
    }
  }

  Future<bool> updateBudgetSpent(String category, double amount) async {
    try {
      if (_useFirestore) {
        // For Firestore, we need to get the budget first, then update it
        Budget? budget = getBudgetByCategory(category);
        if (budget != null) {
          budget = budget.copyWith(spent: budget.spent + amount);
          await _firestoreService.saveBudget(budget);
          // The stream listener will handle updating the UI
        } else {
          logger.warning('No budget found for category: $category');
          return false;
        }
      } else {
        // For SQLite, use the database service
        await _databaseService.updateBudgetSpent(category, amount);
        await loadBudgets();
      }
      return true;
    } catch (e) {
      logger.warning('Failed to update budget spent: $e');
      return false;
    }
  }

  double getTotalBudget() {
    return _budgets.fold(0, (sum, budget) => sum + budget.amount);
  }

  double getTotalSpent() {
    return _budgets.fold(0, (sum, budget) => sum + budget.spent);
  }

  double getRemainingBudget() {
    return getTotalBudget() - getTotalSpent();
  }

  double getPercentUsed() {
    if (getTotalBudget() == 0) return 0;
    return (getTotalSpent() / getTotalBudget()) * 100;
  }

  List<Budget> getBudgetsByOverspent() {
    return _budgets.where((budget) => budget.spent > budget.amount).toList();
  }

  List<Budget> getBudgetsNearLimit() {
    return _budgets.where((budget) => 
      budget.percentUsed >= 80 && budget.percentUsed < 100
    ).toList();
  }

  Future<List<app_models.Transaction>> getTransactionsForBudgets() async {
    try {
      if (_useFirestore) {
        // For web platform, use Firestore transaction service
        logger.info('Getting transactions from Firestore for budget timeline');
        return await _firestoreService.getTransactions();
      } else {
        // For mobile platforms, use SQLite
        return await _databaseService.getTransactions();
      }
    } catch (e) {
      logger.warning('Error getting transactions for budgets: $e');
      return [];
    }
  }
  
  @override
  void dispose() {
    // Cancel the budget subscription to prevent memory leaks
    _budgetSubscription?.cancel();
    _transactionsSubscription?.cancel();
    logger.info('Disposing BudgetViewModel');
    super.dispose();
  }
}
