import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'kenya_sms_service.dart';
import '../models/notification_model.dart';
import '../models/action_item_model.dart';
import '../models/anomaly_model.dart';
import '../models/transaction_model.dart' as app_models;
import '../models/income_source_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/bill_model.dart';
import '../models/time_period_model.dart';
import 'action_items_service.dart';
import 'anomaly_detection_service.dart';

class SmartNotificationService {
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  final Logger _logger = Logger('SmartNotificationService');
  final List<SmartNotification> _notifications = [];
  final List<NotificationGroup> _groups = [];
  NotificationPreferences _preferences = NotificationPreferences();
  
  final StreamController<List<SmartNotification>> _notificationController = 
      StreamController<List<SmartNotification>>.broadcast();
  
  Stream<List<SmartNotification>> get notificationStream => _notificationController.stream;
  
  List<SmartNotification> get notifications => List.unmodifiable(_notifications);
  List<SmartNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead && n.shouldShow).toList();
  
  int get unreadCount => unreadNotifications.length;

  // Notification templates for consistent messaging
  static final Map<NotificationType, NotificationTemplate> _templates = {
    NotificationType.budgetAlert: NotificationTemplate(
      type: NotificationType.budgetAlert,
      titleTemplate: '{category} Budget Alert',
      messageTemplate: 'You\'ve used {percentage}% of your {category} budget ({spent} of {total})',
      defaultPriority: NotificationPriority.high,
      defaultChannels: [NotificationChannel.inApp, NotificationChannel.push],
      defaultExpiry: Duration(days: 3),
      accentColor: Colors.orange,
    ),
    
    NotificationType.goalReminder: NotificationTemplate(
      type: NotificationType.goalReminder,
      titleTemplate: '{goal_name} Goal Reminder',
      messageTemplate: 'Only {days_left} days left! You need {amount_needed} more to reach your goal.',
      defaultPriority: NotificationPriority.medium,
      defaultChannels: [NotificationChannel.inApp, NotificationChannel.push],
      defaultExpiry: Duration(days: 7),
      accentColor: Colors.blue,
    ),
    
    NotificationType.billDue: NotificationTemplate(
      type: NotificationType.billDue,
      titleTemplate: '{bill_name} Due Soon',
      messageTemplate: '{bill_name} ({amount}) is due in {days} day{plural}',
      defaultPriority: NotificationPriority.high,
      defaultChannels: [NotificationChannel.inApp, NotificationChannel.push, NotificationChannel.sms],
      defaultExpiry: Duration(days: 1),
      accentColor: Colors.red,
    ),
    
    NotificationType.anomalyDetected: NotificationTemplate(
      type: NotificationType.anomalyDetected,
      titleTemplate: 'Unusual Activity Detected',
      messageTemplate: '{anomaly_description}',
      defaultPriority: NotificationPriority.medium,
      defaultChannels: [NotificationChannel.inApp, NotificationChannel.push],
      defaultExpiry: Duration(days: 5),
      accentColor: Colors.purple,
    ),
    
    NotificationType.savingsOpportunity: NotificationTemplate(
      type: NotificationType.savingsOpportunity,
      titleTemplate: 'Savings Opportunity',
      messageTemplate: '{opportunity_description}',
      defaultPriority: NotificationPriority.low,
      defaultChannels: [NotificationChannel.inApp],
      defaultExpiry: Duration(days: 14),
      accentColor: Colors.green,
    ),
    
    NotificationType.mpesaAlert: NotificationTemplate(
      type: NotificationType.mpesaAlert,
      titleTemplate: 'M-Pesa Activity Alert',
      messageTemplate: '{mpesa_description}',
      defaultPriority: NotificationPriority.medium,
      defaultChannels: [NotificationChannel.inApp, NotificationChannel.push],
      defaultExpiry: Duration(days: 7),
      accentColor: Colors.teal,
    ),
    
    NotificationType.weeklyInsight: NotificationTemplate(
      type: NotificationType.weeklyInsight,
      titleTemplate: 'Your Weekly Financial Insight',
      messageTemplate: '{insight_message}',
      defaultPriority: NotificationPriority.low,
      defaultChannels: [NotificationChannel.inApp, NotificationChannel.email],
      defaultExpiry: Duration(days: 7),
      accentColor: Colors.indigo,
    ),
    
    NotificationType.monthlyReport: NotificationTemplate(
      type: NotificationType.monthlyReport,
      titleTemplate: 'Monthly Financial Report Ready',
      messageTemplate: 'Your {month} financial summary is ready. You {saved_or_overspent} {amount} this month.',
      defaultPriority: NotificationPriority.medium,
      defaultChannels: [NotificationChannel.inApp, NotificationChannel.email],
      defaultExpiry: Duration(days: 30),
      accentColor: Colors.deepPurple,
    ),
    
    NotificationType.emergencyAlert: NotificationTemplate(
      type: NotificationType.emergencyAlert,
      titleTemplate: 'Financial Emergency Alert',
      messageTemplate: '{emergency_message}',
      defaultPriority: NotificationPriority.critical,
      defaultChannels: [NotificationChannel.inApp, NotificationChannel.push, NotificationChannel.sms],
      defaultExpiry: Duration(hours: 24),
      accentColor: Colors.red,
    ),
    
    NotificationType.achievementUnlocked: NotificationTemplate(
      type: NotificationType.achievementUnlocked,
      titleTemplate: 'Achievement Unlocked! 🎉',
      messageTemplate: '{achievement_description}',
      defaultPriority: NotificationPriority.low,
      defaultChannels: [NotificationChannel.inApp],
      defaultExpiry: Duration(days: 30),
      accentColor: Colors.amber,
    ),
  };

  /// Initialize the notification service
  void initialize() {
    _schedulePeriodicChecks();
    _loadPreferences();
  }

  /// Generate notifications based on current financial data
  Future<void> generateSmartNotifications({
    required List<app_models.Transaction> allTransactions,
    required List<IncomeSource> allIncomeSources,
    required List<Budget> allBudgets,
    required List<Goal> allGoals,
    required List<Bill> allBills,
    required TimePeriod currentPeriod,
  }) async {
    final newNotifications = <SmartNotification>[];

    // 1. Generate notifications from action items
    final actionItems = ActionItemsService.generateActionItems(
      allTransactions: allTransactions,
      allIncomeSources: allIncomeSources,
      allBudgets: allBudgets,
      allGoals: allGoals,
      allBills: allBills,
      currentPeriod: currentPeriod,
    );

    for (final item in actionItems.take(5)) { // Top 5 most urgent
      if (_shouldCreateNotificationForActionItem(item)) {
        newNotifications.add(_createNotificationFromActionItem(item));
      }
    }

    // 2. Generate notifications from anomalies
    final anomalies = AnomalyDetectionService.detectAnomalies(
      allTransactions: allTransactions,
      allIncomeSources: allIncomeSources,
      currentPeriod: currentPeriod,
    );

    for (final anomaly in anomalies.where((a) => a.severity.index >= 2)) { // High and Critical only
      if (_shouldCreateNotificationForAnomaly(anomaly)) {
        newNotifications.add(_createNotificationFromAnomaly(anomaly));
      }
    }

    // 3. Generate bill reminders
    newNotifications.addAll(_generateBillReminders(allBills));

    // 4. Generate goal reminders
    newNotifications.addAll(_generateGoalReminders(allGoals));

    // 5. Generate weekly/monthly insights
    newNotifications.addAll(_generatePeriodicInsights(
      allTransactions, allIncomeSources, currentPeriod));

    // 6. Generate achievement notifications
    newNotifications.addAll(_generateAchievementNotifications(
      allTransactions, allIncomeSources, allGoals));

    // Add new notifications and update stream
    for (final notification in newNotifications) {
      await addNotification(notification);
    }
  }

  /// Add a notification to the system
  Future<void> addNotification(SmartNotification notification) async {
    // Check if similar notification already exists
    if (_hasSimilarNotification(notification)) return;

    // Check preferences
    if (!_preferences.isTypeEnabled(notification.type)) return;
    if (!_preferences.shouldSendNow() && notification.priority != NotificationPriority.critical) return;

    _notifications.add(notification);
    _sortNotifications();
    _groupNotifications();
    _notificationController.add(_notifications);

    // Send to appropriate channels
    await _sendToChannels(notification);
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationController.add(_notifications);
    }
  }

  /// Mark notification as actioned
  void markAsActioned(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isActioned: true);
      _notificationController.add(_notifications);
    }
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    _groups.clear();
    _notificationController.add(_notifications);
  }

  /// Clear expired notifications
  void clearExpired() {
    _notifications.removeWhere((n) => n.isExpired);
    _notificationController.add(_notifications);
  }

  /// Update notification preferences
  void updatePreferences(NotificationPreferences preferences) {
    _preferences = preferences;
    _savePreferences();
  }

  // Private helper methods

  bool _shouldCreateNotificationForActionItem(ActionItem item) {
    // Don't create notifications for low priority items unless it's been a while
    if (item.priority == ActionItemPriority.low) {
      return !_hasRecentNotificationOfType(item.type.toString());
    }
    
    // Always create for high priority items
    if (item.priority.index >= 2) return true;
    
    // Create for medium priority if no recent similar notification
    return !_hasRecentNotificationOfType(item.type.toString());
  }

  bool _shouldCreateNotificationForAnomaly(Anomaly anomaly) {
    // Only create notifications for significant anomalies
    return anomaly.severity.index >= 2 && 
           !_hasRecentNotificationOfType(anomaly.type.toString());
  }

  SmartNotification _createNotificationFromActionItem(ActionItem item) {
    NotificationType notificationType;
    
    switch (item.type) {
      case ActionItemType.budgetAlert:
        notificationType = NotificationType.budgetAlert;
        break;
      case ActionItemType.goalAlert:
        notificationType = NotificationType.goalReminder;
        break;
      case ActionItemType.billReminder:
        notificationType = NotificationType.billDue;
        break;
      case ActionItemType.mpesaAlert:
        notificationType = NotificationType.mpesaAlert;
        break;
      case ActionItemType.savingsOpportunity:
        notificationType = NotificationType.savingsOpportunity;
        break;
      default:
        notificationType = NotificationType.weeklyInsight;
    }

    final template = _templates[notificationType]!;
    
    return template.generate(
      data: {
        'category': item.category ?? '',
        'amount': item.amount?.toStringAsFixed(0) ?? '0',
        'description': item.description,
      },
      customTitle: item.title,
      customMessage: item.description,
      priority: _mapActionItemPriorityToNotificationPriority(item.priority),
      actionRoute: item.targetRoute,
      actionArguments: item.routeArguments,
    );
  }

  SmartNotification _createNotificationFromAnomaly(Anomaly anomaly) {
    final template = _templates[NotificationType.anomalyDetected]!;
    
    return template.generate(
      data: {
        'anomaly_description': anomaly.message,
        'category': anomaly.category ?? '',
        'amount': anomaly.amount?.toStringAsFixed(0) ?? '0',
      },
      customTitle: anomaly.title,
      customMessage: anomaly.message,
      priority: _mapAnomalySeverityToNotificationPriority(anomaly.severity),
    );
  }

  List<SmartNotification> _generateBillReminders(List<Bill> bills) {
    final notifications = <SmartNotification>[];
    final now = DateTime.now();
    
    for (final bill in bills) {
      final daysUntilDue = bill.dueDate.difference(now).inDays;
      
      if (daysUntilDue <= 3 && daysUntilDue >= 0) {
        final template = _templates[NotificationType.billDue]!;
        
        notifications.add(template.generate(
          data: {
            'bill_name': bill.name,
            'amount': '\$${bill.amount.toStringAsFixed(2)}',
            'days': daysUntilDue.toString(),
            'plural': daysUntilDue == 1 ? '' : 's',
          },
          priority: daysUntilDue <= 1 ? NotificationPriority.critical : NotificationPriority.high,
          scheduledFor: daysUntilDue == 0 ? now : bill.dueDate.subtract(Duration(days: 1)),
          actionRoute: '/bills',
          actionArguments: {'bill_id': bill.id},
        ));
      }
    }
    
    return notifications;
  }

  List<SmartNotification> _generateGoalReminders(List<Goal> goals) {
    final notifications = <SmartNotification>[];
    final now = DateTime.now();
    
    for (final goal in goals) {
      if (goal.currentAmount >= goal.targetAmount) continue;
      
      final daysLeft = goal.targetDate?.difference(now).inDays ?? 0;
      final progressPercentage = (goal.currentAmount / goal.targetAmount) * 100;
      
      if (daysLeft <= 30 && daysLeft > 0 && progressPercentage < 80) {
        final template = _templates[NotificationType.goalReminder]!;
        final amountNeeded = goal.targetAmount - goal.currentAmount;
        
        notifications.add(template.generate(
          data: {
            'goal_name': goal.name,
            'days_left': daysLeft.toString(),
            'amount_needed': '\$${amountNeeded.toStringAsFixed(0)}',
            'progress': progressPercentage.toStringAsFixed(0),
          },
          priority: daysLeft <= 7 ? NotificationPriority.high : NotificationPriority.medium,
          actionRoute: '/goals',
          actionArguments: {'goal_id': goal.id},
        ));
      }
    }
    
    return notifications;
  }

  List<SmartNotification> _generatePeriodicInsights(
    List<app_models.Transaction> transactions, 
    List<IncomeSource> incomeSources, 
    TimePeriod currentPeriod
  ) {
    final notifications = <SmartNotification>[];
    final now = DateTime.now();
    
    // Weekly insight (every Monday)
    if (now.weekday == 1 && !_hasRecentNotificationOfType('weekly_insight')) {
      final weeklySpending = transactions
          .where((tx) => tx.date.isAfter(now.subtract(Duration(days: 7))))
          .fold(0.0, (total, tx) => total + tx.amount.abs());
      
      final template = _templates[NotificationType.weeklyInsight]!;
      
      notifications.add(template.generate(
        data: {
          'insight_message': 'You spent \$${weeklySpending.toStringAsFixed(0)} this week. '
              '${weeklySpending > 500 ? 'Consider reviewing your expenses.' : 'Great job staying on track!'}',
        },
        actionRoute: '/reports',
      ));
    }
    
    // Monthly report (first day of month)
    if (now.day == 1 && !_hasRecentNotificationOfType('monthly_report')) {
      final lastMonth = DateTime(now.year, now.month - 1);
      
      final monthlyIncome = incomeSources.fold<double>(0, (total, income) => total + income.amount);
      final monthlyExpenses = transactions.fold<double>(0, (total, tx) => total + tx.amount.abs());
      
      final netAmount = monthlyIncome - monthlyExpenses;
      final template = _templates[NotificationType.monthlyReport]!;
      
      notifications.add(template.generate(
        data: {
          'month': _getMonthName(lastMonth.month),
          'saved_or_overspent': netAmount >= 0 ? 'saved' : 'overspent',
          'amount': '\$${netAmount.abs().toStringAsFixed(0)}',
        },
        actionRoute: '/reports',
      ));
    }
    
    return notifications;
  }

  List<SmartNotification> _generateAchievementNotifications(
    List<app_models.Transaction> transactions,
    List<IncomeSource> incomeSources,
    List<Goal> goals,
  ) {
    final notifications = <SmartNotification>[];
    // Use the provided transactions parameter instead of fetching again
    
    // Check for completed goals
    for (final goal in goals) {
      if (goal.currentAmount >= goal.targetAmount && 
          !_hasRecentNotificationOfType('achievement_${goal.id}')) {
        
        final template = _templates[NotificationType.achievementUnlocked]!;
        
        notifications.add(template.generate(
          data: {
            'achievement_description': 'You\'ve reached your ${goal.name} goal of \$${goal.targetAmount.toStringAsFixed(0)}! 🎯',
          },
          actionRoute: '/goals',
          actionArguments: {'goal_id': goal.id},
        ));
      }
    }
    
    // Check for spending milestones
    final totalTransactions = transactions.length;
    if (totalTransactions > 0 && totalTransactions % 100 == 0 && 
        !_hasRecentNotificationOfType('milestone_$totalTransactions')) {
      
      final template = _templates[NotificationType.achievementUnlocked]!;
      
      notifications.add(template.generate(
        data: {
          'achievement_description': 'You\'ve recorded $totalTransactions transactions! Your financial tracking is impressive! 📊',
        },
        actionRoute: '/reports',
      ));
    }
    
    return notifications;
  }

  bool _hasSimilarNotification(SmartNotification notification) {
    return _notifications.any((n) => 
        n.type == notification.type &&
        n.title == notification.title &&
        n.createdAt.difference(notification.createdAt).inHours.abs() < 24);
  }

  bool _hasRecentNotificationOfType(String type) {
    final oneDayAgo = DateTime.now().subtract(Duration(days: 1));
    return _notifications.any((n) => 
        n.type.toString().contains(type) && n.createdAt.isAfter(oneDayAgo));
  }

  void _sortNotifications() {
    _notifications.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
  }

  void _groupNotifications() {
    final groupMap = <NotificationType, List<SmartNotification>>{};
    
    for (final notification in _notifications) {
      groupMap.putIfAbsent(notification.type, () => []).add(notification);
    }
    
    _groups.clear();
    groupMap.forEach((type, notifications) {
      if (notifications.length > 1) {
        _groups.add(NotificationGroup(
          id: 'group_${type.name}',
          type: type,
          title: _getGroupTitle(type),
          notifications: notifications,
          createdAt: notifications.first.createdAt,
          updatedAt: notifications.last.createdAt,
        ));
      }
    });
  }

  String _getGroupTitle(NotificationType type) {
    switch (type) {
      case NotificationType.budgetAlert:
        return 'Budget Alerts';
      case NotificationType.goalReminder:
        return 'Goal Reminders';
      case NotificationType.billDue:
        return 'Bills Due';
      case NotificationType.anomalyDetected:
        return 'Unusual Activity';
      default:
        return 'Notifications';
    }
  }

  NotificationPriority _mapActionItemPriorityToNotificationPriority(ActionItemPriority priority) {
    switch (priority) {
      case ActionItemPriority.low:
        return NotificationPriority.low;
      case ActionItemPriority.medium:
        return NotificationPriority.medium;
      case ActionItemPriority.high:
        return NotificationPriority.high;
      case ActionItemPriority.urgent:
        return NotificationPriority.critical;
    }
  }

  NotificationPriority _mapAnomalySeverityToNotificationPriority(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.low:
        return NotificationPriority.low;
      case AnomalySeverity.medium:
        return NotificationPriority.medium;
      case AnomalySeverity.high:
        return NotificationPriority.high;
      case AnomalySeverity.critical:
        return NotificationPriority.critical;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<void> _sendToChannels(SmartNotification notification) async {
    for (final channel in notification.channels) {
      switch (channel) {
        case NotificationChannel.inApp:
          // Already handled by adding to _notifications
          break;
        case NotificationChannel.push:
          await _sendPushNotification(notification);
          break;
        case NotificationChannel.email:
          await _sendEmailNotification(notification);
          break;
        case NotificationChannel.sms:
          await _sendSmsNotification(notification);
          break;
      }
    }
  }

  Future<void> _sendPushNotification(SmartNotification notification) async {
    try {
      // TODO: Implement push notification using firebase_messaging
      // For now, we'll use a placeholder implementation
      _logger.info('Push notification: ${notification.title} - ${notification.message}');
      
      // Update notification as delivered via push
      await _updateNotificationStatus(notification.id, 'push_delivered');
    } catch (e) {
      _logger.warning('Failed to send push notification: $e');
    }
  }

  Future<void> _sendEmailNotification(SmartNotification notification) async {
    try {
      // TODO: Implement email notification (SendGrid, AWS SES, etc.)
      // For now, we'll use a placeholder implementation
      _logger.info('Email notification: ${notification.title} - ${notification.message}');
      
      // Update notification as delivered via email
      await _updateNotificationStatus(notification.id, 'email_delivered');
    } catch (e) {
      _logger.warning('Failed to send email notification: $e');
    }
  }

  Future<void> _sendSmsNotification(SmartNotification notification) async {
    try {
      // Get user's phone number from profile
      final phoneNumber = await _getUserPhoneNumber();
      if (phoneNumber == null) {
        _logger.warning('Cannot send SMS: User phone number not found');
        return;
      }

      // Format message for SMS (160 char limit consideration)
      final smsMessage = _formatSmsMessage(notification);
      
      // Send via Kenya SMS service
      final result = await KenyaSmsService.sendSmsNotification(
        phoneNumber: phoneNumber,
        message: smsMessage,
        notificationType: notification.type.toString(),
      );

      if (result.success) {
        _logger.info('SMS sent successfully via ${result.provider}: ${result.messageId}');
        
        // Update notification as delivered
        await _updateNotificationStatus(notification.id, 'sms_delivered');
      } else {
        _logger.warning('SMS failed to send: ${result.errorMessage}');
        
        // Fallback to push notification if SMS fails
        await _sendPushNotification(notification);
      }
    } catch (e) {
      _logger.severe('Error sending SMS notification: $e');
      
      // Fallback to push notification
      await _sendPushNotification(notification);
    }
  }
  
  /// Get user's phone number from profile
  Future<String?> _getUserPhoneNumber() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['phoneNumber'] as String?;
      }
      
      return null;
    } catch (e) {
      _logger.warning('Failed to get user phone number: $e');
      return null;
    }
  }
  
  /// Format notification message for SMS (Kenya-optimized)
  String _formatSmsMessage(SmartNotification notification) {
    // SMS character limit considerations for Kenya
    const maxLength = 160;
    
    String message = '${notification.title}\n${notification.message}';
    
    // Add FinanceFlow branding for Kenya market
    const signature = '\n- FinanceFlow Kenya';
    
    // Truncate if too long
    if (message.length + signature.length > maxLength) {
      final availableLength = maxLength - signature.length - 3; // -3 for "..."
      message = '${message.substring(0, availableLength)}...';
    }
    
    return message + signature;
  }
  
  /// Update notification delivery status
  Future<void> _updateNotificationStatus(String notificationId, String status) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'deliveryStatus': status,
            'deliveredAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      _logger.warning('Failed to update notification status: $e');
    }
  }

  void _schedulePeriodicChecks() {
    // Check for new notifications every hour
    Timer.periodic(Duration(hours: 1), (timer) {
      clearExpired();
    });
  }

  void _loadPreferences() {
    // TODO: Load preferences from SharedPreferences
    // For now, use default preferences
    _preferences = NotificationPreferences();
    // Set default values
    // Note: Actual implementation would load from SharedPreferences
  }

  void _savePreferences() {
    // TODO: Save preferences to SharedPreferences
    // For now, preferences are saved in memory only
    _logger.info('Saving notification preferences: ${_preferences.toString()}');
  }

  void dispose() {
    _notificationController.close();
  }
}
