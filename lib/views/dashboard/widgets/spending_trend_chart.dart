import 'package:financeflow_app/services/transaction_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SpendingTrendChart extends StatefulWidget {
  const SpendingTrendChart({super.key});

  @override
  State<SpendingTrendChart> createState() => _SpendingTrendChartState();
}

class _SpendingTrendChartState extends State<SpendingTrendChart> {
  late Future<Map<String, double>> _spendingHistoryFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the monthly spending history (last 12 months of actual data) once when the widget is initialized.
    final transactionService = Provider.of<TransactionService>(context, listen: false);
    _spendingHistoryFuture = transactionService.getMonthlySpendingHistory(numberOfMonths: 12);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: _spendingHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide the widget instead of showing error message
        }

        final spendingData = snapshot.data!;
        List<FlSpot> spots = [];
        List<String> monthLabels = [];
        double maxY = 0;
        double intervalY = 1000; // Default interval

        int index = 0;
        spendingData.forEach((label, total) {
          final value = total.toDouble();
          spots.add(FlSpot(index.toDouble(), value));
          // Label comes as 'MMM yyyy' → show 'MMM'
          final parts = label.split(' ');
          monthLabels.add(parts.isNotEmpty ? parts.first : label);
          if (value > maxY) maxY = value;
          index++;
        });

        if (maxY > 0) {
          intervalY = (maxY / 5).ceilToDouble(); // Aim for 5 grid lines
          if (intervalY == 0) intervalY = 100; // Avoid zero interval
        }
        
        if (spots.isEmpty) {
            return const Center(child: Text('Not enough data for trend chart.'));
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Spending Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: intervalY,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).dividerColor.withValues(alpha:0.5),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < monthLabels.length) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8.0,
                                  child: Text(monthLabels[index], style: const TextStyle(fontSize: 10)),
                                );
                              }
                              return Container();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: intervalY,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(NumberFormat.compact().format(value), style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
                      ),
                      minX: 0,
                      maxX: (spots.length -1).toDouble(),
                      minY: 0,
                      maxY: maxY == 0 ? 500 : (maxY * 1.1).ceilToDouble(), // Add some padding to max Y
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
