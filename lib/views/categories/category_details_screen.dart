import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/transaction_model.dart' as models;
import '../../services/transaction_service.dart';
import '../../widgets/animated_transaction_item.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final String category;

  const CategoryDetailsScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  final TransactionService _transactionService = TransactionService.instance;
  List<models.Transaction> _transactions = [];
  bool _isLoading = true;
  double _totalAmount = 0;
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  final DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _transactionService.getTransactionsByCategory(
        widget.category,
        _startDate,
        _endDate,
      );

      double total = 0;
      for (var transaction in transactions) {
        total += transaction.amount;
      }

      setState(() {
        _transactions = transactions;
        _totalAmount = total;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildSummary(),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Transactions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  _transactions.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'No transactions in this category',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final transaction = _transactions[index];
                              return _buildTransactionItem(transaction, index);
                            },
                            childCount: _transactions.length,
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.category,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Spent:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                NumberFormat.currency(symbol: '\$').format(_totalAmount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${_transactions.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _transactions.isNotEmpty
                    ? NumberFormat.currency(symbol: '\$')
                        .format(_totalAmount / _transactions.length)
                    : '\$0.00',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildTransactionItem(models.Transaction transaction, int index) {
    final amountText = NumberFormat.currency(symbol: '\$').format(transaction.amount);
    final dateText = DateFormat('MMM d, yyyy').format(transaction.date);

    return AnimatedTransactionItem(
      title: transaction.title,
      subtitle: transaction.notes ?? '',
      amount: amountText,
      date: dateText,
      isExpense: transaction.isExpense,
      icon: Icons.category,
      onTap: () {
        // Show transaction details
      },
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: 50 * index),
        );
  }
}
