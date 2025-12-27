import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum GoalStatus {
  active,
  completed,
  paused,
  abandoned
}

enum GoalMilestoneType {
  percentage, // e.g., 25%, 50%, 75%
  amount,     // e.g., $500, $1000
  date        // e.g., reached $X by specific date
}

class GoalMilestone {
  final String id;
  final String title;
  final String description;
  final GoalMilestoneType type;
  final double targetValue; // percentage, amount, or date (as timestamp)
  final bool isReached;
  final DateTime? reachedDate;
  
  GoalMilestone({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.isReached = false,
    this.reachedDate,
  }) : id = id ?? const Uuid().v4();
  
  GoalMilestone copyWith({
    String? title,
    String? description,
    GoalMilestoneType? type,
    double? targetValue,
    bool? isReached,
    DateTime? reachedDate,
  }) {
    return GoalMilestone(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      isReached: isReached ?? this.isReached,
      reachedDate: reachedDate ?? this.reachedDate,
    );
  }
}

class EnhancedGoal {
  final String id;
  final String title;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime targetDate;
  final GoalStatus status;
  final Color color;
  final IconData icon;
  final List<GoalMilestone> milestones;
  final List<GoalContribution> contributions;
  
  EnhancedGoal({
    String? id,
    required this.title,
    required this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.startDate,
    required this.targetDate,
    this.status = GoalStatus.active,
    this.color = Colors.blue,
    this.icon = Icons.flag,
    List<GoalMilestone>? milestones,
    List<GoalContribution>? contributions,
  }) : 
    id = id ?? const Uuid().v4(),
    milestones = milestones ?? [],
    contributions = contributions ?? [];
  
  double get progressPercentage => 
    targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  
  int get daysRemaining => 
    targetDate.difference(DateTime.now()).inDays;
  
  bool get isCompleted => 
    currentAmount >= targetAmount || status == GoalStatus.completed;
  
  String get timeToCompletionEstimate {
    if (isCompleted) return 'Completed';
    if (contributions.isEmpty) return 'No contributions yet';
    
    // Calculate average daily contribution
    final totalDays = DateTime.now().difference(startDate).inDays;
    if (totalDays <= 0) return 'Just started';
    
    final averageDailyContribution = currentAmount / totalDays;
    if (averageDailyContribution <= 0) return 'No progress';
    
    final remainingAmount = targetAmount - currentAmount;
    final daysToComplete = remainingAmount / averageDailyContribution;
    
    if (daysToComplete < 1) return 'Almost there!';
    if (daysToComplete < 7) return '${daysToComplete.round()} days';
    if (daysToComplete < 30) return '${(daysToComplete / 7).round()} weeks';
    if (daysToComplete < 365) return '${(daysToComplete / 30).round()} months';
    return '${(daysToComplete / 365).round()} years';
  }
  
  List<GoalMilestone> get upcomingMilestones {
    if (isCompleted) return [];
    return milestones
        .where((m) => !m.isReached)
        .toList()
      ..sort((a, b) {
        if (a.type == GoalMilestoneType.percentage && b.type == GoalMilestoneType.percentage) {
          return a.targetValue.compareTo(b.targetValue);
        }
        if (a.type == GoalMilestoneType.amount && b.type == GoalMilestoneType.amount) {
          return a.targetValue.compareTo(b.targetValue);
        }
        if (a.type == GoalMilestoneType.date && b.type == GoalMilestoneType.date) {
          return a.targetValue.compareTo(b.targetValue);
        }
        // Mixed types, prioritize percentage, then amount, then date
        if (a.type == GoalMilestoneType.percentage) return -1;
        if (b.type == GoalMilestoneType.percentage) return 1;
        if (a.type == GoalMilestoneType.amount) return -1;
        if (b.type == GoalMilestoneType.amount) return 1;
        return 0;
      });
  }
  
  EnhancedGoal copyWith({
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    GoalStatus? status,
    Color? color,
    IconData? icon,
    List<GoalMilestone>? milestones,
    List<GoalContribution>? contributions,
  }) {
    return EnhancedGoal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      milestones: milestones ?? this.milestones,
      contributions: contributions ?? this.contributions,
    );
  }
  
  EnhancedGoal addContribution(GoalContribution contribution) {
    final newContributions = List<GoalContribution>.from(contributions)..add(contribution);
    final newCurrentAmount = currentAmount + contribution.amount;
    
    // Check if any milestones are reached
    final newMilestones = milestones.map((milestone) {
      if (milestone.isReached) return milestone;
      
      bool isReached = false;
      switch (milestone.type) {
        case GoalMilestoneType.percentage:
          isReached = (newCurrentAmount / targetAmount) >= (milestone.targetValue / 100);
          break;
        case GoalMilestoneType.amount:
          isReached = newCurrentAmount >= milestone.targetValue;
          break;
        case GoalMilestoneType.date:
          // Date milestones are checked separately
          break;
      }
      
      if (isReached) {
        return milestone.copyWith(
          isReached: true,
          reachedDate: DateTime.now(),
        );
      }
      return milestone;
    }).toList();
    
    // Check if goal is completed
    final newStatus = newCurrentAmount >= targetAmount ? GoalStatus.completed : status;
    
    return copyWith(
      currentAmount: newCurrentAmount,
      contributions: newContributions,
      milestones: newMilestones,
      status: newStatus,
    );
  }
}

class GoalContribution {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;
  
  GoalContribution({
    String? id,
    required this.amount,
    required this.date,
    this.note,
  }) : id = id ?? const Uuid().v4();
}
