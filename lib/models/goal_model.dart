class Goal {
  final String? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? description;
  final String? category;
  final int priority;
  final String? icon;
  final double? targetMonthlyContribution;

  Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.description,
    this.category,
    this.priority = 1,
    this.icon,
    this.targetMonthlyContribution,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate?.toIso8601String(),
      'description': description,
      'category': category,
      'priority': priority,
      'icon': icon,
      'targetMonthlyContribution': targetMonthlyContribution,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id']?.toString(),
      name: map['name'] ?? map['title'] ?? '',
      targetAmount: map['targetAmount']?.toDouble() ?? 0.0,
      currentAmount: map['currentAmount']?.toDouble() ?? 0.0,
      targetDate: map['targetDate'] != null 
          ? (map['targetDate'] is DateTime 
              ? map['targetDate'] as DateTime
              : map['targetDate'].runtimeType.toString().contains('Timestamp')
                  ? (map['targetDate'] as dynamic).toDate()
                  : DateTime.parse(map['targetDate'] as String))
          : null,
      description: map['description'],
      category: map['category'],
      priority: map['priority'] ?? 1,
      icon: map['icon']?.toString(),
      targetMonthlyContribution: (map['targetMonthlyContribution'] as num?)?.toDouble(),
    );
  }

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? description,
    String? category,
    String? icon,
    double? targetMonthlyContribution,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      targetMonthlyContribution: targetMonthlyContribution ?? this.targetMonthlyContribution,
    );
  }

  double get progressPercentage => (currentAmount / targetAmount) * 100;
  bool get isCompleted => currentAmount >= targetAmount;
}
