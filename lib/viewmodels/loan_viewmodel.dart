import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/loan_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/realtime_data_service.dart';

class LoanViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  final RealtimeDataService _realtimeDataService = RealtimeDataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Loan> _loans = [];
  bool _isLoading = false;
  bool _useFirestore = false; // Flag to determine if we should use Firestore or SQLite
  StreamSubscription<List<Loan>>? _loanSubscription;
  final Logger logger = Logger('LoanViewModel');

  List<Loan> get loans => _loans;
  bool get isLoading => _isLoading;
  bool get useFirestore => _useFirestore;
  
  LoanViewModel() {
    // Check if user is authenticated to determine data source
    _checkDataSource();
  }
  
  /// Check if we should use Firestore or SQLite
  void _checkDataSource() {
    final user = _auth.currentUser;
    _useFirestore = user != null;
    logger.info('Using Firestore: $_useFirestore');
    
    if (_useFirestore) {
      // Subscribe to real-time updates if using Firestore
      _subscribeToLoans();
    } else {
      // Load from SQLite if not using Firestore
      loadLoans();
    }
  }
  
  /// Subscribe to real-time loan updates from Firestore
  void _subscribeToLoans() {
    logger.info('Subscribing to loan updates');
    
    // Cancel any existing subscription
    _loanSubscription?.cancel();
    
    // Start the loans stream if not already started
    _realtimeDataService.startLoansStream();
    
    // Subscribe to the stream
    _loanSubscription = _realtimeDataService.loansStream.listen(
      (loans) {
        _loans = loans;
        _isLoading = false;
        logger.info('Received ${_loans.length} loans');
        notifyListeners();
      },
      onError: (error) {
        logger.severe('Error in loan stream: $error');
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  Future<void> loadLoans() async {
    if (_useFirestore) {
      // For Firestore, we're already subscribed to real-time updates
      // Just update the loading state
      _isLoading = true;
      notifyListeners();
      
      // The stream listener will handle updating loans
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
        _loans = await _databaseService.getLoans();
      } catch (e) {
        logger.info('Error loading loans: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> addLoan(Loan loan) async {
    try {
      if (_useFirestore) {
        // For Firestore, save to cloud
        await _firestoreService.saveLoan(loan);
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, save to local database
        if (loan.id == null) {
          // New loan
          await _databaseService.insertLoan(loan);
        } else {
          // Update existing loan
          await _databaseService.updateLoan(loan);
        }
        await loadLoans();
      }
      return true;
    } catch (e) {
      logger.warning('Error adding/updating loan: $e');
      return false;
    }
  }

  Future<bool> deleteLoan(String id) async {
    try {
      if (_useFirestore) {
        // For Firestore, delete from cloud
        await _firestoreService.deleteLoan(id);
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, delete from local database
        await _databaseService.deleteLoan(int.parse(id));
        await loadLoans();
      }
      return true;
    } catch (e) {
      logger.warning('Error deleting loan: $e');
      return false;
    }
  }

  Future<bool> recordLoanPayment(String loanId, double amount) async {
    try {
      final loan = _loans.firstWhere((loan) => loan.id == loanId);
      final updatedLoan = loan.copyWith(
        amountPaid: loan.amountPaid + amount,
        status: (loan.amountPaid + amount) >= loan.totalAmount ? 'Paid' : 'Active',
      );
      
      if (_useFirestore) {
        // For Firestore, save to cloud
        await _firestoreService.saveLoan(updatedLoan);
        // The stream listener will handle updating the UI
      } else {
        // For SQLite, update in local database
        await _databaseService.updateLoan(updatedLoan);
        await loadLoans();
      }
      return true;
    } catch (e) {
      logger.warning('Error recording loan payment: $e');
      return false;
    }
  }

  double getTotalLoanAmount() {
    return _loans.fold(0, (sum, loan) => sum + loan.totalAmount);
  }

  double getTotalRemainingAmount() {
    return _loans.fold(0, (sum, loan) => sum + loan.remainingAmount);
  }

  double getTotalAmountPaid() {
    return _loans.fold(0, (sum, loan) => sum + loan.amountPaid);
  }

  double getTotalInterestPaid() {
    return _loans.fold(0, (sum, loan) {
      // Calculate interest paid based on loan type and payments made
      if (loan.interestRate == 0) return sum;
      
      // For simplicity, calculate interest as a portion of amount paid
      // This assumes simple interest calculation
      final interestPortion = (loan.amountPaid * loan.interestRate / 100) / 
                             (1 + loan.interestRate / 100);
      return sum + interestPortion;
    });
  }

  List<Loan> getActiveLoans() {
    return _loans.where((loan) => loan.status == 'Active').toList();
  }

  List<Loan> getOverdueLoans() {
    return _loans.where((loan) => loan.isOverdue).toList();
  }

  List<Loan> getLoansByStatus(String status) {
    return _loans.where((loan) => loan.status == status).toList();
  }

  List<Loan> getUpcomingPayments(int daysAhead) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: daysAhead));
    
    return _loans.where((loan) {
      if (loan.status != 'Active') return false;
      
      // Calculate next payment date based on frequency
      DateTime nextPayment;
      switch (loan.paymentFrequency) {
        case 'Weekly':
          final daysSinceStart = now.difference(loan.startDate).inDays;
          final weeksPassed = (daysSinceStart / 7).floor();
          nextPayment = loan.startDate.add(Duration(days: (weeksPassed + 1) * 7));
          break;
        case 'Bi-weekly':
          final daysSinceStart = now.difference(loan.startDate).inDays;
          final biWeeksPassed = (daysSinceStart / 14).floor();
          nextPayment = loan.startDate.add(Duration(days: (biWeeksPassed + 1) * 14));
          break;
        case 'Monthly':
          final monthsSinceStart = (now.year - loan.startDate.year) * 12 + 
                                  now.month - loan.startDate.month;
          nextPayment = DateTime(
            loan.startDate.year + ((loan.startDate.month + monthsSinceStart + 1) ~/ 12),
            (loan.startDate.month + monthsSinceStart + 1) % 12 == 0 ? 12 : (loan.startDate.month + monthsSinceStart + 1) % 12,
            loan.startDate.day,
          );
          break;
        default:
          return false;
      }
      
      return nextPayment.isAfter(now) && nextPayment.isBefore(cutoff);
    }).toList();
  }
  
  @override
  void dispose() {
    // Cancel the loan subscription to prevent memory leaks
    _loanSubscription?.cancel();
    logger.info('Disposing LoanViewModel');
    super.dispose();
  }
}
