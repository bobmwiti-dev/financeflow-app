import 'package:flutter/material.dart';
import 'spending_challenge_model.dart';

class ChallengeTemplate {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final int defaultDurationDays;
  final double? suggestedTargetAmount;
  final List<String> categories;
  final IconData icon;
  final Color color;
  final String motivationalQuote;
  final List<String> tips;

  const ChallengeTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.defaultDurationDays,
    this.suggestedTargetAmount,
    required this.categories,
    required this.icon,
    required this.color,
    required this.motivationalQuote,
    required this.tips,
  });

  SpendingChallenge toChallenge({
    DateTime? startDate,
    double? customTargetAmount,
  }) {
    final start = startDate ?? DateTime.now();
    final end = start.add(Duration(days: defaultDurationDays));
    
    return SpendingChallenge(
      title: title,
      description: description,
      type: type,
      difficulty: difficulty,
      status: ChallengeStatus.active,
      startDate: start,
      endDate: end,
      categories: categories,
      targetAmount: customTargetAmount ?? suggestedTargetAmount ?? 0.0,
      currentAmount: 0.0,
      icon: icon,
      color: color,
    );
  }
}

class ChallengeTemplates {
  static const List<ChallengeTemplate> templates = [
    // No-Spend Challenges
    ChallengeTemplate(
      id: 'no_coffee_week',
      title: 'No Coffee Week',
      description: 'Skip your daily coffee purchases for one week and save money!',
      type: ChallengeType.noSpend,
      difficulty: ChallengeDifficulty.easy,
      defaultDurationDays: 7,
      categories: ['Food'],
      icon: Icons.coffee,
      color: Colors.brown,
      motivationalQuote: 'Small changes lead to big savings!',
      tips: [
        'Make coffee at home instead',
        'Try herbal tea as an alternative',
        'Calculate how much you\'ll save per month',
        'Use the saved money for something special',
      ],
    ),
    
    ChallengeTemplate(
      id: 'no_takeout_month',
      title: 'No Takeout Month',
      description: 'Cook all meals at home for 30 days and discover your culinary skills!',
      type: ChallengeType.noSpend,
      difficulty: ChallengeDifficulty.hard,
      defaultDurationDays: 30,
      categories: ['Food'],
      icon: Icons.restaurant,
      color: Colors.orange,
      motivationalQuote: 'Home cooking = healthier wallet and body!',
      tips: [
        'Plan your meals in advance',
        'Batch cook on weekends',
        'Try new recipes to stay motivated',
        'Calculate your monthly savings',
      ],
    ),
    
    ChallengeTemplate(
      id: 'entertainment_freeze',
      title: 'Entertainment Freeze',
      description: 'Find free entertainment options for two weeks',
      type: ChallengeType.noSpend,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 14,
      categories: ['Entertainment'],
      icon: Icons.movie,
      color: Colors.purple,
      motivationalQuote: 'The best things in life are free!',
      tips: [
        'Visit free museums and parks',
        'Have movie nights at home',
        'Try free community events',
        'Read books from the library',
      ],
    ),
    
    // Budget Limit Challenges
    ChallengeTemplate(
      id: 'grocery_budget_challenge',
      title: 'Grocery Budget Challenge',
      description: 'Stay within your grocery budget for the month',
      type: ChallengeType.budgetLimit,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 30,
      suggestedTargetAmount: 300.0,
      categories: ['Food'],
      icon: Icons.shopping_cart,
      color: Colors.green,
      motivationalQuote: 'Smart shopping leads to smart savings!',
      tips: [
        'Make a shopping list and stick to it',
        'Use coupons and shop sales',
        'Buy generic brands',
        'Avoid shopping when hungry',
      ],
    ),
    
    ChallengeTemplate(
      id: 'transport_budget',
      title: 'Transport Budget Challenge',
      description: 'Keep transportation costs under budget this month',
      type: ChallengeType.budgetLimit,
      difficulty: ChallengeDifficulty.easy,
      defaultDurationDays: 30,
      suggestedTargetAmount: 150.0,
      categories: ['Transport'],
      icon: Icons.directions_car,
      color: Colors.blue,
      motivationalQuote: 'Every mile saved is money earned!',
      tips: [
        'Use public transport when possible',
        'Walk or bike for short distances',
        'Carpool with friends or colleagues',
        'Combine errands into one trip',
      ],
    ),
    
    // Savings Target Challenges
    ChallengeTemplate(
      id: 'emergency_fund_boost',
      title: 'Emergency Fund Boost',
      description: 'Save extra money for your emergency fund this month',
      type: ChallengeType.savingsTarget,
      difficulty: ChallengeDifficulty.medium,
      defaultDurationDays: 30,
      suggestedTargetAmount: 200.0,
      categories: [],
      icon: Icons.savings,
      color: Colors.teal,
      motivationalQuote: 'Every dollar saved is peace of mind!',
      tips: [
        'Set up automatic transfers',
        'Save loose change daily',
        'Cut one unnecessary expense',
        'Use the 52-week savings challenge',
      ],
    ),
    
    ChallengeTemplate(
      id: 'vacation_fund',
      title: 'Vacation Fund Challenge',
      description: 'Save money for your dream vacation',
      type: ChallengeType.savingsTarget,
      difficulty: ChallengeDifficulty.hard,
      defaultDurationDays: 90,
      suggestedTargetAmount: 500.0,
      categories: [],
      icon: Icons.flight_takeoff,
      color: Colors.indigo,
      motivationalQuote: 'Dream big, save bigger!',
      tips: [
        'Create a vision board for motivation',
        'Save all unexpected income',
        'Sell items you no longer need',
        'Take on a side hustle',
      ],
    ),
    
    // Habit Building Challenges
    ChallengeTemplate(
      id: 'daily_expense_tracking',
      title: 'Daily Expense Tracking',
      description: 'Track every expense for 21 days to build the habit',
      type: ChallengeType.habitBuilding,
      difficulty: ChallengeDifficulty.easy,
      defaultDurationDays: 21,
      categories: [],
      icon: Icons.track_changes,
      color: Colors.amber,
      motivationalQuote: 'Awareness is the first step to control!',
      tips: [
        'Use your phone to log expenses immediately',
        'Set daily reminders',
        'Review your spending each evening',
        'Celebrate small wins',
      ],
    ),
    
    ChallengeTemplate(
      id: 'weekly_budget_review',
      title: 'Weekly Budget Review',
      description: 'Review your budget every week for a month',
      type: ChallengeType.habitBuilding,
      difficulty: ChallengeDifficulty.easy,
      defaultDurationDays: 28,
      categories: [],
      icon: Icons.analytics,
      color: Colors.cyan,
      motivationalQuote: 'Regular reviews lead to better results!',
      tips: [
        'Set a specific day and time each week',
        'Compare actual vs planned spending',
        'Adjust next week\'s budget if needed',
        'Celebrate staying on track',
      ],
    ),
  ];
  
  static List<ChallengeTemplate> getTemplatesByDifficulty(ChallengeDifficulty difficulty) {
    return templates.where((template) => template.difficulty == difficulty).toList();
  }
  
  static List<ChallengeTemplate> getTemplatesByType(ChallengeType type) {
    return templates.where((template) => template.type == type).toList();
  }
  
  static List<ChallengeTemplate> getTemplatesByCategory(String category) {
    return templates.where((template) => template.categories.contains(category)).toList();
  }
  
  static ChallengeTemplate? getTemplateById(String id) {
    try {
      return templates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }
}
