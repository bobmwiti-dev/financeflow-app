import 'package:flutter/material.dart';

class BudgetCategory {
  final String name;
  final double amount;
  final double spent;
  final Color color;
  final IconData icon;
  final List<BudgetSubcategory> subcategories;

  BudgetCategory({
    required this.name,
    required this.amount,
    required this.spent,
    required this.color,
    required this.icon,
    required this.subcategories,
  });

  double get remaining => amount - spent;
  double get percentSpent => amount > 0 ? (spent / amount) * 100 : 0;
  double get percentValue => amount > 0 ? amount / 100 : 0;
}

class BudgetSubcategory {
  final String name;
  final double amount;
  final double spent;
  final IconData icon;

  BudgetSubcategory({
    required this.name,
    required this.amount,
    required this.spent,
    required this.icon,
  });

  double get remaining => amount - spent;
  double get percentSpent => amount > 0 ? (spent / amount) * 100 : 0;
  double get percentOfParent => amount > 0 ? amount / 100 : 0;
}

class FamilyMember {
  final String name;
  final String avatarUrl;
  final double budgetAllocation;
  final double spent;
  final List<BudgetCategory> categories;

  FamilyMember({
    required this.name,
    required this.avatarUrl,
    required this.budgetAllocation,
    required this.spent,
    required this.categories,
  });

  double get remaining => budgetAllocation - spent;
  double get percentSpent => budgetAllocation > 0 ? (spent / budgetAllocation) * 100 : 0;
}

class FamilyGoal {
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final IconData icon;
  final Color color;

  FamilyGoal({
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.icon,
    required this.color,
  });

  double get percentComplete => targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;
  bool get isCompleted => currentAmount >= targetAmount;
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;
}

class FamilyBudgetData {
  final double totalBudget;
  final double totalSpent;
  final List<BudgetCategory> categories;
  final List<FamilyMember> members;
  final List<FamilyGoal> goals;

  FamilyBudgetData({
    required this.totalBudget,
    required this.totalSpent,
    required this.categories,
    required this.members,
    required this.goals,
  });

  double get remaining => totalBudget - totalSpent;
  double get percentSpent => totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;
}

// Sample data for testing
class FamilyBudgetSampleData {
  static FamilyBudgetData getSampleData() {
    // Housing subcategories
    final housingSubcategories = [
      BudgetSubcategory(
        name: 'Rent/Mortgage',
        amount: 1200,
        spent: 1200,
        icon: Icons.home,
      ),
      BudgetSubcategory(
        name: 'Utilities',
        amount: 250,
        spent: 230,
        icon: Icons.bolt,
      ),
      BudgetSubcategory(
        name: 'Maintenance',
        amount: 125,
        spent: 75,
        icon: Icons.build,
      ),
    ];

    // Food subcategories
    final foodSubcategories = [
      BudgetSubcategory(
        name: 'Groceries',
        amount: 800,
        spent: 720,
        icon: Icons.shopping_cart,
      ),
      BudgetSubcategory(
        name: 'Dining Out',
        amount: 300,
        spent: 350,
        icon: Icons.restaurant,
      ),
    ];

    // Transportation subcategories
    final transportSubcategories = [
      BudgetSubcategory(
        name: 'Gas',
        amount: 200,
        spent: 180,
        icon: Icons.local_gas_station,
      ),
      BudgetSubcategory(
        name: 'Public Transit',
        amount: 100,
        spent: 90,
        icon: Icons.directions_bus,
      ),
      BudgetSubcategory(
        name: 'Car Maintenance',
        amount: 150,
        spent: 75,
        icon: Icons.car_repair,
      ),
    ];

    // Utilities subcategories
    final utilitiesSubcategories = [
      BudgetSubcategory(
        name: 'Internet',
        amount: 80,
        spent: 80,
        icon: Icons.wifi,
      ),
      BudgetSubcategory(
        name: 'Phone',
        amount: 120,
        spent: 120,
        icon: Icons.phone_android,
      ),
      BudgetSubcategory(
        name: 'Streaming',
        amount: 50,
        spent: 65,
        icon: Icons.tv,
      ),
    ];

    // Other subcategories
    final otherSubcategories = [
      BudgetSubcategory(
        name: 'Entertainment',
        amount: 100,
        spent: 85,
        icon: Icons.movie,
      ),
      BudgetSubcategory(
        name: 'Shopping',
        amount: 150,
        spent: 200,
        icon: Icons.shopping_bag,
      ),
    ];

    // Main categories
    final categories = [
      BudgetCategory(
        name: 'Housing',
        amount: 1575,
        spent: 1505,
        color: const Color(0xFF4C51BF),
        icon: Icons.home,
        subcategories: housingSubcategories,
      ),
      BudgetCategory(
        name: 'Food',
        amount: 1100,
        spent: 1070,
        color: const Color(0xFF48BB78),
        icon: Icons.restaurant,
        subcategories: foodSubcategories,
      ),
      BudgetCategory(
        name: 'Transportation',
        amount: 450,
        spent: 345,
        color: const Color(0xFFED8936),
        icon: Icons.directions_car,
        subcategories: transportSubcategories,
      ),
      BudgetCategory(
        name: 'Utilities',
        amount: 250,
        spent: 265,
        color: const Color(0xFF38B2AC),
        icon: Icons.bolt,
        subcategories: utilitiesSubcategories,
      ),
      BudgetCategory(
        name: 'Other',
        amount: 250,
        spent: 285,
        color: const Color(0xFFE53E3E),
        icon: Icons.category,
        subcategories: otherSubcategories,
      ),
    ];

    // Family members
    final members = [
      FamilyMember(
        name: 'John',
        avatarUrl: '',
        budgetAllocation: 1800,
        spent: 1650,
        categories: [],
      ),
      FamilyMember(
        name: 'Sarah',
        avatarUrl: '',
        budgetAllocation: 1500,
        spent: 1420,
        categories: [],
      ),
      FamilyMember(
        name: 'Emily',
        avatarUrl: '',
        budgetAllocation: 300,
        spent: 280,
        categories: [],
      ),
      FamilyMember(
        name: 'Michael',
        avatarUrl: '',
        budgetAllocation: 200,
        spent: 220,
        categories: [],
      ),
    ];

    // Family goals
    final goals = [
      FamilyGoal(
        name: 'Summer Vacation',
        description: 'Trip to Hawaii in July',
        targetAmount: 3000,
        currentAmount: 1800,
        targetDate: DateTime(2025, 7, 15),
        icon: Icons.beach_access,
        color: Colors.blue,
      ),
      FamilyGoal(
        name: 'New Car',
        description: 'Saving for a new family car',
        targetAmount: 10000,
        currentAmount: 3500,
        targetDate: DateTime(2026, 1, 1),
        icon: Icons.directions_car,
        color: Colors.green,
      ),
      FamilyGoal(
        name: 'Emergency Fund',
        description: '6 months of expenses',
        targetAmount: 15000,
        currentAmount: 7500,
        targetDate: DateTime(2025, 12, 31),
        icon: Icons.savings,
        color: Colors.amber,
      ),
    ];

    // Calculate totals
    double totalBudget = 0;
    double totalSpent = 0;
    for (var category in categories) {
      totalBudget += category.amount;
      totalSpent += category.spent;
    }

    return FamilyBudgetData(
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      categories: categories,
      members: members,
      goals: goals,
    );
  }
}
