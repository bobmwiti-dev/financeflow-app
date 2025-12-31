// ignore_for_file: unused_element

import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
// Use alias to match database_service.dart
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import 'firestore_service.dart';

import '../models/insight_model.dart';
import '../models/income_source_model.dart';
import '../models/loan_model.dart';
import '../models/transaction_model.dart' as app_models;
import '../constants/app_constants.dart';
import 'database_service.dart';

class InsightsService {
  static final InsightsService instance = InsightsService._internal();
  final DatabaseService _databaseService = DatabaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random();
  final Logger logger = Logger('InsightsService');

  InsightsService._internal();

  /// Calculates the 'In My Pocket' amount for the current month.
  /// This is a safe-to-spend estimate after accounting for goals and budgets.
  Future<double> calculateInMyPocket() async {
    final bool useFirestore = _auth.currentUser != null;
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);

    // 1. Fetch all necessary data
    final incomeSources = useFirestore
        ? await _firestoreService.getIncomeSources()
        : await _databaseService.getIncomeSources();

    final goals = useFirestore
        ? await _firestoreService.getGoals()
        : await _databaseService.getGoals();

    final budgets = useFirestore
        ? await _firestoreService.getBudgets()
        : await _databaseService.getBudgets();

    // 2. Calculate total income for the current month
    final double totalIncome = incomeSources
        .where((source) => source.date.isAfter(currentMonthStart))
        .fold(0.0, (sum, source) => sum + source.amount);

    // 3. Calculate total savings goal contributions for the month
    final double totalGoalContributions = goals
        .fold(0.0, (sum, goal) => sum + (goal.targetMonthlyContribution ?? 0.0));

    // 4. Calculate total budgeted spending for the month
    final double totalBudgetedSpending = budgets
        .fold(0.0, (sum, budget) => sum + budget.amount);

    // 5. Calculate 'In My Pocket' amount
    final inMyPocket = totalIncome - totalGoalContributions - totalBudgetedSpending;

    logger.info(
        'In My Pocket Calculation: Income (\$${totalIncome.toStringAsFixed(2)}) - Goals (\$${totalGoalContributions.toStringAsFixed(2)}) - Budgets (\$${totalBudgetedSpending.toStringAsFixed(2)}) = \$${inMyPocket.toStringAsFixed(2)}');

