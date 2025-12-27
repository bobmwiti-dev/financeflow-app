import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction_model.dart';
import '../widgets/animated_data_list.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/sync_status_indicator.dart';

/// A widget that displays a list of transactions with animations
class AnimatedTransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isLoading;
  final Function(Transaction) onTap;
  final Function(Transaction) onDelete;
  final Function(Transaction) onEdit;
  final String emptyMessage;
  final bool showSyncStatus;

  const AnimatedTransactionList({
    super.key,
    required this.transactions,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    this.isLoading = false,
    this.emptyMessage = 'No transactions found',
    this.showSyncStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && transactions.isEmpty) {
      return Center(
        child: DataLoadingIndicator(
          isLoading: true,
          message: 'Loading transactions...',
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
      );
    }

    return Column(
      children: [
        if (showSyncStatus && isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SyncStatusIndicator(
                  isSyncing: isLoading,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Syncing transactions...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: AnimatedDataList<Transaction>(
            items: transactions,
            itemBuilder: (context, transaction, animation) {
              return _buildTransactionItem(context, transaction, animation);
            },
            keyExtractor: (transaction) => 'transaction-${transaction.id ?? 0}',
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction, Animation<double> animation) {
    final theme = Theme.of(context);
    final isExpense = transaction.amount < 0;
    final amountColor = isExpense ? Colors.red : Colors.green;
    
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => onTap(transaction),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(transaction.category),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description ?? 'No description',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.category.isEmpty ? 'Uncategorized' : transaction.category,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isExpense ? '-' : '+'}\$${transaction.amount.abs().toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(transaction.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate()
          .slideX(begin: 0.05, end: 0, duration: const Duration(milliseconds: 200))
          .fadeIn(duration: const Duration(milliseconds: 300)),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null || category.isEmpty) return Icons.receipt;
    switch (category.toLowerCase()) {
      case 'food':
      case 'groceries':
      case 'dining':
        return Icons.restaurant;
      case 'transportation':
      case 'travel':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.lightbulb;
      case 'housing':
      case 'rent':
        return Icons.home;
      case 'healthcare':
      case 'medical':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'income':
      case 'salary':
        return Icons.attach_money;
      default:
        return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
