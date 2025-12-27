import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart' as app_models;
import '../services/database_service.dart';
import '../services/firestore_service.dart';

class TransactionViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<app_models.Transaction> _transactions = [];
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now();
  bool _useFirestore = true;
  StreamSubscription<List<app_models.Transaction>>? _transactionSubscription;
  final Logger logger = Logger('TransactionViewModel');

  List<app_models.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;
  bool get useFirestore => _useFirestore;
  
  // Store all transactions for reports and analytics
  List<app_models.Transaction> _allTransactions = [];
  List<app_models.Transaction> get allTransactions => _allTransactions;
  
  TransactionViewModel() {
    logger.info('Initializing TransactionViewModel');
    
    // No mock data initialization - app will start with empty state
    
    // Check if user is authenticated to determine data source
    _checkDataSource();
    
    // Set up auth state listener
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        logger.info('User signed in, switching to Firestore');
        _useFirestore = true;
        _setupFirestoreListener();
      } else {
        logger.info('User signed out, switching to local database');
        _useFirestore = false;
        _transactionSubscription?.cancel();
      }
      // Reload transactions when auth state changes
      loadTransactionsByMonth(_selectedMonth);
    });
    
    // Load transactions for the current month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadTransactionsByMonth(_selectedMonth);
    });
  }
  
  void _setupFirestoreListener() {
    _transactionSubscription?.cancel();
    _transactionSubscription = _firestoreService.transactionsStream().listen(
      (transactions) {
        _transactions = transactions;
        // Mark loading complete when stream delivers data
        if (_isLoading) {
          _isLoading = false;
        }
        notifyListeners();
      },
      onError: (error) {
        logger.severe('Error in Firestore listener: $error');
        _useFirestore = false;
        // Ensure loading flag is cleared on error to avoid infinite spinner
        _isLoading = false;
        notifyListeners();
        loadTransactionsByMonth(_selectedMonth);
      },
    );
  }
  

  
  /// Check if we should use Firestore or SQLite
  void _checkDataSource() {
    final user = _auth.currentUser;
    _useFirestore = user != null;
    logger.info('Using ${_useFirestore ? 'Firestore' : 'SQLite'} as data source');
  }
  
  /// Load all transactions (for reports and analytics)
  Future<void> loadAllTransactions() async {
    logger.info('loadAllTransactions called');
    
    if (_isLoading) {
      logger.info('Already loading, skipping duplicate request');
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      if (_useFirestore) {
        logger.info('Loading all transactions from Firestore');
        // Get all transactions from Firestore
        _allTransactions = await _firestoreService.getTransactions();
        _transactions = _allTransactions;
      } else {
        logger.info('Loading all transactions from local database');
        try {
          _allTransactions = await _databaseService
              .getTransactions()
              .timeout(const Duration(seconds: 10));
          _transactions = _allTransactions;
        } on TimeoutException catch (_) {
          logger.warning('Local DB getTransactions timed out');
          _allTransactions = [];
          _transactions = [];
        }
      }
      
      logger.info('Successfully loaded ${_allTransactions.length} transactions');
    } catch (e) {
      logger.severe('Error loading all transactions: $e');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load transactions for a specific month
  Future<void> loadTransactionsByMonth(DateTime month) async {
    final monthKey = '${month.year}-${month.month}';
    logger.info('loadTransactionsByMonth called for month: $monthKey');
  
    // Prevent multiple simultaneous loads for the same month
    if (_isLoading) {
      logger.info('Already loading, skipping duplicate request');
      return;
    }
  
    // If already loaded for this month, skip
    if (_selectedMonth.year == month.year && _selectedMonth.month == month.month && _transactions.isNotEmpty) {
      logger.info('Transactions already loaded for this month, skipping');
      return;
    }
  
    _isLoading = true;
    _selectedMonth = month;
    notifyListeners();

    try {
      logger.info('Loading transactions for ${DateFormat('MMMM yyyy').format(month)}');
    
      if (_useFirestore) {
        logger.info('Using Firestore as data source');
        // Use the stream listener instead of direct query for better performance
        _setupFirestoreListener();
        // Give the stream a moment to load, then finish
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        logger.info('Using local database as data source');
        logger.info('Getting transactions for ${month.toIso8601String()}');
        try {
          _transactions = await _databaseService
              .getTransactionsByMonth(month)
              .timeout(const Duration(seconds: 5)); // Reduced timeout
        } on TimeoutException catch (_) {
          logger.warning('Local DB getTransactionsByMonth timed out');
          _transactions = [];
        }
      }
    
      logger.info('Successfully loaded ${_transactions.length} transactions');
    } catch (e) {
      logger.severe('Error loading transactions: $e');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Add a new transaction
  Future<void> addTransaction(app_models.Transaction transaction) async {
    try {
      logger.info('Adding new transaction: ${transaction.title}');
      _isLoading = true;
      notifyListeners();
      
      if (_useFirestore) {
        // Add to Firestore - the stream listener will automatically update _transactions
        await _firestoreService.addTransaction(transaction).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Add operation timed out', const Duration(seconds: 10));
          },
        );
        logger.info('Transaction added to Firestore: ${transaction.title}');
      } else {
        // Add to local database and reload transactions
        await _databaseService.insertTransaction(transaction);
        _transactions = await _databaseService.getTransactionsByMonth(_selectedMonth);
        logger.info('Transaction added to local database: ${transaction.title}');
      }
    } catch (e) {
      logger.severe('Error adding transaction: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Update an existing transaction
  Future<void> updateTransaction(app_models.Transaction transaction) async {
    try {
      logger.info('Updating transaction: ${transaction.id}');
      _isLoading = true;
      notifyListeners();
      
      if (_useFirestore) {
        // Update in Firestore - the stream listener will automatically update _transactions
        await _firestoreService.updateTransaction(transaction).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Update operation timed out', const Duration(seconds: 10));
          },
        );
        logger.info('Transaction updated in Firestore: ${transaction.id}');
      } else {
        // Update in local database and reload transactions
        await _databaseService.updateTransaction(transaction);
        _transactions = await _databaseService.getTransactionsByMonth(_selectedMonth);
        logger.info('Transaction updated in local database: ${transaction.id}');
      }
    } catch (e) {
      logger.severe('Error updating transaction: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    try {
      logger.info('Deleting transaction: $id');
      _isLoading = true;
      notifyListeners();
      
      if (_useFirestore) {
        // Delete from Firestore - the stream listener will automatically update _transactions
        await _firestoreService.deleteTransaction(id).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Delete operation timed out', const Duration(seconds: 10));
          },
        );
        logger.info('Transaction deleted from Firestore: $id');
      } else {
        // Delete from local database and reload transactions
        await _databaseService.deleteTransaction(id);
        _transactions = await _databaseService.getTransactionsByMonth(_selectedMonth);
        logger.info('Transaction deleted from local database: $id');
      }
    } catch (e) {
      logger.severe('Error deleting transaction: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get the total income for the selected month
  double getTotalIncome() {
    final targetMonth = _selectedMonth;
    return _transactions
        .where((t) => t.isIncome && 
                     t.date.year == targetMonth.year && 
                     t.date.month == targetMonth.month)
        .fold(0.0, (total, t) => total + t.amount);
  }
  
  /// Get the total expenses for the selected month
  double getTotalExpenses() {
    final targetMonth = _selectedMonth;
    logger.info('getTotalExpenses: Target month is ${targetMonth.year}-${targetMonth.month}');
    logger.info('getTotalExpenses: Total transactions loaded: ${_transactions.length}');
    
    // Log all transactions to see what we have
    for (var t in _transactions) {
      logger.info('Transaction: ${t.title} - \$${t.amount} - ${t.type} - ${t.date}');
    }
    
    final expenseTransactions = _transactions
        .where((t) => t.isExpense && 
                     t.date.year == targetMonth.year && 
                     t.date.month == targetMonth.month)
        .toList();
    
    logger.info('getTotalExpenses: Found ${expenseTransactions.length} expense transactions for January 2025');
    
    for (var t in expenseTransactions) {
      logger.info('Expense: ${t.title} - \$${t.amount} on ${t.date}');
    }
    
    final total = expenseTransactions.fold(0.0, (total, t) => total + t.amount.abs());
    logger.info('getTotalExpenses: Total expenses = \$$total');
    
    return total;
  }
  
  /// Get the current balance (income - expenses)
  double getBalance() {
    return getTotalIncome() - getTotalExpenses();
  }
  
  /// Get the total amount of unpaid transactions
  double getTotalUnpaid() {
    return _transactions
        .where((t) => t.status == app_models.TransactionStatus.pending || 
                     t.status == app_models.TransactionStatus.partial)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
  
  /// Get a map of category totals for the selected month
  Map<String, double> getCategoryTotals() {
    final Map<String, double> categoryTotals = {};
    
    for (var transaction in _transactions) {
      if (transaction.isExpense) {
        categoryTotals.update(
          transaction.category,
          (total) => total + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    
    return categoryTotals;
  }
  
  /// Format a date as 'MMMM yyyy' (e.g., 'June 2023')
  String getMonthYearString(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Get a list of unique expense categories for the selected month
  List<String> get uniqueExpenseCategories {
    final categories = _transactions
        .where((t) => t.isExpense)
        .map((t) => t.category)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
  
  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }
}
