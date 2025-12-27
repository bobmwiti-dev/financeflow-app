import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/notification_model.dart';
import '../models/time_period_model.dart';
import '../viewmodels/transaction_viewmodel_fixed.dart';
import '../viewmodels/income_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/goal_viewmodel.dart';
import '../viewmodels/bill_viewmodel.dart';
import 'smart_notification_service.dart';
import 'notification_scheduler.dart';

class NotificationIntegrationService {
  static final NotificationIntegrationService _instance = NotificationIntegrationService._internal();
  factory NotificationIntegrationService() => _instance;
  NotificationIntegrationService._internal();

  final SmartNotificationService _notificationService = SmartNotificationService();
  final NotificationScheduler _scheduler = NotificationScheduler();
  
  bool _isInitialized = false;

  /// Initialize the notification integration with ViewModels
  void initialize({
    required TransactionViewModel transactionViewModel,
    required IncomeViewModel incomeViewModel,
    required BudgetViewModel budgetViewModel,
    required GoalViewModel goalViewModel,
    required BillViewModel billViewModel,
  }) {
    if (_isInitialized) return;

    // Initialize services
    _notificationService.initialize();
    _scheduler.initialize();

    // Set up listeners for data changes
    _setupDataChangeListeners(
      transactionViewModel: transactionViewModel,
      incomeViewModel: incomeViewModel,
      budgetViewModel: budgetViewModel,
      goalViewModel: goalViewModel,
      billViewModel: billViewModel,
    );

    // Generate initial notifications
    _generateInitialNotifications(
      transactionViewModel: transactionViewModel,
      incomeViewModel: incomeViewModel,
      budgetViewModel: budgetViewModel,
      goalViewModel: goalViewModel,
      billViewModel: billViewModel,
    );

    _isInitialized = true;
    Logger('NotificationIntegrationService').info('NotificationIntegrationService initialized');
  }

  /// Set up listeners for data changes to trigger notifications
  void _setupDataChangeListeners({
    required TransactionViewModel transactionViewModel,
    required IncomeViewModel incomeViewModel,
    required BudgetViewModel budgetViewModel,
    required GoalViewModel goalViewModel,
    required BillViewModel billViewModel,
  }) {
    // Listen to transaction changes
    transactionViewModel.addListener(() {
      _onDataChanged(
        transactionViewModel: transactionViewModel,
        incomeViewModel: incomeViewModel,
        budgetViewModel: budgetViewModel,
        goalViewModel: goalViewModel,
        billViewModel: billViewModel,
      );
    });

    // Listen to income changes
    incomeViewModel.addListener(() {
      _onDataChanged(
        transactionViewModel: transactionViewModel,
        incomeViewModel: incomeViewModel,
        budgetViewModel: budgetViewModel,
        goalViewModel: goalViewModel,
        billViewModel: billViewModel,
      );
    });

    // Listen to budget changes
    budgetViewModel.addListener(() {
      _onDataChanged(
        transactionViewModel: transactionViewModel,
        incomeViewModel: incomeViewModel,
        budgetViewModel: budgetViewModel,
        goalViewModel: goalViewModel,
        billViewModel: billViewModel,
      );
    });

    // Listen to goal changes
    goalViewModel.addListener(() {
      _onDataChanged(
        transactionViewModel: transactionViewModel,
        incomeViewModel: incomeViewModel,
        budgetViewModel: budgetViewModel,
        goalViewModel: goalViewModel,
        billViewModel: billViewModel,
      );
    });

    // Listen to bill changes
    billViewModel.addListener(() {
      _onDataChanged(
        transactionViewModel: transactionViewModel,
        incomeViewModel: incomeViewModel,
        budgetViewModel: budgetViewModel,
        goalViewModel: goalViewModel,
        billViewModel: billViewModel,
      );
    });
  }

  /// Generate initial notifications when app starts
  Future<void> _generateInitialNotifications({
    required TransactionViewModel transactionViewModel,
    required IncomeViewModel incomeViewModel,
    required BudgetViewModel budgetViewModel,
    required GoalViewModel goalViewModel,
    required BillViewModel billViewModel,
  }) async {
    try {
      await _generateNotifications(
        transactionViewModel: transactionViewModel,
        incomeViewModel: incomeViewModel,
        budgetViewModel: budgetViewModel,
        goalViewModel: goalViewModel,
        billViewModel: billViewModel,
      );
    } catch (e) {
      Logger('NotificationIntegrationService').severe('Error generating initial notifications: $e');
    }
  }

