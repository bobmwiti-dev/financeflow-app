import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../models/currency_model.dart';
import 'package:intl/intl.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  static const String _currencyPrefsKey = 'currency_preferences';
  static const String _exchangeRatesKey = 'exchange_rates';
  static const String _lastUpdateKey = 'last_exchange_update';

  CurrencyPreferences _preferences = const CurrencyPreferences();
  Map<String, ExchangeRate> _exchangeRates = {};
  
  final StreamController<CurrencyPreferences> _preferencesController = 
      StreamController<CurrencyPreferences>.broadcast();
  
  Stream<CurrencyPreferences> get preferencesStream => _preferencesController.stream;
  CurrencyPreferences get preferences => _preferences;
  Currency get primaryCurrency => CurrencyData.getCurrency(_preferences.primaryCurrency);

  /// Initialize the currency service
  Future<void> initialize() async {
    await _loadPreferences();
    await _loadExchangeRates();
    _initializeDefaultRates();
  }

  /// Load currency preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_currencyPrefsKey);
      
      if (prefsJson != null) {
        final data = jsonDecode(prefsJson);
        _preferences = CurrencyPreferences(
          primaryCurrency: SupportedCurrency.values.firstWhere(
            (c) => c.name == data['primaryCurrency'],
            orElse: () => SupportedCurrency.kes,
          ),
          secondaryCurrency: data['secondaryCurrency'] != null
              ? SupportedCurrency.values.firstWhere(
                  (c) => c.name == data['secondaryCurrency'],
                  orElse: () => SupportedCurrency.usd,
                )
              : null,
          showCurrencySymbol: data['showCurrencySymbol'] ?? true,
          showCurrencyCode: data['showCurrencyCode'] ?? false,
          displayFormat: CurrencyDisplayFormat.values.firstWhere(
            (f) => f.name == data['displayFormat'],
            orElse: () => CurrencyDisplayFormat.symbolBefore,
          ),
          enableCurrencyConversion: data['enableCurrencyConversion'] ?? false,
          customExchangeRates: Map<String, double>.from(data['customExchangeRates'] ?? {}),
        );
      }
    } catch (e) {
      Logger('CurrencyService').severe('Error loading currency preferences: $e');
      _preferences = const CurrencyPreferences();
    }
    
    _preferencesController.add(_preferences);
  }

  /// Save currency preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'primaryCurrency': _preferences.primaryCurrency.name,
        'secondaryCurrency': _preferences.secondaryCurrency?.name,
        'showCurrencySymbol': _preferences.showCurrencySymbol,
        'showCurrencyCode': _preferences.showCurrencyCode,
        'displayFormat': _preferences.displayFormat.name,
        'enableCurrencyConversion': _preferences.enableCurrencyConversion,
        'customExchangeRates': _preferences.customExchangeRates,
      };
      
      await prefs.setString(_currencyPrefsKey, jsonEncode(data));
      _preferencesController.add(_preferences);
    } catch (e) {
      Logger('CurrencyService').severe('Error saving currency preferences: $e');
    }
  }

  /// Update currency preferences
  Future<void> updatePreferences(CurrencyPreferences newPreferences) async {
    _preferences = newPreferences;
    await _savePreferences();
  }

  /// Set primary currency
  Future<void> setPrimaryCurrency(SupportedCurrency currency) async {
    _preferences = _preferences.copyWith(primaryCurrency: currency);
    await _savePreferences();
  }

  /// Set secondary currency for conversion
  Future<void> setSecondaryCurrency(SupportedCurrency? currency) async {
    _preferences = _preferences.copyWith(secondaryCurrency: currency);
    await _savePreferences();
  }

  /// Format amount according to current preferences
  String formatAmount(double amount, {Currency? currency, bool compact = false}) {
    final curr = currency ?? primaryCurrency;
    
    if (compact && amount >= 1000) {
      return _formatCompactAmount(amount, curr);
    }
    
    return _formatFullAmount(amount, curr);
  }

  /// Format amount in compact form (e.g., KSh 1.5K, KSh 2.3M)
  String _formatCompactAmount(double amount, Currency currency) {
    String formattedAmount;
    
    if (amount >= 1000000000) {
      formattedAmount = '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      formattedAmount = '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      formattedAmount = '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      formattedAmount = amount.toStringAsFixed(currency.decimalPlaces);
    }
    
    return _applyCurrencyFormat(formattedAmount, currency);
  }

  /// Format amount in full form with proper number formatting
  String _formatFullAmount(double amount, Currency currency) {
    final formatter = NumberFormat.currency(
      locale: currency.locale,
      symbol: '',
      decimalDigits: currency.decimalPlaces,
    );
    
    final formattedAmount = formatter.format(amount);
    return _applyCurrencyFormat(formattedAmount, currency);
  }

  /// Apply currency symbol/code formatting based on preferences
  String _applyCurrencyFormat(String formattedAmount, Currency currency) {
    final showSymbol = _preferences.showCurrencySymbol;
    final showCode = _preferences.showCurrencyCode;
    
    switch (_preferences.displayFormat) {
      case CurrencyDisplayFormat.symbolBefore:
        return showSymbol ? '${currency.symbol}$formattedAmount' : formattedAmount;
      
      case CurrencyDisplayFormat.symbolAfter:
        return showSymbol ? '$formattedAmount ${currency.symbol}' : formattedAmount;
      
      case CurrencyDisplayFormat.codeBefore:
        return showCode ? '${currency.isoCode} $formattedAmount' : formattedAmount;
      
      case CurrencyDisplayFormat.codeAfter:
        return showCode ? '$formattedAmount ${currency.isoCode}' : formattedAmount;
      
      case CurrencyDisplayFormat.symbolAndCode:
        if (showSymbol && showCode) {
          return '${currency.symbol}$formattedAmount (${currency.isoCode})';
        } else if (showSymbol) {
          return '${currency.symbol}$formattedAmount';
        } else if (showCode) {
          return '$formattedAmount ${currency.isoCode}';
        } else {
          return formattedAmount;
        }
    }
  }

  /// Format amount with secondary currency conversion
  String formatAmountWithConversion(double amount, {Currency? fromCurrency}) {
    final from = fromCurrency ?? primaryCurrency;
    final primary = formatAmount(amount, currency: from);
    
    if (!_preferences.enableCurrencyConversion || _preferences.secondaryCurrency == null) {
      return primary;
    }
    
    final secondary = CurrencyData.getCurrency(_preferences.secondaryCurrency!);
    final convertedAmount = convertAmount(amount, from, secondary);
    final secondaryFormatted = formatAmount(convertedAmount, currency: secondary, compact: true);
    
    return '$primary (~$secondaryFormatted)';
  }

  /// Convert amount between currencies
  double convertAmount(double amount, Currency fromCurrency, Currency toCurrency) {
    if (fromCurrency.code == toCurrency.code) return amount;
    
    final rateKey = '${fromCurrency.isoCode}_${toCurrency.isoCode}';
    final rate = _exchangeRates[rateKey]?.rate ?? _getDefaultRate(fromCurrency, toCurrency);
    
    return amount * rate;
  }

  /// Get exchange rate between two currencies
  double getExchangeRate(Currency fromCurrency, Currency toCurrency) {
    if (fromCurrency.code == toCurrency.code) return 1.0;
    
    final rateKey = '${fromCurrency.isoCode}_${toCurrency.isoCode}';
    return _exchangeRates[rateKey]?.rate ?? _getDefaultRate(fromCurrency, toCurrency);
  }

  /// Load exchange rates from storage
  Future<void> _loadExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString(_exchangeRatesKey);
      
      if (ratesJson != null) {
        final data = jsonDecode(ratesJson) as Map<String, dynamic>;
        _exchangeRates = data.map((key, value) {
          final rateData = value as Map<String, dynamic>;
          return MapEntry(
            key,
            ExchangeRate(
              fromCurrency: rateData['fromCurrency'],
              toCurrency: rateData['toCurrency'],
              rate: rateData['rate'].toDouble(),
              lastUpdated: DateTime.parse(rateData['lastUpdated']),
              source: rateData['source'] ?? 'Manual',
            ),
          );
        });
      }
    } catch (e) {
      Logger('CurrencyService').severe('Error loading exchange rates: $e');
      _exchangeRates = {};
    }
  }

  /// Save exchange rates to storage
  Future<void> _saveExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _exchangeRates.map((key, rate) => MapEntry(
        key,
        {
          'fromCurrency': rate.fromCurrency,
          'toCurrency': rate.toCurrency,
          'rate': rate.rate,
          'lastUpdated': rate.lastUpdated.toIso8601String(),
          'source': rate.source,
        },
      ));
      
      await prefs.setString(_exchangeRatesKey, jsonEncode(data));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      Logger('CurrencyService').severe('Error saving exchange rates: $e');
    }
  }

  /// Initialize default exchange rates (approximate rates for offline use)
  void _initializeDefaultRates() {
    final defaultRates = {
      // KES to other currencies (base rates as of 2024)
      'KES_USD': 0.0069, // 1 KES = 0.0069 USD (approx 145 KES = 1 USD)
      'KES_EUR': 0.0063, // 1 KES = 0.0063 EUR
      'KES_GBP': 0.0054, // 1 KES = 0.0054 GBP
      'KES_UGX': 25.5,   // 1 KES = 25.5 UGX
      'KES_TZS': 17.2,   // 1 KES = 17.2 TZS
      'KES_ZAR': 0.125,  // 1 KES = 0.125 ZAR
      'KES_NGN': 11.2,   // 1 KES = 11.2 NGN
      'KES_GHS': 0.084,  // 1 KES = 0.084 GHS
      'KES_INR': 0.58,   // 1 KES = 0.58 INR
      'KES_CAD': 0.0094, // 1 KES = 0.0094 CAD
      'KES_AUD': 0.0104, // 1 KES = 0.0104 AUD
      
      // USD to other currencies
      'USD_EUR': 0.91,   // 1 USD = 0.91 EUR
      'USD_GBP': 0.78,   // 1 USD = 0.78 GBP
      'USD_KES': 145.0,  // 1 USD = 145 KES
      'USD_UGX': 3700.0, // 1 USD = 3700 UGX
      'USD_TZS': 2500.0, // 1 USD = 2500 TZS
      'USD_ZAR': 18.1,   // 1 USD = 18.1 ZAR
      'USD_NGN': 1620.0, // 1 USD = 1620 NGN
      'USD_GHS': 12.1,   // 1 USD = 12.1 GHS
      'USD_INR': 83.5,   // 1 USD = 83.5 INR
      'USD_CAD': 1.36,   // 1 USD = 1.36 CAD
      'USD_AUD': 1.51,   // 1 USD = 1.51 AUD
    };

    final now = DateTime.now();
    
    for (final entry in defaultRates.entries) {
      final parts = entry.key.split('_');
      if (parts.length == 2 && !_exchangeRates.containsKey(entry.key)) {
        _exchangeRates[entry.key] = ExchangeRate(
          fromCurrency: parts[0],
          toCurrency: parts[1],
          rate: entry.value,
          lastUpdated: now,
          source: 'Default',
        );
      }
    }

    // Generate reverse rates
    final reverseRates = <String, ExchangeRate>{};
    for (final entry in _exchangeRates.entries) {
      final rate = entry.value;
      final reverseKey = '${rate.toCurrency}_${rate.fromCurrency}';
      
      if (!_exchangeRates.containsKey(reverseKey)) {
        reverseRates[reverseKey] = ExchangeRate(
          fromCurrency: rate.toCurrency,
          toCurrency: rate.fromCurrency,
          rate: 1.0 / rate.rate,
          lastUpdated: rate.lastUpdated,
          source: rate.source,
        );
      }
    }
    
    _exchangeRates.addAll(reverseRates);
  }

  /// Get default exchange rate when no stored rate is available
  double _getDefaultRate(Currency fromCurrency, Currency toCurrency) {
    // If no rate is available, return 1.0 (no conversion)
    // In a production app, you might want to fetch from an API
    return 1.0;
  }

  /// Update exchange rate manually
  Future<void> updateExchangeRate(Currency fromCurrency, Currency toCurrency, double rate) async {
    final rateKey = '${fromCurrency.isoCode}_${toCurrency.isoCode}';
    final reverseKey = '${toCurrency.isoCode}_${fromCurrency.isoCode}';
    
    _exchangeRates[rateKey] = ExchangeRate(
      fromCurrency: fromCurrency.isoCode,
      toCurrency: toCurrency.isoCode,
      rate: rate,
      lastUpdated: DateTime.now(),
      source: 'Manual',
    );
    
    _exchangeRates[reverseKey] = ExchangeRate(
      fromCurrency: toCurrency.isoCode,
      toCurrency: fromCurrency.isoCode,
      rate: 1.0 / rate,
      lastUpdated: DateTime.now(),
      source: 'Manual',
    );
    
    await _saveExchangeRates();
  }

  /// Get all available exchange rates
  Map<String, ExchangeRate> get exchangeRates => Map.unmodifiable(_exchangeRates);

  /// Check if exchange rates are stale and need updating
  bool get needsRateUpdate {
    if (_exchangeRates.isEmpty) return true;
    
    final staleRates = _exchangeRates.values.where((rate) => rate.isStale);
    return staleRates.length > _exchangeRates.length * 0.5; // More than 50% stale
  }

  /// Get currency suggestions based on user location/preferences
  List<Currency> getCurrencySuggestions() {
    // Start with Kenya as primary market
    final suggestions = <Currency>[
      CurrencyData.getCurrency(SupportedCurrency.kes),
    ];

    // Add popular global currencies
    suggestions.addAll([
      CurrencyData.getCurrency(SupportedCurrency.usd),
      CurrencyData.getCurrency(SupportedCurrency.eur),
      CurrencyData.getCurrency(SupportedCurrency.gbp),
    ]);

    // Add regional African currencies
    suggestions.addAll([
      CurrencyData.getCurrency(SupportedCurrency.ugx),
      CurrencyData.getCurrency(SupportedCurrency.tzs),
      CurrencyData.getCurrency(SupportedCurrency.zar),
      CurrencyData.getCurrency(SupportedCurrency.ngn),
    ]);

    return suggestions;
  }

  /// Format amount for input fields (without currency symbol)
  String formatAmountForInput(double amount, {Currency? currency}) {
    final curr = currency ?? primaryCurrency;
    final formatter = NumberFormat.currency(
      locale: curr.locale,
      symbol: '',
      decimalDigits: curr.decimalPlaces,
    );
    
    return formatter.format(amount).trim();
  }

  /// Parse amount from string input
  double parseAmount(String input, {Currency? currency}) {
    final curr = currency ?? primaryCurrency;
    
    // Remove currency symbols and codes
    String cleanInput = input
        .replaceAll(curr.symbol, '')
        .replaceAll(curr.isoCode, '')
        .replaceAll(RegExp(r'[^\d.,]'), '')
        .trim();
    
    // Handle different decimal separators
    if (cleanInput.contains(',') && cleanInput.contains('.')) {
      // Assume comma is thousands separator and dot is decimal
      cleanInput = cleanInput.replaceAll(',', '');
    } else if (cleanInput.contains(',')) {
      // Could be decimal separator in some locales
      final parts = cleanInput.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        // Likely decimal separator
        cleanInput = cleanInput.replaceAll(',', '.');
      } else {
        // Likely thousands separator
        cleanInput = cleanInput.replaceAll(',', '');
      }
    }
    
    return double.tryParse(cleanInput) ?? 0.0;
  }

  /// Dispose of resources
  void dispose() {
    _preferencesController.close();
  }
}
