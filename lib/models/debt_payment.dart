class DebtPayment {
  final int? id;
  final int goalId; // foreign key to DebtPayoffGoal.id
  final double amount;
  final DateTime date;
  final String? note;

  DebtPayment({
    this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
  });

  factory DebtPayment.fromMap(Map<String, dynamic> map) => DebtPayment(
        id: map['id'] as int?,
        goalId: map['goalId'] as int,
        amount: map['amount'] as double,
        date: DateTime.parse(map['date'] as String),
        note: map['note'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'goalId': goalId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };
}
