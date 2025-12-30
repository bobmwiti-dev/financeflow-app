import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart' as models;

class TransactionService {
  // Singleton pattern
  static final TransactionService _instance = TransactionService._internal();
  static TransactionService get instance => _instance;
  factory TransactionService() => _instance;
  
  TransactionService._internal();

  List<models.Transaction> _lastTransactions = [];
  List<models.Transaction> get lastTransactions => _lastTransactions;
  
  final Logger _logger = Logger('TransactionService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;
  
  // Collection reference
  CollectionReference get _transactionsCollection => 
      _firestore.collection('transactions');
      
  // Check if a transaction with the given SMS reference exists
  Future<bool> checkTransactionExistsBySmsReference(String smsReference) async {
    if (_userId == null || smsReference.isEmpty) {
      _logger.warning('Cannot check transaction: User not authenticated or empty SMS reference');
      return false;
    }
    
    try {
      final querySnapshot = await _transactionsCollection
          .where('smsReference', isEqualTo: smsReference)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.severe('Error checking transaction by SMS reference: $e');
      return false;
    }
  }
  
  // Get transactions stream for real-time updates
  Stream<List<models.Transaction>> getTransactionsStream() {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return Stream.value([]);
    }
    
    // Changed query to avoid needing composite index
    // Just get all transactions and sort in memory for testing
    return _transactionsCollection
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
          try {
            if (snapshot.docs.isEmpty) {
              _logger.info('No transactions found in collection');
              _lastTransactions = []; // Also clear the cache here
              return <models.Transaction>[];
            }
            
            final transactions = snapshot.docs.map((doc) {
              try {
                return models.Transaction.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
              } catch (e) {
                _logger.severe('Error parsing transaction document ${doc.id}: $e');
                return null;
              }
            })
            .where((transaction) => transaction != null)
            .cast<models.Transaction>()
            .toList();
            
            // Sort in memory by date descending (newest first) since we removed Firestore orderBy
            transactions.sort((a, b) => b.date.compareTo(a.date));

            _lastTransactions = transactions; // Cache the latest transactions
            
            return transactions;
          } catch (e) {
            _logger.severe('Error processing transaction snapshot: $e');
            return <models.Transaction>[];
          }
        })
        .handleError((error) {
          _logger.severe('Stream error in getTransactionsStream: $error');
          return <models.Transaction>[];
        });
  }
  
  // Get transactions for a specific month
  Stream<List<models.Transaction>> getTransactionsByMonth(DateTime month) {
    final userId = _auth.currentUser?.uid;
    
    if (userId == null) {
      // User is not authenticated, return an empty stream
      _logger.warning('Cannot get transactions: No authenticated user');
      return Stream.value([]);
    }
    
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    return _transactionsCollection
        .where('userId', isEqualTo: userId)  // Filter by current user
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            // Check if there are any documents before processing
            if (snapshot.docs.isEmpty) {
              _logger.info('No transactions found for ${month.year}-${month.month}');
              return <models.Transaction>[];
            }
            
            final transactions = snapshot.docs.map((doc) {
              try {
                return models.Transaction.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
              } catch (e) {
                _logger.severe('Error parsing transaction document ${doc.id}: $e');
                // Return null for failed items so we can filter them out below
                return null;
              }
            })
            // Filter out any null entries from parsing errors
            .where((transaction) => transaction != null)
            .cast<models.Transaction>()
            .toList();
            
            _logger.info('Retrieved ${transactions.length} transactions for ${month.year}-${month.month}');
            return transactions;
          } catch (e) {
            _logger.severe('Error processing transaction snapshot: $e');
            return <models.Transaction>[];
          }
        })
        // Handle stream errors by returning an empty list
        .handleError((error) {
          _logger.severe('Stream error in getTransactionsByMonth: $error');
          return <models.Transaction>[];
        });
  }
  
  // Get recent transactions
  Future<List<models.Transaction>> getRecentTransactions(int limit) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return [];
    }
    
    try {
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: _userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return models.Transaction.fromMap(data, id: doc.id);
      }).toList();
    } catch (e) {
      _logger.severe('Error getting recent transactions: $e');
      return [];
    }
  }
  
  // Add a new transaction
  Future<String?> addTransaction(models.Transaction transaction) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return null;
    }
    
    try {
      final docRef = await _transactionsCollection.add(transaction.toFirestore());
      _logger.info('Added transaction with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.severe('Error adding transaction: $e');
      return null;
    }
  }
  
  // Update an existing transaction
  Future<bool> updateTransaction(String id, models.Transaction transaction) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return false;
    }
    
    try {
      await _transactionsCollection.doc(id).update(transaction.toFirestore());
      _logger.info('Updated transaction with ID: $id');
      return true;
    } catch (e) {
      _logger.severe('Error updating transaction: $e');
      return false;
    }
  }
  
  // Delete a transaction
  Future<bool> deleteTransaction(String id) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return false;
    }
    
    try {
      await _transactionsCollection.doc(id).delete();
      _logger.info('Deleted transaction with ID: $id');
      return true;
    } catch (e) {
      _logger.severe('Error deleting transaction: $e');
      return false;
    }
  }
  
  // Get transactions by category within a date range
  Future<List<models.Transaction>> getTransactionsByCategory(
    String category,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return [];
    }
    
    try {
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: _userId)
          .where('category', isEqualTo: category)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return models.Transaction.fromMap(data, id: doc.id);
      }).toList();
    } catch (e) {
      _logger.severe('Error getting transactions by category: $e');
      return [];
    }
  }

  // Get spending by category for a specific month
  Future<Map<String, double>> getSpendingByCategory(DateTime month) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return {};
    }
    
    try {
      // Calculate start and end dates for the month
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: _userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();
          
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return models.Transaction.fromMap(data, id: doc.id);
      }).toList();
      
      // Group transactions by category and sum amounts
      final Map<String, double> categoryTotals = {};
      for (final transaction in transactions) {
        final category = transaction.category;
        final amount = transaction.amount;
        
        if (categoryTotals.containsKey(category)) {
          categoryTotals[category] = categoryTotals[category]! + amount;
        } else {
          categoryTotals[category] = amount;
        }
      }
      
      return categoryTotals;
    } catch (e) {
      _logger.severe('Error getting spending by category: $e');
      return {};
    }
  }
  
  // Get monthly spending trend for the last n months
  Future<List<Map<String, dynamic>>> getMonthlySpendingTrend(int months) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return [];
    }
    
    try {
      final now = DateTime.now();
      // Start from N-1 months ago so we include the current month as the last point.
      final startMonth = DateTime(now.year, now.month - (months - 1), 1);
      final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Single range query for all transactions in the period
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: _userId)
          .where('date', isGreaterThanOrEqualTo: startMonth)
          .where('date', isLessThanOrEqualTo: endOfCurrentMonth)
          .get();

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return models.Transaction.fromMap(data, id: doc.id);
      }).toList();

      // Aggregate expenses per month
      final Map<DateTime, double> monthlyTotals = {};
      for (final tx in transactions) {
        if (!(tx.isExpense || tx.amount < 0)) continue;

        final monthKey = DateTime(tx.date.year, tx.date.month, 1);
        if (monthKey.isBefore(startMonth) || monthKey.isAfter(endOfCurrentMonth)) {
          continue;
        }

        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + tx.amount.abs();
      }

      // Build a continuous list of months from startMonth to current month
      final List<Map<String, dynamic>> result = [];
      for (int i = 0; i < months; i++) {
        final monthDate = DateTime(startMonth.year, startMonth.month + i, 1);
        result.add({
          'month': monthDate,
          'total': monthlyTotals[monthDate] ?? 0.0,
        });
      }

      return result;
    } catch (e) {
      _logger.severe('Error getting monthly spending trend: $e');
      return [];
    }
  }

  // Get total spending per month for the last [numberOfMonths] months.
  // Returns a map where keys are 'MMM yyyy' and values are absolute expense totals (positive numbers).
  Future<Map<String, double>> getMonthlySpendingHistory({int? numberOfMonths}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _logger.warning('No authenticated user found');
      return {};
    }

    try {
      // Fetch all transactions for this user so we can compute the full
      // spending history from the earliest to latest expense month.
      final query = await _transactionsCollection
          .where('userId', isEqualTo: uid)
          .get();

      if (query.docs.isEmpty) {
        return {};
      }

      // First pass: compute totals by month (DateTime key) and track the
      // earliest and latest months where we have any expense.
      final Map<DateTime, double> monthlyTotals = {};
      DateTime? earliestMonth;
      DateTime? latestMonth;

      for (final doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Determine if this transaction should be treated as an expense.
        // Some older records may have inconsistent type strings, so we
        // also fall back to checking the sign of the amount.
        final typeStr = data['type']?.toString().toLowerCase() ?? '';
        final rawAmount = (data['amount'] as num).toDouble();
        final isExpenseByType = typeStr.contains('expense');
        final isExpenseBySign = rawAmount < 0;

        if (!(isExpenseByType || isExpenseBySign)) continue;

        final double amount = rawAmount.abs();

        // Parse stored timestamp
        DateTime txDate;
        final raw = data['date'];
        if (raw is Timestamp) {
          txDate = raw.toDate();
        } else if (raw is int) {
          txDate = DateTime.fromMillisecondsSinceEpoch(
              raw > 1000000000000 ? raw : raw * 1000);
        } else {
          txDate = DateTime.parse(raw.toString());
        }

        final monthKey = DateTime(txDate.year, txDate.month, 1);
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;

        if (earliestMonth == null || monthKey.isBefore(earliestMonth)) {
          earliestMonth = monthKey;
        }
        if (latestMonth == null || monthKey.isAfter(latestMonth)) {
          latestMonth = monthKey;
        }
      }

      if (earliestMonth == null || latestMonth == null) {
        return {};
      }

      // Build a continuous map from earliest to latest month, filling any
      // missing months with 0.0 so the chart has a smooth x-axis.
      final Map<String, double> totals = {};
      final earliest = earliestMonth;
      final latest = latestMonth;

      var current = DateTime(earliest.year, earliest.month, 1);
      while (!current.isAfter(latest)) {
        final label = DateFormat('MMM yyyy').format(current);
        totals[label] = monthlyTotals[current] ?? 0.0;
        current = DateTime(current.year, current.month + 1, 1);
      }

      // If a specific numberOfMonths was requested, trim to the last N months.
      if (numberOfMonths != null && totals.length > numberOfMonths) {
        final keys = totals.keys.toList();
        final startIndex = keys.length - numberOfMonths;
        final trimmedEntries = keys
            .sublist(startIndex)
            .map((k) => MapEntry(k, totals[k]!))
            .toList();
        return {for (var e in trimmedEntries) e.key: e.value};
      }

      return totals;
    } catch (e) {
      _logger.severe('Error computing monthly spending history: $e');
      return {};
    }
  }

  // Get total income for a specific month
  Future<double> getTotalIncome(DateTime month) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return 0.0;
    }
    
    try {
      // Calculate start and end dates for the month
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: _userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .where('amount', isGreaterThan: 0)
          .get();
          
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return models.Transaction.fromMap(data, id: doc.id);
      }).toList();
      
      // Sum all positive transactions (income)
      double total = 0;
      for (final transaction in transactions) {
        total += transaction.amount;
      }
      
      return total;
    } catch (e) {
      _logger.severe('Error getting total income: $e');
      return 0.0;
    }
  }
  
  // Get total expenses for a specific month
  Future<double> getTotalExpenses(DateTime month) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found');
      return 0.0;
    }
    
    try {
      // Calculate start and end dates for the month
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: _userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .where('amount', isLessThan: 0)
          .get();
          
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return models.Transaction.fromMap(data, id: doc.id);
      }).toList();
      
      // Sum all negative transactions (expenses)
      double total = 0;
      for (final transaction in transactions) {
        total += transaction.amount.abs();
      }
      
      return total;
    } catch (e) {
      _logger.severe('Error getting total expenses: $e');
      return 0.0;
    }
  }

  // Get frequent payees
  Future<List<String>> getFrequentPayees({int limit = 5}) async {
    if (_userId == null) {
      _logger.warning('No authenticated user found, cannot get frequent payees.');
      return [];
    }

    try {
      // Fetch all transactions, consider limiting if performance becomes an issue
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: _userId)
          .orderBy('date', descending: true)
          .limit(500)
          .get();
      if (snapshot.docs.isEmpty) {
        _logger.info('No transactions found, returning empty list of payees.');
        return [];
      }

      final payees = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final transaction = models.Transaction.fromMap(data, id: doc.id);
        // Use 'title' field for payee name, normalize to lower case and trim whitespace
        final payeeName = transaction.title.trim().toLowerCase(); 
        if (payeeName.isNotEmpty) {
          payees[payeeName] = (payees[payeeName] ?? 0) + 1;
        }
      }

      // Sort payees by frequency (most frequent first)
      final sortedPayees = payees.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Return the top 'limit' payee names, capitalized
      return sortedPayees
          .take(limit)
          .map((entry) {
            // Capitalize each word in the payee name
            return entry.key.split(' ').map((word) {
              if (word.isEmpty) return '';
              return '${word[0].toUpperCase()}${word.substring(1)}';
            }).join(' ');
          })
          .toList();

    } catch (e) {
      _logger.severe('Error getting frequent payees: $e');
      return [];
    }
  }


   


  Future<List<models.Transaction>> getUpcomingBills({int limit = 5}) async {
    if (_userId == null) {
      _logger.warning('User not authenticated, cannot fetch upcoming bills.');
      return [];
    }
    DateTime now = DateTime.now();

    try {
      final querySnapshot = await _transactionsCollection
          .where('userId', isEqualTo: _userId)
          .where('type', isEqualTo: 'bill')
          .where('date', isGreaterThan: now.toIso8601String().substring(0,10))
          .orderBy('date', descending: false)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => models.Transaction.fromFirestore(doc.data() as DocumentSnapshot<Map<String, dynamic>>, doc.id as SnapshotOptions?))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching upcoming bills: $e');
      return [];
    }
  }
}
