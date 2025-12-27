import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/income_source_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/realtime_data_service.dart';

class IncomeViewModel extends ChangeNotifier {
  final DatabaseService _databaseService;
  final FirestoreService _firestoreService;
  final RealtimeDataService _realtimeDataService;
  final FirebaseAuth _auth;

  List<IncomeSource> _incomeSources = [];
  bool _isLoading = false;
  bool _useFirestore = false;
  StreamSubscription<List<IncomeSource>>? _incomeSourceSubscription;
  DateTime? _selectedMonth;
  final Logger logger = Logger('IncomeViewModel');

  IncomeViewModel({
    required DatabaseService databaseService,
    required FirestoreService firestoreService,
    required RealtimeDataService realtimeDataService,
    required FirebaseAuth auth,
  })  : _databaseService = databaseService,
        _firestoreService = firestoreService,
        _realtimeDataService = realtimeDataService,
        _auth = auth {
    // Check if user is authenticated to determine data source
    _checkDataSource();
    _selectedMonth = DateTime.now();
  }

  List<IncomeSource> get incomeSources => _incomeSources;
  bool get isLoading => _isLoading;
  bool get useFirestore => _useFirestore;
  DateTime? get selectedMonth => _selectedMonth;

  /// Set selected month and refresh data
  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  /// Get income sources filtered by month
  List<IncomeSource> getFilteredIncomeSources() {
    if (_selectedMonth == null) return _incomeSources;
    
    final startDate = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1);
    final endDate = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 0, 23, 59, 59);
    return _incomeSources.where((income) {
      final incomeDate = income.date;
      return !incomeDate.isBefore(startDate) && !incomeDate.isAfter(endDate);
    }).toList();
  }

  /// Get total income for the selected month
  double getTotalIncome() {
    final filteredIncome = getFilteredIncomeSources();
    return filteredIncome.fold(0.0, (sum, income) => sum + income.amount);
  }

  /// Get recurring income for the selected month
  List<IncomeSource> getRecurringIncome() {
    final filteredIncome = getFilteredIncomeSources();
    return filteredIncome.where((income) => income.isRecurring).toList();
  }

  /// Get income sources by type for the selected month
  List<IncomeSource> getIncomeByType(String type) {
    final filteredIncome = getFilteredIncomeSources();
    return filteredIncome.where((income) => income.type == type).toList();
  }

  /// Get recent income entries for the selected month
  List<IncomeSource> getRecentIncome(int count) {
    final filteredIncome = getFilteredIncomeSources();
    return filteredIncome.take(count).toList();
  }

  /// Get income distribution by type for the selected month
  Map<String, double> getIncomeDistribution() {
    final filteredIncome = getFilteredIncomeSources();
    final Map<String, double> distribution = {};
    for (final income in filteredIncome) {
      distribution[income.type] = (distribution[income.type] ?? 0) + income.amount;
    }
    return distribution;
  }

  /// Load income sources from the appropriate data source
  Future<void> _loadIncomeSources() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (_useFirestore) {
        // For Firestore, load from the stream subscription
        _incomeSources = await _firestoreService.getIncomeSourcesStream().first;
      } else {
        // For SQLite, load from the database
        _incomeSources = await _databaseService.getIncomeSources();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      logger.severe('Error loading income sources: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Check if we should use Firestore or SQLite
  void _checkDataSource() {
    final user = _auth.currentUser;
    _useFirestore = user != null;
    logger.info('Using Firestore: $_useFirestore');
    
    if (_useFirestore) {
      // Subscribe to real-time updates if using Firestore
      _subscribeToIncomeSources();
    }
  }

  /// Subscribe to real-time income source updates from Firestore
  void _subscribeToIncomeSources() {
    _incomeSourceSubscription?.cancel();
    _incomeSourceSubscription = _firestoreService.getIncomeSourcesStream().listen((sources) {
      _incomeSources = sources;
      notifyListeners();
    }, onError: (error) {
      logger.severe('Error subscribing to income sources: $error');
      _loadIncomeSources();
    });
  }

  /// Add a new income source
  Future<void> addIncomeSource(IncomeSource income) async {
    try {
      if (_useFirestore) {
        await _firestoreService.addIncomeSource(income);
      } else {
        await _databaseService.insertIncomeSource(income);
      }
      await _loadIncomeSources();
    } catch (e) {
      logger.severe('Error adding income source: $e');
      rethrow;
    }
  }

  /// Delete an income source
  Future<void> deleteIncomeSource(dynamic id) async {
    try {
      if (_useFirestore) {
        await _firestoreService.deleteIncomeSource(id.toString());
      } else {
        await _databaseService.deleteIncomeSource(id is int ? id : int.parse(id.toString()));
      }
      await _loadIncomeSources();
    } catch (e) {
      logger.severe('Error deleting income source: $e');
      rethrow;
    }
  }

  /// Load income sources from the appropriate data source
  Future<void> loadIncomeSources() async {
    await _loadIncomeSources();
  }

  /// Sync income sources with real-time data service
  Future<void> syncWithRealtime() async {
    try {
      if (_useFirestore) {
        final sources = await _firestoreService.getIncomeSourcesStream().first;
        await _realtimeDataService.syncIncomeSources(sources);
      } else {
        final sources = await _databaseService.getIncomeSources();
        await _realtimeDataService.syncIncomeSources(sources);
      }
    } catch (e) {
      logger.severe('Error syncing income sources: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Cancel the income source subscription to prevent memory leaks
    _incomeSourceSubscription?.cancel();
    logger.info('Disposing IncomeViewModel');
    super.dispose();
  }
}
