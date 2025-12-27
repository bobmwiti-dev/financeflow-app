import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/notification_model.dart';
import '../models/transaction_model.dart';
import '../models/income_source_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/bill_model.dart';
import '../models/time_period_model.dart';
import 'smart_notification_service.dart';

class NotificationScheduler {
  static final NotificationScheduler _instance = NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  final SmartNotificationService _notificationService = SmartNotificationService();
  Timer? _dailyTimer;
  Timer? _hourlyTimer;
  Timer? _realTimeTimer;
  
  bool _isInitialized = false;

  /// Initialize the scheduler with automatic triggers
  void initialize() {
    if (_isInitialized) return;
    
    _scheduleDailyChecks();
    _scheduleHourlyChecks();
    _scheduleRealTimeChecks();
    
    _isInitialized = true;
    Logger('NotificationScheduler').info('NotificationScheduler initialized');
  }

  /// Schedule daily notification checks (every day at 8 AM)
  void _scheduleDailyChecks() {
    final now = DateTime.now();
    final tomorrow8AM = DateTime(now.year, now.month, now.day + 1, 8, 0);
    final timeUntilTomorrow8AM = tomorrow8AM.difference(now);
    
    // Schedule first run
    Timer(timeUntilTomorrow8AM, () {
      _performDailyChecks();
      
      // Then schedule recurring daily checks
      _dailyTimer = Timer.periodic(Duration(days: 1), (timer) {
        _performDailyChecks();
      });
    });
  }

  /// Schedule hourly notification checks
  void _scheduleHourlyChecks() {
    _hourlyTimer = Timer.periodic(Duration(hours: 1), (timer) {
      _performHourlyChecks();
    });
  }

  /// Schedule real-time checks (every 15 minutes for urgent items)
  void _scheduleRealTimeChecks() {
    _realTimeTimer = Timer.periodic(Duration(minutes: 15), (timer) {
      _performRealTimeChecks();
    });
  }

  /// Perform daily notification checks
  Future<void> _performDailyChecks() async {
    Logger('NotificationScheduler').info('Performing daily notification checks...');
    
    try {
      // Get financial data (in real implementation, this would come from ViewModels)
      final financialData = await _getFinancialData();
      
      // Generate daily notifications
      await _generateDailyNotifications(financialData);
      
      // Generate weekly notifications (on Mondays)
      if (DateTime.now().weekday == 1) {
        await _generateWeeklyNotifications(financialData);
      }
      
      // Generate monthly notifications (on 1st of month)
      if (DateTime.now().day == 1) {
        await _generateMonthlyNotifications(financialData);
      }
      
    } catch (e) {
      Logger('NotificationScheduler').severe('Error in daily notification checks: $e');
    }
  }

  /// Perform hourly notification checks
  Future<void> _performHourlyChecks() async {
    try {
      final financialData = await _getFinancialData();
      
      // Check for urgent bill reminders
      await _checkUrgentBillReminders(financialData.bills);
      
      // Check for critical budget alerts
      await _checkCriticalBudgetAlerts(financialData);
      
      // Check for goal deadline alerts
      await _checkGoalDeadlineAlerts(financialData.goals);
      
    } catch (e) {
      Logger('NotificationScheduler').severe('Error in hourly notification checks: $e');
    }
  }

  /// Perform real-time checks for immediate alerts
  Future<void> _performRealTimeChecks() async {
    try {
      final financialData = await _getFinancialData();
      
      // Check for emergency alerts (account balance critically low)
      await _checkEmergencyAlerts(financialData);
      
      // Check for anomaly alerts
      await _checkAnomalyAlerts(financialData);
      
    } catch (e) {
      Logger('NotificationScheduler').severe('Error in real-time notification checks: $e');
    }
  }

  /// Generate daily notifications
  Future<void> _generateDailyNotifications(FinancialData data) async {
    final notifications = <SmartNotification>[];
    
    // Daily spending summary
    final todaySpending = _getTodaySpending(data.transactions);
    if (todaySpending > 100) { // Threshold for daily spending alert
      notifications.add(_createDailySpendingAlert(todaySpending));
    }
    
    // Bills due today
    final billsDueToday = _getBillsDueToday(data.bills);
    for (final bill in billsDueToday) {
      notifications.add(_createBillDueNotification(bill));
    }
    
    // Budget warnings (75% threshold)
    final budgetWarnings = _getBudgetWarnings(data);
    for (final warning in budgetWarnings) {
      notifications.add(warning);
    }
    
    // Add notifications to service
    for (final notification in notifications) {
      await _notificationService.addNotification(notification);
    }
  }

