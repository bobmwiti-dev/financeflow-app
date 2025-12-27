import 'package:flutter/material.dart';

enum FamilyRole {
  parent,
  child,
  teen,
  guardian,
}

enum BudgetStatus {
  safe,
  warning,
  danger,
  exceeded,
}

class FamilyMember {
  final String? id;
  final String name;
  final double budget;
  final double spent;
  final FamilyRole role;
  final String? avatarPath;
  final DateTime? dateOfBirth;
  final String? email;
  final bool isActive;
  final Map<String, dynamic>? preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FamilyMember({
    this.id,
    required this.name,
    required this.budget,
    this.role = FamilyRole.child,
    this.spent = 0.0,
    this.avatarPath,
    this.dateOfBirth,
    this.email,
    this.isActive = true,
    this.preferences,
    this.createdAt,
    this.updatedAt,
  }) : assert(budget >= 0, 'Budget cannot be negative'),
       assert(spent >= 0, 'Spent amount cannot be negative'),
       assert(name.trim().isNotEmpty, 'Name cannot be empty');

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'budget': budget,
      'spent': spent,
      'role': role.name,
      'avatarPath': avatarPath,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'email': email,
      'isActive': isActive,
      'preferences': preferences,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      budget: (map['budget'] ?? 0.0).toDouble(),
      spent: (map['spent'] ?? 0.0).toDouble(),
      role: FamilyRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => FamilyRole.child,
      ),
      avatarPath: map['avatarPath'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'])
          : null,
      email: map['email'],
      isActive: map['isActive'] ?? true,
      preferences: map['preferences'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  // Computed properties
  double get remaining => budget - spent;
  double get percentUsed => budget > 0 ? (spent / budget) * 100 : 0.0;
  bool get isOverBudget => spent > budget;
  double get overBudgetAmount => isOverBudget ? spent - budget : 0.0;

  // Age calculation
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // Budget status
  BudgetStatus get budgetStatus {
    if (percentUsed >= 100) return BudgetStatus.exceeded;
    if (percentUsed >= 80) return BudgetStatus.danger;
    if (percentUsed >= 60) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }

  // Status color
  Color get statusColor {
    switch (budgetStatus) {
      case BudgetStatus.safe:
        return Colors.green;
      case BudgetStatus.warning:
        return Colors.orange;
      case BudgetStatus.danger:
        return Colors.red.shade700;
      case BudgetStatus.exceeded:
        return Colors.red.shade900;
    }
  }

  // Role-based budget presets
  static const Map<FamilyRole, double> rolePresets = {
    FamilyRole.parent: 2000.0,
    FamilyRole.guardian: 1500.0,
    FamilyRole.teen: 500.0,
    FamilyRole.child: 200.0,
  };

  // Role display names
  static const Map<FamilyRole, String> roleDisplayNames = {
    FamilyRole.parent: 'Parent',
    FamilyRole.guardian: 'Guardian',
    FamilyRole.teen: 'Teenager',
    FamilyRole.child: 'Child',
  };

  // Role icons
  static const Map<FamilyRole, IconData> roleIcons = {
    FamilyRole.parent: Icons.person,
    FamilyRole.guardian: Icons.shield,
    FamilyRole.teen: Icons.school,
    FamilyRole.child: Icons.child_care,
  };

  // Get suggested budget based on role
  double get suggestedBudget => rolePresets[role] ?? 200.0;
  
  // Get role display name
  String get roleDisplayName => roleDisplayNames[role] ?? 'Child';
  
  // Get role icon
  IconData get roleIcon => roleIcons[role] ?? Icons.child_care;

  // Budget recommendation based on age
  double get recommendedBudget {
    if (age == null) return suggestedBudget;
    
    switch (role) {
      case FamilyRole.child:
        if (age! < 8) return 50.0;
        if (age! < 12) return 100.0;
        return 200.0;
      case FamilyRole.teen:
        if (age! < 16) return 300.0;
        return 500.0;
      case FamilyRole.parent:
      case FamilyRole.guardian:
        return suggestedBudget;
    }
  }

  // Spending velocity (spending per day)
  double getSpendingVelocity(DateTime periodStart) {
    final daysSinceStart = DateTime.now().difference(periodStart).inDays;
    return daysSinceStart > 0 ? spent / daysSinceStart : 0.0;
  }

  // Projected spending for the month
  double getProjectedMonthlySpending(DateTime monthStart) {
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final velocity = getSpendingVelocity(monthStart);
    return velocity * daysInMonth;
  }

  // Copy with method
  FamilyMember copyWith({
    String? id,
    String? name,
    double? budget,
    double? spent,
    FamilyRole? role,
    String? avatarPath,
    DateTime? dateOfBirth,
    String? email,
    bool? isActive,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FamilyMember(id: $id, name: $name, role: ${role.name}, budget: $budget, spent: $spent)';
  }
}
