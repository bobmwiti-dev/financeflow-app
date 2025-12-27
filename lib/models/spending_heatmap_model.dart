import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendingHeatmapData {
  final DateTime date;
  final double amount;
  final List<SpendingTransaction> transactions;
  
  SpendingHeatmapData({
    required this.date,
    required this.amount,
    required this.transactions,
  });
  
  // Get intensity level from 0-5 based on spending amount
  int getIntensityLevel(double maxDailySpending) {
    if (amount <= 0) return 0;
    
    // Calculate intensity on a scale of 0-5
    final ratio = amount / maxDailySpending;
    if (ratio < 0.1) return 1;
    if (ratio < 0.25) return 2;
    if (ratio < 0.5) return 3;
    if (ratio < 0.75) return 4;
    return 5;
  }
  
  // Get color based on intensity level
  Color getHeatColor(int intensity) {
    switch (intensity) {
      case 0: return Colors.grey.shade100; // No spending
      case 1: return Colors.green.shade100;
      case 2: return Colors.green.shade300;
      case 3: return Colors.orange.shade300;
      case 4: return Colors.orange.shade500;
      case 5: return Colors.red.shade500;
      default: return Colors.grey.shade100;
    }
  }
  
  String getFormattedDate() {
    return DateFormat('MMM d, yyyy').format(date);
  }
  
  String getFormattedAmount() {
    return '\$${amount.toStringAsFixed(2)}';
  }
  
  String getDayOfWeek() {
    return DateFormat('EEE').format(date);
  }
  
  bool isToday() {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  bool isWeekend() {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}

class SpendingTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final IconData icon;
  
  SpendingTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.icon,
  });
}

class MonthlySpendingData {
  final DateTime month;
  final List<SpendingHeatmapData> dailyData;
  
  MonthlySpendingData({
    required this.month,
    required this.dailyData,
  });
  
  String getFormattedMonth() {
    return DateFormat('MMMM yyyy').format(month);
  }
  
  double get totalSpending {
    return dailyData.fold(0, (sum, day) => sum + day.amount);
  }
  
  double get averageDailySpending {
    if (dailyData.isEmpty) return 0;
    return totalSpending / dailyData.length;
  }
  
  double get maxDailySpending {
    if (dailyData.isEmpty) return 0;
    return dailyData.map((day) => day.amount).reduce((a, b) => a > b ? a : b);
  }
  
  int get daysWithSpending {
    return dailyData.where((day) => day.amount > 0).length;
  }
  
  int get daysWithoutSpending {
    return dailyData.where((day) => day.amount <= 0).length;
  }
  
  // Get the day with highest spending
  SpendingHeatmapData? get highestSpendingDay {
    if (dailyData.isEmpty) return null;
    return dailyData.reduce((a, b) => a.amount > b.amount ? a : b);
  }
  
  // Get weekday vs weekend spending comparison
  Map<String, double> get weekdayVsWeekendSpending {
    double weekdayTotal = 0;
    double weekendTotal = 0;
    int weekdayCount = 0;
    int weekendCount = 0;
    
    for (final day in dailyData) {
      if (day.isWeekend()) {
        weekendTotal += day.amount;
        weekendCount++;
      } else {
        weekdayTotal += day.amount;
        weekdayCount++;
      }
    }
    
    final weekdayAvg = weekdayCount > 0 ? weekdayTotal / weekdayCount : 0;
    final weekendAvg = weekendCount > 0 ? weekendTotal / weekendCount : 0;
    
    return {
      'weekday': weekdayAvg.toDouble(),
      'weekend': weekendAvg.toDouble(),
    };
  }
  
  // Get spending by day of week
  Map<int, double> get spendingByDayOfWeek {
    final result = <int, double>{};
    final counts = <int, int>{};
    
    for (final day in dailyData) {
      final weekday = day.date.weekday;
      result[weekday] = (result[weekday] ?? 0) + day.amount;
      counts[weekday] = (counts[weekday] ?? 0) + 1;
    }
    
    // Convert to averages
    for (final weekday in result.keys) {
      result[weekday] = (result[weekday]! / counts[weekday]!).toDouble();
    }
    
    return result;
  }
}
