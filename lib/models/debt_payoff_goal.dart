/// A model representing a user’s goal to pay off a specific debt (loan / credit card).
///
/// This is separate from the generic `Goal` model because debt payoff goals have
/// unique fields such as interest rate and minimum payment that are not relevant
/// for generic savings goals.
///
/// All numeric fields are stored as `double` for simplicity. Dates are stored as
/// ISO-8601 strings when serialised.
class DebtPayoffGoal {
  final String? id;

  /// A user-friendly name for the debt, e.g. "Car Loan" or "Visa Credit Card".
  final String name;

  /// The original principal or credit limit.
  final double originalAmount;

  /// The current outstanding balance (updated periodically).
  final double currentBalance;

  /// Annual Percentage Rate (APR) or interest rate expressed as a percentage
  /// (e.g. 17.99 means 17.99%).
  final double interestRate;

  /// Minimum required payment per month.
  final double minimumMonthlyPayment;

  /// Optional target date by which the user wants the debt paid off.
  final DateTime? targetDate;

  /// Optional description / notes.
  final String? description;

  /// Timestamp when the goal was created.
  final DateTime createdAt;

  /// Timestamp when the goal was last updated.
  final DateTime updatedAt;

  DebtPayoffGoal({
    this.id,
    required this.name,
    required this.originalAmount,
    required this.currentBalance,
    required this.interestRate,
    required this.minimumMonthlyPayment,
    this.targetDate,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Helper: outstanding percentage paid off.
  double get progressPercentage =>
      ((originalAmount - currentBalance) / originalAmount) * 100;

  bool get isPaidOff => currentBalance <= 0.01;

  // Serialisation helpers ---------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'originalAmount': originalAmount,
      'currentBalance': currentBalance,
      'interestRate': interestRate,
      'minimumMonthlyPayment': minimumMonthlyPayment,
      'targetDate': targetDate?.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DebtPayoffGoal.fromMap(Map<String, dynamic> map) {
    return DebtPayoffGoal(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      originalAmount: (map['originalAmount'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      interestRate: (map['interestRate'] as num?)?.toDouble() ?? 0.0,
      minimumMonthlyPayment:
          (map['minimumMonthlyPayment'] as num?)?.toDouble() ?? 0.0,
      targetDate:
          map['targetDate'] != null ? DateTime.parse(map['targetDate']) : null,
      description: map['description'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  DebtPayoffGoal copyWith({
    String? id,
    String? name,
    double? originalAmount,
    double? currentBalance,
    double? interestRate,
    double? minimumMonthlyPayment,
    DateTime? targetDate,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtPayoffGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      originalAmount: originalAmount ?? this.originalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      interestRate: interestRate ?? this.interestRate,
      minimumMonthlyPayment: minimumMonthlyPayment ?? this.minimumMonthlyPayment,
      targetDate: targetDate ?? this.targetDate,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
