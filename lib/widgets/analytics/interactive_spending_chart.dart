import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_extensions.dart';

import '../../models/insight_model.dart';

class InteractiveSpendingChart extends StatefulWidget {
  final List<SpendingPatternInsight> insights;
  final String title;
  final Function(SpendingPatternInsight)? onInsightTap;
  
  const InteractiveSpendingChart({
    super.key,
    required this.insights,
    required this.title,
    this.onInsightTap,
  });

  @override
  State<InteractiveSpendingChart> createState() => _InteractiveSpendingChartState();
}

class _InteractiveSpendingChartState extends State<InteractiveSpendingChart> {
  int touchedIndex = -1;
  bool _showDetails = false;
  SpendingPatternInsight? _selectedInsight;
  
  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty) {
      return _buildEmptyState();
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showDetails ? Icons.bar_chart : Icons.pie_chart,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                  tooltip: _showDetails ? 'Show Chart' : 'Show Details',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_showDetails) ...[
              SizedBox(
                height: 220,
                child: _buildChart(),
              ),
            ] else ...[
              _buildDetailsList(),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300)).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No spending data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your expenses to see insights here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Stack(
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    touchedIndex = -1;
                    _selectedInsight = null;
                    return;
                  }
                  
                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  if (touchedIndex >= 0 && touchedIndex < widget.insights.length) {
                    _selectedInsight = widget.insights[touchedIndex];
                    
                    if (widget.onInsightTap != null && _selectedInsight != null) {
                      widget.onInsightTap!(_selectedInsight!);
                    }
                  }
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: _generateSections(),
          ),
        ),
        if (_selectedInsight != null)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedInsight!.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedInsight!.currentAmount.toCurrency(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(
                      widget.insights.fold(0.0, (sum, item) => sum + item.currentAmount),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<PieChartSectionData> _generateSections() {
    return List.generate(widget.insights.length, (i) {
      final insight = widget.insights[i];
      final isTouched = i == touchedIndex;
      final double fontSize = isTouched ? 20 : 16;
      final double radius = isTouched ? 90 : 80;
      
      // Generate a consistent color based on the category name
      final color = _getCategoryColor(insight.category);
      
      return PieChartSectionData(
        color: color,
        value: insight.currentAmount,
        title: '${(insight.currentAmount / widget.insights.fold(0.0, (sum, item) => sum + item.currentAmount) * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        badgeWidget: _getBadgeWidget(insight, isTouched),
        badgePositionPercentageOffset: 1.1,
      );
    });
  }
  
  Widget? _getBadgeWidget(SpendingPatternInsight insight, bool isTouched) {
    if (!isTouched) return null;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(insight.category).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        insight.category,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    // Generate a color based on the category name
    final List<Color> categoryColors = [
      Colors.blue.shade400,
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.amber.shade400,
      Colors.cyan.shade400,
      Colors.deepPurple.shade400,
      Colors.lime.shade400,
    ];
    
    // Use the hash code of the category to pick a color
    final index = category.hashCode % categoryColors.length;
    return categoryColors[index.abs()];
  }

  Widget _buildDetailsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...widget.insights.asMap().entries.map((entry) {
          final i = entry.key;
          final insight = entry.value;
          final isSelected = _selectedInsight == insight;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? _getCategoryColor(insight.category).withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _getCategoryColor(insight.category) : Colors.grey.shade200,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedInsight = isSelected ? null : insight;
                  touchedIndex = isSelected ? -1 : i;
                });
                
                if (widget.onInsightTap != null && !isSelected) {
                  widget.onInsightTap!(insight);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(insight.category),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Text(
                            insight.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: '\$').format(insight.currentAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${insight.percentageChange >= 0 ? '+' : ''}${insight.percentageChange.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: insight.percentageChange >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate()
            .fadeIn(delay: Duration(milliseconds: 50 * i))
            .slideX(begin: 0.2, end: 0);
        }),
      ],
    );
  }
}