  /// Generate weekly notifications (Mondays)
  Future<void> _generateWeeklyNotifications(FinancialData data) async {
    final notifications = <SmartNotification>[];
    
    // Weekly spending summary
    final weeklySpending = _getWeeklySpending(data.transactions);
    notifications.add(_createWeeklySpendingSummary(weeklySpending));
    
    // Goal progress updates
    final goalUpdates = _getWeeklyGoalUpdates(data.goals);
    notifications.addAll(goalUpdates);
    
    // Savings opportunities
    final savingsOpportunities = _getWeeklySavingsOpportunities(data.transactions);
    notifications.addAll(savingsOpportunities);
    
    // Add notifications to service
    for (final notification in notifications) {
      await _notificationService.addNotification(notification);
    }
  }

  /// Generate monthly notifications (1st of month)
  Future<void> _generateMonthlyNotifications(FinancialData data) async {
    final notifications = <SmartNotification>[];
    
    // Monthly financial report
    notifications.add(_createMonthlyReport(data));
    
    // Achievement notifications
    final achievements = _getMonthlyAchievements(data);
    notifications.addAll(achievements);
    
    // Budget reset notifications
    notifications.add(_createBudgetResetNotification());
    
    // Add notifications to service
    for (final notification in notifications) {
      await _notificationService.addNotification(notification);
    }
  }

  /// Check for urgent bill reminders
  Future<void> _checkUrgentBillReminders(List<Bill> bills) async {
    final now = DateTime.now();
    
    for (final bill in bills) {
      final hoursUntilDue = bill.dueDate.difference(now).inHours;
      
      if (hoursUntilDue <= 24 && hoursUntilDue > 0) {
        final notification = _createUrgentBillReminder(bill, hoursUntilDue);
        await _notificationService.addNotification(notification);
      }
    }
  }

  /// Check for critical budget alerts
  Future<void> _checkCriticalBudgetAlerts(FinancialData data) async {
    final currentPeriod = TimePeriod.currentMonth();
    
    for (final budget in data.budgets) {
      final spending = _getCategorySpending(data.transactions, budget.category, currentPeriod);
      final utilizationPercentage = (spending / budget.amount) * 100;
      
      if (utilizationPercentage >= 100) {
        final notification = _createBudgetExceededAlert(budget, spending);
        await _notificationService.addNotification(notification);
      }
    }
  }

  /// Check for goal deadline alerts
  Future<void> _checkGoalDeadlineAlerts(List<Goal> goals) async {
    final now = DateTime.now();
    
    for (final goal in goals) {
      if (goal.currentAmount >= goal.targetAmount) continue;
      
      final daysUntilDeadline = goal.targetDate?.difference(now).inDays ?? 0;
      final progressPercentage = (goal.currentAmount / goal.targetAmount) * 100;
      
      if (daysUntilDeadline <= 7 && progressPercentage < 50) {
        final notification = _createGoalDeadlineAlert(goal, daysUntilDeadline);
        await _notificationService.addNotification(notification);
      }
    }
  }

  /// Check for emergency alerts
  Future<void> _checkEmergencyAlerts(FinancialData data) async {
    // Calculate current balance (simplified)
    final totalIncome = data.incomeSources.fold(0.0, (sum, income) => sum + income.amount);
    final totalExpenses = data.transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
    
    final currentBalance = totalIncome - totalExpenses;
    
    // Emergency alert if balance is critically low
    if (currentBalance < 100) {
      final notification = _createEmergencyBalanceAlert(currentBalance);
      await _notificationService.addNotification(notification);
    }
  }

  /// Check for anomaly alerts
  Future<void> _checkAnomalyAlerts(FinancialData data) async {
    // This would integrate with the existing AnomalyDetectionService
    // For now, we'll create a simple check for unusual spending
    
    final todaySpending = _getTodaySpending(data.transactions);
    final averageDailySpending = _getAverageDailySpending(data.transactions);
    
    if (todaySpending > averageDailySpending * 3) { // 300% above average
      final notification = _createSpendingAnomalyAlert(todaySpending, averageDailySpending);
      await _notificationService.addNotification(notification);
    }
  }

  // Helper methods for creating specific notifications

