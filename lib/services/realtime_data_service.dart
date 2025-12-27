import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart' as app_models;
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/income_source_model.dart';
import '../models/loan_model.dart';

/// Real-time data service for FinanceFlow app
/// Provides streams of data from Firestore for real-time updates
class RealtimeDataService extends ChangeNotifier {
  // Use a factory pattern that doesn't rely on a singleton
  // This avoids the issues with disposal and recreation
  factory RealtimeDataService() {
    return RealtimeDataService._create();
  }
  
  // Private constructor for creating new instances
  RealtimeDataService._create() {
    _isDisposed = false;
    _logger.info('Created new RealtimeDataService instance');
    _setupAuthListener();
  }

  // Static logger to ensure consistent naming
  static final _logger = Logger('RealtimeDataService');
  
  // Service dependencies
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Track disposal state to prevent errors
  bool _isDisposed = false;
  bool _isInitialized = false;
  StreamSubscription? _authSubscription;
  
  // Stream controllers
  final StreamController<List<app_models.Transaction>> _transactionsController = 
      StreamController<List<app_models.Transaction>>.broadcast();
  final StreamController<List<Budget>> _budgetsController = 
      StreamController<List<Budget>>.broadcast();
  final StreamController<List<Goal>> _goalsController = 
      StreamController<List<Goal>>.broadcast();
  final StreamController<List<IncomeSource>> _incomeSourcesController = 
      StreamController<List<IncomeSource>>.broadcast();
  final StreamController<List<Loan>> _loansController = 
      StreamController<List<Loan>>.broadcast();
  
  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _transactionsSubscription;
  StreamSubscription<QuerySnapshot>? _budgetsSubscription;
  StreamSubscription<QuerySnapshot>? _goalsSubscription;
  StreamSubscription<QuerySnapshot>? _incomeSourcesSubscription;
  StreamSubscription<QuerySnapshot>? _loansSubscription;
  
  // Streams
  Stream<List<app_models.Transaction>> get transactionsStream => _transactionsController.stream;
  Stream<List<Budget>> get budgetsStream => _budgetsController.stream;
  Stream<List<Goal>> get goalsStream => _goalsController.stream;
  Stream<List<IncomeSource>> get incomeSourcesStream => _incomeSourcesController.stream;
  Stream<List<Loan>> get loansStream => _loansController.stream;
  
  // Collection references
  CollectionReference get _transactionsCollection => _db.collection('transactions');
  CollectionReference get _budgetsCollection => _db.collection('budgets');
  CollectionReference get _goalsCollection => _db.collection('goals');
  CollectionReference get _incomeSourcesCollection => _db.collection('income_sources');
  CollectionReference get _loansCollection => _db.collection('loans');
  
