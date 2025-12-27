import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'logger_service.dart';

class MockDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Logger _logger = Logger('MockDataService');

  /// Generate mock transactions for March-August 2024 (excluding Jan/Feb)
  static Future<bool> generateMockData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.error('No authenticated user found');
        return false;
      }

      final userId = user.uid;
      _logger.info('Starting mock data generation for user: $userId');

      // Generate data for March 2025 to August 2025
      final months = [
        DateTime(2025, 3), // March
        DateTime(2025, 4), // April
        DateTime(2025, 5), // May
        DateTime(2025, 6), // June
        DateTime(2025, 7), // July
        DateTime(2025, 8), // August
      ];

      final random = Random(12345); // Fixed seed for consistent data
      int totalTransactions = 0;
      int totalIncomes = 0;
      int totalBudgets = 0;

      for (final month in months) {
        // Generate transactions for this month
        final transactionCount = await _generateTransactionsForMonth(userId, month, random);
        totalTransactions += transactionCount;

        // Generate income for this month
        final incomeCount = await _generateIncomeForMonth(userId, month, random);
        totalIncomes += incomeCount;

        // Generate budgets for this month
        final budgetCount = await _generateBudgetsForMonth(userId, month, random);
        totalBudgets += budgetCount;

        // Generate loans for this month
        if (month.month == 3) { // Only generate loans once in March
          await _generateLoans(userId, random);
        }
      }

      _logger.info('Mock data generation completed successfully');
      _logger.info('Generated: $totalTransactions transactions, $totalIncomes incomes, $totalBudgets budgets');
      
      return true;
    } catch (e) {
      _logger.error('Error generating mock data: $e');
      return false;
    }
  }

  static Future<int> _generateTransactionsForMonth(String userId, DateTime month, Random random) async {
    final categories = [
      {'name': 'Food & Dining', 'amounts': [15, 25, 45, 80, 120]},
      {'name': 'Transportation', 'amounts': [20, 35, 50, 75]},
      {'name': 'Shopping', 'amounts': [30, 60, 100, 200, 350]},
      {'name': 'Entertainment', 'amounts': [25, 40, 75, 150]},
      {'name': 'Bills & Utilities', 'amounts': [50, 100, 150, 250]},
      {'name': 'Healthcare', 'amounts': [40, 80, 150, 300]},
      {'name': 'Education', 'amounts': [100, 200, 500]},
      {'name': 'Personal Care', 'amounts': [20, 40, 80]},
    ];

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final transactionCount = 15 + random.nextInt(11); // 15-25 transactions per month

    final batch = _firestore.batch();
    
    for (int i = 0; i < transactionCount; i++) {
      final day = 1 + random.nextInt(daysInMonth);
      final date = DateTime(month.year, month.month, day);
      
      final category = categories[random.nextInt(categories.length)];
      final amounts = category['amounts'] as List<int>;
      final amount = amounts[random.nextInt(amounts.length)].toDouble();
      
      final docRef = _firestore.collection('transactions').doc();
      batch.set(docRef, {
        'id': docRef.id,
        'userId': userId,
        'amount': amount,
        'category': category['name'],
        'description': _generateTransactionDescription(category['name'] as String, random),
        'date': Timestamp.fromDate(date),
        'isExpense': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
    return transactionCount;
  }

  static Future<int> _generateIncomeForMonth(String userId, DateTime month, Random random) async {
    final incomeSources = [
      {'name': 'Salary', 'amount': 3500.0, 'type': 'salary'},
      {'name': 'Freelance Work', 'amount': 800.0, 'type': 'freelance'},
      {'name': 'Investment Returns', 'amount': 200.0, 'type': 'investment'},
      {'name': 'Side Business', 'amount': 600.0, 'type': 'business'},
    ];

    final batch = _firestore.batch();
    
    for (final source in incomeSources) {
      // Add some variation to amounts (±10%)
      final baseAmount = source['amount'] as double;
      final variation = (random.nextDouble() - 0.5) * 0.2; // ±10%
      final amount = baseAmount * (1 + variation);
      
      final docRef = _firestore.collection('income_sources').doc();
      batch.set(docRef, {
        'id': docRef.id,
        'userId': userId,
        'name': source['name'],
        'amount': amount,
        'type': source['type'],
        'date': Timestamp.fromDate(DateTime(month.year, month.month, 1)),
        'notes': 'Monthly ${source['name'].toString().toLowerCase()}',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
    return incomeSources.length;
  }

  static Future<int> _generateBudgetsForMonth(String userId, DateTime month, Random random) async {
    final budgetCategories = [
      {'category': 'Food & Dining', 'baseAmount': 600.0, 'variation': 0.25},
      {'category': 'Transportation', 'baseAmount': 300.0, 'variation': 0.20},
      {'category': 'Shopping', 'baseAmount': 400.0, 'variation': 0.40},
      {'category': 'Entertainment', 'baseAmount': 200.0, 'variation': 0.50},
      {'category': 'Bills & Utilities', 'baseAmount': 500.0, 'variation': 0.15},
      {'category': 'Healthcare', 'baseAmount': 250.0, 'variation': 0.60},
    ];

    final batch = _firestore.batch();
    
    for (final budget in budgetCategories) {
      // Add monthly variation based on category
      final baseAmount = budget['baseAmount'] as double;
      final variation = budget['variation'] as double;
      final randomFactor = (random.nextDouble() - 0.5) * 2 * variation; // ±variation%
      final amount = (baseAmount * (1 + randomFactor)).roundToDouble();
      
      final docRef = _firestore.collection('budgets').doc();
      batch.set(docRef, {
        'id': docRef.id,
        'userId': userId,
        'category': budget['category'],
        'amount': amount,
        'spent': 0.0,
        'startDate': Timestamp.fromDate(DateTime(month.year, month.month, 1)),
        'endDate': Timestamp.fromDate(DateTime(month.year, month.month + 1, 0)),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
    return budgetCategories.length;
  }

  static Future<void> _generateLoans(String userId, Random random) async {
    final loans = [
      {
        'name': 'Car Loan',
        'totalAmount': 25000.0,
        'amountPaid': 6500.0,
        'interestRate': 4.5,
        'startDate': DateTime(2023, 1, 15),
        'dueDate': DateTime(2027, 6, 15),
        'lender': 'ABC Bank',
        'status': 'Active',
        'paymentFrequency': 'Monthly',
        'installmentAmount': 450.0,
        'notes': 'Car loan for Honda Civic',
      },
      {
        'name': 'Student Loan',
        'totalAmount': 35000.0,
        'amountPaid': 7000.0,
        'interestRate': 3.8,
        'startDate': DateTime(2022, 9, 1),
        'dueDate': DateTime(2030, 12, 31),
        'lender': 'Education Finance Corp',
        'status': 'Active',
        'paymentFrequency': 'Monthly',
        'installmentAmount': 320.0,
        'notes': 'Master\'s degree loan',
      },
      {
        'name': 'Personal Loan',
        'totalAmount': 10000.0,
        'amountPaid': 2500.0,
        'interestRate': 8.2,
        'startDate': DateTime(2024, 3, 10),
        'dueDate': DateTime(2026, 3, 10),
        'lender': 'Credit Union',
        'status': 'Active',
        'paymentFrequency': 'Monthly',
        'installmentAmount': 425.0,
        'notes': 'Home improvement loan',
      },
    ];

    final batch = _firestore.batch();
    
    for (final loan in loans) {
      final docRef = _firestore.collection('loans').doc();
      batch.set(docRef, {
        'id': docRef.id,
        'userId': userId,
        'name': loan['name'],
        'totalAmount': loan['totalAmount'],
        'amountPaid': loan['amountPaid'],
        'interestRate': loan['interestRate'],
        'startDate': Timestamp.fromDate(loan['startDate'] as DateTime),
        'dueDate': Timestamp.fromDate(loan['dueDate'] as DateTime),
        'lender': loan['lender'],
        'status': loan['status'],
        'paymentFrequency': loan['paymentFrequency'],
        'installmentAmount': loan['installmentAmount'],
        'notes': loan['notes'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  static String _generateTransactionDescription(String category, Random random) {
    final descriptions = {
      'Food & Dining': ['Restaurant dinner', 'Grocery shopping', 'Coffee shop', 'Fast food lunch', 'Takeout order'],
      'Transportation': ['Gas station', 'Uber ride', 'Bus fare', 'Parking fee', 'Car maintenance'],
      'Shopping': ['Clothing store', 'Online purchase', 'Electronics', 'Home goods', 'Gift purchase'],
      'Entertainment': ['Movie tickets', 'Concert', 'Streaming service', 'Gaming', 'Sports event'],
      'Bills & Utilities': ['Electric bill', 'Water bill', 'Internet', 'Phone bill', 'Insurance'],
      'Healthcare': ['Doctor visit', 'Pharmacy', 'Dental checkup', 'Health insurance', 'Medical supplies'],
      'Education': ['Course fee', 'Books', 'Online learning', 'Workshop', 'Certification'],
      'Personal Care': ['Haircut', 'Skincare', 'Gym membership', 'Spa treatment', 'Personal items'],
    };
    
    final categoryDescriptions = descriptions[category] ?? ['General expense'];
    return categoryDescriptions[random.nextInt(categoryDescriptions.length)];
  }

  /// Clear all mock data (for testing purposes)
  static Future<bool> clearMockData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final userId = user.uid;
      final collections = ['transactions', 'income_sources', 'budgets'];

      for (final collectionName in collections) {
        final query = _firestore
            .collection(collectionName)
            .where('userId', isEqualTo: userId);
        
        final snapshot = await query.get();
        
        if (snapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      }

      _logger.info('Mock data cleared successfully');
      return true;
    } catch (e) {
      _logger.error('Error clearing mock data: $e');
      return false;
    }
  }
}
