import 'package:flutter/material.dart';
import 'dashboard_widget_config.dart';

/// Configuration for the dashboard layout and widgets
class DashboardConfig {
  final List<DashboardWidgetConfig> widgets;
  final bool showQuickActions;
  final bool showRecentTransactions;
  final bool showFinancialSummary;

  DashboardConfig({
    required this.widgets,
    this.showQuickActions = true,
    this.showRecentTransactions = true,
    this.showFinancialSummary = true,
  });

  /// Create a default dashboard configuration
  static DashboardConfig createDefault() {
    return DashboardConfig(
      widgets: [
        DashboardWidgetConfig(
          id: 'monthly-spending',
          name: 'Monthly Spending',
          title: 'Monthly Spending',
          type: WidgetType.monthlySpendingTrend,
          position: 0,
          settings: {
            'chartType': 'line',
            'showLegend': true,
          },
          size: const Size(1, 240),
        ),
        DashboardWidgetConfig(
          id: 'category-breakdown',
          name: 'Category Breakdown',
          title: 'Spending by Category',
          type: WidgetType.spendingPieChart,
          position: 1,
          settings: {
            'chartType': 'pie',
            'showLegend': true,
          },
          size: const Size(1, 240),
        ),
      ],
      showQuickActions: true,
      showRecentTransactions: true,
      showFinancialSummary: true,
    );
  }

  /// Create a copy with updated properties
  DashboardConfig copyWith({
    List<DashboardWidgetConfig>? widgets,
    bool? showQuickActions,
    bool? showRecentTransactions,
    bool? showFinancialSummary,
  }) {
    return DashboardConfig(
      widgets: widgets ?? this.widgets,
      showQuickActions: showQuickActions ?? this.showQuickActions,
      showRecentTransactions: showRecentTransactions ?? this.showRecentTransactions,
      showFinancialSummary: showFinancialSummary ?? this.showFinancialSummary,
    );
  }
  
  /// Create from JSON
  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    final List<dynamic> widgetsJson = json['widgets'] ?? [];
    return DashboardConfig(
      widgets: widgetsJson.map((w) => DashboardWidgetConfig.fromJson(w)).toList(),
      showQuickActions: json['showQuickActions'] ?? true,
      showRecentTransactions: json['showRecentTransactions'] ?? true,
      showFinancialSummary: json['showFinancialSummary'] ?? true,
    );
  }
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'widgets': widgets.map((w) => w.toJson()).toList(),
      'showQuickActions': showQuickActions,
      'showRecentTransactions': showRecentTransactions,
      'showFinancialSummary': showFinancialSummary,
    };
  }
}
