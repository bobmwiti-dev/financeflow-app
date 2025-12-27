/// Configuration for M-Pesa import with intelligent settings
class MpesaImportConfig {
  final bool enableAutomaticCategorization;
  final bool skipDuplicates;
  final bool validateTransactions;
  final double minimumConfidenceThreshold;
  final List<String> excludedNumbers;
  final List<String> excludedKeywords;
  final Map<String, String> customMerchantMappings;
  final bool enableIncomeDetection;
  final List<String> salaryKeywords;
  final List<String> loanKeywords;
  final int maxImportDays;

  const MpesaImportConfig({
    this.enableAutomaticCategorization = true,
    this.skipDuplicates = true,
    this.validateTransactions = true,
    this.minimumConfidenceThreshold = 0.7,
    this.excludedNumbers = const [],
    this.excludedKeywords = const ['FULIZA', 'REVERSAL', 'REFUND'],
    this.customMerchantMappings = const {},
    this.enableIncomeDetection = true,
    this.salaryKeywords = const ['SALARY', 'PAYROLL', 'WAGES', 'STIPEND'],
    this.loanKeywords = const ['FULIZA', 'LOAN', 'CREDIT'],
    this.maxImportDays = 90,
  });

  /// Default configuration for Kenya market
  factory MpesaImportConfig.defaultKenya() {
    return const MpesaImportConfig(
      enableAutomaticCategorization: true,
      skipDuplicates: true,
      validateTransactions: true,
      minimumConfidenceThreshold: 0.8,
      excludedKeywords: [
        'FULIZA', 'REVERSAL', 'REFUND', 'CANCELLED', 'FAILED',
        'M-SHWARI', 'KCB-MPESA', 'EQUITY-MPESA'
      ],
      salaryKeywords: [
        'SALARY', 'PAYROLL', 'WAGES', 'STIPEND', 'ALLOWANCE',
        'BONUS', 'COMMISSION', 'PENSION', 'RETIREMENT'
      ],
      loanKeywords: [
        'FULIZA', 'LOAN', 'CREDIT', 'ADVANCE', 'BORROW',
        'M-SHWARI', 'KCB-MPESA', 'EQUITY-MPESA'
      ],
      maxImportDays: 180, // 6 months for comprehensive history
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

  /// Check if SMS contains excluded keywords
  bool containsExcludedKeywords(String smsBody) {
    final upperSms = smsBody.toUpperCase();
    return excludedKeywords.any((keyword) => upperSms.contains(keyword.toUpperCase()));
  }

  /// Check if SMS contains salary keywords
  bool containsSalaryKeywords(String smsBody) {
    final upperSms = smsBody.toUpperCase();
    return salaryKeywords.any((keyword) => upperSms.contains(keyword.toUpperCase()));
  }

  /// Check if SMS contains loan keywords
  bool containsLoanKeywords(String smsBody) {
    final upperSms = smsBody.toUpperCase();
    return loanKeywords.any((keyword) => upperSms.contains(keyword.toUpperCase()));
  }

  /// Get custom merchant mapping if available
  String? getCustomMerchantMapping(String merchantName) {
    final upperMerchant = merchantName.toUpperCase();
    for (final entry in customMerchantMappings.entries) {
      if (upperMerchant.contains(entry.key.toUpperCase())) {
        return entry.value;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'enableAutomaticCategorization': enableAutomaticCategorization,
      'skipDuplicates': skipDuplicates,
      'validateTransactions': validateTransactions,
      'minimumConfidenceThreshold': minimumConfidenceThreshold,
      'excludedNumbers': excludedNumbers,
      'excludedKeywords': excludedKeywords,
      'customMerchantMappings': customMerchantMappings,
      'enableIncomeDetection': enableIncomeDetection,
      'salaryKeywords': salaryKeywords,
      'loanKeywords': loanKeywords,
      'maxImportDays': maxImportDays,
    };
  }

  factory MpesaImportConfig.fromMap(Map<String, dynamic> map) {
    return MpesaImportConfig(
      enableAutomaticCategorization: map['enableAutomaticCategorization'] ?? true,
      skipDuplicates: map['skipDuplicates'] ?? true,
      validateTransactions: map['validateTransactions'] ?? true,
      minimumConfidenceThreshold: (map['minimumConfidenceThreshold'] ?? 0.7).toDouble(),
      excludedNumbers: List<String>.from(map['excludedNumbers'] ?? []),
      excludedKeywords: List<String>.from(map['excludedKeywords'] ?? []),
      customMerchantMappings: Map<String, String>.from(map['customMerchantMappings'] ?? {}),
      enableIncomeDetection: map['enableIncomeDetection'] ?? true,
      salaryKeywords: List<String>.from(map['salaryKeywords'] ?? []),
      loanKeywords: List<String>.from(map['loanKeywords'] ?? []),
      maxImportDays: map['maxImportDays'] ?? 90,
    );
  }

  MpesaImportConfig copyWith({
    bool? enableAutomaticCategorization,
    bool? skipDuplicates,
    bool? validateTransactions,
    double? minimumConfidenceThreshold,
    List<String>? excludedNumbers,
    List<String>? excludedKeywords,
    Map<String, String>? customMerchantMappings,
    bool? enableIncomeDetection,
    List<String>? salaryKeywords,
    List<String>? loanKeywords,
    int? maxImportDays,
  }) {
    return MpesaImportConfig(
      enableAutomaticCategorization: enableAutomaticCategorization ?? this.enableAutomaticCategorization,
      skipDuplicates: skipDuplicates ?? this.skipDuplicates,
      validateTransactions: validateTransactions ?? this.validateTransactions,
      minimumConfidenceThreshold: minimumConfidenceThreshold ?? this.minimumConfidenceThreshold,
      excludedNumbers: excludedNumbers ?? this.excludedNumbers,
      excludedKeywords: excludedKeywords ?? this.excludedKeywords,
      customMerchantMappings: customMerchantMappings ?? this.customMerchantMappings,
      enableIncomeDetection: enableIncomeDetection ?? this.enableIncomeDetection,
      salaryKeywords: salaryKeywords ?? this.salaryKeywords,
      loanKeywords: loanKeywords ?? this.loanKeywords,
      maxImportDays: maxImportDays ?? this.maxImportDays,
    );
  }
}
