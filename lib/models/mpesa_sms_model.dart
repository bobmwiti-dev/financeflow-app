import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents different types of M-Pesa transactions
enum MpesaTransactionType {
  sent, // Money sent to someone
  received, // Money received from someone
  deposit, // Cash deposit at agent
  withdrawal, // Cash withdrawal at agent
  paybill, // Bill payment
  buyGoods, // Buy goods payment
  airtime, // Airtime purchase
  reversal, // Transaction reversal
  unknown
}

/// Enhanced model for parsed M-Pesa SMS transaction with validation and intelligence
class MpesaSmsTransaction {
  final String? id;
  final String originalSms;
  final String mpesaCode;
  final MpesaTransactionType type;
  final double amount;
  final String? recipient;
  final String? sender;
  final String? paybillNumber;
  final String? accountNumber;
  final String? agentNumber;
  final double balance;
  final double? oldBalance;
  final DateTime transactionDate;
  final DateTime smsDate;
  final bool isImported;
  final String? importedTransactionId;
  final String? category;
  final String? merchantType;
  final String? notes;
  final double confidence;
  final bool isValidated;
  final Map<String, dynamic>? metadata;

  MpesaSmsTransaction({
    this.id,
    required this.originalSms,
    required this.mpesaCode,
    required this.type,
    required this.amount,
    this.recipient,
    this.sender,
    this.paybillNumber,
    this.accountNumber,
    this.agentNumber,
    required this.balance,
    this.oldBalance,
    required this.transactionDate,
    required this.smsDate,
    this.isImported = false,
    this.importedTransactionId,
    this.category,
    this.merchantType,
    this.notes,
    this.confidence = 1.0,
    this.isValidated = false,
    this.metadata,
  });

