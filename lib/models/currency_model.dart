enum SupportedCurrency {
  kes, // Kenyan Shilling (Primary)
  usd, // US Dollar
  eur, // Euro
  gbp, // British Pound
  ugx, // Ugandan Shilling
  tzs, // Tanzanian Shilling
  zar, // South African Rand
  ngn, // Nigerian Naira
  ghs, // Ghanaian Cedi
  etb, // Ethiopian Birr
  rwf, // Rwandan Franc
  mad, // Moroccan Dirham
  egp, // Egyptian Pound
  inr, // Indian Rupee
  cad, // Canadian Dollar
  aud, // Australian Dollar
}

class Currency {
  final SupportedCurrency code;
  final String name;
  final String symbol;
  final String isoCode;
  final int decimalPlaces;
  final String locale;
  final bool isDefault;
  final String flag;
  final String region;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.isoCode,
    this.decimalPlaces = 2,
    required this.locale,
    this.isDefault = false,
    required this.flag,
    required this.region,
  });

  @override
  String toString() => '$symbol ($isoCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class CurrencyData {
  static const Map<SupportedCurrency, Currency> currencies = {
    SupportedCurrency.kes: Currency(
      code: SupportedCurrency.kes,
      name: 'Kenyan Shilling',
      symbol: 'KSh',
      isoCode: 'KES',
      decimalPlaces: 2,
      locale: 'en_KE',
      isDefault: true,
      flag: '🇰🇪',
      region: 'Kenya',
    ),
    SupportedCurrency.usd: Currency(
      code: SupportedCurrency.usd,
      name: 'US Dollar',
      symbol: '\$',
      isoCode: 'USD',
      decimalPlaces: 2,
      locale: 'en_US',
      flag: '🇺🇸',
      region: 'United States',
    ),
    SupportedCurrency.eur: Currency(
      code: SupportedCurrency.eur,
      name: 'Euro',
      symbol: '€',
      isoCode: 'EUR',
      decimalPlaces: 2,
      locale: 'en_EU',
      flag: '🇪🇺',
      region: 'European Union',
    ),
    SupportedCurrency.gbp: Currency(
      code: SupportedCurrency.gbp,
      name: 'British Pound',
      symbol: '£',
      isoCode: 'GBP',
      decimalPlaces: 2,
      locale: 'en_GB',
      flag: '🇬🇧',
      region: 'United Kingdom',
    ),
    SupportedCurrency.ugx: Currency(
      code: SupportedCurrency.ugx,
      name: 'Ugandan Shilling',
      symbol: 'USh',
      isoCode: 'UGX',
      decimalPlaces: 0, // UGX typically doesn't use decimals
      locale: 'en_UG',
      flag: '🇺🇬',
      region: 'Uganda',
    ),
    SupportedCurrency.tzs: Currency(
      code: SupportedCurrency.tzs,
      name: 'Tanzanian Shilling',
      symbol: 'TSh',
      isoCode: 'TZS',
      decimalPlaces: 0, // TZS typically doesn't use decimals
      locale: 'en_TZ',
      flag: '🇹🇿',
      region: 'Tanzania',
    ),
    SupportedCurrency.zar: Currency(
      code: SupportedCurrency.zar,
      name: 'South African Rand',
      symbol: 'R',
      isoCode: 'ZAR',
      decimalPlaces: 2,
      locale: 'en_ZA',
      flag: '🇿🇦',
      region: 'South Africa',
    ),
    SupportedCurrency.ngn: Currency(
      code: SupportedCurrency.ngn,
      name: 'Nigerian Naira',
      symbol: '₦',
      isoCode: 'NGN',
      decimalPlaces: 2,
      locale: 'en_NG',
      flag: '🇳🇬',
      region: 'Nigeria',
    ),
    SupportedCurrency.ghs: Currency(
      code: SupportedCurrency.ghs,
      name: 'Ghanaian Cedi',
      symbol: '₵',
      isoCode: 'GHS',
      decimalPlaces: 2,
      locale: 'en_GH',
      flag: '🇬🇭',
      region: 'Ghana',
    ),
    SupportedCurrency.inr: Currency(
      code: SupportedCurrency.inr,
      name: 'Indian Rupee',
      symbol: '₹',
      isoCode: 'INR',
      decimalPlaces: 2,
      locale: 'en_IN',
      flag: '🇮🇳',
      region: 'India',
    ),
    SupportedCurrency.cad: Currency(
      code: SupportedCurrency.cad,
      name: 'Canadian Dollar',
      symbol: 'C\$',
      isoCode: 'CAD',
      decimalPlaces: 2,
      locale: 'en_CA',
      flag: '🇨🇦',
      region: 'Canada',
    ),
    SupportedCurrency.etb: Currency(
      code: SupportedCurrency.etb,
      name: 'Ethiopian Birr',
      symbol: 'Br',
      isoCode: 'ETB',
      decimalPlaces: 2,
      locale: 'en_ET',
      flag: '🇪🇹',
      region: 'Ethiopia',
    ),
    SupportedCurrency.rwf: Currency(
      code: SupportedCurrency.rwf,
      name: 'Rwandan Franc',
      symbol: 'RF',
      isoCode: 'RWF',
      decimalPlaces: 0,
      locale: 'en_RW',
      flag: '🇷🇼',
      region: 'Rwanda',
    ),
    SupportedCurrency.mad: Currency(
      code: SupportedCurrency.mad,
      name: 'Moroccan Dirham',
      symbol: 'MAD',
      isoCode: 'MAD',
      decimalPlaces: 2,
      locale: 'en_MA',
      flag: '🇲🇦',
      region: 'Morocco',
    ),
    SupportedCurrency.egp: Currency(
      code: SupportedCurrency.egp,
      name: 'Egyptian Pound',
      symbol: 'E£',
      isoCode: 'EGP',
      decimalPlaces: 2,
      locale: 'en_EG',
      flag: '🇪🇬',
      region: 'Egypt',
    ),
    SupportedCurrency.aud: Currency(
      code: SupportedCurrency.aud,
      name: 'Australian Dollar',
      symbol: 'A\$',
      isoCode: 'AUD',
      decimalPlaces: 2,
      locale: 'en_AU',
      flag: '🇦🇺',
      region: 'Australia',
    ),
  };

  static Currency get defaultCurrency => currencies[SupportedCurrency.kes]!;

  static Currency getCurrency(SupportedCurrency code) {
    return currencies[code] ?? defaultCurrency;
  }

  static List<Currency> get allCurrencies => currencies.values.toList();

  static List<Currency> get popularCurrencies => [
    currencies[SupportedCurrency.kes]!, // Kenya (Primary)
    currencies[SupportedCurrency.usd]!, // Global standard
    currencies[SupportedCurrency.ugx]!, // Regional (Uganda)
    currencies[SupportedCurrency.tzs]!, // Regional (Tanzania)
    currencies[SupportedCurrency.etb]!, // Regional (Ethiopia)
    currencies[SupportedCurrency.rwf]!, // Regional (Rwanda)
    currencies[SupportedCurrency.zar]!, // Regional (South Africa)
    currencies[SupportedCurrency.ngn]!, // Regional (Nigeria)
    currencies[SupportedCurrency.eur]!, // European market
    currencies[SupportedCurrency.gbp]!, // UK market
  ];

  static List<Currency> get africanCurrencies => [
    currencies[SupportedCurrency.kes]!, // Kenya
    currencies[SupportedCurrency.ugx]!, // Uganda
    currencies[SupportedCurrency.tzs]!, // Tanzania
    currencies[SupportedCurrency.etb]!, // Ethiopia
    currencies[SupportedCurrency.rwf]!, // Rwanda
    currencies[SupportedCurrency.zar]!, // South Africa
    currencies[SupportedCurrency.ngn]!, // Nigeria
    currencies[SupportedCurrency.ghs]!, // Ghana
    currencies[SupportedCurrency.mad]!, // Morocco
    currencies[SupportedCurrency.egp]!, // Egypt
  ];
}

