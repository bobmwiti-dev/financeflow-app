import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/currency_model.dart';
import '../services/currency_service.dart';

class CurrencySelector extends StatefulWidget {
  final Currency? selectedCurrency;
  final Function(Currency) onCurrencySelected;
  final bool showPopularFirst;
  final bool showRegionalCurrencies;
  final String? title;

  const CurrencySelector({
    super.key,
    this.selectedCurrency,
    required this.onCurrencySelected,
    this.showPopularFirst = true,
    this.showRegionalCurrencies = true,
    this.title,
  });

  @override
  State<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> {
  final TextEditingController _searchController = TextEditingController();
  List<Currency> _filteredCurrencies = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _updateFilteredCurrencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredCurrencies() {
    List<Currency> currencies;
    
    if (widget.showPopularFirst) {
      currencies = [
        ...CurrencyData.popularCurrencies,
        ...CurrencyData.allCurrencies.where(
          (c) => !CurrencyData.popularCurrencies.contains(c)
        ),
      ];
    } else {
      currencies = CurrencyData.allCurrencies;
    }

    if (_searchQuery.isNotEmpty) {
      currencies = currencies.where((currency) {
        final query = _searchQuery.toLowerCase();
        return currency.name.toLowerCase().contains(query) ||
               currency.isoCode.toLowerCase().contains(query) ||
               currency.region.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredCurrencies = currencies;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _updateFilteredCurrencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title ?? 'Select Currency',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search currencies...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[600]!),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Currency list
          Expanded(
            child: _filteredCurrencies.isEmpty
                ? _buildEmptyState()
                : _buildCurrencyList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No currencies found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredCurrencies.length,
      itemBuilder: (context, index) {
        final currency = _filteredCurrencies[index];
        final isSelected = widget.selectedCurrency?.code == currency.code;
        final isPopular = CurrencyData.popularCurrencies.contains(currency);
        final isAfrican = CurrencyData.africanCurrencies.contains(currency);
        
        return _buildCurrencyTile(currency, isSelected, isPopular, isAfrican, index);
      },
    );
  }

  Widget _buildCurrencyTile(Currency currency, bool isSelected, bool isPopular, bool isAfrican, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            widget.onCurrencySelected(currency);
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Flag and symbol
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: currency.code == SupportedCurrency.kes
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      currency.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Currency info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            currency.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.blue[700] : Colors.black,
                            ),
                          ),
                          if (currency.code == SupportedCurrency.kes) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (isPopular && currency.code != SupportedCurrency.kes) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (isAfrican && currency.code != SupportedCurrency.kes) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AFRICA',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${currency.symbol} • ${currency.isoCode}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.blue[600] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${currency.region}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Selection indicator
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 50))
      .slideX(begin: 0.2, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

class CurrencyDropdown extends StatelessWidget {
  final Currency selectedCurrency;
  final Function(Currency) onCurrencyChanged;
  final bool showFlag;
  final bool compact;

  const CurrencyDropdown({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    this.showFlag = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCurrencySelector(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showFlag) ...[
              Text(
                selectedCurrency.flag,
                style: TextStyle(fontSize: compact ? 16 : 20),
              ),
              SizedBox(width: compact ? 4 : 8),
            ],
            Text(
              compact ? selectedCurrency.isoCode : selectedCurrency.symbol,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(width: compact ? 2 : 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: compact ? 16 : 20,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencySelector(
        selectedCurrency: selectedCurrency,
        onCurrencySelected: onCurrencyChanged,
      ),
    );
  }
}

class CurrencyPreferencesScreen extends StatefulWidget {
  const CurrencyPreferencesScreen({super.key});

  @override
  State<CurrencyPreferencesScreen> createState() => _CurrencyPreferencesScreenState();
}

class _CurrencyPreferencesScreenState extends State<CurrencyPreferencesScreen> {
  final CurrencyService _currencyService = CurrencyService();
  late CurrencyPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = _currencyService.preferences;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Primary Currency
          _buildSection(
            'Primary Currency',
            'Your main currency for displaying amounts',
            [
              _buildCurrencyTile(
                'Primary Currency',
                CurrencyData.getCurrency(_preferences.primaryCurrency),
                () => _showCurrencySelector(true),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Secondary Currency
          _buildSection(
            'Secondary Currency',
            'Optional currency for conversion display',
            [
              _buildCurrencyTile(
                'Secondary Currency',
                _preferences.secondaryCurrency != null
                    ? CurrencyData.getCurrency(_preferences.secondaryCurrency!)
                    : null,
                () => _showCurrencySelector(false),
                optional: true,
              ),
              
              SwitchListTile(
                title: const Text('Enable Currency Conversion'),
                subtitle: const Text('Show amounts in both currencies'),
                value: _preferences.enableCurrencyConversion,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences.copyWith(enableCurrencyConversion: value);
                  });
                  _currencyService.updatePreferences(_preferences);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Display Format
          _buildSection(
            'Display Format',
            'How currency amounts are shown',
            [
              _buildFormatTile(CurrencyDisplayFormat.symbolBefore, 'KSh 1,000.00'),
              _buildFormatTile(CurrencyDisplayFormat.symbolAfter, '1,000.00 KSh'),
              _buildFormatTile(CurrencyDisplayFormat.codeBefore, 'KES 1,000.00'),
              _buildFormatTile(CurrencyDisplayFormat.codeAfter, '1,000.00 KES'),
              _buildFormatTile(CurrencyDisplayFormat.symbolAndCode, 'KSh 1,000.00 (KES)'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Display Options
          _buildSection(
            'Display Options',
            'Customize how currency information is shown',
            [
              SwitchListTile(
                title: const Text('Show Currency Symbol'),
                subtitle: const Text('Display symbol like KSh, \$, €'),
                value: _preferences.showCurrencySymbol,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences.copyWith(showCurrencySymbol: value);
                  });
                  _currencyService.updatePreferences(_preferences);
                },
              ),
              
              SwitchListTile(
                title: const Text('Show Currency Code'),
                subtitle: const Text('Display code like KES, USD, EUR'),
                value: _preferences.showCurrencyCode,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences.copyWith(showCurrencyCode: value);
                  });
                  _currencyService.updatePreferences(_preferences);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Preview
          _buildSection(
            'Preview',
            'See how amounts will be displayed',
            [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Amount: 1,500.00',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyService.formatAmount(1500.00),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (_preferences.enableCurrencyConversion && _preferences.secondaryCurrency != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _currencyService.formatAmountWithConversion(1500.00),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildCurrencyTile(String title, Currency? currency, VoidCallback onTap, {bool optional = false}) {
    return ListTile(
      title: Text(title),
      subtitle: currency != null
          ? Text('${currency.flag} ${currency.name} (${currency.isoCode})')
          : Text(optional ? 'None selected' : 'Select currency'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildFormatTile(CurrencyDisplayFormat format, String example) {
    return RadioListTile<CurrencyDisplayFormat>(
      title: Text(_getFormatName(format)),
      subtitle: Text(example),
      value: format,
      groupValue: _preferences.displayFormat,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _preferences = _preferences.copyWith(displayFormat: value);
          });
          _currencyService.updatePreferences(_preferences);
        }
      },
    );
  }

  String _getFormatName(CurrencyDisplayFormat format) {
    switch (format) {
      case CurrencyDisplayFormat.symbolBefore:
        return 'Symbol Before';
      case CurrencyDisplayFormat.symbolAfter:
        return 'Symbol After';
      case CurrencyDisplayFormat.codeBefore:
        return 'Code Before';
      case CurrencyDisplayFormat.codeAfter:
        return 'Code After';
      case CurrencyDisplayFormat.symbolAndCode:
        return 'Symbol and Code';
    }
  }

  void _showCurrencySelector(bool isPrimary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencySelector(
        selectedCurrency: isPrimary
            ? CurrencyData.getCurrency(_preferences.primaryCurrency)
            : (_preferences.secondaryCurrency != null
                ? CurrencyData.getCurrency(_preferences.secondaryCurrency!)
                : null),
        onCurrencySelected: (currency) {
          setState(() {
            if (isPrimary) {
              _preferences = _preferences.copyWith(primaryCurrency: currency.code);
            } else {
              _preferences = _preferences.copyWith(secondaryCurrency: currency.code);
            }
          });
          _currencyService.updatePreferences(_preferences);
        },
        title: isPrimary ? 'Select Primary Currency' : 'Select Secondary Currency',
      ),
    );
  }
}
