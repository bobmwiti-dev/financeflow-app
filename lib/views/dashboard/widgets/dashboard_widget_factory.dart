import 'package:financeflow_app/themes/app_theme.dart';
import 'package:flutter/material.dart';

import '../../../models/dashboard_widget_config.dart';
import '../../../services/spending_analytics_service.dart';
import 'visualizations/animated_bar_chart.dart';
import 'visualizations/animated_pie_chart.dart';
import 'visualizations/comparative_spending_widget.dart';
import 'visualizations/spending_heat_map.dart';
import 'visualizations/budget_progress_bar.dart';

/// Factory class to create dashboard widgets based on their configuration
class DashboardWidgetFactory {
  final SpendingAnalyticsService _analyticsService = SpendingAnalyticsService();
  
  /// Create a widget based on its configuration
  Widget createWidget(DashboardWidgetConfig config) {
    switch (config.type) {
      case WidgetType.spendingPieChart:
        return _createSpendingPieChart(config);
      case WidgetType.monthlySpendingTrend:
        return _createMonthlySpendingTrend(config);
      case WidgetType.categoryComparison:
        return _createCategoryComparison(config);
      case WidgetType.spendingHeatMap:
        return _createSpendingHeatMap(config);
      case WidgetType.budgetProgressBar:
        // Example: You may want to fetch these values from analytics or config
        final double budget = config.settings['budget'] ?? 2000.0;
        final double spent = config.settings['spent'] ?? 1200.0;
        final String title = config.title.isNotEmpty ? config.title : 'Budget Progress';
        return BudgetProgressBar(
          budget: budget,
          spent: spent,
          title: title,
        );
      case WidgetType.savingsGoalTracker:
        // Simple placeholder for SavingsGoalTracker
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.savings, color: Colors.green, size: 40),
                SizedBox(height: 8),
                Text('Savings Goal Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Track your savings goals here!'),
              ],
            ),
          ),
        );
      case WidgetType.recentTransactions:
        // Simple placeholder for RecentTransactions
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, color: Colors.blue, size: 40),
                SizedBox(height: 8),
                Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Your recent transactions will appear here.'),
              ],
            ),
          ),
        );
    }
  }
  
  Widget _createSpendingPieChart(DashboardWidgetConfig config) {
    final period = _getPeriodFromSettings(config.settings);
    
    return FutureBuilder<Map<String, double>>(
      future: _analyticsService.getSpendingByCategory(period),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final data = snapshot.data!;
        final maxCategories = config.settings['maxCategories'] ?? 5;
        
        // Limit to top categories if needed
        if (data.length > maxCategories) {
          final sortedEntries = data.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          final topEntries = sortedEntries.take(maxCategories - 1).toList();
          final otherValue = sortedEntries
              .skip(maxCategories - 1)
              .fold(0.0, (sum, entry) => sum + (entry.value as num).toDouble());
          
          final Map<String, double> limitedData = {
            for (var entry in topEntries) entry.key: (entry.value as num).toDouble()
          };
          
          if (otherValue > 0) {
            limitedData['Other'] = otherValue;
          }
          
          return AnimatedPieChart(
            data: limitedData,
            showLegend: config.settings['showLegend'] ?? true,
            showPercentages: config.settings['showPercentages'] ?? true,
          );
        }
        
        return AnimatedPieChart(
          data: data.map((key, value) => MapEntry(key, (value as num).toDouble())),
          showLegend: config.settings['showLegend'] ?? true,
          showPercentages: config.settings['showPercentages'] ?? true,
        );
      },
    );
  }
  
  Widget _createMonthlySpendingTrend(DashboardWidgetConfig config) {
    final months = config.settings['months'] ?? 6;
    final showAverage = config.settings['showAverage'] ?? true;
    
    return FutureBuilder<Map<DateTime, double>>(
      future: _analyticsService.getMonthlySpendingTrend(months).then((list) {
        // Convert List<MonthlySpending> to Map<DateTime, double>
        final Map<DateTime, double> map = {};
        for (final item in list) {
          map[item.month] = item.amount;
        }
        return map;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final data = snapshot.data!;
        final sortedEntries = data.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        
        final List<double> values = sortedEntries.map((e) => (e.value as num).toDouble()).toList();
        final List<String> labels = sortedEntries.map((e) => 
          '${e.key.month}/${e.key.year.toString().substring(2)}'
        ).toList();
        
        if (showAverage && values.isNotEmpty) {
          final total = values.reduce((a, b) => a + b);
          final average = total / values.length;
          values.add(average);
          labels.add('Avg');
        }
        
        return AnimatedBarChart(
          data: values,
          labels: labels,
          showValues: true,
        );
      },
    );
  }
  
  Widget _createCategoryComparison(DashboardWidgetConfig config) {
    final List<String> periodIds = List<String>.from(config.settings['periods'] ?? ['current_month', 'previous_month']);
    final List<DateTimeRange> periods = periodIds.map((id) => _getPeriodFromId(id)).toList();
    final List<String> periodLabels = periodIds.map((id) => _getPeriodLabel(id)).toList();
    // Ensure all required parameters are provided
    return CategoryComparisonWidget(
      periods: periods,
      periodLabels: periodLabels,
      categories: const ['Food', 'Transport', 'Entertainment', 'Shopping', 'Bills'],
      // Add other required parameters if needed
    );
  }
  
  Widget _createSpendingHeatMap(DashboardWidgetConfig config) {
    final period = _getPeriodFromSettings(config.settings);
    final type = _getHeatMapTypeFromSettings(config.settings);
    
    return SpendingHeatMap(
      period: period,
      type: type,
      title: config.title.isNotEmpty ? config.title : 'Spending Heat Map',
      baseColor: config.settings['color'] != null
          ? Color(config.settings['color'] as int)
          : AppTheme.accentColor,
    
    );
  }
  
  DateTimeRange _getPeriodFromSettings(Map<String, dynamic> settings) {
    final now = DateTime.now();
    final periodStr = settings['period'] ?? 'month';
    
    switch (periodStr) {
      case 'day':
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
      case 'week':
        // Start from the beginning of the week (Sunday)
        final start = now.subtract(Duration(days: now.weekday % 7));
        final normalizedStart = DateTime(start.year, start.month, start.day);
        final end = normalizedStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: normalizedStart, end: end);
      case 'year':
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year + 1, 1, 1).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
      case 'quarter':
        final currentQuarter = (now.month - 1) ~/ 3;
        final startMonth = currentQuarter * 3 + 1;
        final start = DateTime(now.year, startMonth, 1);
        final end = DateTime(now.year, startMonth + 3, 1).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
      case 'month':
      default:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
    }
  }
  
  DateTimeRange _getPeriodFromId(String periodId) {
    final now = DateTime.now();
    
    switch (periodId) {
      case 'current_month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
      case 'previous_month':
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
      case 'year_to_date':
        final start = DateTime(now.year, 1, 1);
        return DateTimeRange(start: start, end: now);
      case 'previous_year':
        final start = DateTime(now.year - 1, 1, 1);
        final end = DateTime(now.year, 1, 1).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
      default:
        // Default to current month
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
    }
  }
  
  String _getPeriodLabel(String periodId) {
    switch (periodId) {
      case 'current_month':
        return 'This Month';
      case 'previous_month':
        return 'Last Month';
      case 'year_to_date':
        return 'Year to Date';
      case 'previous_year':
        return 'Last Year';
      default:
        return periodId.replaceAll('_', ' ');
    }
  }
  
  HeatMapType _getHeatMapTypeFromSettings(Map<String, dynamic> settings) {
    final typeStr = settings['type'] ?? 'category';
    
    switch (typeStr) {
      case 'date':
        return HeatMapType.date;
      case 'location':
        return HeatMapType.location;
      case 'category':
      default:
        return HeatMapType.category;
    }
  }
}
