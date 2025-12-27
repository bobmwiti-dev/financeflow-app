import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_extensions.dart';

class FilterOptions {
  final DateTimeRange? dateRange;
  final List<String> selectedCategories;
  final double? minAmount;
  final double? maxAmount;
  final bool showOnlyHighSpending;
  
  const FilterOptions({
    this.dateRange,
    this.selectedCategories = const [],
    this.minAmount,
    this.maxAmount,
    this.showOnlyHighSpending = false,
  });
  
  FilterOptions copyWith({
    DateTimeRange? dateRange,
    List<String>? selectedCategories,
    double? minAmount,
    double? maxAmount,
    bool? showOnlyHighSpending,
  }) {
    return FilterOptions(
      dateRange: dateRange ?? this.dateRange,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      showOnlyHighSpending: showOnlyHighSpending ?? this.showOnlyHighSpending,
    );
  }
}

class EnhancedFilterDialog extends StatefulWidget {
  final FilterOptions initialFilters;
  final List<String> availableCategories;
  
  const EnhancedFilterDialog({
    super.key,
    required this.initialFilters,
    required this.availableCategories,
  });

  @override
  State<EnhancedFilterDialog> createState() => _EnhancedFilterDialogState();
}

class _EnhancedFilterDialogState extends State<EnhancedFilterDialog> {
  late FilterOptions _filters;
  late double _minAmount;
  late double _maxAmount;
  final double _absoluteMinAmount = 0;
  final double _absoluteMaxAmount = 1000; // This could be dynamically set based on data
  
  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _minAmount = _filters.minAmount ?? _absoluteMinAmount;
    _maxAmount = _filters.maxAmount ?? _absoluteMaxAmount;
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDateRangeSection(),
              const Divider(height: 32),
              _buildCategoriesSection(),
              const Divider(height: 32),
              _buildAmountRangeSection(),
              const Divider(height: 32),
              _buildAdditionalOptionsSection(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_filters),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDateRangeSection() {
    final dateRange = _filters.dateRange;
    String displayText = dateRange == null
        ? 'All time'
        : '${DateFormat('MMM d, y').format(dateRange.start)} - ${DateFormat('MMM d, y').format(dateRange.end)}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayText,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                if (dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _filters = _filters.copyWith(dateRange: null);
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDateOption('Last 7 days', 7),
            _buildQuickDateOption('Last 30 days', 30),
            _buildQuickDateOption('Last 3 months', 90),
          ],
        ),
      ],
    );
  }
  
  Widget _buildQuickDateOption(String label, int days) {
    return TextButton(
      onPressed: () => _selectQuickDateRange(days),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
        ),
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
  
  void _selectQuickDateRange(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    
    setState(() {
      _filters = _filters.copyWith(
        dateRange: DateTimeRange(start: start, end: end),
      );
    });
  }
  
  Future<void> _selectDateRange() async {
    final initialDateRange = _filters.dateRange ?? 
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );
    
    final dateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (dateRange != null) {
      setState(() {
        _filters = _filters.copyWith(dateRange: dateRange);
      });
    }
  }
  
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_filters.selectedCategories.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _filters = _filters.copyWith(selectedCategories: []);
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableCategories.map((category) {
            final isSelected = _filters.selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  List<String> newCategories = [..._filters.selectedCategories];
                  if (selected) {
                    newCategories.add(category);
                  } else {
                    newCategories.remove(category);
                  }
                  _filters = _filters.copyWith(selectedCategories: newCategories);
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected 
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildAmountRangeSection() {
    // Using CurrencyService via toCurrency() extension
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              _absoluteMinAmount.toCurrency(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Text(
              _absoluteMaxAmount.toCurrency(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RangeSlider(
          values: RangeValues(_minAmount, _maxAmount),
          min: _absoluteMinAmount,
          max: _absoluteMaxAmount,
          divisions: 20,
          labels: RangeLabels(
            _minAmount.toCurrency(),
            _maxAmount.toCurrency(),
          ),
          onChanged: (values) {
            setState(() {
              _minAmount = values.start;
              _maxAmount = values.end;
            });
          },
          onChangeEnd: (values) {
            setState(() {
              _filters = _filters.copyWith(
                minAmount: values.start,
                maxAmount: values.end,
              );
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min: ${_minAmount.toCurrency()}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Max: ${_maxAmount.toCurrency()}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAdditionalOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Show only high-spending days'),
          subtitle: const Text('Days above 75% of your average'),
          contentPadding: EdgeInsets.zero,
          value: _filters.showOnlyHighSpending,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(showOnlyHighSpending: value);
            });
          },
        ),
      ],
    );
  }
  
  void _resetFilters() {
    setState(() {
      _filters = const FilterOptions();
      _minAmount = _absoluteMinAmount;
      _maxAmount = _absoluteMaxAmount;
    });
  }
}

class EnhancedFilterButton extends StatelessWidget {
  final FilterOptions currentFilters;
  final List<String> availableCategories;
  final Function(FilterOptions) onFiltersChanged;
  
  const EnhancedFilterButton({
    super.key,
    required this.currentFilters,
    required this.availableCategories,
    required this.onFiltersChanged,
  });
  
  bool get hasActiveFilters => 
    currentFilters.dateRange != null ||
    currentFilters.selectedCategories.isNotEmpty ||
    currentFilters.minAmount != null ||
    currentFilters.maxAmount != null ||
    currentFilters.showOnlyHighSpending;
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: hasActiveFilters 
              ? Theme.of(context).primaryColor 
              : Colors.grey.shade300,
          width: hasActiveFilters ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showFilterDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list,
                size: 20,
                color: hasActiveFilters 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                hasActiveFilters ? 'Filters (${_getActiveFilterCount()})' : 'Filter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasActiveFilters ? FontWeight.bold : FontWeight.normal,
                  color: hasActiveFilters 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  int _getActiveFilterCount() {
    int count = 0;
    if (currentFilters.dateRange != null) count++;
    if (currentFilters.selectedCategories.isNotEmpty) count++;
    if (currentFilters.minAmount != null || currentFilters.maxAmount != null) count++;
    if (currentFilters.showOnlyHighSpending) count++;
    return count;
  }
  
  Future<void> _showFilterDialog(BuildContext context) async {
    final result = await showDialog<FilterOptions>(
      context: context,
      builder: (context) => EnhancedFilterDialog(
        initialFilters: currentFilters,
        availableCategories: availableCategories,
      ),
    );
    
    if (result != null) {
      onFiltersChanged(result);
    }
  }
}
