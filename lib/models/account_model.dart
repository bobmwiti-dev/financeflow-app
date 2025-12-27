import 'package:equatable/equatable.dart';

/// Account types supported by the app
enum AccountType {
  bank('Bank Account'),
  mpesa('M-Pesa'),
  cash('Cash'),
  savings('Savings Account'),
  investment('Investment Account');

  const AccountType(this.displayName);
  final String displayName;
  
  /// Check if this account type is a bank account
  bool get isBank => this == AccountType.bank || this == AccountType.savings;
}

/// Account model for tracking real balances with starting balance
class Account extends Equatable {
  final String id;
  final String name;
  final AccountType type;
  final double startingBalance;
  final DateTime startingDate;
  final String currency;
  final String? bankName;
  final String? accountNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.startingBalance,
    required this.startingDate,
    this.currency = 'KES',
    this.bankName,
    this.accountNumber,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new account with generated ID and timestamps
  factory Account.create({
    required String name,
    required AccountType type,
    required double startingBalance,
    required DateTime startingDate,
    String currency = 'KES',
    String? bankName,
    String? accountNumber,
  }) {
    final now = DateTime.now();
    return Account(
      id: 'acc_${now.millisecondsSinceEpoch}',
      name: name,
      type: type,
      startingBalance: startingBalance,
      startingDate: startingDate,
      currency: currency,
      bankName: bankName,
      accountNumber: accountNumber,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy account with updated fields
  Account copyWith({
    String? name,
    AccountType? type,
    double? startingBalance,
    DateTime? startingDate,
    String? currency,
    String? bankName,
    String? accountNumber,
    bool? isActive,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      startingBalance: startingBalance ?? this.startingBalance,
      startingDate: startingDate ?? this.startingDate,
      currency: currency ?? this.currency,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'startingBalance': startingBalance,
      'startingDate': startingDate.toIso8601String(),
      'currency': currency,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => AccountType.bank,
      ),
      startingBalance: (json['startingBalance'] as num).toDouble(),
      startingDate: DateTime.parse(json['startingDate'] as String),
      currency: json['currency'] as String? ?? 'KES',
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Get display name with type
  String get displayNameWithType => '$name (${type.displayName})';

  /// Get masked account number for display
  String get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.length < 4) {
      return accountNumber ?? '';
    }
    final last4 = accountNumber!.substring(accountNumber!.length - 4);
    return '****$last4';
  }

  /// Check if account is M-Pesa
  bool get isMpesa => type == AccountType.mpesa;

  /// Check if account is bank account
  bool get isBank => type == AccountType.bank || type == AccountType.savings;

  /// Get icon for account type
  String get iconName {
    switch (type) {
      case AccountType.bank:
        return 'account_balance';
      case AccountType.mpesa:
        return 'phone_android';
      case AccountType.cash:
        return 'payments';
      case AccountType.savings:
        return 'savings';
      case AccountType.investment:
        return 'trending_up';
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        startingBalance,
        startingDate,
        currency,
        bankName,
        accountNumber,
        isActive,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Account(id: $id, name: $name, type: ${type.displayName}, '
        'startingBalance: $startingBalance, currency: $currency)';
  }
}

/// Default accounts for Kenya market
class DefaultAccounts {
  static List<Account> getKenyaDefaults() {
    final now = DateTime.now();
    return [
      Account.create(
        name: 'Main Bank Account',
        type: AccountType.bank,
        startingBalance: 0.0,
        startingDate: now,
        currency: 'KES',
      ),
      Account.create(
        name: 'M-Pesa',
        type: AccountType.mpesa,
        startingBalance: 0.0,
        startingDate: now,
        currency: 'KES',
      ),
      Account.create(
        name: 'Cash',
        type: AccountType.cash,
        startingBalance: 0.0,
        startingDate: now,
        currency: 'KES',
      ),
    ];
  }

  /// Popular Kenyan banks for quick setup
  static List<String> get kenyaBanks => [
        'KCB Bank',
        'Equity Bank',
        'Cooperative Bank',
        'Standard Chartered',
        'Barclays Bank',
        'NCBA Bank',
        'Absa Bank',
        'DTB Bank',
        'Stanbic Bank',
        'Family Bank',
        'NIC Bank',
        'Diamond Trust Bank',
        'Other',
      ];
}
