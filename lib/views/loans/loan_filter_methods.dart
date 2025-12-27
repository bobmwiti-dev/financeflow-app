import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../themes/app_theme.dart';

mixin LoanFilterMethods<T extends StatefulWidget> on State<T> {
  void showAdvancedFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              buildAdvancedFiltersHeader(),
              Expanded(
                child: buildAdvancedFiltersContent(scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAdvancedFiltersHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Advanced Filters',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: clearAdvancedFilters,
                child: const Text('Clear All'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: applyAdvancedFilters,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAdvancedFiltersContent(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildAmountRangeFilter(),
          const SizedBox(height: 24),
          buildDateRangeFilter(),
          const SizedBox(height: 24),
          buildInterestRateFilter(),
          const SizedBox(height: 24),
          buildLenderFilter(),
          const SizedBox(height: 24),
          buildPaymentFrequencyFilter(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget buildAmountRangeFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Amount Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: getSelectedAmountRange() ?? const RangeValues(0, 500000),
              min: 0,
              max: 500000,
              divisions: 50,
              labels: RangeLabels(
                NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                    .format(getSelectedAmountRange()?.start ?? 0),
                NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                    .format(getSelectedAmountRange()?.end ?? 500000),
              ),
              onChanged: setSelectedAmountRange,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(getSelectedAmountRange()?.start ?? 0),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(getSelectedAmountRange()?.end ?? 500000),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDateRangeFilter() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final selectedRange = getSelectedDateRange();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Start Date Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: selectedRange,
                );
                if (picked != null) {
                  setSelectedDateRange(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range),
                    const SizedBox(width: 8),
                    Text(
                      selectedRange != null
                          ? '${dateFormat.format(selectedRange.start)} - ${dateFormat.format(selectedRange.end)}'
                          : 'Select date range',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInterestRateFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interest Rate Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: getSelectedInterestRange() ?? const RangeValues(0, 20),
              min: 0,
              max: 20,
              divisions: 40,
              labels: RangeLabels(
                '${getSelectedInterestRange()?.start.toStringAsFixed(1) ?? 0}%',
                '${getSelectedInterestRange()?.end.toStringAsFixed(1) ?? 20}%',
              ),
              onChanged: setSelectedInterestRange,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${getSelectedInterestRange()?.start.toStringAsFixed(1) ?? 0}%',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  '${getSelectedInterestRange()?.end.toStringAsFixed(1) ?? 20}%',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLenderFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lender',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: getAvailableLenders().map((lender) {
                final isSelected = getSelectedLenders().contains(lender);
                return FilterChip(
                  label: Text(lender),
                  selected: isSelected,
                  onSelected: (selected) => toggleLenderFilter(lender),
                  selectedColor: AppTheme.primaryColor.withAlpha(51),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentFrequencyFilter() {
    final frequencies = ['Weekly', 'Bi-weekly', 'Monthly', 'Quarterly'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Frequency',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: frequencies.map((frequency) {
                final isSelected = getSelectedFrequencies().contains(frequency);
                return FilterChip(
                  label: Text(frequency),
                  selected: isSelected,
                  onSelected: (selected) => toggleFrequencyFilter(frequency),
                  selectedColor: AppTheme.primaryColor.withAlpha(51),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Abstract methods that implementing classes must provide
  RangeValues? getSelectedAmountRange();
  void setSelectedAmountRange(RangeValues range);
  
  DateTimeRange? getSelectedDateRange();
  void setSelectedDateRange(DateTimeRange range);
  
  RangeValues? getSelectedInterestRange();
  void setSelectedInterestRange(RangeValues range);
  
  List<String> getAvailableLenders();
  List<String> getSelectedLenders();
  void toggleLenderFilter(String lender);
  
  List<String> getSelectedFrequencies();
  void toggleFrequencyFilter(String frequency);
  
  void clearAdvancedFilters();
  void applyAdvancedFilters();
}
