import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart' as models;
import '../../services/transaction_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/animated_buttons.dart';
import '../../widgets/animated_transaction_item.dart';

import 'add_transaction_screen.dart';

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
  StreamSubscription<List<models.Transaction>>? _transactionSubscription;
  
  // Financial summary
  double _totalAmount = 0;
  double _averageAmount = 0;
  double _maxAmount = 0;
  DateTime? _lastTransactionDate;

  @override
  void initState() {
    super.initState();
    _loadCategoryTransactions();
  }
  
  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _loadCategoryTransactions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Subscribe to real-time transaction updates
      _transactionSubscription = _transactionService
          .getTransactionsStream()
          .listen((transactions) {
        // Filter transactions by category
        final categoryTransactions = transactions.where((t) => 
          t.category.toLowerCase() == widget.category.toLowerCase()
        ).toList();
        
        // Calculate summary data
        _calculateSummary(categoryTransactions);
        
        setState(() {
          _transactions = categoryTransactions;
          _isLoading = false;
        });
      });
    } catch (e) {
      // Log the error instead of using print
      debugPrint('Error loading category transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _calculateSummary(List<models.Transaction> transactions) {
    if (transactions.isEmpty) {
      setState(() {
        _totalAmount = 0;
        _averageAmount = 0;
        _maxAmount = 0;
        _lastTransactionDate = null;
      });
      return;
    }
    
    double total = 0;
    double max = 0;
    DateTime? lastDate;
    
    for (final transaction in transactions) {
      // Use absolute value for calculations
      final amount = transaction.amount.abs();
      
      total += amount;
      
      if (amount > max) {
        max = amount;
      }
      
      if (lastDate == null || transaction.date.isAfter(lastDate)) {
        lastDate = transaction.date;
      }
    }
    
    setState(() {
      _totalAmount = total;
      _averageAmount = total / transactions.length;
      _maxAmount = max;
      _lastTransactionDate = lastDate;
    });
  }
  
  void _showTransactionDetails({required models.Transaction transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow('Amount', NumberFormat.currency(symbol: '₹').format(transaction.amount)),
              _detailRow('Category', transaction.category),
              _detailRow('Date', DateFormat('MMMM d, yyyy').format(transaction.date)),
              
              if (transaction.description != null && transaction.description!.isNotEmpty)
                _detailRow('Description', transaction.description!),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Edit transaction
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionScreen(
                            transaction: transaction,
                          ),
                        ),
                      ).then((_) => _loadCategoryTransactions());
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Delete transaction
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Transaction'),
                          content: const Text('Are you sure you want to delete this transaction?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        // The dialog is already closed by the Navigator.pop(context, true) call
                        // No need to call Navigator.pop() again
                        
                        // Perform the async operation
                        if (transaction.firestoreId != null) {
                          try {
                            // Do the async work without using BuildContext
                            await _transactionService.deleteTransaction(transaction.firestoreId!);
                            
                            // Only reload data if widget is still mounted
                            if (mounted) {
                              _loadCategoryTransactions();
                            }
                          } catch (e) {
                            // Show error without using BuildContext after async gap
                            if (mounted) {
                              // Use a method that doesn't require BuildContext
                              _showErrorMessage(e.toString());
                            }
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to show error messages without using BuildContext after async gaps
  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    // Use a post-frame callback to ensure we're not in the middle of a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $message'))
      );
    });
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_cart;
      case 'utilities':
        return Icons.lightbulb;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'rent':
        return Icons.home;
      case 'salary':
        return Icons.attach_money;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.receipt;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(widget.category),
                                  size: 32,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.category,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _summaryRow('Total Spent', currencyFormat.format(_totalAmount)),
                            _summaryRow('Average Transaction', currencyFormat.format(_averageAmount)),
                            _summaryRow('Largest Transaction', currencyFormat.format(_maxAmount)),
                            _summaryRow(
                              'Last Transaction',
                              _lastTransactionDate != null
                                  ? DateFormat('MMMM d, yyyy').format(_lastTransactionDate!)
                                  : 'N/A',
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
                if (_transactions.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(32.0),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${widget.category} transactions found',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];

                        final amountText = transaction.amount < 0
                            ? currencyFormat.format(transaction.amount)
                            : '+${currencyFormat.format(transaction.amount)}';

                        final dateText = DateFormat('MMM d, yyyy').format(transaction.date);

                        return AnimatedTransactionItem(
                          title: transaction.title,
                          subtitle: transaction.category,
                          amount: amountText,
                          date: dateText,
                          icon: _getCategoryIcon(widget.category),
                          onTap: () => _showTransactionDetails(transaction: transaction),
                        ).animate().fadeIn(duration: 300.ms, delay: 100.ms * index);
                      },
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
      floatingActionButton: AnimatedButtons.floatingActionButton(
        onPressed: () async {
          // Capture the context before the async gap
          final currentContext = context;
          if (!mounted) return;
          
          final result = await Navigator.push(
            currentContext,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                initialCategory: widget.category,
              ),
            ),
          );

          if (result == true && mounted) {
            _loadCategoryTransactions();
          }
        },
        icon: Icons.add,
        tooltip: 'Add ${widget.category} Transaction',
      ),
    );
  }
  
  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
