import 'package:flutter/material.dart';

enum NotificationType {
  budgetAlert,
  goalReminder,
  billDue,
  anomalyDetected,
  savingsOpportunity,
  mpesaAlert,
  weeklyInsight,
  monthlyReport,
  emergencyAlert,
  achievementUnlocked,
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

enum NotificationChannel {
  inApp,
  push,
  email,
  sms,
}

enum NotificationFrequency {
  immediate,
  daily,
  weekly,
  monthly,
  custom,
}

class SmartNotification {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final String? subtitle;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? expiresAt;
  final List<NotificationChannel> channels;
  final String? actionRoute;
  final Map<String, dynamic> actionArguments;
  final bool isRead;
  final bool isActioned;
  final String? imageUrl;
  final Color? accentColor;

  SmartNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.subtitle,
    this.data = const {},
    required this.createdAt,
    this.scheduledFor,
    this.expiresAt,
    this.channels = const [NotificationChannel.inApp],
    this.actionRoute,
    this.actionArguments = const {},
    this.isRead = false,
    this.isActioned = false,
    this.imageUrl,
    this.accentColor,
  });

  // Get icon based on notification type
  IconData get icon {
    switch (type) {
      case NotificationType.budgetAlert:
        return Icons.account_balance_wallet;
      case NotificationType.goalReminder:
        return Icons.flag;
      case NotificationType.billDue:
        return Icons.receipt_long;
      case NotificationType.anomalyDetected:
        return Icons.warning;
      case NotificationType.savingsOpportunity:
        return Icons.savings;
      case NotificationType.mpesaAlert:
        return Icons.phone_android;
      case NotificationType.weeklyInsight:
        return Icons.insights;
      case NotificationType.monthlyReport:
        return Icons.assessment;
      case NotificationType.emergencyAlert:
        return Icons.emergency;
      case NotificationType.achievementUnlocked:
        return Icons.emoji_events;
    }
  }

  // Get color based on priority
  Color get color {
    if (accentColor != null) return accentColor!;
    
    switch (priority) {
      case NotificationPriority.low:
        return Colors.blue;
      case NotificationPriority.medium:
        return Colors.orange;
      case NotificationPriority.high:
        return Colors.red;
      case NotificationPriority.critical:
        return Colors.purple;
    }
  }

  // Get priority label
  String get priorityLabel {
    switch (priority) {
      case NotificationPriority.low:
        return 'Info';
      case NotificationPriority.medium:
        return 'Notice';
      case NotificationPriority.high:
        return 'Important';
      case NotificationPriority.critical:
        return 'Urgent';
    }
  }

  // Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Check if notification should be shown now
  bool get shouldShow {
    if (isExpired) return false;
    if (scheduledFor == null) return true;
    return DateTime.now().isAfter(scheduledFor!);
  }

  // Get urgency score for sorting
  int get urgencyScore {
    int baseScore = priority.index * 100;
    
    // Add urgency based on type
    switch (type) {
      case NotificationType.emergencyAlert:
        baseScore += 200;
        break;
      case NotificationType.billDue:
        baseScore += 150;
        break;
      case NotificationType.budgetAlert:
        baseScore += 100;
        break;
      case NotificationType.anomalyDetected:
        baseScore += 80;
        break;
      case NotificationType.goalReminder:
        baseScore += 60;
        break;
      default:
        break;
    }
    
    // Add urgency based on time sensitivity
    if (scheduledFor != null) {
      final hoursUntilScheduled = scheduledFor!.difference(DateTime.now()).inHours;
      if (hoursUntilScheduled <= 1) {
        baseScore += 50;
      }
    }
    
    return baseScore;
  }

  // Create copy with updated fields
  SmartNotification copyWith({
    bool? isRead,
    bool? isActioned,
    DateTime? scheduledFor,
  }) {
    return SmartNotification(
      id: id,
      type: type,
      priority: priority,
      title: title,
      message: message,
      subtitle: subtitle,
      data: data,
      createdAt: createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      expiresAt: expiresAt,
      channels: channels,
      actionRoute: actionRoute,
      actionArguments: actionArguments,
      isRead: isRead ?? this.isRead,
      isActioned: isActioned ?? this.isActioned,
      imageUrl: imageUrl,
      accentColor: accentColor,
    );
  }

  @override
  String toString() {
    return 'SmartNotification{type: $type, priority: $priority, title: $title}';
  }
}