class CurrencyPreferences {
  final SupportedCurrency primaryCurrency;
  final SupportedCurrency? secondaryCurrency;
  final bool showCurrencySymbol;
  final bool showCurrencyCode;
  final CurrencyDisplayFormat displayFormat;
  final bool enableCurrencyConversion;
  final Map<String, double> customExchangeRates;

  const CurrencyPreferences({
    this.primaryCurrency = SupportedCurrency.kes,
    this.secondaryCurrency,
    this.showCurrencySymbol = true,
    this.showCurrencyCode = false,
    this.displayFormat = CurrencyDisplayFormat.symbolBefore,
    this.enableCurrencyConversion = false,
    this.customExchangeRates = const {},
  });

  CurrencyPreferences copyWith({
    SupportedCurrency? primaryCurrency,
    SupportedCurrency? secondaryCurrency,
    bool? showCurrencySymbol,
    bool? showCurrencyCode,
    CurrencyDisplayFormat? displayFormat,
    bool? enableCurrencyConversion,
    Map<String, double>? customExchangeRates,
  }) {
    return CurrencyPreferences(
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      secondaryCurrency: secondaryCurrency ?? this.secondaryCurrency,
      showCurrencySymbol: showCurrencySymbol ?? this.showCurrencySymbol,
      showCurrencyCode: showCurrencyCode ?? this.showCurrencyCode,
      displayFormat: displayFormat ?? this.displayFormat,
      enableCurrencyConversion: enableCurrencyConversion ?? this.enableCurrencyConversion,
      customExchangeRates: customExchangeRates ?? this.customExchangeRates,
    );
  }
}