  SmartNotification _createDailySpendingAlert(double amount) {
    return SmartNotification(
      id: 'daily_spending_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.budgetAlert,
      priority: NotificationPriority.medium,
      title: 'Daily Spending Update',
      message: 'You\'ve spent \$${amount.toStringAsFixed(0)} today. Stay mindful of your budget!',
      createdAt: DateTime.now(),
      channels: [NotificationChannel.inApp],
      actionRoute: '/reports',
    );
  }

  SmartNotification _createBillDueNotification(Bill bill) {
    return SmartNotification(
      id: 'bill_due_${bill.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.billDue,
      priority: NotificationPriority.high,
      title: '${bill.name} Due Today',
      message: '${bill.name} (\$${bill.amount.toStringAsFixed(2)}) is due today. Don\'t forget to pay!',
      createdAt: DateTime.now(),
      channels: [NotificationChannel.inApp, NotificationChannel.push],
      actionRoute: '/bills',
      actionArguments: {'bill_id': bill.id},
      accentColor: Colors.red,
    );
  }

  SmartNotification _createWeeklySpendingSummary(double weeklySpending) {
    return SmartNotification(
      id: 'weekly_summary_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.weeklyInsight,
      priority: NotificationPriority.low,
      title: 'Weekly Spending Summary',
      message: 'You spent \$${weeklySpending.toStringAsFixed(0)} this week. '
          '${weeklySpending > 500 ? 'Consider reviewing your expenses.' : 'Great job managing your spending!'}',
      createdAt: DateTime.now(),
      channels: [NotificationChannel.inApp],
      actionRoute: '/reports',
      accentColor: Colors.blue,
    );
  }

  SmartNotification _createMonthlyReport(FinancialData data) {
    final lastMonth = DateTime.now().subtract(Duration(days: 30));
    final monthlyIncome = data.incomeSources
        .where((income) => income.date.isAfter(lastMonth))
        .fold(0.0, (sum, income) => sum + income.amount);
    
    final monthlyExpenses = data.transactions
        .where((tx) => tx.type == TransactionType.expense && tx.date.isAfter(lastMonth))
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
    
    final netAmount = monthlyIncome - monthlyExpenses;
    
    return SmartNotification(
      id: 'monthly_report_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.monthlyReport,
      priority: NotificationPriority.medium,
      title: 'Monthly Financial Report',
      message: 'Last month you ${netAmount >= 0 ? 'saved' : 'overspent'} '
          '\$${netAmount.abs().toStringAsFixed(0)}. Tap to see your full report.',
      createdAt: DateTime.now(),
      channels: [NotificationChannel.inApp, NotificationChannel.email],
      actionRoute: '/reports',
      accentColor: netAmount >= 0 ? Colors.green : Colors.orange,
    );
  }

  SmartNotification _createUrgentBillReminder(Bill bill, int hoursUntilDue) {
    return SmartNotification(
      id: 'urgent_bill_${bill.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.billDue,
      priority: NotificationPriority.critical,
      title: 'Urgent: ${bill.name} Due Soon!',
      message: '${bill.name} (\$${bill.amount.toStringAsFixed(2)}) is due in $hoursUntilDue hours!',
      createdAt: DateTime.now(),
      channels: [NotificationChannel.inApp, NotificationChannel.push, NotificationChannel.sms],
      actionRoute: '/bills',
      actionArguments: {'bill_id': bill.id},
      accentColor: Colors.red,
    );
  }

  SmartNotification _createBudgetExceededAlert(Budget budget, double spending) {
    return SmartNotification(
      id: 'budget_exceeded_${budget.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.budgetAlert,
      priority: NotificationPriority.critical,
      title: '${budget.category} Budget Exceeded!',
      message: 'You\'ve spent \$${spending.toStringAsFixed(0)} of your \$${budget.amount.toStringAsFixed(0)} ${budget.category} budget.',
      createdAt: DateTime.now(),
      channels: [NotificationChannel.inApp, NotificationChannel.push],
      actionRoute: '/budgets',
      actionArguments: {'category': budget.category},
      accentColor: Colors.red,
    );
  }

  SmartNotification _createGoalDeadlineAlert(Goal goal, int daysLeft) {
    final amountNeeded = goal.targetAmount - goal.currentAmount;
    
    return SmartNotification(
      id: 'goal_deadline_${goal.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.goalReminder,
      priority: NotificationPriority.high,
      title: '${goal.name} Deadline Approaching!',
      message: 'Only $daysLeft days left! You need \$${amountNeeded.toStringAsFixed(0)} more to reach your goal.',
      createdAt: DateTime.now(),
      channels: [NotificationChannel.inApp, NotificationChannel.push],
      actionRoute: '/goals',
      actionArguments: {'goal_id': goal.id},
      accentColor: Colors.orange,
    );
  }

