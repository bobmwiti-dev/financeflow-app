import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../services/spending_analytics_service.dart';
import '../../../../themes/app_theme.dart';
import 'animated_bar_chart.dart';

/// A widget that shows spending comparisons across different time periods
class ComparativeSpendingWidget extends StatefulWidget {
  final List<DateTimeRange> periods;
  final List<String> periodLabels;
  final String category;
  final String title;
  
  const ComparativeSpendingWidget({
    required this.periods,
    required this.periodLabels,
    this.category = 'All',
    this.title = 'Spending Comparison',
    super.key,
  });
  
  @override
  State<ComparativeSpendingWidget> createState() => _ComparativeSpendingWidgetState();
}

class _ComparativeSpendingWidgetState extends State<ComparativeSpendingWidget> {
  late Future<List<double>> _periodTotalsFuture;
  final SpendingAnalyticsService _service = SpendingAnalyticsService();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void didUpdateWidget(ComparativeSpendingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.periods != oldWidget.periods || widget.category != oldWidget.category) {
      _loadData();
    }
  }
  
  void _loadData() {
    final periodTotals = widget.periods.map((period) => 
      _service.getTotalSpending(period, category: widget.category)
    ).toList();
    
    _periodTotalsFuture = Future.wait(periodTotals);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate()
                  .fadeIn(duration: const Duration(milliseconds: 700))
                  .slideX(begin: -0.2, end: 0),
              ),
              if (widget.category != 'All')
                Chip(
                  label: Text(
                    widget.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppTheme.accentColor,
                  padding: const EdgeInsets.all(4),
                ).animate()
                  .fadeIn(duration: const Duration(milliseconds: 700))
                  .slideX(begin: 0.2, end: 0),
            ],
          ),
        ),
        FutureBuilder<List<double>>(
          future: _periodTotalsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  height: 200,
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            
            final data = snapshot.data!;
            return _buildComparisonChart(data);
          },
        ),
      ],
    );
  }
  
  Widget _buildComparisonChart(List<double> data) {
    // Use our animated bar chart for the visualization
    return AnimatedBarChart(
      data: data,
      labels: widget.periodLabels,
      barColor: AppTheme.accentColor,
    );
  }
}

/// A widget that compares spending across categories for different time periods
class CategoryComparisonWidget extends StatefulWidget {
  final List<DateTimeRange> periods;
  final List<String> periodLabels;
  final List<String> categories;
  final String title;
  
  const CategoryComparisonWidget({
    required this.periods,
    required this.periodLabels,
    this.categories = const [],
    this.title = 'Category Comparison',
    super.key,
  });
  
  @override
  State<CategoryComparisonWidget> createState() => _CategoryComparisonWidgetState();
}

class _CategoryComparisonWidgetState extends State<CategoryComparisonWidget> {
  late Future<Map<String, List<double>>> _dataFuture;
  final SpendingAnalyticsService _service = SpendingAnalyticsService();
  int _selectedCategoryIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void didUpdateWidget(CategoryComparisonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.periods != oldWidget.periods || widget.categories != oldWidget.categories) {
      _loadData();
    }
  }
  
  void _loadData() {
    _dataFuture = _service.getCategoryComparison(
      widget.periods,
      widget.categories,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate()
            .fadeIn(duration: const Duration(milliseconds: 500))
            .slideX(begin: -0.2, end: 0),
        ),
        FutureBuilder<Map<String, List<double>>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  height: 200,
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            
            final data = snapshot.data!;
            if (data.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No data available for comparison.'),
                ),
              );
            }
            
            final categories = data.keys.toList();
            
            return Column(
              children: [
                // Category selector
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedCategoryIndex;
                      final category = categories[index];
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AnimatedScale(
                              scale: isSelected ? 1.08 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategoryIndex = index;
                                    });
                                  }
                                },
                                backgroundColor: Colors.grey.withValues(alpha: 50),
                                selectedColor: AppTheme.accentColor,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).animate(delay: Duration(milliseconds: 60 * index))
                        .fadeIn(duration: const Duration(milliseconds: 400))
                        .slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Bar chart for the selected category
                AnimatedBarChart(
                  data: data[categories[_selectedCategoryIndex]]!,
                  labels: widget.periodLabels,
                  title: categories[_selectedCategoryIndex],
                  barColor: _getCategoryColor(categories[_selectedCategoryIndex]),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'bills':
        return Colors.red;
      default:
        return AppTheme.accentColor;
    }
  }
}