  /// Create from Firestore document
  factory MpesaSmsTransaction.fromMap(Map<String, dynamic> map) {
    return MpesaSmsTransaction(
      id: map['id'] as String?,
      originalSms: map['originalSms'] as String,
      mpesaCode: map['mpesaCode'] as String,
      type: MpesaTransactionType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MpesaTransactionType.unknown,
      ),
      amount: (map['amount'] as num).toDouble(),
      recipient: map['recipient'] as String?,
      sender: map['sender'] as String?,
      paybillNumber: map['paybillNumber'] as String?,
      accountNumber: map['accountNumber'] as String?,
      agentNumber: map['agentNumber'] as String?,
      balance: (map['balance'] as num).toDouble(),
      oldBalance: map['oldBalance']?.toDouble(),
      transactionDate: map['transactionDate'] is Timestamp
          ? (map['transactionDate'] as Timestamp).toDate()
          : DateTime.parse(map['transactionDate'] as String),
      smsDate: map['smsDate'] is Timestamp
          ? (map['smsDate'] as Timestamp).toDate()
          : DateTime.parse(map['smsDate'] as String),
      isImported: map['isImported'] as bool? ?? false,
      importedTransactionId: map['importedTransactionId'] as String?,
      category: map['category'] as String?,
      merchantType: map['merchantType'] as String?,
      notes: map['notes'] as String?,
      confidence: (map['confidence'] ?? 1.0).toDouble(),
      isValidated: map['isValidated'] as bool? ?? false,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalSms': originalSms,
      'mpesaCode': mpesaCode,
      'type': type.toString(),
      'amount': amount,
      'recipient': recipient,
      'sender': sender,
      'paybillNumber': paybillNumber,
      'accountNumber': accountNumber,
      'agentNumber': agentNumber,
      'balance': balance,
      'oldBalance': oldBalance,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'smsDate': Timestamp.fromDate(smsDate),
      'isImported': isImported,
      'importedTransactionId': importedTransactionId,
      'category': category,
      'merchantType': merchantType,
      'notes': notes,
      'confidence': confidence,
      'isValidated': isValidated,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  MpesaSmsTransaction copyWith({
    String? id,
    String? originalSms,
    String? mpesaCode,
    MpesaTransactionType? type,
    double? amount,
    String? recipient,
    String? sender,
    String? paybillNumber,
    String? accountNumber,
    String? agentNumber,
    double? balance,
    double? oldBalance,
    DateTime? transactionDate,
    DateTime? smsDate,
    bool? isImported,
    String? importedTransactionId,
    String? category,
    String? merchantType,
    String? notes,
    double? confidence,
    bool? isValidated,
    Map<String, dynamic>? metadata,
  }) {
    return MpesaSmsTransaction(
      id: id ?? this.id,
      originalSms: originalSms ?? this.originalSms,
      mpesaCode: mpesaCode ?? this.mpesaCode,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      recipient: recipient ?? this.recipient,
      sender: sender ?? this.sender,
      paybillNumber: paybillNumber ?? this.paybillNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      agentNumber: agentNumber ?? this.agentNumber,
      balance: balance ?? this.balance,
      oldBalance: oldBalance ?? this.oldBalance,
      transactionDate: transactionDate ?? this.transactionDate,
      smsDate: smsDate ?? this.smsDate,
      isImported: isImported ?? this.isImported,
      importedTransactionId: importedTransactionId ?? this.importedTransactionId,
      category: category ?? this.category,
      merchantType: merchantType ?? this.merchantType,
      notes: notes ?? this.notes,
      confidence: confidence ?? this.confidence,
      isValidated: isValidated ?? this.isValidated,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get human-readable transaction description
  String get description {
    switch (type) {
      case MpesaTransactionType.sent:
        return 'Sent to ${recipient ?? 'Unknown'}';
      case MpesaTransactionType.received:
        return 'Received from ${sender ?? 'Unknown'}';
      case MpesaTransactionType.deposit:
        return 'Cash deposit at agent ${agentNumber ?? 'Unknown'}';
      case MpesaTransactionType.withdrawal:
        return 'Cash withdrawal at agent ${agentNumber ?? 'Unknown'}';
      case MpesaTransactionType.paybill:
        return 'Paybill to ${paybillNumber ?? 'Unknown'}${accountNumber != null ? ' (Acc: $accountNumber)' : ''}';
      case MpesaTransactionType.buyGoods:
        return 'Buy goods from ${recipient ?? 'Unknown'}';
      case MpesaTransactionType.airtime:
        return 'Airtime purchase';
      case MpesaTransactionType.reversal:
        return 'Transaction reversal';
      default:
        return 'M-Pesa transaction';
    }
  }

  /// Check if this is an expense transaction
  bool get isExpense {
    return [
      MpesaTransactionType.sent,
      MpesaTransactionType.withdrawal,
      MpesaTransactionType.paybill,
      MpesaTransactionType.buyGoods,
      MpesaTransactionType.airtime,
    ].contains(type);
  }

  /// Check if this is an income transaction
  bool get isIncome {
    return [
      MpesaTransactionType.received,
      MpesaTransactionType.deposit,
      MpesaTransactionType.reversal,
    ].contains(type);
  }
  
  /// Calculate old balance from new balance and amount
  double get calculatedOldBalance {
    if (oldBalance != null) return oldBalance!;
    
    // Calculate based on transaction type
    switch (type) {
      case MpesaTransactionType.sent:
      case MpesaTransactionType.paybill:
      case MpesaTransactionType.buyGoods:
      case MpesaTransactionType.withdrawal:
      case MpesaTransactionType.airtime:
        return balance + amount;
      case MpesaTransactionType.received:
      case MpesaTransactionType.deposit:
        return balance - amount;
      default:
        return balance;
    }
  }

  /// Check if transaction amounts are consistent
  bool get isBalanceConsistent {
    if (oldBalance == null) return true; // Can't validate without old balance
    
    final expectedNewBalance = isExpense
        ? oldBalance! - amount
        : oldBalance! + amount;
    
    return (balance - expectedNewBalance).abs() < 0.01; // Allow small rounding errors
  }

  /// Check if this is likely a merchant transaction
  bool get isMerchantTransaction {
    return category != null && 
           !['Transfer', 'Personal', 'Unknown'].contains(category);
  }

  @override
  String toString() {
    return 'MpesaSmsTransaction(code: $mpesaCode, type: $type, amount: $amount, date: $transactionDate, confidence: $confidence)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MpesaSmsTransaction && other.mpesaCode == mpesaCode;
  }

  @override
  int get hashCode => mpesaCode.hashCode;
}

/// Configuration for M-Pesa SMS import
class MpesaImportConfig {
  final bool autoImportEnabled;
  final bool categorizeAutomatically;
  final bool importOnlyNewSms;
  final List<String> excludedNumbers;
  final Map<String, String> categoryMappings;
  final DateTime? lastImportDate;
  final int maxDaysToImport;

  MpesaImportConfig({
    this.autoImportEnabled = false,
    this.categorizeAutomatically = true,
    this.importOnlyNewSms = true,
    this.excludedNumbers = const [],
    this.categoryMappings = const {},
    this.lastImportDate,
    this.maxDaysToImport = 30,
  });

  factory MpesaImportConfig.fromMap(Map<String, dynamic> map) {
    return MpesaImportConfig(
      autoImportEnabled: map['autoImportEnabled'] as bool? ?? false,
      categorizeAutomatically: map['categorizeAutomatically'] as bool? ?? true,
      importOnlyNewSms: map['importOnlyNewSms'] as bool? ?? true,
      excludedNumbers: List<String>.from(map['excludedNumbers'] ?? []),
      categoryMappings: Map<String, String>.from(map['categoryMappings'] ?? {}),
      lastImportDate: map['lastImportDate'] != null
          ? (map['lastImportDate'] is Timestamp
              ? (map['lastImportDate'] as Timestamp).toDate()
              : DateTime.parse(map['lastImportDate'] as String))
          : null,
      maxDaysToImport: map['maxDaysToImport'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoImportEnabled': autoImportEnabled,
      'categorizeAutomatically': categorizeAutomatically,
      'importOnlyNewSms': importOnlyNewSms,
      'excludedNumbers': excludedNumbers,
      'categoryMappings': categoryMappings,
      'lastImportDate': lastImportDate != null ? Timestamp.fromDate(lastImportDate!) : null,
      'maxDaysToImport': maxDaysToImport,
    };
  }

  /// Default configuration optimized for Kenya market
  factory MpesaImportConfig.defaultKenya() {
    return MpesaImportConfig(
      autoImportEnabled: true,
      categorizeAutomatically: true,
      importOnlyNewSms: true,
      excludedNumbers: const [],
      categoryMappings: const {
        'NAIVAS': 'Groceries',
        'JAVA HOUSE': 'Dining',
        'KPLC': 'Utilities',
        'UBER': 'Transport',
        'EQUITY BANK': 'Banking',
      },
      maxDaysToImport: 180, // 6 months for Kenya market
    );
  }

  /// Check if a phone number should be excluded
  bool isNumberExcluded(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return excludedNumbers.any((excluded) {
      final cleanExcluded = excluded.replaceAll(RegExp(r'[^\d+]'), '');
      return cleanNumber.contains(cleanExcluded) || cleanExcluded.contains(cleanNumber);
    });
  }

  /// Check if SMS contains excluded keywords (Fuliza, refunds, etc.)
  bool containsExcludedKeywords(String smsBody) {
    const excludedKeywords = ['FULIZA', 'REVERSAL', 'REFUND', 'CANCELLED', 'FAILED'];
    final upperSms = smsBody.toUpperCase();
    return excludedKeywords.any((keyword) => upperSms.contains(keyword));
  }

  /// Check if SMS contains salary keywords
  bool containsSalaryKeywords(String smsBody) {
    const salaryKeywords = ['SALARY', 'PAYROLL', 'WAGES', 'STIPEND', 'ALLOWANCE', 'BONUS'];
    final upperSms = smsBody.toUpperCase();
    return salaryKeywords.any((keyword) => upperSms.contains(keyword));
  }

  /// Check if SMS contains loan keywords
  bool containsLoanKeywords(String smsBody) {
    const loanKeywords = ['FULIZA', 'LOAN', 'CREDIT', 'ADVANCE', 'M-SHWARI'];
    final upperSms = smsBody.toUpperCase();
    return loanKeywords.any((keyword) => upperSms.contains(keyword));
  }

  MpesaImportConfig copyWith({
    bool? autoImportEnabled,
    bool? categorizeAutomatically,
    bool? importOnlyNewSms,
    List<String>? excludedNumbers,
    Map<String, String>? categoryMappings,
    DateTime? lastImportDate,
    int? maxDaysToImport,
  }) {
    return MpesaImportConfig(
      autoImportEnabled: autoImportEnabled ?? this.autoImportEnabled,
      categorizeAutomatically: categorizeAutomatically ?? this.categorizeAutomatically,
      importOnlyNewSms: importOnlyNewSms ?? this.importOnlyNewSms,
      excludedNumbers: excludedNumbers ?? this.excludedNumbers,
      categoryMappings: categoryMappings ?? this.categoryMappings,
      lastImportDate: lastImportDate ?? this.lastImportDate,
      maxDaysToImport: maxDaysToImport ?? this.maxDaysToImport,
    );
  }
}