  /// Called when any data changes to regenerate notifications
  Future<void> _onDataChanged({
    required TransactionViewModel transactionViewModel,
    required IncomeViewModel incomeViewModel,
    required BudgetViewModel budgetViewModel,
    required GoalViewModel goalViewModel,
    required BillViewModel billViewModel,
  }) async {
    // Debounce rapid changes
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      await _generateNotifications(
        transactionViewModel: transactionViewModel,
        incomeViewModel: incomeViewModel,
        budgetViewModel: budgetViewModel,
        goalViewModel: goalViewModel,
        billViewModel: billViewModel,
      );
    } catch (e) {
      Logger('NotificationIntegrationService').severe('Error generating notifications on data change: $e');
    }
  }

  /// Generate notifications based on current data
  Future<void> _generateNotifications({
    required TransactionViewModel transactionViewModel,
    required IncomeViewModel incomeViewModel,
    required BudgetViewModel budgetViewModel,
    required GoalViewModel goalViewModel,
    required BillViewModel billViewModel,
  }) async {
    final currentPeriod = TimePeriod.currentMonth();

    await _notificationService.generateSmartNotifications(
      allTransactions: transactionViewModel.allTransactions,
      allIncomeSources: incomeViewModel.incomeSources,
      allBudgets: budgetViewModel.budgets,
      allGoals: goalViewModel.goals,
      allBills: billViewModel.bills,
      currentPeriod: currentPeriod,
    );
  }

  /// Manually trigger notification generation (for testing)
  Future<void> generateTestNotifications({
    required TransactionViewModel transactionViewModel,
    required IncomeViewModel incomeViewModel,
    required BudgetViewModel budgetViewModel,
    required GoalViewModel goalViewModel,
    required BillViewModel billViewModel,
  }) async {
    Logger('NotificationIntegrationService').info('Generating test notifications...');
    
    await _generateNotifications(
      transactionViewModel: transactionViewModel,
      incomeViewModel: incomeViewModel,
      budgetViewModel: budgetViewModel,
      goalViewModel: goalViewModel,
      billViewModel: billViewModel,
    );

    // Also generate some sample notifications for testing
    await _generateSampleNotifications();
  }

  /// Generate sample notifications for testing purposes
  Future<void> _generateSampleNotifications() async {
    final sampleNotifications = [
      // Budget alert sample
      _notificationService.addNotification(
        _createSampleBudgetAlert(),
      ),
      
      // Goal reminder sample
      _notificationService.addNotification(
        _createSampleGoalReminder(),
      ),
      
      // Bill reminder sample
      _notificationService.addNotification(
        _createSampleBillReminder(),
      ),
      
      // M-Pesa alert sample
      _notificationService.addNotification(
        _createSampleMPesaAlert(),
      ),
      
      // Achievement sample
      _notificationService.addNotification(
        _createSampleAchievement(),
      ),
    ];

    await Future.wait(sampleNotifications);
    Logger('NotificationIntegrationService').info('Sample notifications generated');
  }

  // Sample notification creators for testing

  dynamic _createSampleBudgetAlert() {
    return _notificationService.addNotification(
      SmartNotification(
        id: 'sample_budget_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.budgetAlert,
        priority: NotificationPriority.high,
        title: 'Grocery Budget Alert',
        message: 'You\'ve used 85% of your grocery budget (\$340 of \$400). Consider reviewing your spending.',
        createdAt: DateTime.now(),
        channels: [NotificationChannel.inApp, NotificationChannel.push],
        actionRoute: '/budgets',
        actionArguments: {'category': 'Grocery'},
        accentColor: Colors.orange,
      ),
    );
  }

  dynamic _createSampleGoalReminder() {
    return _notificationService.addNotification(
      SmartNotification(
        id: 'sample_goal_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.goalReminder,
        priority: NotificationPriority.medium,
        title: 'Emergency Fund Goal Reminder',
        message: 'Only 15 days left! You need \$500 more to reach your emergency fund goal.',
        createdAt: DateTime.now(),
        channels: [NotificationChannel.inApp, NotificationChannel.push],
        actionRoute: '/goals',
        actionArguments: {'goal_id': 'emergency_fund'},
        accentColor: Colors.blue,
      ),
    );
  }

  dynamic _createSampleBillReminder() {
    return _notificationService.addNotification(
      SmartNotification(
        id: 'sample_bill_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.billDue,
        priority: NotificationPriority.high,
        title: 'Electricity Bill Due Tomorrow',
        message: 'Kenya Power (\$67.50) is due tomorrow. Don\'t forget to pay!',
        createdAt: DateTime.now(),
        channels: [NotificationChannel.inApp, NotificationChannel.push, NotificationChannel.sms],
        actionRoute: '/bills',
        actionArguments: {'bill_id': 'electricity'},
        accentColor: Colors.red,
      ),
    );
  }

  dynamic _createSampleMPesaAlert() {
    return _notificationService.addNotification(
      SmartNotification(
        id: 'sample_mpesa_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.mpesaAlert,
        priority: NotificationPriority.medium,
        title: 'M-Pesa Activity Alert',
        message: 'M-Pesa spending increased by 150% this month. Review your mobile money transactions.',
        createdAt: DateTime.now(),
        channels: [NotificationChannel.inApp, NotificationChannel.push],
        actionRoute: '/mpesa_import',
        accentColor: Colors.teal,
      ),
    );
  }

  dynamic _createSampleAchievement() {
    return _notificationService.addNotification(
      SmartNotification(
        id: 'sample_achievement_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.achievementUnlocked,
        priority: NotificationPriority.low,
        title: 'Achievement Unlocked! 🎉',
        message: 'You\'ve recorded 100 transactions! Your financial tracking is impressive!',
        createdAt: DateTime.now(),
        channels: [NotificationChannel.inApp],
        actionRoute: '/reports',
        accentColor: Colors.amber,
      ),
    );
  }

  /// Get notification service for external access
  SmartNotificationService get notificationService => _notificationService;

  /// Dispose of resources
  void dispose() {
    _scheduler.dispose();
    _notificationService.dispose();
    _isInitialized = false;
  }
}
