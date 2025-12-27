import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../themes/app_theme.dart';
import '../../../models/family_budget_model.dart';

class FamilySpendingTrends extends StatefulWidget {
  const FamilySpendingTrends({super.key});

  @override
  State<FamilySpendingTrends> createState() => _FamilySpendingTrendsState();
}

class _FamilySpendingTrendsState extends State<FamilySpendingTrends> {
  String _selectedPeriod = 'Month';
  int _selectedCategoryIndex = -1;
  
  final List<String> _periods = ['Week', 'Month', 'Quarter', 'Year'];
  
  // Sample data for the chart
  final List<Map<String, dynamic>> _monthlyData = [
    {'day': 1, 'amount': 120},
    {'day': 2, 'amount': 90},
    {'day': 3, 'amount': 75},
    {'day': 4, 'amount': 110},
    {'day': 5, 'amount': 230},
    {'day': 6, 'amount': 160},
    {'day': 7, 'amount': 70},
    {'day': 8, 'amount': 95},
    {'day': 9, 'amount': 105},
    {'day': 10, 'amount': 190},
    {'day': 11, 'amount': 120},
    {'day': 12, 'amount': 85},
    {'day': 13, 'amount': 75},
    {'day': 14, 'amount': 140},
    {'day': 15, 'amount': 200},
    {'day': 16, 'amount': 135},
    {'day': 17, 'amount': 155},
    {'day': 18, 'amount': 90},
    {'day': 19, 'amount': 120},
    {'day': 20, 'amount': 130},
    {'day': 21, 'amount': 110},
    {'day': 22, 'amount': 75},
    {'day': 23, 'amount': 80},
    {'day': 24, 'amount': 95},
    {'day': 25, 'amount': 145},
    {'day': 26, 'amount': 180},
    {'day': 27, 'amount': 130},
    {'day': 28, 'amount': 95},
    {'day': 29, 'amount': 110},
    {'day': 30, 'amount': 150},
  ];

  @override
  Widget build(BuildContext context) {
    // In a real app, this would come from the ViewModel
    final categories = FamilyBudgetSampleData.getSampleData().categories;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildPeriodSelector(),
          const SizedBox(height: 24),
          _buildSpendingChart(),
          const SizedBox(height: 24),
          _buildInsightsSection(),
          const SizedBox(height: 24),
          _buildCategorySelector(categories),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 4),
            Text(
              'April 2025',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                  ),
            ).animate()
              .fadeIn(
                  duration: const Duration(milliseconds: 400),
                  delay: const Duration(milliseconds: 100))
              .slideX(begin: -0.1, end: 0),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
          color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 400))
          .slideX(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 200))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildSpendingChart() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value % 5 != 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 50,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(
                      '\$${value.toInt()}',
                      style: TextStyle(
                        color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          minX: 1,
          maxX: 30,
          minY: 0,
          maxY: 250,
          lineBarsData: [
            LineChartBarData(
              spots: _monthlyData
                  .map((data) => FlSpot(data['day'].toDouble(), data['amount'].toDouble()))
                  .toList(),
              isCurved: true,
              color: AppTheme.accentColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.accentColor.withAlpha(26),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.white,
              tooltipRoundedRadius: 8,
              tooltipBorder: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final day = barSpot.x.toInt();
                  final amount = barSpot.y;
                  return LineTooltipItem(
                    'Day $day\n',
                    const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '\$${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 300))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          icon: Icons.trending_up,
          title: 'Spending Increase',
          description: 'Your spending is 15% higher than last month',
          color: AppTheme.warningColor,
          delay: 0,
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.calendar_today,
          title: 'Highest Spending Day',
          description: 'April 5th had the highest spending (\$230)',
          color: AppTheme.infoColor,
          delay: 100,
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.category,
          title: 'Top Spending Category',
          description: 'Housing accounts for 35% of your spending',
          color: AppTheme.accentColor,
          delay: 200,
        ),
      ],
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 400))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 500 + delay))
      .slideX(begin: 0.05, end: 0);
  }

  Widget _buildCategorySelector(List<BudgetCategory> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip(
                'All',
                AppTheme.accentColor,
                -1,
                Icons.all_inclusive,
              ),
              ...List.generate(
                categories.length,
                (index) => _buildCategoryChip(
                  categories[index].name,
                  categories[index].color,
                  index,
                  categories[index].icon,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 500))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildCategoryChip(String label, Color color, int index, IconData icon) {
    final isSelected = index == _selectedCategoryIndex;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha((255 * 0.1).round()),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 600 + (index + 1) * 50))
      .slideX(begin: 0.05, end: 0);
  }
}
