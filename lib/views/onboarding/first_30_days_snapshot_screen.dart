import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../viewmodels/transaction_viewmodel_fixed.dart' as fixed;
import '../../viewmodels/income_viewmodel.dart';
import '../../themes/app_theme.dart';

class First30DaysSnapshotScreen extends StatefulWidget {
  const First30DaysSnapshotScreen({super.key});

  @override
  State<First30DaysSnapshotScreen> createState() => _First30DaysSnapshotScreenState();
}

class _First30DaysSnapshotScreenState extends State<First30DaysSnapshotScreen> {
  bool _isMarkingDone = false;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));

    return Scaffold(
      appBar: AppBar(
        title: const Text('First 30 Days Snapshot'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<fixed.TransactionViewModel, IncomeViewModel>(
        builder: (context, txVm, incomeVm, child) {
          final tx = txVm.allTransactions.isNotEmpty ? txVm.allTransactions : txVm.transactions;
          final last30Tx = tx.where((t) => t.date.isAfter(since)).toList();

          double outflow = 0.0;
          final categorySpend = <String, double>{};
          double mpesaFees = 0.0;

          for (final t in last30Tx) {
            if (t.amount < 0) {
              final amt = t.amount.abs();
              outflow += amt;
              categorySpend[t.category] = (categorySpend[t.category] ?? 0.0) + amt;

              final text = '${t.title} ${t.description ?? ''} ${t.category}'.toLowerCase();
              final isFee = text.contains('fee') ||
                  text.contains('charge') ||
                  text.contains('transaction cost') ||
                  text.contains('cost') ||
                  text.contains('mpesa') && text.contains('charge');
              if (isFee) {
                mpesaFees += amt;
              }
            }
          }

          final last30Income = incomeVm.incomeSources
              .where((i) => i.date.isAfter(since))
              .fold<double>(0.0, (sum, i) => sum + i.amount);

          final net = last30Income - outflow;

          final topCategories = categorySpend.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final top3 = topCategories.take(3).toList();

          final savedOrOverspent = net >= 0
              ? 'You saved ${currency.format(net)} in the last 30 days.'
              : 'You overspent ${currency.format(net.abs())} in the last 30 days.';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your first month, simplified',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  savedOrOverspent,
                  style: TextStyle(
                    color: net >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        label: 'Total inflow',
                        value: currency.format(last30Income),
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricCard(
                        label: 'Total outflow',
                        value: currency.format(outflow),
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        label: 'M-Pesa fees',
                        value: currency.format(mpesaFees),
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricCard(
                        label: 'Net',
                        value: currency.format(net),
                        color: net >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Top categories',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (top3.isEmpty)
                  const Text('No spending data yet.')
                else
                  ...top3.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.key),
                      trailing: Text(
                        currency.format(e.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isMarkingDone
                        ? null
                        : () async {
                            setState(() {
                              _isMarkingDone = true;
                            });
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('first_30_snapshot_shown', true);
                            if (!context.mounted) return;
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/dashboard',
                              (route) => false,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isMarkingDone
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Go to Dashboard'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
