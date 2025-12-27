import 'package:flutter/material.dart';

/// Enum defining the types of widgets available for the dashboard
enum WidgetType {
  spendingPieChart,
  budgetProgressBar, // Kept for backward compatibility but functionality removed
  savingsGoalTracker,
  recentTransactions,
  monthlySpendingTrend,
  categoryComparison,
  spendingHeatMap,
}

/// Model class for dashboard widget configuration
class DashboardWidgetConfig {
  final String id;
  final String name;
  final String title;
  final WidgetType type;
  final Map<String, dynamic> settings;
  final int position;
  final Size size;

  DashboardWidgetConfig({
    required this.id,
    required this.name,
    required this.title,
    required this.type,
    required this.settings,
    required this.position,
    this.size = const Size(1, 1), // Default size (can be used for grid layout)
  });

  /// Create a copy of this configuration with updated values
  DashboardWidgetConfig copyWith({
    String? id,
    String? name,
    String? title,
    WidgetType? type,
    Map<String, dynamic>? settings,
    int? position,
    Size? size,
  }) {
    return DashboardWidgetConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      type: type ?? this.type,
      settings: settings ?? Map.from(this.settings),
      position: position ?? this.position,
      size: size ?? this.size,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'type': type.toString().split('.').last,
      'settings': settings,
      'position': position,
      'size': {
        'width': size.width,
        'height': size.height,
      },
    };
  }

  /// Create from JSON
  factory DashboardWidgetConfig.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetConfig(
      id: json['id'],
      name: json['name'] ?? 'Widget',
      title: json['title'],
      type: WidgetType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => WidgetType.spendingPieChart,
      ),
      settings: Map<String, dynamic>.from(json['settings']),
      position: json['position'],
      size: Size(
        json['size']['width'].toDouble(),
        json['size']['height'].toDouble(),
      ),
    );
  }

  /// Create default configurations for each widget type
  static DashboardWidgetConfig createDefault(WidgetType type, int position) {
    switch (type) {
      case WidgetType.spendingPieChart:
        return DashboardWidgetConfig(
          id: 'pie_chart_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Spending Pie Chart',
          title: 'Spending by Category',
          type: type,
          settings: {
            'period': 'month',
            'showLegend': true,
            'maxCategories': 5,
          },
          position: position,
        );
      case WidgetType.budgetProgressBar:
        return DashboardWidgetConfig(
          id: 'budget_progress_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Budget Progress Bar',
          title: 'Budget Progress',
          type: type,
          settings: {
            'period': 'month',
            'showRemaining': true,
          },
          position: position,
        );
      case WidgetType.savingsGoalTracker:
        return DashboardWidgetConfig(
          id: 'savings_goal_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Savings Goal Tracker',
          title: 'Savings Goals',
          type: type,
          settings: {
            'showAllGoals': true,
            'sortBy': 'progress',
          },
          position: position,
        );
      case WidgetType.recentTransactions:
        return DashboardWidgetConfig(
          id: 'recent_transactions_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Recent Transactions',
          title: 'Recent Transactions',
          type: type,
          settings: {
            'limit': 5,
            'showAmount': true,
          },
          position: position,
        );
      case WidgetType.monthlySpendingTrend:
        return DashboardWidgetConfig(
          id: 'monthly_trend_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Monthly Spending Trend',
          title: 'Monthly Spending Trend',
          type: type,
          settings: {
            'months': 6,
            'showAverage': true,
          },
          position: position,
          size: const Size(2, 1), // Double width for trend charts
        );
      case WidgetType.categoryComparison:
        return DashboardWidgetConfig(
          id: 'category_comparison_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Category Comparison',
          title: 'Category Comparison',
          type: type,
          settings: {
            'periods': ['current_month', 'previous_month'],
            'categories': [],
          },
          position: position,
          size: const Size(2, 1), // Double width for comparison charts
        );
      case WidgetType.spendingHeatMap:
        return DashboardWidgetConfig(
          id: 'heat_map_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Spending Heat Map',
          title: 'Spending Heat Map',
          type: type,
          settings: {
            'period': 'month',
            'type': 'category',
          },
          position: position,
          size: const Size(2, 2), // Full width and height for heat maps
        );
    }
  }
}

/// Model class for storing the entire dashboard configuration
class DashboardConfig {
  final List<DashboardWidgetConfig> widgets;
  final String name;
  final bool isDefault;

  DashboardConfig({
    required this.widgets,
    required this.name,
    this.isDefault = false,
  });

  /// Create a copy with updated values
  DashboardConfig copyWith({
    List<DashboardWidgetConfig>? widgets,
    String? name,
    bool? isDefault,
  }) {
    return DashboardConfig(
      widgets: widgets ?? List.from(this.widgets),
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'widgets': widgets.map((w) => w.toJson()).toList(),
      'name': name,
      'isDefault': isDefault,
    };
  }

  /// Create from JSON
  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    return DashboardConfig(
      widgets: (json['widgets'] as List)
          .map((w) => DashboardWidgetConfig.fromJson(w))
          .toList(),
      name: json['name'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  /// Create a default dashboard configuration
  static DashboardConfig createDefault() {
    return DashboardConfig(
      name: 'Default Dashboard',
      isDefault: true,
      widgets: [
        DashboardWidgetConfig.createDefault(WidgetType.spendingPieChart, 0),
        DashboardWidgetConfig.createDefault(WidgetType.budgetProgressBar, 1),
        DashboardWidgetConfig.createDefault(WidgetType.monthlySpendingTrend, 2),
        DashboardWidgetConfig.createDefault(WidgetType.recentTransactions, 3),
      ],
    );
  }
}
