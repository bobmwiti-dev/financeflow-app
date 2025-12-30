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
      final List<Map<String, dynamic>> monthlyTotals = [];
      
      // Calculate totals for each month
      for (int i = 0; i < months; i++) {
        final targetMonth = DateTime(now.year, now.month - i, 1);
        final endDate = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);
        
        final snapshot = await _transactionsCollection
            .where('userId', isEqualTo: _userId)
            .where('date', isGreaterThanOrEqualTo: targetMonth)
            .where('date', isLessThanOrEqualTo: endDate)
            .get();
            
        final transactions = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return models.Transaction.fromMap(data, id: doc.id);
        }).toList();
        
        // Sum all transactions for the month
        double total = 0;
        for (final transaction in transactions) {
          total += transaction.amount;
        }
        
        monthlyTotals.add({
          'month': targetMonth,
          'total': total,
        });
      }
      
      // Sort by month (oldest first)
      monthlyTotals.sort((a, b) => (a['month'] as DateTime).compareTo(b['month'] as DateTime));
      
      return monthlyTotals;
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

    // Default to 12 months if not specified
    final monthsToInclude = numberOfMonths ?? 12;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (monthsToInclude - 1), 1);

    try {
      var queryRef = _transactionsCollection.where('userId', isEqualTo: uid);
      queryRef = queryRef.where('date', isGreaterThanOrEqualTo: start);
      final query = await queryRef.get();

      // Pre-fill all months with 0.0 to ensure February and other months show up
      final Map<String, double> totals = {}; 
      for (int i = 0; i < monthsToInclude; i++) {
        final monthDate = DateTime(start.year, start.month + i, 1);
        totals[DateFormat('MMM yyyy').format(monthDate)] = 0.0;
      }

      // Process transactions and add to existing months
      for (final doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final typeStr = data['type']?.toString() ?? '';
        if (!typeStr.contains('expense')) continue; // only expenses
        double amount = (data['amount'] as num).toDouble().abs();

        // Parse stored timestamp
        DateTime txDate;
        final raw = data['date'];
        if (raw is Timestamp) {
          txDate = raw.toDate();
        } else if (raw is int) {
          txDate = DateTime.fromMillisecondsSinceEpoch(raw > 1000000000000 ? raw : raw * 1000);
        } else {
          txDate = DateTime.parse(raw.toString());
        }

        final label = DateFormat('MMM yyyy').format(DateTime(txDate.year, txDate.month, 1));
        if (totals.containsKey(label)) {
          totals[label] = (totals[label] ?? 0) + amount;
        }
      }

      // Sort the keys chronologically and return
      final sortedEntries = totals.entries.toList()
        ..sort((a, b) => DateFormat('MMM yyyy').parse(a.key).compareTo(DateFormat('MMM yyyy').parse(b.key)));
      return { for (var e in sortedEntries) e.key : e.value };
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
