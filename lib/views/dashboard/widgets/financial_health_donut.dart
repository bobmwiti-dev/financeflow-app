import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Displays a donut chart comparing this month's income vs expenses
/// and shows the net cash-flow in the centre.
class FinancialHealthDonut extends StatelessWidget {
  final double income;
  final double expenses;

  const FinancialHealthDonut({super.key, required this.income, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final net = income - expenses;
    final currency = NumberFormat.compactCurrency(symbol: '\$');

    // If both income and expenses are zero, show placeholder.
    if (income == 0 && expenses == 0) {
      return const Center(child: Text('No data yet'));
    }

    final total = income + expenses;
    final incomePct = total == 0 ? 0.0 : income / total * 100;
    final expensePct = total == 0 ? 0.0 : expenses / total * 100;

    final List<PieChartSectionData> sections = [
      PieChartSectionData(
        color: Colors.green,
        value: income,
        title: '${incomePct.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: expenses,
        title: '${expensePct.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Health',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 60,
                      sectionsSpace: 2,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currency.format(net),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: net >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Net',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(color: Colors.green, label: 'Income', amount: currency.format(income)),
                _buildLegendItem(color: Colors.red, label: 'Expenses', amount: currency.format(expenses)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label, required String amount}) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
