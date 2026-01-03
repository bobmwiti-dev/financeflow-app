import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_theme.dart';
import '../../../models/transaction_model.dart' as models;
import '../../../views/transactions/transaction_details_screen.dart';
import '../../../utils/category_icons.dart';
import '../../../utils/currency_extensions.dart';

class RecentTransactionsCard extends StatelessWidget {
  RecentTransactionsCard({super.key});

  // Recent transactions will be loaded from real data
  final List<Map<String, dynamic>> _recentTransactions = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                      Icons.receipt_long,
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
                          'Recent transactions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Latest activity across your accounts',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      // Show more options
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTransactionsList(context, theme, colorScheme),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    // Navigate to transactions screen
                    Navigator.pushNamed(context, '/expenses');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    textStyle: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('View all transactions'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTransactionsList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        _buildTransactionHeader(theme, colorScheme),
        Divider(
          height: 16,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        if (_recentTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No recent transactions',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ..._recentTransactions.map(
            (transaction) => _buildTransactionItem(
              context,
              theme,
              colorScheme,
              transaction,
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Name',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Category',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> transaction,
  ) {
    final dateFormat = DateFormat('MMM dd');

    final amount = (transaction['amount'] as num).toDouble();
    final isExpense = amount < 0;
    final amountColor = isExpense ? colorScheme.error : colorScheme.primary;
    final amountPrefix = isExpense ? '' : '+';
    final formattedAmount = amount.abs().toKenyaDualCurrency();
    
    // Create a Transaction object from the mock data
    final transactionObj = models.Transaction(
      title: transaction['title'],
      amount: transaction['amount'],
      date: transaction['date'],
      category: transaction['category'],
      userId: '',
      accountId: 'default_account',
      type: transaction['amount'] < 0 ? models.TransactionType.expense : models.TransactionType.income,
    );
    
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(
              transaction: transactionObj,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Add brand logo/icon
            CategoryIcons.getBrandWidget(
              transaction['title'],
              size: 20.0,
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(
                transaction['title'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getCategoryColor(transaction['category']).withAlpha(24),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  transaction['category'],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getCategoryColor(transaction['category']),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '$amountPrefix$formattedAmount',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                dateFormat.format(transaction['date']),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    if (AppTheme.categoryColors.containsKey(category)) {
      return AppTheme.categoryColors[category]!;
    }
    return AppTheme.categoryColors['Other']!;
  }
}
