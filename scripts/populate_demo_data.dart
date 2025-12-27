import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

/// Script to populate Firestore with realistic demo data from March 2024 to August 2024
/// This will complement your existing January and February data
Future<void> main() async {
  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    stdout.writeln('${record.level.name}: ${record.message}');
  });
  
  final logger = Logger('DemoDataPopulator');
  
  logger.info('🚀 Starting demo data population...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    // Get current user or use demo user ID
    final userId = auth.currentUser?.uid ?? 'demo_user';
    logger.info('📍 Populating data for user: $userId');
    
    final random = Random();
    
    // Generate data for March 2024 to August 2024 (6 months)
    final startDate = DateTime(2024, 3, 1);
    final endDate = DateTime(2024, 8, 31);
    
    await populateTransactions(firestore, userId, startDate, endDate, random, logger);
    await populateIncomes(firestore, userId, startDate, endDate, random, logger);
    await populateBudgets(firestore, userId, startDate, endDate, random, logger);
    await populateGoals(firestore, userId, random, logger);
    await populateBills(firestore, userId, startDate, endDate, random, logger);
    
    logger.info('✅ Demo data population completed!');
    logger.info('🎉 Your app now has 8 months of realistic financial data!');
    
  } catch (e) {
    logger.severe('❌ Error during data population: $e');
    exit(1);
  }
}

Future<void> populateTransactions(FirebaseFirestore firestore, String userId, 
    DateTime startDate, DateTime endDate, Random random, Logger logger) async {
  
  logger.info('💰 Populating transactions...');
  
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
  
  final batch = firestore.batch();
  int transactionCount = 0;
  
  // Generate transactions for each month
  for (var month = startDate.month; month <= endDate.month; month++) {
    final year = month <= 8 ? 2024 : 2024;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    // Generate 15-25 transactions per month
    final monthlyTransactions = 15 + random.nextInt(11);
    
    for (int i = 0; i < monthlyTransactions; i++) {
      final day = 1 + random.nextInt(daysInMonth);
      final date = DateTime(year, month, day);
      
      final category = categories[random.nextInt(categories.length)];
      final amounts = category['amounts'] as List<int>;
      final amount = amounts[random.nextInt(amounts.length)].toDouble();
      
      final docRef = firestore.collection('transactions').doc();
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
      
      transactionCount++;
      
      // Commit batch every 500 operations
      if (transactionCount % 500 == 0) {
        await batch.commit();
        logger.info('   Added $transactionCount transactions...');
      }
    }
  }
  
  // Commit remaining transactions
  if (transactionCount % 500 != 0) {
    await batch.commit();
  }
  
  logger.info('   ✅ Added $transactionCount transactions');
}

