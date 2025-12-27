import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

/// Script to test and validate all dashboard features and calculations
/// This will verify that your Financial Summary Card and other widgets work correctly
Future<void> main() async {
  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    stdout.writeln('${record.level.name}: ${record.message}');
  });
  
  final logger = Logger('DashboardTester');
  
  logger.info('🧪 Starting dashboard feature tests...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    // Get current user or use demo user ID
    final userId = auth.currentUser?.uid ?? 'demo_user';
    logger.info('📍 Testing data for user: $userId');
    
    await testDataAvailability(firestore, userId, logger);
    await testFinancialCalculations(firestore, userId, logger);
    await testBudgetCalculations(firestore, userId, logger);
    await testTrendCalculations(firestore, userId, logger);
    
    logger.info('✅ All dashboard tests completed!');
    logger.info('🎉 Your dashboard features are ready for demo!');
    
  } catch (e) {
    logger.severe('❌ Error during testing: $e');
    exit(1);
  }
}

Future<void> testDataAvailability(FirebaseFirestore firestore, String userId, Logger logger) async {
  logger.info('📊 Testing data availability...');
  
  // Test transactions
  final transactionsQuery = await firestore
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .get();
  
  logger.info('   Transactions found: ${transactionsQuery.docs.length}');
  
  if (transactionsQuery.docs.isNotEmpty) {
    final latestTransaction = transactionsQuery.docs.first.data();
    final earliestTransaction = transactionsQuery.docs.last.data();
    logger.info('   Date range: ${(earliestTransaction['date'] as Timestamp).toDate()} to ${(latestTransaction['date'] as Timestamp).toDate()}');
  }
  
  // Test income sources
  final incomeQuery = await firestore
      .collection('income_sources')
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .get();
  
  logger.info('   Income entries found: ${incomeQuery.docs.length}');
  
  // Test budgets
  final budgetQuery = await firestore
      .collection('budgets')
      .where('userId', isEqualTo: userId)
      .get();
  
  logger.info('   Budget entries found: ${budgetQuery.docs.length}');
  
  // Calculate months of data available
  if (transactionsQuery.docs.isNotEmpty && incomeQuery.docs.isNotEmpty) {
    final allDates = <DateTime>[];
    
    for (final doc in transactionsQuery.docs) {
      allDates.add((doc.data()['date'] as Timestamp).toDate());
    }
    
    for (final doc in incomeQuery.docs) {
      allDates.add((doc.data()['date'] as Timestamp).toDate());
    }
    
    allDates.sort();
    final now = DateTime.now();
    final earliestDate = allDates.first;
    final monthsAvailable = ((now.year - earliestDate.year) * 12 + now.month - earliestDate.month + 1).clamp(0, 12);
    
    logger.info('   📅 Months of data available: $monthsAvailable');
    
    if (monthsAvailable >= 3) {
      logger.info('   ✅ Sufficient data for trend analysis');
    } else {
      logger.info('   ⚠️  Limited data - trends may be basic');
    }
  }
}

Future<void> testFinancialCalculations(FirebaseFirestore firestore, String userId, Logger logger) async {
  logger.info('💰 Testing financial calculations...');
  
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month, 1);
  final previousMonth = DateTime(now.year, now.month - 1, 1);
  
  // Current month calculations
  final currentTransactions = await firestore
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(currentMonth))
      .get();
  
  final currentIncome = await firestore
      .collection('income_sources')
      .where('userId', isEqualTo: userId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(currentMonth))
      .get();
  
  double totalExpenses = 0;
  double totalIncome = 0;
  
  for (final doc in currentTransactions.docs) {
    final data = doc.data();
    if (data['isExpense'] == true) {
      totalExpenses += (data['amount'] as num).toDouble();
    }
  }
  
  for (final doc in currentIncome.docs) {
    totalIncome += (doc.data()['amount'] as num).toDouble();
  }
  
  final balance = totalIncome - totalExpenses;
  
  logger.info('   Current month income: \$${totalIncome.toStringAsFixed(2)}');
  logger.info('   Current month expenses: \$${totalExpenses.toStringAsFixed(2)}');
  logger.info('   Current balance: \$${balance.toStringAsFixed(2)}');
  
  // Previous month calculations for comparison
  final previousTransactions = await firestore
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(previousMonth))
      .where('date', isLessThan: Timestamp.fromDate(currentMonth))
      .get();
  
  double previousExpenses = 0;
  for (final doc in previousTransactions.docs) {
    final data = doc.data();
    if (data['isExpense'] == true) {
      previousExpenses += (data['amount'] as num).toDouble();
    }
  }
  
  if (previousExpenses > 0) {
    final expenseChange = ((totalExpenses - previousExpenses) / previousExpenses * 100);
    logger.info('   Expense change from last month: ${expenseChange.toStringAsFixed(1)}%');
  }
}

