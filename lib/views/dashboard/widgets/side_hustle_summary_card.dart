import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../models/transaction_model.dart' as models;
import '../../../services/transaction_service.dart';
import '../../../themes/app_theme.dart';

class SideHustleSummaryCard extends StatelessWidget {
  final DateTime selectedMonth;

  const SideHustleSummaryCard({super.key, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionViewModel>(
      builder: (context, transactionViewModel, child) {
        final monthKey = DateTime(selectedMonth.year, selectedMonth.month);

        final businessTransactions = transactionViewModel.transactions.where((t) {
          final isSameMonth =
              t.date.year == monthKey.year && t.date.month == monthKey.month;
          return isSameMonth && t.isBusiness;
        }).toList();

        double businessIncome = 0;
        double businessExpenses = 0;

        for (final t in businessTransactions) {
          if (t.amount > 0 || t.type == models.TransactionType.income) {
            businessIncome += t.amount.abs();
          } else if (t.amount < 0 || t.type == models.TransactionType.expense) {
            businessExpenses += t.amount.abs();
          }
        }

        final net = businessIncome - businessExpenses;
        final currency = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: Colors.deepPurple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Side-hustle Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/side_hustle_report',
                          arguments: selectedMonth.year,
                        );
                      },
                      child: const Text('View report'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (businessTransactions.isEmpty) ...[
                  Text(
                    'No business / side-hustle transactions recorded for this month.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetric(
                          label: 'Revenue (month)',
                          value: currency.format(businessIncome),
                          color: AppTheme.incomeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetric(
                          label: 'Expenses (month)',
                          value: currency.format(businessExpenses),
                          color: AppTheme.expenseColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (net >= 0
                              ? Colors.green
                              : Colors.red)
                          .withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Net Profit (month)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currency.format(net),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                net >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Year-to-date summary for tax-ready aggregates
                FutureBuilder<Map<String, double>>(
                  future: TransactionService.instance
                      .getBusinessSummaryForYear(selectedMonth.year),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final data = snapshot.data ?? const {
                      'income': 0.0,
                      'expenses': 0.0,
                      'net': 0.0
                    };
                    final ytdIncome = data['income'] ?? 0.0;
                    final ytdExpenses = data['expenses'] ?? 0.0;
                    final ytdNet = data['net'] ?? 0.0;

                    if (ytdIncome == 0 && ytdExpenses == 0) {
                      return Text(
                        'No side-hustle activity recorded yet this year.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Year-to-date (side-hustle)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetric(
                                label: 'Revenue (YTD)',
                                value: currency.format(ytdIncome),
                                color: AppTheme.incomeColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetric(
                                label: 'Expenses (YTD)',
                                value: currency.format(ytdExpenses),
                                color: AppTheme.expenseColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Net (YTD): ${currency.format(ytdNet)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ytdNet >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tip: Use this year-to-date view as a simple, tax-ready summary of your side-hustle.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
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

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
