import 'package:flutter/material.dart';
import '../models/action_item_model.dart';
import '../models/transaction_model.dart';
import '../models/income_source_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/bill_model.dart';
import '../models/time_period_model.dart';

class ActionItemsService {
  /// Generate intelligent action items based on user's financial data
  static List<ActionItem> generateActionItems({
    required List<Transaction> allTransactions,
    required List<IncomeSource> allIncomeSources,
    required List<Budget> allBudgets,
    required List<Goal> allGoals,
    required List<Bill> allBills,
    required TimePeriod currentPeriod,
  }) {
    final actionItems = <ActionItem>[];
    final now = DateTime.now();

    // 1. Budget Alerts
    actionItems.addAll(_generateBudgetAlerts(
      allTransactions,
      allBudgets,
      currentPeriod,
      now,
    ));

    // 2. Goal Alerts
    actionItems.addAll(_generateGoalAlerts(
      allGoals,
      now,
    ));

    // 3. Bill Reminders
    actionItems.addAll(_generateBillReminders(
      allBills,
      now,
    ));

    // 4. M-Pesa Alerts (Kenya-specific)
    actionItems.addAll(_generateMPesaAlerts(
      allTransactions,
      currentPeriod,
      now,
    ));

    // 5. Savings Opportunities
    actionItems.addAll(_generateSavingsOpportunities(
      allTransactions,
      currentPeriod,
      now,
    ));

    // 6. Debt Alerts
    actionItems.addAll(_generateDebtAlerts(
      allGoals,
      now,
    ));

    // 7. Category Review Suggestions
    actionItems.addAll(_generateCategoryReviewSuggestions(
      allTransactions,
      currentPeriod,
      now,
    ));

    // Sort by urgency score (highest first)
    actionItems.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));

    // Return top 10 most important action items
    return actionItems.take(10).toList();
  }

  /// Generate navigation shortcuts based on user's data and activity
  static List<NavigationShortcut> generateNavigationShortcuts({
    required List<Transaction> allTransactions,
    required List<IncomeSource> allIncomeSources,
    required List<Budget> allBudgets,
    required List<Goal> allGoals,
    required List<Bill> allBills,
  }) {
    final shortcuts = <NavigationShortcut>[];

    // Core navigation shortcuts
    shortcuts.addAll([
      // Spending Heatmap
      NavigationShortcut(
        id: 'heatmap',
        type: NavigationShortcutType.analysis,
        title: 'Spending Heatmap',
        description: 'Visual calendar of your spending patterns',
        route: '/spending_heatmap',
        icon: Icons.calendar_view_month,
        color: Colors.purple,
        badge: _getTransactionCountBadge(allTransactions),
        priority: 100,
      ),

      // Cash Flow Forecast (Dashboard)
      NavigationShortcut(
        id: 'cash_flow',
        type: NavigationShortcutType.analysis,
        title: 'Cash Flow Forecast',
        description: 'Detailed 3-month financial projection',
        route: '/dashboard',
        arguments: {'focus': 'cash_flow'},
        icon: Icons.trending_up,
        color: Colors.blue,
        priority: 90,
      ),

      // Goals Management
      NavigationShortcut(
        id: 'goals',
        type: NavigationShortcutType.management,
        title: 'Financial Goals',
        description: 'Track progress on your savings goals',
        route: '/goals',
        icon: Icons.flag,
        color: Colors.green,
        badge: _getActiveGoalsBadge(allGoals),
        priority: 85,
      ),

      // Budget Management
      NavigationShortcut(
        id: 'budgets',
        type: NavigationShortcutType.management,
        title: 'Budget Manager',
        description: 'Review and adjust your budgets',
        route: '/budgets',
        icon: Icons.account_balance_wallet,
        color: Colors.orange,
        badge: _getBudgetAlertsBadge(allBudgets, allTransactions),
        priority: 80,
      ),

      // Bills & Subscriptions
      NavigationShortcut(
        id: 'bills',
        type: NavigationShortcutType.management,
        title: 'Bills & Subscriptions',
        description: 'Manage recurring payments',
        route: '/bills',
        icon: Icons.receipt_long,
        color: Colors.red,
        badge: _getUpcomingBillsBadge(allBills),
        priority: 75,
      ),

      // M-Pesa Import (Kenya-specific)
      NavigationShortcut(
        id: 'mpesa',
        type: NavigationShortcutType.feature,
        title: 'M-Pesa Import',
        description: 'Import M-Pesa transaction history',
        route: '/mpesa_import',
        icon: Icons.phone_android,
        color: Colors.teal,
        priority: 70,
      ),

      // Family Finance
      NavigationShortcut(
        id: 'family',
        type: NavigationShortcutType.feature,
        title: 'Family Finance',
        description: 'Manage shared expenses and budgets',
        route: '/family',
        icon: Icons.family_restroom,
        color: Colors.indigo,
        priority: 65,
      ),

      // Insights Screen
      NavigationShortcut(
        id: 'insights',
        type: NavigationShortcutType.analysis,
        title: 'Financial Insights',
        description: 'AI-powered spending analysis',
        route: '/insights',
        icon: Icons.psychology,
        color: Colors.deepPurple,
        priority: 60,
      ),
    ]);

    // Sort by priority (highest first)
    shortcuts.sort((a, b) => b.priority.compareTo(a.priority));

    return shortcuts;
  }

  /// Generate quick insights for summary display
  static List<QuickInsight> generateQuickInsights({
    required List<Transaction> allTransactions,
    required List<IncomeSource> allIncomeSources,
    required List<Budget> allBudgets,
    required List<Goal> allGoals,
    required TimePeriod currentPeriod,
  }) {
    final insights = <QuickInsight>[];
    final now = DateTime.now();

    // Current period transactions
    final currentTransactions = allTransactions
        .where((tx) => currentPeriod.containsDate(tx.date))
        .toList();

    final currentExpenses = currentTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());

    final currentIncome = allIncomeSources
        .where((income) => currentPeriod.containsDate(income.date))
        .fold(0.0, (sum, income) => sum + income.amount);

    // Previous period for comparison
    final previousPeriod = currentPeriod.getPreviousPeriod();
    final previousTransactions = allTransactions
        .where((tx) => previousPeriod.containsDate(tx.date))
        .toList();

    final previousExpenses = previousTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());

    // Spending insight
    final expenseChange = previousExpenses > 0 
        ? ((currentExpenses - previousExpenses) / previousExpenses) * 100
        : 0.0;

    insights.add(QuickInsight(
      id: 'spending',
      title: 'Total Spending',
      value: '\$${currentExpenses.toStringAsFixed(0)}',
      description: 'This ${currentPeriod.type.name}',
      icon: Icons.shopping_cart,
      color: Colors.red,
      trend: expenseChange > 5 ? 'up' : expenseChange < -5 ? 'down' : 'stable',
      changePercentage: expenseChange,
    ));

    // Savings rate insight
    final savingsRate = currentIncome > 0 
        ? ((currentIncome - currentExpenses) / currentIncome) * 100
        : 0.0;

    insights.add(QuickInsight(
      id: 'savings_rate',
      title: 'Savings Rate',
      value: '${savingsRate.toStringAsFixed(1)}%',
      description: 'Of income saved',
      icon: Icons.savings,
      color: savingsRate >= 20 ? Colors.green : savingsRate >= 10 ? Colors.orange : Colors.red,
    ));

    // Budget utilization insight
    final activeBudgets = allBudgets.where((budget) => 
        currentPeriod.containsDate(budget.startDate) ||
        currentPeriod.containsDate(budget.endDate) ||
        (budget.startDate.isBefore(currentPeriod.startDate) && 
         budget.endDate.isAfter(currentPeriod.endDate))).toList();

    if (activeBudgets.isNotEmpty) {
      final totalBudget = activeBudgets.fold(0.0, (sum, budget) => sum + budget.amount);
      final budgetUtilization = totalBudget > 0 ? (currentExpenses / totalBudget) * 100 : 0.0;

      insights.add(QuickInsight(
        id: 'budget_utilization',
        title: 'Budget Used',
        value: '${budgetUtilization.toStringAsFixed(1)}%',
        description: 'Of total budget',
        icon: Icons.account_balance_wallet,
        color: budgetUtilization >= 90 ? Colors.red : budgetUtilization >= 75 ? Colors.orange : Colors.green,
      ));
    }

    // Active goals insight
    final activeGoals = allGoals.where((goal) => 
        goal.targetDate?.isAfter(now) == true && goal.currentAmount < goal.targetAmount).length;

    if (activeGoals > 0) {
      insights.add(QuickInsight(
        id: 'active_goals',
        title: 'Active Goals',
        value: activeGoals.toString(),
        description: 'In progress',
        icon: Icons.flag,
        color: Colors.blue,
      ));
    }

    return insights;
  }

  // Private helper methods for generating specific action items

  static List<ActionItem> _generateBudgetAlerts(
    List<Transaction> transactions,
    List<Budget> budgets,
    TimePeriod currentPeriod,
    DateTime now,
  ) {
    final actionItems = <ActionItem>[];

    for (final budget in budgets) {
      // Check if budget is active in current period
      if (!currentPeriod.containsDate(budget.startDate) && 
          !currentPeriod.containsDate(budget.endDate) &&
          !(budget.startDate.isBefore(currentPeriod.startDate) && 
            budget.endDate.isAfter(currentPeriod.endDate))) {
        continue;
      }

      // Calculate spending for this budget category
      final categorySpending = transactions
          .where((tx) => 
              tx.type == TransactionType.expense &&
              tx.category == budget.category &&
              currentPeriod.containsDate(tx.date))
          .fold(0.0, (sum, tx) => sum + tx.amount.abs());

      final utilizationPercentage = (categorySpending / budget.amount) * 100;

      // Generate alerts based on utilization
      if (utilizationPercentage >= 90) {
        actionItems.add(ActionItem(
          id: 'budget_alert_${budget.id}',
          type: ActionItemType.budgetAlert,
          priority: utilizationPercentage >= 100 ? ActionItemPriority.urgent : ActionItemPriority.high,
          title: '${budget.category} Budget Alert',
          description: 'You\'ve used ${utilizationPercentage.toStringAsFixed(0)}% of your ${budget.category} budget (\$${categorySpending.toStringAsFixed(0)} of \$${budget.amount.toStringAsFixed(0)})',
          actionText: 'Review Budget',
          targetRoute: '/budgets',
          routeArguments: {'category': budget.category},
          createdAt: now,
          amount: categorySpending,
          category: budget.category,
          metadata: {
            'budget_id': budget.id,
            'utilization_percentage': utilizationPercentage,
            'budget_amount': budget.amount,
            'spent_amount': categorySpending,
          },
        ));
      } else if (utilizationPercentage >= 75) {
        actionItems.add(ActionItem(
          id: 'budget_warning_${budget.id}',
          type: ActionItemType.budgetAlert,
          priority: ActionItemPriority.medium,
          title: '${budget.category} Budget Warning',
          description: 'You\'re at ${utilizationPercentage.toStringAsFixed(0)}% of your ${budget.category} budget',
          actionText: 'Monitor Spending',
          targetRoute: '/budgets',
          routeArguments: {'category': budget.category},
          createdAt: now,
          amount: categorySpending,
          category: budget.category,
          metadata: {
            'budget_id': budget.id,
            'utilization_percentage': utilizationPercentage,
          },
        ));
      }
    }

    return actionItems;
  }

  static List<ActionItem> _generateGoalAlerts(
    List<Goal> goals,
    DateTime now,
  ) {
    final actionItems = <ActionItem>[];

    for (final goal in goals) {
      if (goal.currentAmount >= goal.targetAmount) continue; // Goal already achieved

      final daysUntilTarget = goal.targetDate?.difference(now).inDays ?? 0;
      final remainingAmount = goal.targetAmount - goal.currentAmount;
      final progressPercentage = (goal.currentAmount / goal.targetAmount) * 100;

      // Generate alerts based on progress and time remaining
      if (daysUntilTarget <= 30 && progressPercentage < 80) {
        actionItems.add(ActionItem(
          id: 'goal_alert_${goal.id}',
          type: ActionItemType.goalAlert,
          priority: daysUntilTarget <= 7 ? ActionItemPriority.urgent : ActionItemPriority.high,
          title: '${goal.name} Goal Alert',
          description: 'Only $daysUntilTarget days left to reach your goal. You need \$${remainingAmount.toStringAsFixed(0)} more.',
          actionText: 'Review Goal',
          targetRoute: '/goals',
          routeArguments: {'goal_id': goal.id},
          createdAt: now,
          dueDate: goal.targetDate,
          amount: remainingAmount,
          metadata: {
            'goal_id': goal.id,
            'progress_percentage': progressPercentage,
            'days_remaining': daysUntilTarget,
          },
        ));
      } else if (progressPercentage < 25 && daysUntilTarget <= 90) {
        actionItems.add(ActionItem(
          id: 'goal_progress_${goal.id}',
          type: ActionItemType.goalAlert,
          priority: ActionItemPriority.medium,
          title: '${goal.name} Needs Attention',
          description: 'You\'re at ${progressPercentage.toStringAsFixed(0)}% progress with $daysUntilTarget days remaining.',
          actionText: 'Update Goal',
          targetRoute: '/goals',
          routeArguments: {'goal_id': goal.id},
          createdAt: now,
          dueDate: goal.targetDate,
          amount: remainingAmount,
          metadata: {
            'goal_id': goal.id,
            'progress_percentage': progressPercentage,
          },
        ));
      }
    }

    return actionItems;
  }

  static List<ActionItem> _generateBillReminders(
    List<Bill> bills,
    DateTime now,
  ) {
    final actionItems = <ActionItem>[];

    for (final bill in bills) {
      final daysUntilDue = bill.dueDate.difference(now).inDays;

      if (daysUntilDue <= 7 && daysUntilDue >= 0) {
        actionItems.add(ActionItem(
          id: 'bill_reminder_${bill.id}',
          type: ActionItemType.billReminder,
          priority: daysUntilDue <= 1 ? ActionItemPriority.urgent : 
                   daysUntilDue <= 3 ? ActionItemPriority.high : ActionItemPriority.medium,
          title: '${bill.name} Due Soon',
          description: '${bill.name} (\$${bill.amount.toStringAsFixed(2)}) is due in $daysUntilDue day${daysUntilDue == 1 ? '' : 's'}',
          actionText: 'View Bills',
          targetRoute: '/bills',
          routeArguments: {'bill_id': bill.id},
          createdAt: now,
          dueDate: bill.dueDate,
          amount: bill.amount,
          metadata: {
            'bill_id': bill.id,
            'days_until_due': daysUntilDue,
          },
        ));
      }
    }

    return actionItems;
  }

  static List<ActionItem> _generateMPesaAlerts(
    List<Transaction> transactions,
    TimePeriod currentPeriod,
    DateTime now,
  ) {
    final actionItems = <ActionItem>[];

    // Find M-Pesa related transactions
    final mpesaTransactions = transactions
        .where((tx) => 
            currentPeriod.containsDate(tx.date) &&
            (tx.title.toLowerCase().contains('mpesa') ||
             tx.title.toLowerCase().contains('safaricom') ||
             tx.title.toLowerCase().contains('airtime') ||
             tx.category.toLowerCase().contains('mobile')))
        .toList();

    if (mpesaTransactions.isNotEmpty) {
      final mpesaTotal = mpesaTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
      
      // Previous period comparison
      final previousPeriod = currentPeriod.getPreviousPeriod();
      final previousMpesaTransactions = transactions
          .where((tx) => 
              previousPeriod.containsDate(tx.date) &&
              (tx.title.toLowerCase().contains('mpesa') ||
               tx.title.toLowerCase().contains('safaricom') ||
               tx.title.toLowerCase().contains('airtime') ||
               tx.category.toLowerCase().contains('mobile')))
          .toList();

      final previousMpesaTotal = previousMpesaTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());

      if (previousMpesaTotal > 0) {
        final changePercentage = ((mpesaTotal - previousMpesaTotal) / previousMpesaTotal) * 100;

        if (changePercentage.abs() > 50) {
          actionItems.add(ActionItem(
            id: 'mpesa_alert_${now.millisecondsSinceEpoch}',
            type: ActionItemType.mpesaAlert,
            priority: ActionItemPriority.medium,
            title: 'M-Pesa Activity Change',
            description: 'M-Pesa spending ${changePercentage > 0 ? 'increased' : 'decreased'} by ${changePercentage.abs().toStringAsFixed(0)}% this ${currentPeriod.type.name}',
            actionText: 'Analyze M-Pesa',
            targetRoute: '/mpesa_import',
            createdAt: now,
            amount: mpesaTotal,
            metadata: {
              'change_percentage': changePercentage,
              'current_total': mpesaTotal,
              'previous_total': previousMpesaTotal,
              'transaction_count': mpesaTransactions.length,
            },
          ));
        }
      }
    }

    return actionItems;
  }

  static List<ActionItem> _generateSavingsOpportunities(
    List<Transaction> transactions,
    TimePeriod currentPeriod,
    DateTime now,
  ) {
    final actionItems = <ActionItem>[];

    // Analyze categories with many small transactions
    final categoryTransactions = <String, List<Transaction>>{};
    
    for (final tx in transactions.where((tx) => 
        tx.type == TransactionType.expense && currentPeriod.containsDate(tx.date))) {
      categoryTransactions.putIfAbsent(tx.category, () => []).add(tx);
    }

    for (final entry in categoryTransactions.entries) {
      final category = entry.key;
      final txList = entry.value;
      
      if (txList.length >= 10) { // Many transactions
        final averageAmount = txList.fold(0.0, (sum, tx) => sum + tx.amount.abs()) / txList.length;
        
        if (averageAmount < 20) { // Small amounts
          actionItems.add(ActionItem(
            id: 'savings_opp_${category}_${now.millisecondsSinceEpoch}',
            type: ActionItemType.savingsOpportunity,
            priority: ActionItemPriority.low,
            title: 'Savings Opportunity in $category',
            description: 'You made ${txList.length} small $category purchases. Consider bulk buying or subscriptions.',
            actionText: 'Review Category',
            targetRoute: '/expenses',
            routeArguments: {'category': category},
            createdAt: now,
            category: category,
            metadata: {
              'transaction_count': txList.length,
              'average_amount': averageAmount,
              'total_amount': txList.fold(0.0, (sum, tx) => sum + tx.amount.abs()),
            },
          ));
        }
      }
    }

    return actionItems;
  }

  static List<ActionItem> _generateDebtAlerts(
    List<Goal> goals,
    DateTime now,
  ) {
    final actionItems = <ActionItem>[];

    // Look for debt-related goals
    final debtGoals = goals.where((goal) => 
        goal.name.toLowerCase().contains('debt') ||
        goal.name.toLowerCase().contains('loan') ||
        goal.name.toLowerCase().contains('credit')).toList();

    for (final goal in debtGoals) {
      final daysUntilTarget = goal.targetDate?.difference(now).inDays ?? 0;
      final progressPercentage = (goal.currentAmount / goal.targetAmount) * 100;

      if (daysUntilTarget <= 60 && progressPercentage < 70) {
        actionItems.add(ActionItem(
          id: 'debt_alert_${goal.id}',
          type: ActionItemType.debtAlert,
          priority: ActionItemPriority.high,
          title: 'Debt Payment Alert',
          description: '${goal.name} needs attention. ${progressPercentage.toStringAsFixed(0)}% complete with $daysUntilTarget days left.',
          actionText: 'Review Debt',
          targetRoute: '/goals',
          routeArguments: {'goal_id': goal.id},
          createdAt: now,
          dueDate: goal.targetDate,
          amount: goal.targetAmount - goal.currentAmount,
          metadata: {
            'goal_id': goal.id,
            'progress_percentage': progressPercentage,
          },
        ));
      }
    }

    return actionItems;
  }

  static List<ActionItem> _generateCategoryReviewSuggestions(
    List<Transaction> transactions,
    TimePeriod currentPeriod,
    DateTime now,
  ) {
    final actionItems = <ActionItem>[];

    // Find categories with unusual activity
    final categoryTotals = <String, double>{};
    
    for (final tx in transactions.where((tx) => 
        tx.type == TransactionType.expense && currentPeriod.containsDate(tx.date))) {
      categoryTotals.update(tx.category, (value) => value + tx.amount.abs(), 
          ifAbsent: () => tx.amount.abs());
    }

    // Find top spending category
    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      
      if (topCategory.value > 500) { // Significant spending
        actionItems.add(ActionItem(
          id: 'category_review_${topCategory.key}_${now.millisecondsSinceEpoch}',
          type: ActionItemType.categoryReview,
          priority: ActionItemPriority.low,
          title: 'Review ${topCategory.key} Spending',
          description: '${topCategory.key} is your top spending category this ${currentPeriod.type.name} (\$${topCategory.value.toStringAsFixed(0)})',
          actionText: 'Analyze Category',
          targetRoute: '/expenses',
          routeArguments: {'category': topCategory.key},
          createdAt: now,
          amount: topCategory.value,
          category: topCategory.key,
          metadata: {
            'category_total': topCategory.value,
            'rank': 1,
          },
        ));
      }
    }

    return actionItems;
  }

  // Helper methods for navigation shortcuts

  static String? _getTransactionCountBadge(List<Transaction> transactions) {
    final recentTransactions = transactions.where((tx) => 
        tx.date.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length;
    return recentTransactions > 0 ? recentTransactions.toString() : null;
  }

  static String? _getActiveGoalsBadge(List<Goal> goals) {
    final activeGoals = goals.where((goal) => 
        goal.targetDate?.isAfter(DateTime.now()) == true && 
        goal.currentAmount < goal.targetAmount).length;
    return activeGoals > 0 ? activeGoals.toString() : null;
  }

  static String? _getBudgetAlertsBadge(List<Budget> budgets, List<Transaction> transactions) {
    // This would need more complex logic to calculate budget alerts
    // For now, return null
    return null;
  }

  static String? _getUpcomingBillsBadge(List<Bill> bills) {
    final upcomingBills = bills.where((bill) => 
        bill.dueDate.isAfter(DateTime.now()) && 
        bill.dueDate.isBefore(DateTime.now().add(const Duration(days: 7)))).length;
    return upcomingBills > 0 ? upcomingBills.toString() : null;
  }
}
