import 'package:flutter/material.dart';

enum ActionItemType {
  budgetAlert,
  goalAlert,
  billReminder,
  mpesaAlert,
  anomalyAction,
  savingsOpportunity,
  debtAlert,
  categoryReview,
}

enum ActionItemPriority {
  low,
  medium,
  high,
  urgent,
}

class ActionItem {
  final String id;
  final ActionItemType type;
  final ActionItemPriority priority;
  final String title;
  final String description;
  final String actionText;
  final String targetRoute;
  final Map<String, dynamic> routeArguments;
  final DateTime createdAt;
  final DateTime? dueDate;
  final double? amount;
  final String? category;
  final bool isDismissible;
  final Map<String, dynamic> metadata;

  ActionItem({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.actionText,
    required this.targetRoute,
    this.routeArguments = const {},
    required this.createdAt,
    this.dueDate,
    this.amount,
    this.category,
    this.isDismissible = true,
    this.metadata = const {},
  });

  // Get icon based on action item type
  IconData get icon {
    switch (type) {
      case ActionItemType.budgetAlert:
        return Icons.account_balance_wallet;
      case ActionItemType.goalAlert:
        return Icons.flag;
      case ActionItemType.billReminder:
        return Icons.receipt_long;
      case ActionItemType.mpesaAlert:
        return Icons.phone_android;
      case ActionItemType.anomalyAction:
        return Icons.warning;
      case ActionItemType.savingsOpportunity:
        return Icons.savings;
      case ActionItemType.debtAlert:
        return Icons.credit_card;
      case ActionItemType.categoryReview:
        return Icons.category;
    }
  }

  // Get color based on priority
  Color get color {
    switch (priority) {
      case ActionItemPriority.low:
        return Colors.blue;
      case ActionItemPriority.medium:
        return Colors.orange;
      case ActionItemPriority.high:
        return Colors.red;
      case ActionItemPriority.urgent:
        return Colors.purple;
    }
  }

  // Get priority label
  String get priorityLabel {
    switch (priority) {
      case ActionItemPriority.low:
        return 'Info';
      case ActionItemPriority.medium:
        return 'Notice';
      case ActionItemPriority.high:
        return 'Important';
      case ActionItemPriority.urgent:
        return 'Urgent';
    }
  }

  // Get urgency score for sorting
  int get urgencyScore {
    int baseScore = priority.index * 100;
    
    // Add urgency based on due date
    if (dueDate != null) {
      final daysUntilDue = dueDate!.difference(DateTime.now()).inDays;
      if (daysUntilDue <= 0) {
        baseScore += 200; // Overdue
      } else if (daysUntilDue <= 1) {
        baseScore += 150; // Due today/tomorrow
      } else if (daysUntilDue <= 7) {
        baseScore += 100; // Due this week
      }
    }
    
    // Add urgency based on amount
    if (amount != null && amount! > 1000) {
      baseScore += 50; // High amount
    }
    
    return baseScore;
  }

  @override
  String toString() {
    return 'ActionItem{type: $type, priority: $priority, title: $title}';
  }
}

enum NavigationShortcutType {
  screen,
  feature,
  analysis,
  management,
}

class NavigationShortcut {
  final String id;
  final NavigationShortcutType type;
  final String title;
  final String description;
  final String route;
  final Map<String, dynamic> arguments;
  final IconData icon;
  final Color color;
  final String? badge; // For showing counts or status
  final bool isEnabled;
  final int priority; // For ordering

  NavigationShortcut({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.route,
    this.arguments = const {},
    required this.icon,
    required this.color,
    this.badge,
    this.isEnabled = true,
    this.priority = 0,
  });

  @override
  String toString() {
    return 'NavigationShortcut{title: $title, route: $route}';
  }
}

class QuickInsight {
  final String id;
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color color;
  final String? trend; // "up", "down", "stable"
  final double? changePercentage;

  QuickInsight({
    required this.id,
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
    this.trend,
    this.changePercentage,
  });

  @override
  String toString() {
    return 'QuickInsight{title: $title, value: $value}';
  }
}
