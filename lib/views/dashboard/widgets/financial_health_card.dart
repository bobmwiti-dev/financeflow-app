import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../themes/app_theme.dart';

class FinancialHealthCard extends StatefulWidget {
  final double income;
  final double expenses;
  final double? previousIncome;
  final double? previousExpenses;

  const FinancialHealthCard({
    super.key,
    required this.income,
    required this.expenses,
    this.previousIncome,
    this.previousExpenses,
  });

  @override
  State<FinancialHealthCard> createState() => _FinancialHealthCardState();
}

class _FinancialHealthCardState extends State<FinancialHealthCard> {
  int _touchedIndex = -1;

  // Calculates the financial health score out of 100
  int _calculateHealthScore(double income, double expenses) {
    if (income <= 0) return 0;
    double savingsRate = (income - expenses) / income;
    // A savings rate of 20% or more is considered healthy (100 score).
    // A savings rate of 0% is average (50 score).
    // A negative savings rate will bring the score down, clamping at 0.
    return (savingsRate * 250 + 50).clamp(0.0, 100.0).toInt();
  }

  String _getHealthStatus(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Average';
    return 'Needs Improvement';
  }

  Color _getHealthColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getEmergencyFundStatus(double savings, double monthlyExpenses) {
    if (monthlyExpenses <= 0) return 'No data';
    final months = savings / monthlyExpenses;
    if (months >= 6) return 'Excellent (${months.toStringAsFixed(1)} months)';
    if (months >= 3) return 'Good (${months.toStringAsFixed(1)} months)';
    if (months >= 1) return 'Fair (${months.toStringAsFixed(1)} months)';
    return 'Low (${months.toStringAsFixed(1)} months)';
  }

  Widget _getTrendIndicator(double current, double? previous) {
    if (previous == null || previous == 0) return const SizedBox.shrink();
    
    final change = ((current - previous) / previous) * 100;
    final isPositive = change > 0;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final color = isPositive ? Colors.green : Colors.red;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '${change.abs().toStringAsFixed(1)}%',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // Validate input data to prevent chart errors
    final validIncome = widget.income.isFinite ? max(0.0, widget.income) : 0.0;
    final validExpenses = widget.expenses.isFinite ? max(0.0, widget.expenses) : 0.0;
    
    final score = _calculateHealthScore(validIncome, validExpenses);
    final healthStatus = _getHealthStatus(score);
    final healthColor = _getHealthColor(score);
    final savings = validIncome - validExpenses;
    final rawSavingsRate = validIncome > 0 ? (savings / validIncome) * 100 : 0.0;
    final savingsRate = rawSavingsRate.isFinite ? rawSavingsRate.clamp(-100.0, 100.0) : 0.0;
    final rawExpenseRatio = validIncome > 0 ? (validExpenses / validIncome) * 100 : 0.0;
    final expenseRatio = rawExpenseRatio.isFinite ? rawExpenseRatio.clamp(0.0, 200.0) : 0.0;
    final emergencyFundStatus = _getEmergencyFundStatus(max(0.0, savings), validExpenses);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withValues(alpha:0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, score, healthStatus, healthColor),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildDonutChart(theme, savings),
                  const SizedBox(width: 20),
                  _buildMetrics(theme, score, healthStatus, savingsRate, expenseRatio, currencyFormat, savings, emergencyFundStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, int score, String healthStatus, Color healthColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Health',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: healthColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    healthStatus,
                    style: TextStyle(
                      color: healthColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _getTrendIndicator(widget.income - widget.expenses, 
                    widget.previousIncome != null && widget.previousExpenses != null 
                        ? widget.previousIncome! - widget.previousExpenses! 
                        : null),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: healthColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$score',
            style: TextStyle(
              color: healthColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChart(ThemeData theme, double savings) {
    return Expanded(
      flex: 2,
      child: AspectRatio(
        aspectRatio: 1,
        child: PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: _buildChartSections(theme, savings),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(ThemeData theme, double savings) {
    final isTouchedSavings = _touchedIndex == 0;
    final isTouchedExpenses = _touchedIndex == 1;
    
    // Ensure all values are valid and positive
    final double savingsValue = max(0.0, savings).isFinite ? max(0.0, savings) : 0.0;
    final double expensesValue = widget.expenses.isFinite ? max(0.0, widget.expenses) : 0.0;
    final double totalValue = savingsValue + expensesValue;
    
    // If no data, show placeholder sections
    if (totalValue <= 0 || widget.income <= 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.withValues(alpha: 0.3),
          value: 1.0,
          title: 'No Data',
          radius: 50.0,
          titleStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ];
    }

    // Calculate safe percentages
    final savingsPercent = (savingsValue / widget.income * 100).isFinite 
        ? (savingsValue / widget.income * 100).clamp(0.0, 100.0) 
        : 0.0;
    final expensesPercent = (expensesValue / widget.income * 100).isFinite 
        ? (expensesValue / widget.income * 100).clamp(0.0, 100.0) 
        : 0.0;

    return [
      PieChartSectionData(
        color: AppTheme.primaryColor,
        value: savingsValue,
        title: '${savingsPercent.toStringAsFixed(0)}%',
        radius: isTouchedSavings ? 60.0 : 50.0,
        titleStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: AppTheme.accentColor,
        value: expensesValue,
        title: '${expensesPercent.toStringAsFixed(0)}%',
        radius: isTouchedExpenses ? 60.0 : 50.0,
        titleStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  Widget _buildMetrics(ThemeData theme, int score, String healthStatus, double savingsRate, double expenseRatio, NumberFormat currencyFormat, double savings, String emergencyFundStatus) {
    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMetricCard(
            icon: Icons.savings,
            title: 'Savings Rate',
            value: '${savingsRate.toStringAsFixed(1)}%',
            trend: _getTrendIndicator(savingsRate, widget.previousIncome != null && widget.previousExpenses != null 
                ? ((widget.previousIncome! - widget.previousExpenses!) / widget.previousIncome!) * 100 
                : null),
            color: savingsRate >= 20 ? Colors.green : savingsRate >= 10 ? Colors.orange : Colors.red,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            icon: Icons.pie_chart,
            title: 'Expense Ratio',
            value: '${expenseRatio.toStringAsFixed(1)}%',
            trend: _getTrendIndicator(expenseRatio, widget.previousIncome != null && widget.previousExpenses != null 
                ? (widget.previousExpenses! / widget.previousIncome!) * 100 
                : null),
            color: expenseRatio <= 50 ? Colors.green : expenseRatio <= 80 ? Colors.orange : Colors.red,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            icon: Icons.security,
            title: 'Emergency Fund',
            value: emergencyFundStatus,
            color: savings >= (widget.expenses * 6) ? Colors.green : 
                   savings >= (widget.expenses * 3) ? Colors.orange : Colors.red,
            isCompact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    Widget? trend,
    bool isCompact = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (trend != null) trend,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 11 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: isCompact ? 2 : 1,
          ),
        ],
      ),
    );
  }


}