    return inMyPocket > 0 ? inMyPocket : 0.0;
  }

  // Generate insights based on user's financial data
  Future<List<Insight>> generateInsights() async {
    // Default to current month
    final now = DateTime.now();
    return generateInsightsForMonth(DateTime(now.year, now.month));
  }

  // Generate insights for a specific month
  Future<List<Insight>> generateInsightsForMonth(DateTime targetMonth) async {
    List<Insight> insights = [];
    
    // Decide data source based on authentication
    final bool useFirestore = _auth.currentUser != null;

    final transactions = useFirestore
        ? await _firestoreService.getTransactions()
        : await _databaseService.getTransactions();

    final budgets = useFirestore
        ? await _firestoreService.getBudgets()
        : await _databaseService.getBudgets();

    final goals = useFirestore
        ? await _firestoreService.getGoals()
        : await _databaseService.getGoals();

    final incomeSources = useFirestore
        ? await _firestoreService.getIncomeSources()
        : await _databaseService.getIncomeSources();

    final loans = useFirestore
        ? await _firestoreService.getLoans()
        : await _databaseService.getLoans();
    
    // Generate different types of insights for the target month
    insights.addAll(await _generateSpendingPatternInsights(transactions, targetMonth));
    insights.addAll(await _generateBudgetAlerts(transactions, budgets, targetMonth));
    insights.addAll(await _generateSavingOpportunities(transactions, targetMonth));
    insights.addAll(await _generateBettingInsights(transactions, goals, targetMonth));
    insights.addAll(await _generateFinancialHealthInsights(
      transactions, budgets, goals, incomeSources, loans, targetMonth
    ));
    insights.addAll(await _generateUnusualSpendingInsights(transactions, targetMonth));
    insights.addAll(await _generateSubscriptionInsights(transactions, targetMonth));
    
    // Sort insights by relevance score (descending)
    insights.sort((a, b) => (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0));
    
    return insights;
  }

  // Get insights from database
  Future<List<Insight>> getInsights() async {
    try {
      // Currently insights are stored locally even when using Firestore for source data
      return await _databaseService.getInsights();
    } catch (e) {
      logger.info('Error getting insights: $e');
      return [];
    }
  }

  // Save an insight to database
  Future<int> saveInsight(Insight insight) async {
    try {
      return await _databaseService.insertInsight(insight);
    } catch (e) {
      logger.info('Error saving insight: $e');
      return -1;
    }
  }

  // Mark insight as read
  Future<bool> markAsRead(int id) async {
    try {
      final insights = await _databaseService.getInsights();
      final insight = insights.firstWhere((i) => i.id == id, orElse: () => throw Exception('Insight not found'));
      final updatedInsight = insight.copyWith(isRead: true);
      await _databaseService.updateInsight(updatedInsight);
      return true;
    } catch (e) {
      logger.warning('Error marking insight as read: $e');
      return false;
    }
  }

  // Dismiss insight
  Future<bool> dismissInsight(int id) async {
    try {
      final insights = await _databaseService.getInsights();
      final insight = insights.firstWhere((i) => i.id == id, orElse: () => throw Exception('Insight not found'));
      final updatedInsight = insight.copyWith(isDismissed: true);
      await _databaseService.updateInsight(updatedInsight);
      return true;
    } catch (e) {
      logger.severe('Error dismissing insight: $e');
      return false;
    }
  }

  // Generate spending pattern insights
  Future<List<Insight>> _generateSpendingPatternInsights(List<app_models.TransactionModel> transactions, DateTime targetMonth) async {
    List<Insight> insights = [];
    
    if (transactions.isEmpty) return insights;
    
    // Group transactions by category
    Map<String, List<app_models.TransactionModel>> categorizedTransactions = {};
    for (var transaction in transactions) {
      if (transaction.amount < 0) { // Only consider expenses
        final category = transaction.category;
        if (!categorizedTransactions.containsKey(category)) {
          categorizedTransactions[category] = [];
        }
        categorizedTransactions[category]!.add(transaction);
      }
    }
    
    // Calculate target month and previous month
    DateTime currentMonthStart = DateTime(targetMonth.year, targetMonth.month, 1);
    DateTime previousMonthStart = DateTime(targetMonth.year, targetMonth.month - 1, 1);
    
    // Analyze spending patterns for each category
    categorizedTransactions.forEach((category, categoryTransactions) {
      // Calculate total spent in current and previous month
      double currentMonthTotal = categoryTransactions
          .where((t) => t.date.isAfter(currentMonthStart))
          .fold(0, (sum, t) => sum + t.amount);
      
      double previousMonthTotal = categoryTransactions
          .where((t) => t.date.isAfter(previousMonthStart) && t.date.isBefore(currentMonthStart))
          .fold(0, (sum, t) => sum + t.amount);
      
      // Only create insight if we have previous month data
      if (previousMonthTotal != 0) {
        // Calculate percentage change
        double percentageChange = ((currentMonthTotal - previousMonthTotal) / previousMonthTotal) * 100;
        
        // Only create insight if change is significant (more than 20%)
        if (percentageChange.abs() >= 20) {
          final insight = Insight(
            id: DateTime.now().millisecondsSinceEpoch + category.hashCode,
            title: '${percentageChange > 0 ? 'Increased' : 'Decreased'} spending on $category',
            description: 'Your spending on $category has ${percentageChange > 0 ? 'increased' : 'decreased'} by ${percentageChange.abs().toStringAsFixed(1)}% compared to last month.',
            type: percentageChange > 0 ? 'warning' : 'positive',
            date: targetMonth,
            data: {
              'category': category,
              'percentageChange': percentageChange,
              'previousAmount': previousMonthTotal,
              'currentAmount': currentMonthTotal,
              'timeFrame': 'month',
              'analysisMonth': DateFormat('yyyy-MM').format(targetMonth),
            },
            relevanceScore: min(1.0, percentageChange.abs() / 100),
          );
          
          insights.add(insight);
        }
      }
    });
    
    return insights;
  }

  // Generate budget alerts
  Future<List<Insight>> _generateBudgetAlerts(List<app_models.TransactionModel> transactions, List<Budget> budgets, DateTime targetMonth) async {
    List<Insight> insights = [];
    
    if (budgets.isEmpty) return insights;
    
    final currentMonth = DateTime(targetMonth.year, targetMonth.month);
    
    // Check each budget
    for (var budget in budgets) {
      // Get transactions for this category in the current month
      final categoryTransactions = transactions.where((t) => 
        t.category == budget.category && 
        t.date.year == currentMonth.year && 
        t.date.month == currentMonth.month &&
        t.amount < 0 // Only expenses
      ).toList();
      
      if (categoryTransactions.isEmpty) continue;
      
      // Calculate total spent
      final totalSpent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
      
      // Calculate percentage of budget used
      final percentageUsed = (totalSpent / budget.amount) * 100;
      
      // Create alerts based on percentage used
      if (percentageUsed >= 90) {
        final insight = Insight(
          id: DateTime.now().millisecondsSinceEpoch + budget.category.hashCode,
          title: 'Budget for ${budget.category} almost depleted',
          description: 'You\'ve used ${percentageUsed.toStringAsFixed(1)}% of your ${budget.category} budget for this month.',
          type: 'warning',
          date: targetMonth,
          data: {
            'category': budget.category,
            'budgetAmount': budget.amount,
            'spentAmount': totalSpent,
            'percentageUsed': percentageUsed,
            'analysisMonth': DateFormat('yyyy-MM').format(targetMonth),
          },
          relevanceScore: min(1.0, percentageUsed / 100),
        );
        
        insights.add(insight);
      } else if (percentageUsed >= 75 && targetMonth.day <= 20) {
        // If we've used 75% of budget but we're only 2/3 through the month
        final insight = Insight(
          id: DateTime.now().millisecondsSinceEpoch + budget.category.hashCode + 1,
          title: 'High spending rate on ${budget.category}',
          description: 'You\'ve already used ${percentageUsed.toStringAsFixed(1)}% of your ${budget.category} budget, but we\'re only ${(targetMonth.day / 30 * 100).toStringAsFixed(1)}% through the month.',
          type: 'warning',
          date: targetMonth,
          data: {
            'category': budget.category,
            'budgetAmount': budget.amount,
            'spentAmount': totalSpent,
            'percentageUsed': percentageUsed,
            'analysisMonth': DateFormat('yyyy-MM').format(targetMonth),
          },
          relevanceScore: min(0.9, percentageUsed / 100),
        );
        
        insights.add(insight);
      }
    }
    
    return insights;
  }

  // Generate saving opportunities
  Future<List<Insight>> _generateSavingOpportunities(List<app_models.TransactionModel> transactions, DateTime targetMonth) async {
    final List<Insight> insights = [];
    
    if (transactions.isEmpty) return insights;
    
    // Initialize categorized transactions map
    final Map<String, List<app_models.TransactionModel>> categorizedTransactions = {};
    
    // Group transactions by category
    for (var transaction in transactions) {
      if (transaction.amount < 0) { // Only consider expenses
        final category = transaction.category;
        categorizedTransactions.putIfAbsent(category, () => []).add(transaction);
      }
    }
    
    // Calculate total spending for percentage calculations
    final totalSpending = transactions
        .where((t) => t.amount < 0) // Only expenses
        .fold(0.0, (sum, t) => sum + t.amount.abs());
        
    if (totalSpending <= 0) return insights; // No spending to analyze
    
    // Analyze each category for potential savings
    for (var category in categorizedTransactions.keys) {
      final categoryTransactions = categorizedTransactions[category]!;
      
      // Calculate total spent in this category
      final totalSpent = categoryTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
      final percentageOfTotal = (totalSpent / totalSpending * 100);
      
      // Only analyze categories that are a significant portion of spending (>10%)
      if (percentageOfTotal > 10) {
        // Get saving suggestions for this category
        final suggestion = _getSavingSuggestion(category, totalSpent);
        if (suggestion != null) {
          insights.add(Insight(
            id: DateTime.now().millisecondsSinceEpoch + category.hashCode,
            title: 'Potential Savings in $category',
            description: 'You\'ve spent ${NumberFormat.currency(symbol: '\$').format(totalSpent)} on $category (${percentageOfTotal.toStringAsFixed(1)}% of total spending). $suggestion',
            type: 'recommendation',
            date: targetMonth,
            data: {
              'category': category,
              'amount': totalSpent,
              'percentage': percentageOfTotal,
              'analysisMonth': DateFormat('yyyy-MM').format(targetMonth),
            },
            relevanceScore: min(0.8, totalSpent / 1000),
          ));
        }
      }
    }
    
    // Add general saving tips if no specific insights were generated
    if (insights.isEmpty) {
      final generalTips = [
        'Consider reviewing your monthly subscriptions and cancel any you no longer use.',
        'Try setting a weekly spending limit for discretionary expenses.',
        'Meal planning can help reduce food waste and save money on groceries.',
        'Use cashback apps when shopping online to earn money back on purchases.'
      ];
      
      final randomTip = generalTips[_random.nextInt(generalTips.length)];
      insights.add(Insight(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'General Saving Tip',
        description: randomTip,
        type: 'general',
        date: DateTime.now(),
        data: {'category': 'General'},
      ));
    }
    
    return insights;
  }

  Future<List<Insight>> _generateBettingInsights(
    List<app_models.TransactionModel> transactions,
    List<Goal> goals,
    DateTime targetMonth,
  ) async {
    final List<Insight> insights = [];

    if (transactions.isEmpty) {
      return insights;
    }

    final bettingKeywords = <String>[
      'sportpesa',
      'betika',
      '22bet',
      'mozzart',
      'odibets',
      'betway',
      'shabiki',
      'mcheza',
      'betlion',
    ];

    final funKeywords = <String>[
      'club',
      'pub',
      'lounge',
      'bar ',
      'wine & spirits',
    ];

    final int year = targetMonth.year;
    final int month = targetMonth.month;

    double monthlyBetting = 0;
    double yearlyBetting = 0;

    for (final t in transactions) {
      if (!t.isExpense) continue;

      final text = '${t.title} ${t.description ?? ''} ${t.category}'.toLowerCase();
      final matchesKeyword =
          bettingKeywords.any((k) => text.contains(k)) ||
          funKeywords.any((k) => text.contains(k));
      if (!matchesKeyword) continue;

      final amount = t.amount.abs();

      if (t.date.year == year && t.date.month == month) {
        monthlyBetting += amount;
      }

      if (t.date.year == year) {
        yearlyBetting += amount;
      }
    }

    if (monthlyBetting <= 0 && yearlyBetting <= 0) {
      return insights;
    }

    final emergencyGoals = goals
        .where((g) => g.category == 'Emergency Fund')
        .toList();
    final double emergencyTarget = emergencyGoals.isNotEmpty
        ? emergencyGoals.first.targetAmount
        : 0.0;

    double? emergencyRatio;
    if (emergencyTarget > 0) {
      emergencyRatio = yearlyBetting / emergencyTarget;
    }

    final currencyFormat =
        NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    final monthStr = currencyFormat.format(monthlyBetting);
    final yearStr = currencyFormat.format(yearlyBetting);

    String description =
        'You have spent $monthStr on betting and fun this month, and $yearStr so far this year.';

    if (emergencyRatio != null && emergencyRatio > 0) {
      final ratioPercent =
          (emergencyRatio * 100).clamp(0, 999).toStringAsFixed(0);
      description +=
          ' This equals about $ratioPercent% of your Emergency Fund goal.';
    }

    if (monthlyBetting > 2000) {
      description +=
          ' Consider capping betting and fun spending at around KSh 2,000 per month to protect your savings.';
    }

    final isHighLeakage = emergencyRatio != null && emergencyRatio >= 0.3;

    final insight = Insight(
      id: DateTime.now().millisecondsSinceEpoch,
      title: isHighLeakage
          ? 'High betting and fun spending detected'
          : 'Betting and fun spending overview',
      description: description,
      type: 'Expense Anomaly',
      date: targetMonth,
      data: {
        'monthlyBetting': monthlyBetting,
        'yearlyBetting': yearlyBetting,
        'emergencyTarget': emergencyTarget,
        'emergencyRatio': emergencyRatio,
        'analysisMonth': DateFormat('yyyy-MM').format(targetMonth),
      },
      relevanceScore: isHighLeakage ? 0.95 : 0.7,
    );

    insights.add(insight);

    return insights;
  }

  // Helper method to get a saving suggestion for a category
  String? _getSavingSuggestion(String category, double amount) {
    final Map<String, List<String>> savingSuggestions = {
      'Food & Drinks': [
        'Meal planning can save up to 20% on grocery bills.',
        'Consider batch cooking on weekends to reduce takeout spending.',
        'Use cashback apps for grocery shopping to earn money back.',
      ],
      'Transportation': [
        'Carpooling 2-3 times a week can save ~30% on fuel costs.',
        'Regular vehicle maintenance improves fuel efficiency by up to 40%.',
        'Compare gas prices using apps to find the best deals in your area.',
      ],
      'Entertainment': [
        'Many museums offer free admission days each month.',
        'Consider a monthly entertainment budget to control spending.',
        'Look for "buy one, get one" deals for movies and events.',
      ],
      'Shopping': [
        'Make a shopping list and stick to it to avoid impulse purchases.',
        'Wait for sales before making major purchases.',
        'Consider buying used or refurbished items when appropriate.',
      ],
    };
    
    if (savingSuggestions.containsKey(category)) {
      final suggestions = savingSuggestions[category]!;
      return suggestions[_random.nextInt(suggestions.length)];
    }
    
    return null;
  }

  // Generate unusual spending alerts
  Future<List<Insight>> _generateUnusualSpendingInsights(List<app_models.TransactionModel> transactions, DateTime targetMonth) async {
    final List<Insight> insights = [];
    if (transactions.length < 10) return insights; // Not enough data for meaningful stats

    // 1. Group expense transactions by category
    final Map<String, List<app_models.TransactionModel>> categorizedExpenses = {};
    for (var transaction in transactions) {
      if (transaction.isExpense) {
        categorizedExpenses.putIfAbsent(transaction.category, () => []).add(transaction);
      }
    }

    // 2. Analyze each category for outliers
    for (var entry in categorizedExpenses.entries) {
      final category = entry.key;
      final categoryTransactions = entry.value;

      // Need at least 5 transactions for a meaningful calculation
      if (categoryTransactions.length < 5) continue;

      // 3. Calculate mean and standard deviation
      final amounts = categoryTransactions.map((t) => t.amount.abs()).toList();
      final sum = amounts.reduce((a, b) => a + b);
      final mean = sum / amounts.length;

      final variance = amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / amounts.length;
      final stdDev = sqrt(variance);

      // 4. Define the threshold for an anomaly (e.g., 2 standard deviations above the mean)
      final threshold = mean + (2 * stdDev);

      // 5. Find transactions that exceed the threshold
      for (var transaction in categoryTransactions) {
        if (transaction.amount.abs() > threshold) {
                    final currencyFormat = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2);
          final insight = Insight(
            id: DateTime.now().millisecondsSinceEpoch + transaction.id.hashCode,
            title: 'Unusual Spending in $category',
                                                description: 'You spent ${currencyFormat.format(transaction.amount.abs())} on \'${transaction.title}\' which is much higher than your average of ${currencyFormat.format(mean)} for this category.',
            type: 'warning',
            date: transaction.date,
            data: {
              'transactionId': transaction.id,
              'category': category,
              'amount': transaction.amount.abs(),
              'mean': mean,
              'stdDev': stdDev,
              'analysisMonth': DateFormat('yyyy-MM').format(targetMonth),
            },
            relevanceScore: 0.9, // High relevance for unusual activity
          );
          insights.add(insight);
        }
      }
    }

    return insights;
  }

  // Generate financial health insights
  Future<List<Insight>> _generateFinancialHealthInsights(
    List<app_models.TransactionModel> transactions,
    List<Budget> budgets,
    List<Goal> goals,
    List<IncomeSource> incomeSources,
    List<Loan> loans,
    DateTime targetMonth,
  ) async {
    List<Insight> insights = [];
    
    if (transactions.isEmpty) return insights;
    
    // Calculate total income
    final totalIncome = incomeSources.fold(0.0, (sum, source) => sum + source.amount);
    
    // Calculate total expenses (monthly average)
    final expenses = transactions.where((t) => t.amount < 0).toList();
    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount.abs());
    final monthsSpan = _calculateMonthsSpan(expenses);
    final averageMonthlyExpenses = monthsSpan > 0 ? totalExpenses / monthsSpan : 0;
    
    // Calculate savings rate
    final savingsRate = totalIncome > 0 ? (totalIncome - averageMonthlyExpenses) / totalIncome : 0;
    
    // Calculate debt-to-income ratio
    final totalDebt = loans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);
    final debtToIncomeRatio = totalIncome > 0 ? totalDebt / totalIncome : 0;
    
    // Calculate emergency fund in months
    final emergencyFund = goals.where((g) => g.category == 'Emergency Fund').fold(0.0, (sum, g) => sum + g.currentAmount);
    final emergencyFundMonths = averageMonthlyExpenses > 0 ? emergencyFund / averageMonthlyExpenses : 0;
    
    // Determine overall financial health
    String overallHealth;
    List<String> recommendations = [];
    
    if (savingsRate >= AppConstants.goodSavingsRateThreshold &&
        debtToIncomeRatio <= AppConstants.goodDebtToIncomeRatio &&
        emergencyFundMonths >= AppConstants.goodEmergencyFundMonths) {
      overallHealth = 'good';
      recommendations.add('Your financial health is excellent! Consider increasing your investments for long-term growth.');
    } else if (savingsRate >= AppConstants.moderateSavingsRateThreshold &&
               debtToIncomeRatio <= AppConstants.moderateDebtToIncomeRatio &&
               emergencyFundMonths >= AppConstants.moderateEmergencyFundMonths) {
      overallHealth = 'moderate';
      
      if (savingsRate < AppConstants.goodSavingsRateThreshold) {
        recommendations.add('Try to increase your savings rate to at least ${(AppConstants.goodSavingsRateThreshold * 100).toStringAsFixed(0)}% of your income.');
      }
      
      if (debtToIncomeRatio > AppConstants.goodDebtToIncomeRatio) {
        recommendations.add('Work on reducing your debt-to-income ratio below ${(AppConstants.goodDebtToIncomeRatio * 100).toStringAsFixed(0)}%.');
      }
      
      if (emergencyFundMonths < AppConstants.goodEmergencyFundMonths) {
        recommendations.add('Build your emergency fund to cover at least ${AppConstants.goodEmergencyFundMonths.toStringAsFixed(0)} months of expenses.');
      }
    } else {
      overallHealth = 'poor';
      
      if (savingsRate < AppConstants.moderateSavingsRateThreshold) {
        recommendations.add('Increase your savings rate by reducing non-essential expenses.');
      }
      
      if (debtToIncomeRatio > AppConstants.moderateDebtToIncomeRatio) {
        recommendations.add('Focus on paying down high-interest debt as quickly as possible.');
      }
      
      if (emergencyFundMonths < AppConstants.moderateEmergencyFundMonths) {
        recommendations.add('Prioritize building an emergency fund to cover at least ${AppConstants.moderateEmergencyFundMonths.toStringAsFixed(0)} months of expenses.');
      }
    }
    
    final insight = Insight(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Your Financial Health: ${overallHealth.substring(0, 1).toUpperCase()}${overallHealth.substring(1)}',
      description: 'Based on your savings rate, debt levels, and emergency fund, your financial health is $overallHealth.',
      type: overallHealth == 'good' ? 'positive' : overallHealth == 'moderate' ? 'neutral' : 'warning',
      date: targetMonth,
      data: {
        'savingsRate': savingsRate,
        'debtToIncomeRatio': debtToIncomeRatio,
        'emergencyFundMonths': emergencyFundMonths,
        'overallHealth': overallHealth,
      'analysisMonth': DateFormat('yyyy-MM').format(targetMonth),
        'recommendations': recommendations,
      },
      relevanceScore: 1.0, // Financial health is always highly relevant
    );
    
    insights.add(insight);
    
    return insights;
  }

  // Helper method to calculate months span in a list of transactions
  int _calculateMonthsSpan(List<app_models.TransactionModel> transactions) {
    if (transactions.isEmpty) return 0;
    
    // Find earliest and latest dates
    DateTime? earliest;
    DateTime? latest;
    
    for (var transaction in transactions) {
      if (earliest == null || transaction.date.isBefore(earliest)) {
        earliest = transaction.date;
      }
      
      if (latest == null || transaction.date.isAfter(latest)) {
        latest = transaction.date;
      }
    }
    
    if (earliest == null || latest == null) return 0;
    
    // Calculate difference in months
    return (latest.year - earliest.year) * 12 + latest.month - earliest.month + 1;
  }

  // Generate subscription detection insights
  Future<List<Insight>> _generateSubscriptionInsights(List<app_models.TransactionModel> transactions, DateTime targetMonth) async {
    final List<Insight> insights = [];
    if (transactions.length < 3) return insights; // Need at least a few transactions

    // 1. Group transactions by payee/title
    final Map<String, List<app_models.TransactionModel>> byPayee = {};
    for (var t in transactions) {
      final title = t.title;
      if (t.isExpense && title.isNotEmpty) {
        byPayee.putIfAbsent(title, () => []).add(t);
      }
    }

    // 2. Analyze each payee for recurring patterns
    for (var entry in byPayee.entries) {
      final payee = entry.key;
      final payeeTransactions = entry.value;

      if (payeeTransactions.length < 2) continue; // Need at least 2 transactions to find a pattern

      // Sort by date to analyze intervals
      payeeTransactions.sort((a, b) => a.date.compareTo(b.date));

      // 3. Look for monthly patterns
      for (int i = 0; i < payeeTransactions.length - 1; i++) {
        final t1 = payeeTransactions[i];
        final t2 = payeeTransactions[i + 1];

        final daysBetween = t2.date.difference(t1.date).inDays;
        final amountDifference = (t1.amount - t2.amount).abs();

        // Check for monthly interval (28-32 days) and similar amount (e.g., within 10% variance)
        if ((daysBetween >= 28 && daysBetween <= 32) && (amountDifference / t1.amount.abs() < 0.10)) {
          // Potential subscription found
          final currencyFormat = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2);
          final insight = Insight(
            id: DateTime.now().millisecondsSinceEpoch + payee.hashCode,
            title: 'Potential Subscription Found',
            description: 'We noticed a recurring payment to \'$payee\' for around ${currencyFormat.format(t1.amount.abs())}. Would you like to track this as a monthly subscription?',
            type: 'recommendation',
            date: t2.date, // Use the date of the last transaction
            data: {
              'payee': payee,
              'amount': t1.amount.abs(),
              'transactionId1': t1.id,
              'transactionId2': t2.id,
              'analysisMonth': DateFormat('yyyy-MM').format(targetMonth),
            },
            relevanceScore: 0.75, // Moderately high relevance
          );
          
          // Avoid adding duplicate insights for the same subscription
                    if (!insights.any((i) => i.data?['payee'] == payee)) {
            insights.add(insight);
          }
          break; // Move to the next payee once a pattern is found
        }
      }
    }

    return insights;
  }
}