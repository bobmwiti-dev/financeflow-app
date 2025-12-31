import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../services/transaction_service.dart';

class SideHustleReportScreen extends StatefulWidget {
  final int? initialYear;

  const SideHustleReportScreen({super.key, this.initialYear});

  @override
  State<SideHustleReportScreen> createState() => _SideHustleReportScreenState();
}

class _SideHustleReportScreenState extends State<SideHustleReportScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Side-hustle Report'),
      ),
      body: FutureBuilder<Map<int, Map<String, double>>>(
        future: TransactionService.instance.getBusinessMonthlySummary(_year),
        builder: (context, snapshot) {
          final currency = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load side-hustle report: ${snapshot.error}'),
              ),
            );
          }

          final monthly = snapshot.data ?? {};

          double totalIncome = 0;
          double totalExpenses = 0;
          for (final entry in monthly.entries) {
            totalIncome += entry.value['income'] ?? 0.0;
            totalExpenses += entry.value['expenses'] ?? 0.0;
          }
          final totalNet = totalIncome - totalExpenses;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Year $_year',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildYearPicker(),
                  ],
                ),
                const SizedBox(height: 12),
                _buildYtdSummary(currency, totalIncome, totalExpenses, totalNet),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/transactions',
                        arguments: {
                          'businessOnly': true,
                          'personalOnly': false,
                          'startDate': DateTime(_year, 1, 1),
                          'endDate': DateTime(_year, 12, 31, 23, 59, 59),
                        },
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View business transactions'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Monthly Net Profit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: _buildNetBarChart(monthly),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tip: Mark transactions as Business to include them in this report.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearPicker() {
    final nowYear = DateTime.now().year;
    final years = List<int>.generate(6, (i) => nowYear - i);

    return DropdownButton<int>(
      value: _year,
      items: years
          .map(
            (y) => DropdownMenuItem(
              value: y,
              child: Text(y.toString()),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _year = value;
        });
      },
    );
  }

  Widget _buildYtdSummary(
    NumberFormat currency,
    double income,
    double expenses,
    double net,
  ) {
    final netColor = net >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Year-to-date summary',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _metric('Revenue', currency.format(income), Colors.green.shade700)),
                Expanded(child: _metric('Expenses', currency.format(expenses), Colors.red.shade700)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Profit', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(currency.format(net), style: TextStyle(fontWeight: FontWeight.bold, color: netColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildNetBarChart(Map<int, Map<String, double>> monthly) {
    final bars = <BarChartGroupData>[];

    double minY = 0;
    double maxY = 0;

    for (int month = 1; month <= 12; month++) {
      final data = monthly[month] ?? const {'income': 0.0, 'expenses': 0.0};
      final net = (data['income'] ?? 0.0) - (data['expenses'] ?? 0.0);

      if (month == 1) {
        minY = net;
        maxY = net;
      } else {
        if (net < minY) minY = net;
        if (net > maxY) maxY = net;
      }

      bars.add(
        BarChartGroupData(
          x: month,
          barRods: [
            BarChartRodData(
              toY: net,
              width: 10,
              borderRadius: BorderRadius.circular(6),
              color: net >= 0 ? Colors.green.shade600 : Colors.red.shade600,
            ),
          ],
        ),
      );
    }

    // Avoid zero-height chart scaling
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    final padding = (maxY - minY) * 0.15;

    return BarChart(
      BarChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: bars,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(NumberFormat.compact().format(value));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final month = value.toInt();
                if (month < 1 || month > 12) return const SizedBox.shrink();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    DateFormat('MMM').format(DateTime(_year, month, 1)),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