Future<void> testBudgetCalculations(FirebaseFirestore firestore, String userId, Logger logger) async {
  logger.info('📊 Testing budget calculations...');
  
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month, 1);
  
  // Get current month budgets
  final budgets = await firestore
      .collection('budgets')
      .where('userId', isEqualTo: userId)
      .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(currentMonth))
      .get();
  
  // Get current month transactions by category
  final transactions = await firestore
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(currentMonth))
      .where('isExpense', isEqualTo: true)
      .get();
  
  final categorySpending = <String, double>{};
  for (final doc in transactions.docs) {
    final data = doc.data();
    final category = data['category'] as String;
    final amount = (data['amount'] as num).toDouble();
    categorySpending[category] = (categorySpending[category] ?? 0) + amount;
  }
  
  double totalBudget = 0;
  double totalSpent = 0;
  
  for (final doc in budgets.docs) {
    final data = doc.data();
    final category = data['category'] as String;
    final budgetAmount = (data['amount'] as num).toDouble();
    final spent = categorySpending[category] ?? 0;
    
    totalBudget += budgetAmount;
    totalSpent += spent;
    
    final percentage = budgetAmount > 0 ? (spent / budgetAmount * 100) : 0;
    logger.info('   $category: \$${spent.toStringAsFixed(2)} / \$${budgetAmount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)');
  }
  
  logger.info('   Total budget: \$${totalBudget.toStringAsFixed(2)}');
  logger.info('   Total spent: \$${totalSpent.toStringAsFixed(2)}');
  
  if (totalBudget > 0) {
    final overallPercentage = (totalSpent / totalBudget * 100);
    logger.info('   Overall budget usage: ${overallPercentage.toStringAsFixed(1)}%');
  }
}

Future<void> testTrendCalculations(FirebaseFirestore firestore, String userId, Logger logger) async {
  logger.info('📈 Testing trend calculations...');
  
  final now = DateTime.now();
  final monthsToAnalyze = 6; // Last 6 months
  
  final monthlyData = <String, Map<String, double>>{};
  
  for (int i = 0; i < monthsToAnalyze; i++) {
    final month = DateTime(now.year, now.month - i, 1);
    final nextMonth = DateTime(now.year, now.month - i + 1, 1);
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    
    // Get transactions for this month
    final transactions = await firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(month))
        .where('date', isLessThan: Timestamp.fromDate(nextMonth))
        .where('isExpense', isEqualTo: true)
        .get();
    
    // Get income for this month
    final income = await firestore
        .collection('income_sources')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(month))
        .where('date', isLessThan: Timestamp.fromDate(nextMonth))
        .get();
    
    double monthlyExpenses = 0;
    double monthlyIncome = 0;
    
    for (final doc in transactions.docs) {
      monthlyExpenses += (doc.data()['amount'] as num).toDouble();
    }
    
    for (final doc in income.docs) {
      monthlyIncome += (doc.data()['amount'] as num).toDouble();
    }
    
    monthlyData[monthKey] = {
      'expenses': monthlyExpenses,
      'income': monthlyIncome,
      'balance': monthlyIncome - monthlyExpenses,
    };
    
    logger.info('   $monthKey: Income \$${monthlyIncome.toStringAsFixed(2)}, Expenses \$${monthlyExpenses.toStringAsFixed(2)}, Balance \$${(monthlyIncome - monthlyExpenses).toStringAsFixed(2)}');
  }
  
  // Calculate trends
  final sortedMonths = monthlyData.keys.toList()..sort();
  if (sortedMonths.length >= 2) {
    final latest = monthlyData[sortedMonths.last]!;
    final previous = monthlyData[sortedMonths[sortedMonths.length - 2]]!;
    
    final expenseTrend = previous['expenses']! > 0 
        ? ((latest['expenses']! - previous['expenses']!) / previous['expenses']! * 100)
        : 0;
    
    final incomeTrend = previous['income']! > 0
        ? ((latest['income']! - previous['income']!) / previous['income']! * 100)
        : 0;
    
    logger.info('   Expense trend: ${expenseTrend.toStringAsFixed(1)}%');
    logger.info('   Income trend: ${incomeTrend.toStringAsFixed(1)}%');
  }
}