  SmartNotification _createEmergencyBalanceAlert(double balance) {
    return SmartNotification(
      id: 'emergency_balance_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.emergencyAlert,
      priority: NotificationPriority.critical,
      title: 'Low Balance Alert!',
      message: 'Your account balance is critically low (\$${balance.toStringAsFixed(2)}). Consider reviewing your expenses.',
      createdAt: DateTime.now(),
      channels: [NotificationChannel.inApp, NotificationChannel.push, NotificationChannel.sms],
      actionRoute: '/reports',
      accentColor: Colors.red,
    );
  }

  SmartNotification _createSpendingAnomalyAlert(double todaySpending, double averageSpending) {
    return SmartNotification(
      id: 'spending_anomaly_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.anomalyDetected,
      priority: NotificationPriority.high,
      title: 'Unusual Spending Detected',
      message: 'Today\'s spending (\$${todaySpending.toStringAsFixed(0)}) is much higher than your average (\$${averageSpending.toStringAsFixed(0)}).',
      createdAt: DateTime.now(),
      channels: [NotificationChannel.inApp, NotificationChannel.push],
      actionRoute: '/reports',
      accentColor: Colors.purple,
    );
  }

  SmartNotification _createBudgetResetNotification() {
    return SmartNotification(
      id: 'budget_reset_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.monthlyReport,
      priority: NotificationPriority.low,
      title: 'New Month, Fresh Budget!',
      message: 'Your monthly budgets have been reset. Time to start fresh with your financial goals!',
      createdAt: DateTime.now(),
      channels: [NotificationChannel.inApp],
      actionRoute: '/budgets',
      accentColor: Colors.green,
    );
  }

  // Helper methods for data calculations

