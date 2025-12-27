import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

import 'database_service.dart';
import 'firestore_service.dart';
import '../models/transaction_model.dart' as app_models;
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/income_source_model.dart';
import '../models/loan_model.dart';

/// Data Migration Service for FinanceFlow app
/// Handles migration of data from SQLite to Firestore
class DataMigrationService extends ChangeNotifier {
  // Singleton pattern
  static final DataMigrationService _instance = DataMigrationService._internal();
  static DataMigrationService get instance => _instance;
  factory DataMigrationService() => _instance;
  DataMigrationService._internal();

  final _logger = Logger('DataMigrationService');
  final DatabaseService _dbService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  
  bool _isMigrating = false;
  double _progress = 0.0;
  String _currentTask = '';
  String? _error;
  
  // Getters
  bool get isMigrating => _isMigrating;
  double get progress => _progress;
  String get currentTask => _currentTask;
  String? get error => _error;
  
  /// Start the migration process
  Future<bool> migrateData() async {
    if (_isMigrating) {
      _logger.warning('Migration already in progress');
      return false;
    }
    
    _isMigrating = true;
    _progress = 0.0;
    _currentTask = 'Preparing migration';
    _error = null;
    notifyListeners();
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }
      
      // Step 1: Migrate transactions
      await _migrateTransactions(currentUser.uid);
      
      // Step 2: Migrate budgets
      await _migrateBudgets(currentUser.uid);
      
      // Step 3: Migrate goals
      await _migrateGoals(currentUser.uid);
      
      // Step 4: Migrate income sources
      await _migrateIncomeSources(currentUser.uid);
      
      // Step 5: Migrate loans
      await _migrateLoans(currentUser.uid);
      
      _currentTask = 'Migration completed successfully';
      _progress = 1.0;
      notifyListeners();
      
      _logger.info('Data migration completed successfully');
      return true;
    } catch (e) {
      _error = 'Migration failed: $e';
      _logger.severe(_error);
      notifyListeners();
      return false;
    } finally {
      _isMigrating = false;
      notifyListeners();
    }
  }
  
  /// Migrate transactions from SQLite to Firestore
  Future<void> _migrateTransactions(String userId) async {
    _currentTask = 'Migrating transactions';
    _progress = 0.1;
    notifyListeners();
    
    try {
      // Get all transactions from SQLite
      final List<app_models.Transaction> transactions = await _dbService.getTransactions();
      _logger.info('Found ${transactions.length} transactions to migrate');
      
      if (transactions.isEmpty) {
        _logger.info('No transactions to migrate');
        return;
      }
      
      // Migrate each transaction to Firestore
      int count = 0;
      for (final app_models.Transaction transaction in transactions) {
        await _firestoreService.saveTransaction(transaction);
        count++;
        _progress = 0.1 + (count / transactions.length) * 0.2;
        notifyListeners();
      }
      
      _logger.info('Migrated $count transactions to Firestore');
    } catch (e) {
      _logger.severe('Error migrating transactions: $e');
      rethrow;
    }
  }
  
  /// Migrate budgets from SQLite to Firestore
  Future<void> _migrateBudgets(String userId) async {
    _currentTask = 'Migrating budgets';
    _progress = 0.3;
    notifyListeners();
    
    try {
      // Get all budgets from SQLite
      final List<Budget> budgets = await _dbService.getBudgets();
      _logger.info('Found ${budgets.length} budgets to migrate');
      
      if (budgets.isEmpty) {
        _logger.info('No budgets to migrate');
        return;
      }
      
      // Migrate each budget to Firestore
      int count = 0;
      for (final Budget budget in budgets) {
        await _firestoreService.saveBudget(budget);
        count++;
        _progress = 0.3 + (count / budgets.length) * 0.2;
        notifyListeners();
      }
      
      _logger.info('Migrated $count budgets to Firestore');
    } catch (e) {
      _logger.severe('Error migrating budgets: $e');
      rethrow;
    }
  }
  
  /// Migrate goals from SQLite to Firestore
  Future<void> _migrateGoals(String userId) async {
    _currentTask = 'Migrating goals';
    _progress = 0.5;
    notifyListeners();
    
    try {
      // Get all goals from SQLite
      final List<Goal> goals = await _dbService.getGoals();
      _logger.info('Found ${goals.length} goals to migrate');
      
      if (goals.isEmpty) {
        _logger.info('No goals to migrate');
        return;
      }
      
      // Migrate each goal to Firestore
      int count = 0;
      for (final Goal goal in goals) {
        await _firestoreService.saveGoal(goal);
        count++;
        _progress = 0.5 + (count / goals.length) * 0.15;
        notifyListeners();
      }
      
      _logger.info('Migrated $count goals to Firestore');
    } catch (e) {
      _logger.severe('Error migrating goals: $e');
      rethrow;
    }
  }
  
  /// Migrate income sources from SQLite to Firestore
  Future<void> _migrateIncomeSources(String userId) async {
    _currentTask = 'Migrating income sources';
    _progress = 0.65;
    notifyListeners();
    
    try {
      // Get all income sources from SQLite
      final List<IncomeSource> incomeSources = await _dbService.getIncomeSources();
      _logger.info('Found ${incomeSources.length} income sources to migrate');
      
      if (incomeSources.isEmpty) {
        _logger.info('No income sources to migrate');
        return;
      }
      
      // Migrate each income source to Firestore
      int count = 0;
      for (final IncomeSource incomeSource in incomeSources) {
        await _firestoreService.saveIncomeSource(incomeSource);
        count++;
        _progress = 0.65 + (count / incomeSources.length) * 0.15;
        notifyListeners();
      }
      
      _logger.info('Migrated $count income sources to Firestore');
    } catch (e) {
      _logger.severe('Error migrating income sources: $e');
      rethrow;
    }
  }
  
  /// Migrate loans from SQLite to Firestore
  Future<void> _migrateLoans(String userId) async {
    _currentTask = 'Migrating loans';
    _progress = 0.8;
    notifyListeners();
    
    try {
      // Get all loans from SQLite
      final List<Loan> loans = await _dbService.getLoans();
      _logger.info('Found ${loans.length} loans to migrate');
      
      if (loans.isEmpty) {
        _logger.info('No loans to migrate');
        return;
      }
      
      // Migrate each loan to Firestore
      int count = 0;
      for (final Loan loan in loans) {
        await _firestoreService.saveLoan(loan);
        count++;
        _progress = 0.8 + (count / loans.length) * 0.2;
        notifyListeners();
      }
      
      _logger.info('Migrated $count loans to Firestore');
    } catch (e) {
      _logger.severe('Error migrating loans: $e');
      rethrow;
    }
  }
  
  /// Reset migration progress
  void resetProgress() {
    _isMigrating = false;
    _progress = 0.0;
    _currentTask = '';
    _error = null;
    notifyListeners();
  }
}
