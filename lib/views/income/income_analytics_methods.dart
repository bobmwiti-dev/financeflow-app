import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../themes/app_theme.dart';

// Additional methods for income screen analytics
class IncomeAnalyticsMethods {
  
  // Templates Bottom Sheet continuation
  static Widget buildTemplateItem(Map<String, dynamic> template, Function(String) getIncomeTypeColor, Function(String) getIncomeTypeIcon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: getIncomeTypeColor(template['type']).withAlpha(51),
          child: FaIcon(
            getIncomeTypeIcon(template['type']),
            color: getIncomeTypeColor(template['type']),
            size: 20,
          ),
        ),
        title: Text(template['name']),
        subtitle: Text('${template['type']} • ${template['frequency']}'),
        trailing: Icon(
          template['isRecurring'] ? Icons.repeat : Icons.event_available,
          color: Colors.grey.shade600,
        ),
        onTap: onTap,
      ),
    );
  }

  // Advanced Filters Bottom Sheet
  static Widget buildAdvancedFiltersSheet(
    BuildContext context,
    DateTimeRange? selectedDateRange,
    RangeValues? selectedAmountRange,
    Function(DateTimeRange?) onDateRangeChanged,
    Function(RangeValues?) onAmountRangeChanged,
    VoidCallback onClearFilters,
    VoidCallback onApplyFilters,
  ) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Advanced Filters',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Filter
                  Text(
                    'Date Range',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.date_range),
                      title: Text(
                        selectedDateRange != null
                            ? '${DateFormat('MMM dd, yyyy').format(selectedDateRange.start)} - ${DateFormat('MMM dd, yyyy').format(selectedDateRange.end)}'
                            : 'Select date range',
                      ),
                      trailing: selectedDateRange != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => onDateRangeChanged(null),
                            )
                          : const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: selectedDateRange,
                        );
                        if (range != null) {
                          onDateRangeChanged(range);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Amount Range Filter
                  Text(
                    'Amount Range',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                '\$${selectedAmountRange?.start.round() ?? 0}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                '\$${selectedAmountRange?.end.round() ?? 10000}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: selectedAmountRange ?? const RangeValues(0, 10000),
                            min: 0,
                            max: 10000,
                            divisions: 100,
                            activeColor: AppTheme.incomeColor,
                            onChanged: onAmountRangeChanged,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onClearFilters,
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onApplyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.incomeColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Income Reminders Bottom Sheet
  static Widget buildRemindersSheet(BuildContext context) {
    final upcomingReminders = [
      {'name': 'Monthly Salary', 'amount': 5000.0, 'dueDate': DateTime.now().add(const Duration(days: 3))},
      {'name': 'Freelance Payment', 'amount': 1500.0, 'dueDate': DateTime.now().add(const Duration(days: 7))},
      {'name': 'Rental Income', 'amount': 2000.0, 'dueDate': DateTime.now().add(const Duration(days: 15))},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Income Reminders',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // Add new reminder functionality
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: upcomingReminders.length,
              itemBuilder: (context, index) {
                final reminder = upcomingReminders[index];
                final daysUntil = (reminder['dueDate'] as DateTime).difference(DateTime.now()).inDays;
                final currencyFormat = NumberFormat.currency(symbol: '\$');
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.incomeColor.withAlpha(51),
                      child: Icon(
                        Icons.schedule,
                        color: AppTheme.incomeColor,
                      ),
                    ),
                    title: Text(reminder['name'] as String),
                    subtitle: Text(
                      'Due in $daysUntil days • ${DateFormat('MMM dd').format(reminder['dueDate'] as DateTime)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(reminder['amount']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.incomeColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: daysUntil <= 3 ? Colors.orange : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            daysUntil <= 3 ? 'Soon' : 'Upcoming',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Handle reminder tap
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Auto-categorization suggestions
  static String suggestCategory(String sourceName) {
    final name = sourceName.toLowerCase();
    
    if (name.contains('salary') || name.contains('wage') || name.contains('payroll')) {
      return 'Salary';
    } else if (name.contains('freelance') || name.contains('contract') || name.contains('gig')) {
      return 'Side Hustle';
    } else if (name.contains('business') || name.contains('company') || name.contains('llc')) {
      return 'Business';
    } else if (name.contains('investment') || name.contains('stock') || name.contains('bond')) {
      return 'Investment';
    } else if (name.contains('dividend') || name.contains('distribution')) {
      return 'Dividend';
    } else if (name.contains('gift') || name.contains('present')) {
      return 'Gift';
    } else if (name.contains('loan') || name.contains('lending')) {
      return 'Loan';
    } else if (name.contains('grant') || name.contains('scholarship')) {
      return 'Grant';
    } else if (name.contains('family') || name.contains('parent') || name.contains('relative')) {
      return 'Family Contribution';
    }
    
    return 'Other';
  }

  // Dark mode color adjustments
  static Color getDarkModeColor(Color lightColor, bool isDarkMode) {
    if (!isDarkMode) return lightColor;
    
    // Adjust colors for dark mode
    final hsl = HSLColor.fromColor(lightColor);
    return hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0)).toColor();
  }

  // Performance optimization helpers
  static Widget buildLazyLoadedList<T>({
    required List<T> items,
    required Widget Function(T item, int index) itemBuilder,
    required ScrollController scrollController,
    int itemsPerPage = 20,
  }) {
    return ListView.builder(
      controller: scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(items[index], index);
      },
    );
  }
}
