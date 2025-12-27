import 'package:flutter/material.dart';

import '../../../themes/app_theme.dart';

class ExpenseFilter extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final List<String> categories;

  const ExpenseFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildFilterChip('All'),
          ...categories.map((category) => _buildFilterChip(category)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = selectedFilter == filter;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(filter),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            onFilterChanged(filter);
          } else {
            onFilterChanged('All');
          }
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
