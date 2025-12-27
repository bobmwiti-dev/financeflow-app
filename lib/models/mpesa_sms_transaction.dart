/// Enhanced M-Pesa SMS transaction model with validation and intelligence
class MpesaSmsTransaction {
  final String transactionId;
  final double amount;
  final String recipient;
  final String transactionType;
  final DateTime timestamp;
  final double newBalance;
  final double? oldBalance;
  final String rawSmsBody;
  final double confidence;
  final String? category;
  final String? merchantType;
  final bool isValidated;
  final Map<String, dynamic>? metadata;

  const MpesaSmsTransaction({
    required this.transactionId,
    required this.amount,
    required this.recipient,
    required this.transactionType,
    required this.timestamp,
    required this.newBalance,
    this.oldBalance,
    required this.rawSmsBody,
    this.confidence = 1.0,
    this.category,
    this.merchantType,
    this.isValidated = false,
    this.metadata,
  });

  /// Calculate old balance from new balance and amount
  double get calculatedOldBalance {
    if (oldBalance != null) return oldBalance!;
    
    // Calculate based on transaction type
    switch (transactionType.toLowerCase()) {
      case 'sent':
      case 'paybill':
      case 'withdraw':
        return newBalance + amount;
      case 'received':
      case 'deposit':
        return newBalance - amount;
      default:
        return newBalance;
    }
  }

  /// Check if transaction amounts are consistent
  bool get isBalanceConsistent {
    if (oldBalance == null) return true; // Can't validate without old balance
    
    final expectedNewBalance = transactionType.toLowerCase().contains('sent') || 
                              transactionType.toLowerCase().contains('paybill')
        ? oldBalance! - amount
        : oldBalance! + amount;
    
    return (newBalance - expectedNewBalance).abs() < 0.01; // Allow small rounding errors
  }

  /// Check if this is likely a merchant transaction
  bool get isMerchantTransaction {
    return category != null && 
           !['Transfer', 'Personal', 'Unknown'].contains(category);
  }

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'amount': amount,
      'recipient': recipient,
      'transactionType': transactionType,
      'timestamp': timestamp.toIso8601String(),
      'newBalance': newBalance,
      'oldBalance': oldBalance,
      'rawSmsBody': rawSmsBody,
      'confidence': confidence,
      'category': category,
      'merchantType': merchantType,
      'isValidated': isValidated,
      'metadata': metadata,
    };
  }

  /// Create from Map (Firestore data)
  factory MpesaSmsTransaction.fromMap(Map<String, dynamic> map) {
    return MpesaSmsTransaction(
      transactionId: map['transactionId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      recipient: map['recipient'] ?? '',
      transactionType: map['transactionType'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      newBalance: (map['newBalance'] ?? 0.0).toDouble(),
      oldBalance: map['oldBalance']?.toDouble(),
      rawSmsBody: map['rawSmsBody'] ?? '',
      confidence: (map['confidence'] ?? 1.0).toDouble(),
      category: map['category'],
      merchantType: map['merchantType'],
      isValidated: map['isValidated'] ?? false,
      metadata: map['metadata'],
    );
  }

  /// Create a copy with updated fields
  MpesaSmsTransaction copyWith({
    String? transactionId,
    double? amount,
    String? recipient,
    String? transactionType,
    DateTime? timestamp,
    double? newBalance,
    double? oldBalance,
    String? rawSmsBody,
    double? confidence,
    String? category,
    String? merchantType,
    bool? isValidated,
    Map<String, dynamic>? metadata,
  }) {
    return MpesaSmsTransaction(
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      recipient: recipient ?? this.recipient,
      transactionType: transactionType ?? this.transactionType,
      timestamp: timestamp ?? this.timestamp,
      newBalance: newBalance ?? this.newBalance,
      oldBalance: oldBalance ?? this.oldBalance,
      rawSmsBody: rawSmsBody ?? this.rawSmsBody,
      confidence: confidence ?? this.confidence,
      category: category ?? this.category,
      merchantType: merchantType ?? this.merchantType,
      isValidated: isValidated ?? this.isValidated,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'MpesaSmsTransaction(id: $transactionId, amount: $amount, type: $transactionType, recipient: $recipient, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MpesaSmsTransaction && other.transactionId == transactionId;
  }

  @override
  int get hashCode => transactionId.hashCode;
}

/// Merchant information for intelligent categorization
class MerchantInfo {
  final String category;
  final String type;
  final double confidence;
  final List<String> keywords;
  final Map<String, dynamic>? metadata;

  const MerchantInfo(
    this.category,
    this.type, {
    this.confidence = 1.0,
    this.keywords = const [],
    this.metadata,
  });

  /// Check if merchant name matches this info
  bool matches(String merchantName) {
    final name = merchantName.toUpperCase();
    return keywords.any((keyword) => name.contains(keyword.toUpperCase()));
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'type': type,
      'confidence': confidence,
      'keywords': keywords,
      'metadata': metadata,
    };
  }

  factory MerchantInfo.fromMap(Map<String, dynamic> map) {
    return MerchantInfo(
      map['category'] ?? '',
      map['type'] ?? '',
      confidence: (map['confidence'] ?? 1.0).toDouble(),
      keywords: List<String>.from(map['keywords'] ?? []),
      metadata: map['metadata'],
    );
  }
}

/// M-Pesa transaction types
enum MpesaTransactionType {
  sent,
  received,
  paybill,
  buyGoods,
  withdraw,
  deposit,
  airtime,
  unknown,
}

extension MpesaTransactionTypeExtension on MpesaTransactionType {
  String get displayName {
    switch (this) {
      case MpesaTransactionType.sent:
        return 'Money Sent';
      case MpesaTransactionType.received:
        return 'Money Received';
      case MpesaTransactionType.paybill:
        return 'Pay Bill';
      case MpesaTransactionType.buyGoods:
        return 'Buy Goods';
      case MpesaTransactionType.withdraw:
        return 'Cash Withdrawal';
      case MpesaTransactionType.deposit:
        return 'Cash Deposit';
      case MpesaTransactionType.airtime:
        return 'Airtime Purchase';
      case MpesaTransactionType.unknown:
        return 'Unknown';
    }
  }

  bool get isExpense {
    return [
      MpesaTransactionType.sent,
      MpesaTransactionType.paybill,
      MpesaTransactionType.buyGoods,
      MpesaTransactionType.withdraw,
      MpesaTransactionType.airtime,
    ].contains(this);
  }

  bool get isIncome {
    return [
      MpesaTransactionType.received,
      MpesaTransactionType.deposit,
    ].contains(this);
  }
}
