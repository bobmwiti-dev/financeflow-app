import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Service for fetching and analyzing spending data
class SpendingAnalyticsService {
  // This would normally fetch data from a database or API
  // For now, we'll generate mock data for demonstration purposes
  
  /// Get total spending for a given period and category
  Future<double> getTotalSpending(DateTimeRange period, {String category = 'All'}) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (category == 'All') {
      return 1200 + math.Random().nextDouble() * 800;
    }
    
    // Return mock data based on category
    switch (category) {
      case 'Food':
        return 350 + math.Random().nextDouble() * 150;
      case 'Transport':
        return 200 + math.Random().nextDouble() * 100;
      case 'Entertainment':
        return 150 + math.Random().nextDouble() * 100;
      case 'Shopping':
        return 250 + math.Random().nextDouble() * 200;
      case 'Bills':
        return 400 + math.Random().nextDouble() * 100;
      default:
        return 100 + math.Random().nextDouble() * 100;
    }
  }
  
  /// Get spending breakdown by category for a given period
  Future<Map<String, double>> getSpendingByCategory(DateTimeRange period) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock data
    return {
      'Food': 350 + math.Random().nextDouble() * 150,
      'Transport': 200 + math.Random().nextDouble() * 100,
      'Entertainment': 150 + math.Random().nextDouble() * 100,
      'Shopping': 250 + math.Random().nextDouble() * 200,
      'Bills': 400 + math.Random().nextDouble() * 100,
      'Other': 100 + math.Random().nextDouble() * 100,
    };
  }
  
  /// Get spending data by date for a given period
  Future<Map<DateTime, double>> getSpendingByDate(DateTimeRange period) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Generate daily spending data for the period
    final Map<DateTime, double> result = {};
    
    for (DateTime date = period.start;
         date.isBefore(period.end) || date.isAtSameMomentAs(period.end);
         date = date.add(const Duration(days: 1))) {
      
      // Generate a somewhat realistic spending pattern
      // Weekends have higher spending
      double baseAmount = 30.0;
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        baseAmount = 60.0;
      }
      
      // Add some randomness
      final double amount = baseAmount + math.Random().nextDouble() * baseAmount;
      result[date] = amount;
    }
    
    return result;
  }
  
  /// Get spending data by location
  Future<Map<String, double>> getSpendingByLocation() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock data
    return {
      'Supermarket': 300 + math.Random().nextDouble() * 150,
      'Restaurant': 200 + math.Random().nextDouble() * 100,
      'Gas Station': 150 + math.Random().nextDouble() * 50,
      'Mall': 250 + math.Random().nextDouble() * 150,
      'Online': 350 + math.Random().nextDouble() * 200,
      'Utility Provider': 200 + math.Random().nextDouble() * 50,
    };
  }
  
  /// Get monthly spending data for trend analysis
  Future<List<MonthlySpending>> getMonthlySpendingTrend(int months) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 600));
    
    final List<MonthlySpending> result = [];
    final DateTime now = DateTime.now();
    
    for (int i = months - 1; i >= 0; i--) {
      final DateTime month = DateTime(now.year, now.month - i, 1);
      
      // Generate somewhat realistic monthly spending with a slight upward trend
      final double baseAmount = 1000.0 + (months - i) * 50;
      final double randomFactor = math.Random().nextDouble() * 300 - 150; // +/- 150
      
      result.add(MonthlySpending(
        month: month,
        amount: baseAmount + randomFactor,
      ));
    }
    
    return result;
  }
  
  /// Get comparative spending data for categories across different periods
  Future<Map<String, List<double>>> getCategoryComparison(
      List<DateTimeRange> periods, List<String> categories) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 700));
    
    // If no specific categories requested, use default ones
    final categoriesToUse = categories.isEmpty
        ? ['Food', 'Transport', 'Entertainment', 'Shopping', 'Bills']
        : categories;
    
    final Map<String, List<double>> result = {};
    
    for (final category in categoriesToUse) {
      result[category] = [];
      
      for (final period in periods) {
        // Generate somewhat consistent data for each category across periods
        double baseAmount;
        switch (category) {
          case 'Food':
            baseAmount = 350;
            break;
          case 'Transport':
            baseAmount = 200;
            break;
          case 'Entertainment':
            baseAmount = 150;
            break;
          case 'Shopping':
            baseAmount = 250;
            break;
          case 'Bills':
            baseAmount = 400;
            break;
          default:
            baseAmount = 100;
        }
        
        // Add some randomness and a slight trend
        final int periodIndex = periods.indexOf(period);
        final double trendFactor = 1.0 + (periodIndex * 0.05); // 5% increase per period
        final double randomFactor = 0.8 + math.Random().nextDouble() * 0.4; // 80-120%
        
        result[category]!.add(baseAmount * trendFactor * randomFactor);
      }
    }
    
    return result;
  }
}

/// Model class for monthly spending data
class MonthlySpending {
  final DateTime month;
  final double amount;
  
  MonthlySpending({
    required this.month,
    required this.amount,
  });
}

/// Helper class for heat map data
class HeatMapData {
  final Map<String, double> data;
  final double minValue;
  final double maxValue;
  
  HeatMapData({
    required this.data,
    required this.minValue,
    required this.maxValue,
  });
  
  /// Create from raw data
  factory HeatMapData.fromMap(Map<String, double> data) {
    if (data.isEmpty) {
      return HeatMapData(data: {}, minValue: 0, maxValue: 0);
    }
    
    final double minValue = data.values.reduce(math.min);
    final double maxValue = data.values.reduce(math.max);
    
    return HeatMapData(
      data: data,
      minValue: minValue,
      maxValue: maxValue,
    );
  }
  
  /// Get color intensity for a value (0.0 to 1.0)
  double getIntensity(String key) {
    if (!data.containsKey(key) || maxValue == minValue) {
      return 0.0;
    }
    
    return (data[key]! - minValue) / (maxValue - minValue);
  }
}
