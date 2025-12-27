import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../themes/app_theme.dart';
import '../../../models/transaction_model.dart' as models;
import '../../../views/transactions/transaction_details_screen.dart';
import '../../../utils/category_icons.dart';

class RecentTransactionsCard extends StatelessWidget {
  RecentTransactionsCard({super.key});

  // Recent transactions will be loaded from real data
  final List<Map<String, dynamic>> _recentTransactions = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Show more options
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTransactionsList(context),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to transactions screen
                  Navigator.pushNamed(context, '/expenses');
                },
                child: const Text('View All Transactions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    return Column(
      children: [
        _buildTransactionHeader(),
        const Divider(),
        if (_recentTransactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No recent transactions', style: TextStyle(color: Colors.grey)),
          )
        else
          ..._recentTransactions.map((transaction) => _buildTransactionItem(context, transaction)),
      ],
    );
  }

  Widget _buildTransactionHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd');
    
    final isExpense = transaction['amount'] < 0;
    final amountColor = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final amountPrefix = isExpense ? '' : '+';
    
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(
              transaction: transactionObj,
            ),
          ),
        );
      },
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
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(transaction['category']).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction['category'],
                  style: TextStyle(
                    color: _getCategoryColor(transaction['category']),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '$amountPrefix${currencyFormat.format(transaction['amount'].abs())}',
                style: TextStyle(
                  fontSize: 14,
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                dateFormat.format(transaction['date']),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
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
