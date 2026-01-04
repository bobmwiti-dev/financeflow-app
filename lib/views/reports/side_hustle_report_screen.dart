import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../services/transaction_service.dart';
import '../../utils/currency_extensions.dart';

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
                _buildYtdSummary(context, totalIncome, totalExpenses, totalNet),
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
                  child: _buildNetBarChart(context, monthly),
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
    BuildContext context,
    double income,
    double expenses,
    double net,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasActivity = income > 0 || expenses > 0;
    final netIsPositive = net >= 0;
    final netColor = netIsPositive ? colorScheme.primary : colorScheme.error;

    final statusLabel = !hasActivity
        ? 'No activity yet'
        : net == 0
            ? 'Break-even YTD'
            : netIsPositive
                ? 'Profitable YTD'
                : 'Running at a loss';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
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
                  'Year-to-date summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: !hasActivity
                        ? colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.9)
                        : netIsPositive
                            ? colorScheme.primaryContainer
                                .withValues(alpha: 0.9)
                            : colorScheme.errorContainer
                                .withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        !hasActivity
                            ? Icons.hourglass_empty
                            : netIsPositive
                                ? Icons.trending_up
                                : Icons.trending_down,
                        size: 14,
                        color: !hasActivity
                            ? colorScheme.onSurfaceVariant
                            : netIsPositive
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: !hasActivity
                              ? colorScheme.onSurfaceVariant
                              : netIsPositive
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasActivity)
              Text(
                'No side-hustle income or expenses recorded for $_year yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _metric(
                      context,
                      'Revenue',
                      income,
                      colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      context,
                      'Expenses',
                      expenses,
                      colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Profit',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    net.toKenyaDualCurrency(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: netColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount.toKenyaDualCurrency(),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNetBarChart(
    BuildContext context,
    Map<int, Map<String, double>> monthly,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              color: net >= 0 ? colorScheme.primary : colorScheme.error,
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            final isZeroLine = value == 0;
            return FlLine(
              color: isZeroLine
                  ? colorScheme.outlineVariant.withValues(alpha: 0.7)
                  : colorScheme.outlineVariant.withValues(alpha: 0.35),
              strokeWidth: isZeroLine ? 1.2 : 0.6,
            );
          },
        ),
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
                return Text(
                  NumberFormat.compact().format(value),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                );
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
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
