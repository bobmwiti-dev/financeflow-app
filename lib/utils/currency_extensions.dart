import '../models/currency_model.dart';
import '../services/currency_service.dart';

extension CurrencyFormatting on double {
  /// Format amount using the current currency preferences
  String toCurrency({Currency? currency, bool compact = false}) {
    return CurrencyService().formatAmount(this, currency: currency, compact: compact);
  }

  /// Format amount with conversion to secondary currency
  String toCurrencyWithConversion({Currency? fromCurrency}) {
    return CurrencyService().formatAmountWithConversion(this, fromCurrency: fromCurrency);
  }

  /// Format amount for input fields (no currency symbol)
  String toCurrencyInput({Currency? currency}) {
    return CurrencyService().formatAmountForInput(this, currency: currency);
  }

  /// Convert to another currency
  double convertTo(Currency toCurrency, {Currency? fromCurrency}) {
    final from = fromCurrency ?? CurrencyService().primaryCurrency;
    return CurrencyService().convertAmount(this, from, toCurrency);
  }

  /// Format as Kenyan amount with smart abbreviations
  String toKenyaCurrency() {
    return KenyaCurrencyUtils.formatKenyaAmount(this);
  }

  /// Format with KES + USD conversion for Kenya market
  String toKenyaDualCurrency() {
    final service = CurrencyService();
    if (service.preferences.enableCurrencyConversion && 
        service.preferences.primaryCurrency == SupportedCurrency.kes) {
      return service.formatAmountWithConversion(this);
    }
    return toCurrency();
  }

  /// Check if amount is typical for a Kenyan category
  bool isTypicalKenyaAmount(String category) {
    return KenyaCurrencyUtils.isTypicalKenyaAmount(this, category);
  }
}

extension StringCurrencyParsing on String {
  /// Parse currency string to double
  double parseCurrency({Currency? currency}) {
    return CurrencyService().parseAmount(this, currency: currency);
  }
}

extension CurrencyHelpers on Currency {
  /// Check if this is an African currency
  bool get isAfrican => CurrencyData.africanCurrencies.contains(this);

  /// Check if this is a popular currency
  bool get isPopular => CurrencyData.popularCurrencies.contains(this);

  /// Check if this is the default currency (KES)
  bool get isDefault => code == SupportedCurrency.kes;

  /// Get exchange rate to another currency
  double exchangeRateTo(Currency toCurrency) {
    return CurrencyService().getExchangeRate(this, toCurrency);
  }

  /// Format amount in this currency
  String formatAmount(double amount, {bool compact = false}) {
    return CurrencyService().formatAmount(amount, currency: this, compact: compact);
  }
}

/// Mixin for widgets that need currency formatting
mixin CurrencyFormattingMixin {
  final CurrencyService _currencyService = CurrencyService();

  /// Format amount using current preferences
  String formatCurrency(double amount, {Currency? currency, bool compact = false}) {
    return _currencyService.formatAmount(amount, currency: currency, compact: compact);
  }

  /// Format amount with conversion
  String formatCurrencyWithConversion(double amount, {Currency? fromCurrency}) {
    return _currencyService.formatAmountWithConversion(amount, fromCurrency: fromCurrency);
  }

  /// Get current primary currency
  Currency get primaryCurrency => _currencyService.primaryCurrency;

  /// Get current currency preferences
  CurrencyPreferences get currencyPreferences => _currencyService.preferences;

  /// Parse amount from string
  double parseCurrencyInput(String input, {Currency? currency}) {
    return _currencyService.parseAmount(input, currency: currency);
  }
}

/// Helper class for common currency operations
class CurrencyHelper {
  static final CurrencyService _service = CurrencyService();

  /// Quick format for display
  static String format(double amount, {Currency? currency, bool compact = false}) {
    return _service.formatAmount(amount, currency: currency, compact: compact);
  }

  /// Quick format with conversion
  static String formatWithConversion(double amount, {Currency? fromCurrency}) {
    return _service.formatAmountWithConversion(amount, fromCurrency: fromCurrency);
  }

  /// Quick parse from string
  static double parse(String input, {Currency? currency}) {
    return _service.parseAmount(input, currency: currency);
  }

  /// Get primary currency
  static Currency get primaryCurrency => _service.primaryCurrency;

  /// Check if multi-currency is enabled
  static bool get isMultiCurrencyEnabled => _service.preferences.enableCurrencyConversion;

  /// Get all supported currencies
  static List<Currency> get allCurrencies => CurrencyData.allCurrencies;

  /// Get popular currencies
  static List<Currency> get popularCurrencies => CurrencyData.popularCurrencies;

  /// Get African currencies
  static List<Currency> get africanCurrencies => CurrencyData.africanCurrencies;

  /// Get currency by code
  static Currency getCurrency(SupportedCurrency code) => CurrencyData.getCurrency(code);

  /// Get default currency (KES)
  static Currency get defaultCurrency => CurrencyData.defaultCurrency;

  /// Format amount specifically for Kenya
  static String formatKenya(double amount) => KenyaCurrencyUtils.formatKenyaAmount(amount);

  /// Get suggested amounts for Kenyan categories
  static List<double> getKenyaSuggestions(String category) {
    return KenyaCurrencyUtils.getSuggestedAmounts(category);
  }

  /// Check M-Pesa limits
  static bool isWithinMpesaLimit(double amount) {
    return amount <= KenyaCurrencyUtils.mpesaTransactionLimit;
  }

  /// Check if amount exceeds daily M-Pesa limit
  static bool exceedsMpesaDailyLimit(double amount) {
    return amount > KenyaCurrencyUtils.mpesaDailyLimit;
  }

  /// Format with dual currency for Kenya market (KES + USD)
  static String formatKenyaDual(double amount) {
    final service = CurrencyService();
    if (service.preferences.enableCurrencyConversion && 
        service.preferences.primaryCurrency == SupportedCurrency.kes) {
      return service.formatAmountWithConversion(amount);
    }
    return format(amount);
  }
}