enum CurrencyDisplayFormat {
  symbolBefore,  // KSh 1,000.00
  symbolAfter,   // 1,000.00 KSh
  codeBefore,    // KES 1,000.00
  codeAfter,     // 1,000.00 KES
  symbolAndCode, // KSh 1,000.00 (KES)
}

class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime lastUpdated;
  final String source;

  const ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.lastUpdated,
    this.source = 'Manual',
  });

  bool get isStale {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inHours > 24; // Consider stale after 24 hours
  }

  @override
  String toString() => '$fromCurrency → $toCurrency: $rate';
}

class CurrencyConversion {
  final double originalAmount;
  final Currency fromCurrency;
  final Currency toCurrency;
  final double convertedAmount;
  final double exchangeRate;
  final DateTime conversionDate;

  const CurrencyConversion({
    required this.originalAmount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.convertedAmount,
    required this.exchangeRate,
    required this.conversionDate,
  });

  @override
  String toString() {
    return '${fromCurrency.symbol}${originalAmount.toStringAsFixed(fromCurrency.decimalPlaces)} = '
           '${toCurrency.symbol}${convertedAmount.toStringAsFixed(toCurrency.decimalPlaces)} '
           '(Rate: $exchangeRate)';
  }
}

// Kenya-specific currency utilities
class KenyaCurrencyUtils {
  // Common Kenyan amount ranges for better UX
  static const List<double> commonKenyaAmounts = [
    50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000
  ];

  // Kenyan mobile money limits (M-Pesa, Airtel Money)
  static const double mpesaDailyLimit = 300000; // KSh 300,000
  static const double mpesaTransactionLimit = 150000; // KSh 150,000
  static const double airtelMoneyDailyLimit = 500000; // KSh 500,000

  // Common Kenyan expense categories with typical amounts
  static const Map<String, List<double>> typicalKenyaExpenses = {
    'Transport': [50, 100, 200, 500, 1000], // Matatu, Uber, fuel
    'Food': [100, 300, 500, 1000, 2000], // Meals, groceries
    'Utilities': [1000, 2000, 5000, 10000], // Electricity, water, internet
    'Rent': [10000, 20000, 50000, 100000], // Housing costs
    'Airtime': [100, 200, 500, 1000], // Mobile credit
    'Shopping': [500, 1000, 5000, 10000], // General shopping
  };

  // Format amount in Kenyan style (with commas)
  static String formatKenyaAmount(double amount) {
    if (amount >= 1000000) {
      return 'KSh ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'KSh ${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    } else {
      return 'KSh ${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
    }
  }

  // Check if amount is within typical Kenyan ranges
  static bool isTypicalKenyaAmount(double amount, String category) {
    final ranges = typicalKenyaExpenses[category];
    if (ranges == null) return true;
    
    return amount >= ranges.first && amount <= ranges.last * 2;
  }

  // Get suggested amounts for category
  static List<double> getSuggestedAmounts(String category) {
    return typicalKenyaExpenses[category] ?? commonKenyaAmounts.take(5).toList();
  }
}
