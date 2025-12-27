import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// Helper function to get const IconData instances for tree shaking
IconData _getIconFromCodePoint(int? codePoint, String? fontFamily) {
  // Map common code points to const IconData instances
  const Map<int, IconData> iconMap = {
    // Challenge and achievement icons
    0xe0b7: Icons.emoji_events, // trophy
    0xe86f: Icons.star, // star
    0xe3f4: Icons.local_fire_department, // fire
    0xe5d2: Icons.check_circle, // check circle
    0xe88e: Icons.military_tech, // medal
    0xe8d9: Icons.workspace_premium, // premium
    
    // Financial icons
    0xe047: Icons.attach_money, // money
    0xe8d8: Icons.savings, // savings
    0xe3c9: Icons.trending_up, // trending up
    0xe3ca: Icons.trending_down, // trending down
    0xe263: Icons.account_balance_wallet, // wallet
    0xe84f: Icons.credit_card, // credit card
    0xe8cc: Icons.receipt, // receipt
    
    // Category icons
    0xe56c: Icons.restaurant, // food
    0xe1a3: Icons.local_gas_station, // fuel
    0xe1a4: Icons.shopping_cart, // shopping
    0xe1a5: Icons.home, // home
    0xe1a6: Icons.directions_car, // transport
    0xe1a7: Icons.school, // education
    0xe1a8: Icons.local_hospital, // health
    
    // Status icons
    0xe002: Icons.error, // error
    0xe88f: Icons.warning, // warning
    0xe86c: Icons.info, // info
    0xe5ca: Icons.done, // done
  };
  
  if (codePoint != null && iconMap.containsKey(codePoint)) {
    return iconMap[codePoint]!;
  }
  
  // Fallback to default icon
  return Icons.emoji_events;
}

enum ChallengeType {
  noSpend,       // No spending in a category for a period
  budgetLimit,   // Stay under budget for a category
  savingsTarget, // Save a specific amount
  habitBuilding, // Build a financial habit (e.g., daily tracking)
  custom         // User-defined challenge
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  expert
}

enum ChallengeStatus {
  notStarted,
  active,
  completed,
  failed
}

class SpendingChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> categories; // Categories this challenge applies to
  final double targetAmount; // Budget limit or savings target
  final double currentAmount; // Current spending or savings
  final IconData icon;
  final Color color;
  final List<ChallengeBadge> availableBadges;
  final List<ChallengeBadge> earnedBadges;
  final List<ChallengeRule> rules;
  final List<Map<String, dynamic>> dailyProgressData; // Not persisted

  SpendingChallenge({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    this.status = ChallengeStatus.notStarted,
    required this.startDate,
    required this.endDate,
    required this.categories,
    this.targetAmount = 0.0,
    this.currentAmount = 0.0,
    this.icon = Icons.emoji_events,
    this.color = Colors.amber,
    List<ChallengeBadge>? availableBadges,
    List<ChallengeBadge>? earnedBadges,
    List<ChallengeRule>? rules,
    this.dailyProgressData = const [],
  })  : id = id ?? const Uuid().v4(),
        availableBadges = availableBadges ?? [],
        earnedBadges = earnedBadges ?? [],
        rules = rules ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'status': status.toString().split('.').last,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'categories': categories,
      'target_amount': targetAmount,
      'icon_code_point': icon.codePoint,
      'icon_font_family': icon.fontFamily,
      // ignore: deprecated_member_use
      'color': color.value,
      'available_badges': availableBadges.map((b) => b.toMap()).toList(),
      'earned_badges': earnedBadges.map((b) => b.toMap()).toList(),
      'rules': rules.map((r) => r.toMap()).toList(),
    };
  }

  factory SpendingChallenge.fromMap(Map<String, dynamic> map) {
    return SpendingChallenge(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => ChallengeType.custom,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == map['difficulty'],
        orElse: () => ChallengeDifficulty.easy,
      ),
      status: ChallengeStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ChallengeStatus.notStarted,
      ),
      startDate: (map['start_date'] as Timestamp).toDate(),
      endDate: (map['end_date'] as Timestamp).toDate(),
      categories: List<String>.from(map['categories'] ?? []),
      targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0.0,
      icon: _getIconFromCodePoint(map['icon_code_point'], map['icon_font_family']),
      color: 
      // ignore: deprecated_member_use
      Color(map['color'] ?? Colors.amber.value),
      availableBadges: (map['available_badges'] as List<dynamic>?)
          ?.map((b) => ChallengeBadge.fromMap(b as Map<String, dynamic>))
          .toList() ??
          [],
      earnedBadges: (map['earned_badges'] as List<dynamic>?)
          ?.map((b) => ChallengeBadge.fromMap(b as Map<String, dynamic>))
          .toList() ??
          [],
      rules: (map['rules'] as List<dynamic>?)
          ?.map((r) => ChallengeRule.fromMap(r as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // Duration of the challenge in days
  int get durationInDays => endDate.difference(startDate).inDays;

  // Days remaining in the challenge
  int get daysRemaining =>
      status == ChallengeStatus.active ? endDate.difference(DateTime.now()).inDays : 0;

  // Progress percentage
  double get progressPercentage {
    if (status == ChallengeStatus.notStarted) return 0.0;
    if (status == ChallengeStatus.completed) return 1.0;
    if (status == ChallengeStatus.failed) {
      if (durationInDays <= 0) return 1.0;
      final daysElapsed = durationInDays - daysRemaining;
      return (daysElapsed / durationInDays).clamp(0.0, 1.0);
    }

    switch (type) {
      case ChallengeType.noSpend:
        // For no-spend challenges: Success = no spending in restricted categories
        // Progress = time elapsed only if no spending occurred
        if (currentAmount > 0) {
          return 0.0; // Failed - spent money in restricted categories
        }
        // If no spending, show progress based on time elapsed
        final totalDays = durationInDays;
        if (totalDays <= 0) return 1.0;
        final daysElapsed = totalDays - daysRemaining;
        return (daysElapsed / totalDays).clamp(0.0, 1.0);

      case ChallengeType.budgetLimit:
        // For budget limit: Progress = staying within budget over time
        // Show progress as time elapsed if still under budget, 0% if over budget
        if (targetAmount <= 0) return 0.0;
        
        // If over budget, challenge failed
        if (currentAmount > targetAmount) {
          return 0.0; // Failed - exceeded budget
        }
        
        // If under budget, show time-based progress
        final totalDays = durationInDays;
        if (totalDays <= 0) return 1.0;
        final daysElapsed = totalDays - daysRemaining;
        return (daysElapsed / totalDays).clamp(0.0, 1.0);

      case ChallengeType.savingsTarget:
        // For savings target: Progress = amount saved toward target
        if (targetAmount <= 0) return 0.0;
        return (currentAmount / targetAmount).clamp(0.0, 1.0);

      case ChallengeType.habitBuilding:
        // For habit building: Progress based on rule completion, not just time
        if (rules.isEmpty) {
          // Fallback to time-based if no rules defined
          final totalDays = durationInDays;
          if (totalDays <= 0) return 1.0;
          final daysElapsed = totalDays - daysRemaining;
          return (daysElapsed / totalDays).clamp(0.0, 1.0);
        }
        
        // Calculate progress based on rule satisfaction
        final satisfiedRules = rules.where((rule) => rule.isSatisfied).length;
        return (satisfiedRules / rules.length).clamp(0.0, 1.0);

      case ChallengeType.custom:
        // For custom challenges: Use rule-based progress if available, otherwise time-based
        if (rules.isNotEmpty) {
          final satisfiedRules = rules.where((rule) => rule.isSatisfied).length;
          return (satisfiedRules / rules.length).clamp(0.0, 1.0);
        }
        
        // Fallback to time-based progress
        final totalDays = durationInDays;
        if (totalDays <= 0) return 1.0;
        final daysElapsed = totalDays - daysRemaining;
        return (daysElapsed / totalDays).clamp(0.0, 1.0);
    }
  }

  // Check if challenge is on track
  bool get isOnTrack {
    if (status != ChallengeStatus.active) return false;

    switch (type) {
      case ChallengeType.noSpend:
        // On track if no spending recorded in restricted categories
        return currentAmount == 0;

      case ChallengeType.budgetLimit:
        // On track if still under budget (simple check)
        return currentAmount <= targetAmount;

      case ChallengeType.savingsTarget:
        // On track if savings are proportionally meeting the target over time
        if (durationInDays == 0) return currentAmount >= targetAmount;
        final elapsedRatio = (durationInDays - daysRemaining) / durationInDays;
        final expectedSavings = targetAmount * elapsedRatio;
        return currentAmount >= expectedSavings;

      case ChallengeType.habitBuilding:
        // On track if majority of rules are satisfied (flexible approach)
        if (rules.isEmpty) return true; // No rules to fail
        final satisfiedCount = rules.where((rule) => rule.isSatisfied).length;
        return satisfiedCount >= (rules.length * 0.7); // 70% threshold

      case ChallengeType.custom:
        // On track if majority of rules are satisfied, or true if no rules
        if (rules.isEmpty) return true;
        final satisfiedCount = rules.where((rule) => rule.isSatisfied).length;
        return satisfiedCount >= (rules.length * 0.5); // 50% threshold for custom
    }
  }

  // Get points earned in this challenge
  int get pointsEarned {
    int basePoints = 0;

    // Base points by difficulty
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        basePoints = 100;
        break;
      case ChallengeDifficulty.medium:
        basePoints = 250;
        break;
      case ChallengeDifficulty.hard:
        basePoints = 500;
        break;
      case ChallengeDifficulty.expert:
        basePoints = 1000;
        break;
    }

    // Adjust based on status and progress
    switch (status) {
      case ChallengeStatus.notStarted:
        return 0;
      case ChallengeStatus.active:
        return (basePoints * progressPercentage).round();
      case ChallengeStatus.completed:
        return basePoints;
      case ChallengeStatus.failed:
        return (basePoints * progressPercentage * 0.5).round();
    }
  }

  // Update challenge with new transaction data
  SpendingChallenge updateWithTransaction(double amount, String category, DateTime date) {
    if (status != ChallengeStatus.active) return this;
    if (date.isBefore(startDate) || date.isAfter(endDate)) return this;
    if (!categories.contains(category) && categories.isNotEmpty) return this;

    double newCurrentAmount = currentAmount;
    ChallengeStatus newStatus = status;
    List<ChallengeBadge> newEarnedBadges = List.from(earnedBadges);

    switch (type) {
      case ChallengeType.noSpend:
        // Track spending amount and fail if any spending occurs
        newCurrentAmount += amount;
        if (amount > 0) {
          newStatus = ChallengeStatus.failed;
        }
        break;

      case ChallengeType.budgetLimit:
        // Add to current spending
        newCurrentAmount += amount;
        // If over budget, challenge fails
        if (newCurrentAmount > targetAmount) {
          newStatus = ChallengeStatus.failed;
        }
        break;

      case ChallengeType.savingsTarget:
        // Add to current savings
        newCurrentAmount += amount;
        // If reached target, challenge completes
        if (newCurrentAmount >= targetAmount) {
          newStatus = ChallengeStatus.completed;

          // Award all remaining badges
          for (final badge in availableBadges) {
            if (!newEarnedBadges.contains(badge)) {
              newEarnedBadges.add(badge);
            }
          }
        }
        break;

      case ChallengeType.habitBuilding:
      case ChallengeType.custom:
        // Update rules based on transaction
        // This would need custom logic per rule type
        break;
    }

    // Check for badges to award
    for (final badge in availableBadges) {
      if (!newEarnedBadges.contains(badge)) {
        if (badge.isEarned(newCurrentAmount, progressPercentage)) {
          newEarnedBadges.add(badge);
        }
      }
    }

    return copyWith(
      currentAmount: newCurrentAmount,
      status: newStatus,
      earnedBadges: newEarnedBadges,
    );
  }

  // Getters for chart data
  List<double> get dailyProgress {
    if (dailyProgressData.isEmpty) return [];
    return dailyProgressData.map((d) => (d['amount'] as num).toDouble()).toList();
  }

  List<DateTime> get progressDates {
    if (dailyProgressData.isEmpty) return [];
    return dailyProgressData.map((d) => d['date'] as DateTime).toList();
  }

  SpendingChallenge updateStatus() {
    if (status == ChallengeStatus.completed || status == ChallengeStatus.failed) {
      return this; // Don't update already completed or failed challenges
    }

    bool isCompleted = false;

    // Check completion criteria based on challenge type
    switch (type) {
      case ChallengeType.noSpend:
        isCompleted = currentAmount == 0;
        break;
      case ChallengeType.budgetLimit:
        isCompleted = currentAmount <= targetAmount;
        break;
      case ChallengeType.savingsTarget:
        isCompleted = currentAmount >= targetAmount;
        break;
      case ChallengeType.habitBuilding:
      case ChallengeType.custom:
        if (rules.isNotEmpty) {
          isCompleted = rules.every((rule) => rule.isSatisfied);
        } else {
          isCompleted = true; // Auto-complete if no rules
        }
        break;
    }

    // Now, check the date
    if (DateTime.now().isAfter(endDate)) {
      // If end date is passed, the challenge is either completed or failed
      return copyWith(status: isCompleted ? ChallengeStatus.completed : ChallengeStatus.failed);
    } else {
      // If end date is not passed, the challenge is still active
      // It cannot be considered 'completed' yet, even if the goal is met
      return copyWith(status: ChallengeStatus.active);
    }
  }

  SpendingChallenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
    ChallengeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    double? targetAmount,
    double? currentAmount,
    IconData? icon,
    Color? color,
    List<ChallengeBadge>? availableBadges,
    List<ChallengeBadge>? earnedBadges,
    List<ChallengeRule>? rules,
    List<Map<String, dynamic>>? dailyProgressData,
  }) {
    return SpendingChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categories: categories ?? this.categories,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      availableBadges: availableBadges ?? this.availableBadges,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      rules: rules ?? this.rules,
      dailyProgressData: dailyProgressData ?? this.dailyProgressData,
    );
  }
}