  double _getTodaySpending(List<Transaction> transactions) {
    final today = DateTime.now();
    return transactions
        .where((tx) => 
            tx.type == TransactionType.expense &&
            tx.date.day == today.day &&
            tx.date.month == today.month &&
            tx.date.year == today.year)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  double _getWeeklySpending(List<Transaction> transactions) {
    final weekAgo = DateTime.now().subtract(Duration(days: 7));
    return transactions
        .where((tx) => 
            tx.type == TransactionType.expense &&
            tx.date.isAfter(weekAgo))
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  double _getAverageDailySpending(List<Transaction> transactions) {
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    final recentTransactions = transactions
        .where((tx) => 
            tx.type == TransactionType.expense &&
            tx.date.isAfter(thirtyDaysAgo))
        .toList();
    
    if (recentTransactions.isEmpty) return 0.0;
    
    final totalSpending = recentTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    return totalSpending / 30;
  }

  List<Bill> _getBillsDueToday(List<Bill> bills) {
    final today = DateTime.now();
    return bills.where((bill) => 
        bill.dueDate.day == today.day &&
        bill.dueDate.month == today.month &&
        bill.dueDate.year == today.year).toList();
  }

  List<SmartNotification> _getBudgetWarnings(FinancialData data) {
    final warnings = <SmartNotification>[];
    final currentPeriod = TimePeriod.currentMonth();
    
    for (final budget in data.budgets) {
      final spending = _getCategorySpending(data.transactions, budget.category, currentPeriod);
      final utilizationPercentage = (spending / budget.amount) * 100;
      
      if (utilizationPercentage >= 75 && utilizationPercentage < 100) {
        warnings.add(SmartNotification(
          id: 'budget_warning_${budget.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.budgetAlert,
          priority: NotificationPriority.medium,
          title: '${budget.category} Budget Warning',
          message: 'You\'ve used ${utilizationPercentage.toStringAsFixed(0)}% of your ${budget.category} budget.',
          createdAt: DateTime.now(),
          channels: [NotificationChannel.inApp],
          actionRoute: '/budgets',
          actionArguments: {'category': budget.category},
          accentColor: Colors.orange,
        ));
      }
    }
    
    return warnings;
  }

  List<SmartNotification> _getWeeklyGoalUpdates(List<Goal> goals) {
    final updates = <SmartNotification>[];
    final now = DateTime.now();
    
    for (final goal in goals) {
      if (goal.currentAmount >= goal.targetAmount) continue;
      
      final progressPercentage = (goal.currentAmount / goal.targetAmount) * 100;
      final daysLeft = goal.targetDate?.difference(now).inDays ?? 0;
      
      if (progressPercentage >= 25 && progressPercentage < 100 && daysLeft > 0) {
        updates.add(SmartNotification(
          id: 'goal_update_${goal.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.goalReminder,
          priority: NotificationPriority.low,
          title: '${goal.name} Progress Update',
          message: 'You\'re ${progressPercentage.toStringAsFixed(0)}% towards your goal! Keep it up!',
          createdAt: DateTime.now(),
          channels: [NotificationChannel.inApp],
          actionRoute: '/goals',
          actionArguments: {'goal_id': goal.id},
          accentColor: Colors.blue,
        ));
      }
    }
    
    return updates;
  }

  List<SmartNotification> _getWeeklySavingsOpportunities(List<Transaction> transactions) {
    final opportunities = <SmartNotification>[];
    
    // Analyze frequent small transactions
    final weekAgo = DateTime.now().subtract(Duration(days: 7));
    final recentTransactions = transactions
        .where((tx) => tx.type == TransactionType.expense && tx.date.isAfter(weekAgo))
        .toList();
    
    final categoryTransactions = <String, List<Transaction>>{};
    for (final tx in recentTransactions) {
      categoryTransactions.putIfAbsent(tx.category, () => []).add(tx);
    }
    
    for (final entry in categoryTransactions.entries) {
      final category = entry.key;
      final txList = entry.value;
      
      if (txList.length >= 5) { // 5 or more transactions in a week
        final averageAmount = txList.fold(0.0, (sum, tx) => sum + tx.amount.abs()) / txList.length;
        
        if (averageAmount < 20) { // Small amounts
          opportunities.add(SmartNotification(
            id: 'savings_opp_${category}_${DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.savingsOpportunity,
            priority: NotificationPriority.low,
            title: 'Savings Opportunity in $category',
            message: 'You made ${txList.length} small $category purchases this week. Consider bulk buying or subscriptions.',
            createdAt: DateTime.now(),
            channels: [NotificationChannel.inApp],
            actionRoute: '/expenses',
            actionArguments: {'category': category},
            accentColor: Colors.green,
          ));
        }
      }
    }
    
    return opportunities;
  }

  List<SmartNotification> _getMonthlyAchievements(FinancialData data) {
    final achievements = <SmartNotification>[];
    
    // Check for completed goals
    for (final goal in data.goals) {
      if (goal.currentAmount >= goal.targetAmount) {
        achievements.add(SmartNotification(
          id: 'achievement_${goal.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.achievementUnlocked,
          priority: NotificationPriority.low,
          title: 'Goal Achieved! 🎉',
          message: 'Congratulations! You\'ve reached your ${goal.name} goal of \$${goal.targetAmount.toStringAsFixed(0)}!',
          createdAt: DateTime.now(),
          channels: [NotificationChannel.inApp],
          actionRoute: '/goals',
          actionArguments: {'goal_id': goal.id},
          accentColor: Colors.amber,
        ));
      }
    }
    
    return achievements;
  }

  double _getCategorySpending(List<Transaction> transactions, String category, TimePeriod period) {
    return transactions
        .where((tx) => 
            tx.type == TransactionType.expense &&
            tx.category == category &&
            period.containsDate(tx.date))
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  /// Get financial data (placeholder - in real implementation, this would come from ViewModels)
  Future<FinancialData> _getFinancialData() async {
    // This is a placeholder. In real implementation, you would:
    // 1. Get data from ViewModels using Provider.of or dependency injection
    // 2. Or pass the data as parameters to the scheduler methods
    
    return FinancialData(
      transactions: [], // Would come from TransactionViewModel
      incomeSources: [], // Would come from IncomeViewModel
      budgets: [], // Would come from BudgetViewModel
      goals: [], // Would come from GoalViewModel
      bills: [], // Would come from BillViewModel
    );
  }

  /// Dispose of all timers
  void dispose() {
    _dailyTimer?.cancel();
    _hourlyTimer?.cancel();
    _realTimeTimer?.cancel();
    _isInitialized = false;
  }
}

/// Data class to hold all financial information
class FinancialData {
  final List<Transaction> transactions;
  final List<IncomeSource> incomeSources;
  final List<Budget> budgets;
  final List<Goal> goals;
  final List<Bill> bills;

  FinancialData({
    required this.transactions,
    required this.incomeSources,
    required this.budgets,
    required this.goals,
    required this.bills,
  });
}
