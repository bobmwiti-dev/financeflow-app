import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../models/transaction_model.dart' as models;
import '../../../services/transaction_service.dart';
import '../../../utils/currency_extensions.dart';

class SideHustleSummaryCard extends StatelessWidget {
  final DateTime selectedMonth;

  const SideHustleSummaryCard({super.key, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionViewModel>(
      builder: (context, transactionViewModel, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
                color: colorScheme.shadow.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
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
                          color:
                              colorScheme.primaryContainer.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.storefront,
                          color: colorScheme.onPrimaryContainer,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Side-hustle Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (businessTransactions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    _buildStatusChip(theme, net),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.pushNamed(
                            context,
                            '/side_hustle_report',
                            arguments: selectedMonth.year,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          textStyle: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('View report'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (businessTransactions.isEmpty) ...[
                    Text(
                      'No business / side-hustle transactions recorded for this month.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            theme: theme,
                            label: 'Revenue (month)',
                            value: businessIncome.toKenyaDualCurrency(),
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetric(
                            theme: theme,
                            label: 'Expenses (month)',
                            value: businessExpenses.toKenyaDualCurrency(),
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: (net >= 0
                                ? colorScheme.primaryContainer
                                : colorScheme.errorContainer)
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (net >= 0
                                  ? colorScheme.primary
                                  : colorScheme.error)
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Net Profit (month)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: net >= 0
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onErrorContainer,
                            ),
                          ),
                          Text(
                            net.toKenyaDualCurrency(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: net >= 0
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Column(
                    children: [
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
                            'net': 0.0,
                          };
                          final ytdIncome = data['income'] ?? 0.0;
                          final ytdExpenses = data['expenses'] ?? 0.0;
                          final ytdNet = data['net'] ?? 0.0;

                          if (ytdIncome == 0 && ytdExpenses == 0) {
                            return Text(
                              'No side-hustle activity recorded yet this year.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Year-to-date (side-hustle)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetric(
                                      theme: theme,
                                      label: 'Revenue (YTD)',
                                      value: ytdIncome.toKenyaDualCurrency(),
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetric(
                                      theme: theme,
                                      label: 'Expenses (YTD)',
                                      value: ytdExpenses.toKenyaDualCurrency(),
                                      color: colorScheme.tertiary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Net (YTD): ${ytdNet.toKenyaDualCurrency()}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: ytdNet >= 0
                                      ? colorScheme.primary
                                      : colorScheme.error,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'Tip: Use this year-to-date view as a simple, tax-ready summary of your side-hustle.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric({
    required ThemeData theme,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme, double net) {
    final colorScheme = theme.colorScheme;
    final bool isProfitable = net >= 0;

    final Color background = isProfitable
        ? colorScheme.secondaryContainer
        : colorScheme.errorContainer;
    final Color foreground = isProfitable
        ? colorScheme.onSecondaryContainer
        : colorScheme.onErrorContainer;
    final IconData icon = isProfitable
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final String label = isProfitable
        ? 'Profitable this month'
        : 'Running at a loss';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
