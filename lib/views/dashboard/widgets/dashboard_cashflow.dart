import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../widgets/animated_financial_chart.dart';

/// Dashboard cash flow widget showing income vs expenses and category breakdown
class DashboardCashflow extends StatelessWidget {
  final double income;
  final double expenses;
  final Map<String, double> categories;

  const DashboardCashflow({
    super.key,
    required this.income,
    required this.expenses,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // Prepare chart data
    final cashFlowData = [
      {'label': 'Income', 'amount': income, 'color': Colors.green},
      {'label': 'Expenses', 'amount': expenses, 'color': Colors.red},
    ];
    
    // Sort categories by amount (descending)
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Prepare category data for pie chart
    final categoryData = sortedCategories.map((entry) => {
      'label': entry.key,
      'amount': entry.value,
      'color': _getCategoryColor(entry.key),
    }).toList();
    
    return Column(
      children: [
        // Income vs Expenses Chart
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1 * 255),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income vs Expenses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: AnimatedFinancialChart(
                    data: cashFlowData,
                    type: ChartType.bar,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildChartLegendItem(
                      color: Colors.green,
                      label: 'Income',
                      amount: currencyFormat.format(income),
                    ),
                    _buildChartLegendItem(
                      color: Colors.red,
                      label: 'Expenses',
                      amount: currencyFormat.format(expenses),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Category Spending Chart
        if (categories.isNotEmpty) Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1 * 255),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spending by Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/spending_analysis');
                      },
                      child: Text('Details'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: AnimatedFinancialChart(
                    data: categoryData,
                    type: ChartType.pie,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: sortedCategories.take(5).map((entry) {
                    final percentage = expenses > 0 
                        ? (entry.value / expenses * 100) 
                        : 0.0;
                    
                    return _buildCategoryLegendItem(
                      category: entry.key,
                      color: _getCategoryColor(entry.key),
                      amount: currencyFormat.format(entry.value),
                      percentage: percentage,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build a legend item for the chart
  Widget _buildChartLegendItem({
    required Color color, 
    required String label, 
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  /// Build a category legend item
  Widget _buildCategoryLegendItem({
    required String category,
    required Color color,
    required String amount,
    required double percentage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Stack(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  /// Get color for category
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Colors.orange;
      case 'transport':
      case 'transportation':
      case 'travel':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'utilities':
      case 'bills':
        return Colors.teal;
      case 'housing':
      case 'rent':
      case 'mortgage':
        return Colors.brown;
      case 'entertainment':
        return Colors.deepPurple;
      case 'health':
      case 'medical':
        return Colors.red;
      case 'education':
        return Colors.indigo;
      case 'salary':
      case 'income':
      case 'wage':
        return Colors.green;
      case 'investment':
        return Colors.lightBlue;
      case 'gift':
        return Colors.pink;
      default:
        return Colors.blueGrey;
    }
  }
}
