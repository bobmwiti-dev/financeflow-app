import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../themes/app_theme.dart';

class FamilyBudgetChart extends StatelessWidget {
  const FamilyBudgetChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Budget Allocation',
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
                    .fadeIn(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 100))
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
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: 35,
                    title: '35%',
                    color: const Color(0xFF4C51BF),
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 25,
                    title: '25%',
                    color: const Color(0xFF48BB78),
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: '20%',
                    color: const Color(0xFFED8936),
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 15,
                    title: '15%',
                    color: const Color(0xFF38B2AC),
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 5,
                    title: '5%',
                    color: const Color(0xFFE53E3E),
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ).animate()
            .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200))
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildLegendItem('Housing', const Color(0xFF4C51BF), 0),
              _buildLegendItem('Food', const Color(0xFF48BB78), 100),
              _buildLegendItem('Transport', const Color(0xFFED8936), 200),
              _buildLegendItem('Utilities', const Color(0xFF38B2AC), 300),
              _buildLegendItem('Other', const Color(0xFFE53E3E), 400),
            ],
          ),
          const SizedBox(height: 16),
          _buildBudgetSummary(context),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int delayMs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF4A5568),
          ),
        ),
      ],
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 400), delay: Duration(milliseconds: 400 + delayMs))
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildBudgetSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Budget', '\$4,500', AppTheme.accentColor),
              _buildSummaryItem('Spent', '\$2,850', AppTheme.expenseColor),
              _buildSummaryItem('Remaining', '\$1,650', AppTheme.incomeColor),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 600))
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