  /// Setup authentication state listener
  void _setupAuthListener() {
    _logger.info('Setting up auth state listener');
    
    // Cancel any existing subscription
    _authSubscription?.cancel();
    
    // Listen for auth state changes
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (_isDisposed) return;
      
      if (user != null) {
        _logger.info('User authenticated: ${user.uid}');
        initializeStreams();
      } else {
        _logger.info('User signed out');
        _cancelAllSubscriptions();
      }
    }, onError: (error) {
      _logger.severe('Auth state listener error: $error');
    });
  }
  
  /// Initialize all data streams
  void initializeStreams() {
    if (_isDisposed) {
      _logger.warning('Attempted to initialize streams on disposed service');
      return;
    }
    
    if (_isInitialized) {
      _logger.info('Streams already initialized, skipping');
      return;
    }
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _logger.warning('Cannot initialize streams: No authenticated user');
      return;
    }
    
    _logger.info('Initializing real-time data streams for user: $userId');
    _isInitialized = true;
    
    // Start all streams
    startTransactionsStream();
    startBudgetsStream();
    startGoalsStream();
    startIncomeSourcesStream();
    startLoansStream();
  }
  
  /// Start streaming transactions
  void startTransactionsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _logger.info('Starting transactions stream');
    
    // Cancel existing subscription if any
    _transactionsSubscription?.cancel();
    
    // Start new subscription
    _transactionsSubscription = _transactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
          try {
            final transactions = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return app_models.Transaction.fromMap(data, id: doc.id);
            }).toList();
            
            _transactionsController.add(transactions);
            _logger.info('Updated transactions stream with ${transactions.length} items');
          } catch (e) {
            _logger.severe('Error processing transactions snapshot: $e');
            _transactionsController.addError(e);
          }
        }, onError: (error) {
          _logger.severe('Error in transactions stream: $error');
          _transactionsController.addError(error);
        });
  }
  
  /// Start streaming budgets
  void startBudgetsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _logger.info('Starting budgets stream');
    
    // Cancel existing subscription if any
    _budgetsSubscription?.cancel();
    
    // Start new subscription
    _budgetsSubscription = _budgetsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          try {
            final budgets = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              _logger.info('Raw budget data from Firestore: $data');
              // Spread Firestore data first, then override with the
              // authoritative document ID so a nullable/invalid 'id'
              // field inside the document cannot clobber doc.id.
              return Budget.fromMap({
                ...data,
                'id': doc.id,
              });
            }).toList();
            
            _budgetsController.add(budgets);
            _logger.info('Updated budgets stream with ${budgets.length} items');
          } catch (e) {
            _logger.severe('Error processing budgets snapshot: $e');
            _budgetsController.addError(e);
          }
        }, onError: (error) {
          _logger.severe('Error in budgets stream: $error');
          _budgetsController.addError(error);
        });
  }
  
  /// Start streaming goals
  void startGoalsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _logger.info('Starting goals stream');
    
    // Cancel existing subscription if any
    _goalsSubscription?.cancel();
    
    // Start new subscription
    _goalsSubscription = _goalsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          try {
            final goals = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return Goal.fromMap(data);
            }).toList();
            
            _goalsController.add(goals);
            _logger.info('Updated goals stream with ${goals.length} items');
          } catch (e) {
            _logger.severe('Error processing goals snapshot: $e');
            _goalsController.addError(e);
          }
        }, onError: (error) {
          _logger.severe('Error in goals stream: $error');
          _goalsController.addError(error);
        });
  }
  
  /// Start streaming income sources
  void startIncomeSourcesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _logger.info('Starting income sources stream');
    
    // Cancel existing subscription if any
    _incomeSourcesSubscription?.cancel();
    
    // Start new subscription
    _incomeSourcesSubscription = _incomeSourcesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          try {
            final incomeSources = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return IncomeSource.fromMap(data);
            }).toList();
            
            _incomeSourcesController.add(incomeSources);
            _logger.info('Updated income sources stream with ${incomeSources.length} items');
          } catch (e) {
            _logger.severe('Error processing income sources snapshot: $e');
            _incomeSourcesController.addError(e);
          }
        }, onError: (error) {
          _logger.severe('Error in income sources stream: $error');
          _incomeSourcesController.addError(error);
        });
  }
  
  /// Start streaming loans
  void startLoansStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _logger.info('Starting loans stream');
    
    // Cancel existing subscription if any
    _loansSubscription?.cancel();
    
    // Start new subscription
    _loansSubscription = _loansCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          try {
            final loans = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Ensure the Firestore document ID is captured
              data['id'] = doc.id;
              return Loan.fromMap(data);
            }).toList();
            
            _loansController.add(loans);
            _logger.info('Updated loans stream with ${loans.length} items');
          } catch (e) {
            _logger.severe('Error processing loans snapshot: $e');
            _loansController.addError(e);
          }
        }, onError: (error) {
          _logger.severe('Error in loans stream: $error');
          _loansController.addError(error);
        });
  }

  /// Sync income sources with Firestore
  Future<void> syncIncomeSources(List<IncomeSource> sources) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      // Get existing documents
      final existingDocs = await _incomeSourcesCollection
          .where('userId', isEqualTo: userId)
          .get();

      // Map of existing IDs to documents
      final existingMap = Map<String, DocumentSnapshot>.fromEntries(
        existingDocs.docs.map((doc) => MapEntry(doc.id, doc)),
      );

      // Process each source
      for (final source in sources) {
        final docId = source.id?.toString();
        if (docId == null || !existingMap.containsKey(docId)) {
          // New source - add to Firestore
          await _incomeSourcesCollection.add({
            'userId': userId,
            'name': source.name,
            'type': source.type,
            'amount': source.amount,
            'date': source.date,
            'isRecurring': source.isRecurring,
            'frequency': source.frequency,
            'notes': source.notes,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Existing source - update in Firestore
          await existingMap[docId]!.reference.update({
            'name': source.name,
            'type': source.type,
            'amount': source.amount,
            'date': source.date,
            'isRecurring': source.isRecurring,
            'frequency': source.frequency,
            'notes': source.notes,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Remove any documents that no longer exist in the local list
      for (final doc in existingDocs.docs) {
        final docId = doc.id;
        if (!sources.any((s) => s.id?.toString() == docId)) {
          await doc.reference.delete();
        }
      }

      _logger.info('Successfully synced ${sources.length} income sources');
    } catch (e) {
      _logger.severe('Error syncing income sources: $e');
      rethrow;
    }
  }
  
  /// Cancel all stream subscriptions but keep controllers open
  void _cancelAllSubscriptions() {
    _logger.info('Cancelling all subscriptions');
    
    // Cancel all subscriptions
    _transactionsSubscription?.cancel();
    _budgetsSubscription?.cancel();
    _goalsSubscription?.cancel();
    _incomeSourcesSubscription?.cancel();
    _loansSubscription?.cancel();
    
    // Reset state
    _isInitialized = false;
  }
  
  /// Stop all streams and clean up resources
  @override
  void dispose() {
    // Prevent multiple disposals
    if (_isDisposed) {
      _logger.warning('Attempted to dispose already disposed RealtimeDataService');
      return;
    }
    
    _logger.info('Disposing real-time data service');
    _isDisposed = true;
    
    // Cancel auth listener
    _authSubscription?.cancel();
    
    // Cancel all data subscriptions
    _cancelAllSubscriptions();
    
    // Close all controllers if they're not closed already
    try {
      if (!_transactionsController.isClosed) _transactionsController.close();
      if (!_budgetsController.isClosed) _budgetsController.close();
      if (!_goalsController.isClosed) _goalsController.close();
      if (!_incomeSourcesController.isClosed) _incomeSourcesController.close();
      if (!_loansController.isClosed) _loansController.close();
    } catch (e) {
      _logger.severe('Error closing stream controllers: $e');
    }
    
    // Call super.dispose() as required
    super.dispose();
  }
  
  /// Restart all streams (useful after manual reconnection)
  void restartStreams() {
    // Don't restart if disposed
    if (_isDisposed) {
      _logger.warning('Attempted to restart streams on disposed RealtimeDataService');
      return;
    }
    
    _logger.info('Restarting all data streams');
    
    // Cancel all existing subscriptions
    _cancelAllSubscriptions();
    
    // Start all streams again
    _isInitialized = false;
    initializeStreams();
  }
}