Future<void> populateIncomes(FirebaseFirestore firestore, String userId,
    DateTime startDate, DateTime endDate, Random random, Logger logger) async {
  
  logger.info('💵 Populating income sources...');
  
  final incomeSources = [
    {'name': 'Salary', 'amount': 3500.0, 'type': 'salary'},
    {'name': 'Freelance Work', 'amount': 800.0, 'type': 'freelance'},
    {'name': 'Investment Returns', 'amount': 200.0, 'type': 'investment'},
    {'name': 'Side Business', 'amount': 600.0, 'type': 'business'},
  ];
  
  final batch = firestore.batch();
  int incomeCount = 0;
  
  // Generate monthly income for each source
  for (var month = startDate.month; month <= endDate.month; month++) {
    final year = month <= 8 ? 2024 : 2024;
    
    for (final source in incomeSources) {
      // Add some variation to amounts (±10%)
      final baseAmount = source['amount'] as double;
      final variation = (random.nextDouble() - 0.5) * 0.2; // ±10%
      final amount = baseAmount * (1 + variation);
      
      final docRef = firestore.collection('income_sources').doc();
      batch.set(docRef, {
        'id': docRef.id,
        'userId': userId,
        'name': source['name'],
        'amount': amount,
        'type': source['type'],
        'date': Timestamp.fromDate(DateTime(year, month, 1)),
        'notes': 'Monthly ${source['name'].toString().toLowerCase()}',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      incomeCount++;
    }
  }
  
  await batch.commit();
  logger.info('   ✅ Added $incomeCount income entries');
}

Future<void> populateBudgets(FirebaseFirestore firestore, String userId,
    DateTime startDate, DateTime endDate, Random random, Logger logger) async {
  
  logger.info('📊 Populating budgets...');
  
  final budgetCategories = [
    {'category': 'Food & Dining', 'amount': 600.0},
    {'category': 'Transportation', 'amount': 300.0},
    {'category': 'Shopping', 'amount': 400.0},
    {'category': 'Entertainment', 'amount': 200.0},
    {'category': 'Bills & Utilities', 'amount': 500.0},
    {'category': 'Healthcare', 'amount': 250.0},
  ];
  
  final batch = firestore.batch();
  int budgetCount = 0;
  
  // Create monthly budgets
  for (var month = startDate.month; month <= endDate.month; month++) {
    final year = month <= 8 ? 2024 : 2024;
    
    for (final budget in budgetCategories) {
      final docRef = firestore.collection('budgets').doc();
      batch.set(docRef, {
        'id': docRef.id,
        'userId': userId,
        'category': budget['category'],
        'amount': budget['amount'],
        'spent': 0.0,
        'startDate': Timestamp.fromDate(DateTime(year, month, 1)),
        'endDate': Timestamp.fromDate(DateTime(year, month + 1, 0)),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      budgetCount++;
    }
  }
  
  await batch.commit();
  logger.info('   ✅ Added $budgetCount budget entries');
}

Future<void> populateGoals(FirebaseFirestore firestore, String userId,
    Random random, Logger logger) async {
  
  logger.info('🎯 Populating financial goals...');
  
  final goals = [
    {
      'name': 'Emergency Fund',
      'targetAmount': 10000.0,
      'currentAmount': 3500.0,
      'category': 'Emergency',
      'deadline': DateTime(2024, 12, 31),
    },
    {
      'name': 'Vacation Fund',
      'targetAmount': 2500.0,
      'currentAmount': 800.0,
      'category': 'Travel',
      'deadline': DateTime(2024, 10, 15),
    },
    {
      'name': 'New Car',
      'targetAmount': 15000.0,
      'currentAmount': 5200.0,
      'category': 'Transportation',
      'deadline': DateTime(2025, 6, 30),
    },
  ];
  
  final batch = firestore.batch();
  
  for (final goal in goals) {
    final docRef = firestore.collection('goals').doc();
    batch.set(docRef, {
      'id': docRef.id,
      'userId': userId,
      'name': goal['name'],
      'targetAmount': goal['targetAmount'],
      'currentAmount': goal['currentAmount'],
      'category': goal['category'],
      'deadline': Timestamp.fromDate(goal['deadline'] as DateTime),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }
  
  await batch.commit();
  logger.info('   ✅ Added ${goals.length} financial goals');
}

Future<void> populateBills(FirebaseFirestore firestore, String userId,
    DateTime startDate, DateTime endDate, Random random, Logger logger) async {
  
  logger.info('📄 Populating recurring bills...');
  
  final bills = [
    {'name': 'Rent', 'amount': 1200.0, 'dueDay': 1},
    {'name': 'Electricity', 'amount': 80.0, 'dueDay': 15},
    {'name': 'Internet', 'amount': 50.0, 'dueDay': 10},
    {'name': 'Phone', 'amount': 35.0, 'dueDay': 20},
    {'name': 'Insurance', 'amount': 150.0, 'dueDay': 5},
  ];
  
  final batch = firestore.batch();
  int billCount = 0;
  
  for (var month = startDate.month; month <= endDate.month; month++) {
    final year = month <= 8 ? 2024 : 2024;
    
    for (final bill in bills) {
      final docRef = firestore.collection('bills').doc();
      batch.set(docRef, {
        'id': docRef.id,
        'userId': userId,
        'name': bill['name'],
        'amount': bill['amount'],
        'dueDate': Timestamp.fromDate(DateTime(year, month, bill['dueDay'] as int)),
        'isPaid': random.nextBool(),
        'category': 'Bills & Utilities',
        'isRecurring': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      billCount++;
    }
  }
  
  await batch.commit();
  logger.info('   ✅ Added $billCount bill entries');
}

String _generateTransactionDescription(String category, Random random) {
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
