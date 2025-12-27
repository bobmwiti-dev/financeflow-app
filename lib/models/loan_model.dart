class Loan {
  final String? id;
  final String name;
  final double totalAmount;
  final double amountPaid;
  final double interestRate;
  final DateTime startDate;
  final DateTime dueDate;
  final String lender;
  final String status; // Active, Paid, Defaulted
  final String paymentFrequency; // Monthly, Weekly, Bi-weekly
  final double installmentAmount;
  final String? notes;

  Loan({
    this.id,
    required this.name,
    required this.totalAmount,
    this.amountPaid = 0.0,
    required this.interestRate,
    required this.startDate,
    required this.dueDate,
    required this.lender,
    this.status = 'Active',
    required this.paymentFrequency,
    required this.installmentAmount,
    this.notes,
  });

  double get remainingAmount => totalAmount - amountPaid;
  
  double get percentPaid => (amountPaid / totalAmount) * 100;

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status == 'Active';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'lender': lender,
      'status': status,
      'paymentFrequency': paymentFrequency,
      'installmentAmount': installmentAmount,
      'notes': notes,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      amountPaid: (map['amountPaid'] ?? 0.0).toDouble(),
      interestRate: (map['interestRate'] ?? 0.0).toDouble(),
      startDate: _parseDateTime(map['startDate']) ?? DateTime.now(),
      dueDate: _parseDateTime(map['dueDate']) ?? DateTime.now().add(const Duration(days: 365)),
      lender: map['lender'] ?? '',
      status: map['status'] ?? 'Active',
      paymentFrequency: map['paymentFrequency'] ?? 'Monthly',
      installmentAmount: (map['installmentAmount'] ?? 0.0).toDouble(),
      notes: map['notes']?.toString(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      // Handle Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      
      // Handle string dates
      if (value is String) {
        return DateTime.parse(value);
      }
      
      // Handle DateTime objects
      if (value is DateTime) {
        return value;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // For Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'lender': lender,
      'status': status,
      'paymentFrequency': paymentFrequency,
      'installmentAmount': installmentAmount,
      'notes': notes,
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0.0).toDouble(),
      interestRate: (json['interestRate'] ?? 0.0).toDouble(),
      startDate: _parseDateTime(json['startDate']) ?? DateTime.now(),
      dueDate: _parseDateTime(json['dueDate']) ?? DateTime.now().add(const Duration(days: 365)),
      lender: json['lender'] ?? '',
      status: json['status'] ?? 'Active',
      paymentFrequency: json['paymentFrequency'] ?? 'Monthly',
      installmentAmount: (json['installmentAmount'] ?? 0.0).toDouble(),
      notes: json['notes']?.toString(),
    );
  }

  Loan copyWith({
    String? id,
    String? name,
    double? totalAmount,
    double? amountPaid,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    String? lender,
    String? status,
    String? paymentFrequency,
    double? installmentAmount,
    String? notes,
  }) {
    return Loan(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      lender: lender ?? this.lender,
      status: status ?? this.status,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      notes: notes ?? this.notes,
    );
  }
}