class ChallengeBadge {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final double unlockThreshold; // Percentage or amount to unlock

  ChallengeBadge({
    required this.name,
    required this.description,
    required this.icon,
    this.color = Colors.amber,
    required this.unlockThreshold,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon_code_point': icon.codePoint,
      'icon_font_family': icon.fontFamily,
      // ignore: deprecated_member_use
      'color': color.value,
      'unlock_threshold': unlockThreshold,
    };
  }

  factory ChallengeBadge.fromMap(Map<String, dynamic> map) {
    return ChallengeBadge(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: _getIconFromCodePoint(map['icon_code_point'], map['icon_font_family']),
      color:
       // ignore: deprecated_member_use
      Color(map['color'] ?? Colors.amber.value),
      unlockThreshold: (map['unlock_threshold'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool isEarned(double currentAmount, double progressPercentage) {
    return progressPercentage >= unlockThreshold;
  }
}

class ChallengeRule {
  final String description;
  final bool isSatisfied;

  ChallengeRule({
    required this.description,
    this.isSatisfied = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'is_satisfied': isSatisfied,
    };
  }

  factory ChallengeRule.fromMap(Map<String, dynamic> map) {
    return ChallengeRule(
      description: map['description'] ?? '',
      isSatisfied: map['is_satisfied'] ?? false,
    );
  }
}