class NotificationPreferences {
  final bool enableInAppNotifications;
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSmsNotifications;
  final Map<NotificationType, bool> typePreferences;
  final Map<NotificationType, NotificationFrequency> frequencyPreferences;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final List<int> enabledWeekdays; // 1-7, Monday-Sunday
  final bool respectQuietHours;
  final bool groupSimilarNotifications;
  final int maxDailyNotifications;

  NotificationPreferences({
    this.enableInAppNotifications = true,
    this.enablePushNotifications = true,
    this.enableEmailNotifications = false,
    this.enableSmsNotifications = false,
    this.typePreferences = const {},
    this.frequencyPreferences = const {},
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 7, minute: 0),
    this.enabledWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.respectQuietHours = true,
    this.groupSimilarNotifications = true,
    this.maxDailyNotifications = 10,
  });

  // Check if a notification type is enabled
  bool isTypeEnabled(NotificationType type) {
    return typePreferences[type] ?? true;
  }

  // Get frequency for a notification type
  NotificationFrequency getFrequency(NotificationType type) {
    return frequencyPreferences[type] ?? NotificationFrequency.immediate;
  }

  // Check if notifications should be sent at current time
  bool shouldSendNow() {
    if (!respectQuietHours) return true;
    
    final now = TimeOfDay.now();
    final currentWeekday = DateTime.now().weekday;
    
    // Check if current weekday is enabled
    if (!enabledWeekdays.contains(currentWeekday)) return false;
    
    // Check quiet hours
    final quietStart = quietHoursStart;
    final quietEnd = quietHoursEnd;
    
    // Handle quiet hours that span midnight
    if (quietStart.hour > quietEnd.hour) {
      // Quiet hours span midnight (e.g., 22:00 - 07:00)
      return !(now.hour >= quietStart.hour || now.hour < quietEnd.hour);
    } else {
      // Quiet hours within same day (e.g., 12:00 - 14:00)
      return !(now.hour >= quietStart.hour && now.hour < quietEnd.hour);
    }
  }
}

class NotificationTemplate {
  final NotificationType type;
  final String titleTemplate;
  final String messageTemplate;
  final NotificationPriority defaultPriority;
  final List<NotificationChannel> defaultChannels;
  final Duration? defaultExpiry;
  final Color? accentColor;

  NotificationTemplate({
    required this.type,
    required this.titleTemplate,
    required this.messageTemplate,
    required this.defaultPriority,
    this.defaultChannels = const [NotificationChannel.inApp, NotificationChannel.push],
    this.defaultExpiry,
    this.accentColor,
  });

  // Generate notification from template with data
  SmartNotification generate({
    required Map<String, dynamic> data,
    String? customTitle,
    String? customMessage,
    NotificationPriority? priority,
    List<NotificationChannel>? channels,
    DateTime? scheduledFor,
    String? actionRoute,
    Map<String, dynamic>? actionArguments,
  }) {
    final now = DateTime.now();
    
    return SmartNotification(
      id: 'notif_${type.name}_${now.millisecondsSinceEpoch}',
      type: type,
      priority: priority ?? defaultPriority,
      title: customTitle ?? _replaceTemplateVariables(titleTemplate, data),
      message: customMessage ?? _replaceTemplateVariables(messageTemplate, data),
      data: data,
      createdAt: now,
      scheduledFor: scheduledFor,
      expiresAt: defaultExpiry != null ? now.add(defaultExpiry!) : null,
      channels: channels ?? defaultChannels,
      actionRoute: actionRoute,
      actionArguments: actionArguments ?? {},
      accentColor: accentColor,
    );
  }

  String _replaceTemplateVariables(String template, Map<String, dynamic> data) {
    String result = template;
    
    data.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    
    return result;
  }
}

class NotificationAction {
  final String id;
  final String label;
  final IconData icon;
  final String? route;
  final Map<String, dynamic> arguments;
  final VoidCallback? onTap;

  NotificationAction({
    required this.id,
    required this.label,
    required this.icon,
    this.route,
    this.arguments = const {},
    this.onTap,
  });
}

class NotificationGroup {
  final String id;
  final NotificationType type;
  final String title;
  final List<SmartNotification> notifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationGroup({
    required this.id,
    required this.type,
    required this.title,
    required this.notifications,
    required this.createdAt,
    required this.updatedAt,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  
  SmartNotification get latestNotification => notifications.last;
  
  NotificationPriority get highestPriority {
    return notifications
        .map((n) => n.priority)
        .reduce((a, b) => a.index > b.index ? a : b);
  }
}
