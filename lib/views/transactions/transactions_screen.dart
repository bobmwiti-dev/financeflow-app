import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_model.dart' as models;
import '../../themes/app_theme.dart';
import '../../widgets/animated_buttons.dart';
import '../../widgets/animated_transaction_item.dart';
import 'add_transaction_screen.dart';
import '../../utils/currency_extensions.dart';
import '../../viewmodels/transaction_viewmodel_fixed.dart';

class TransactionsScreen extends StatefulWidget {
  final String? category;
  
  const TransactionsScreen({super.key, this.category});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<models.Transaction> _transactions = [];
  List<models.Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  VoidCallback? _viewModelListener;
  
  // Filter variables
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  bool _showIncomeOnly = false;
  bool _showExpensesOnly = false;
  bool _showBusinessOnly = false;
  bool _showPersonalOnly = false;
  
  @override
  void initState() {
    super.initState();
    
    // If category is provided, set it as filter
    if (widget.category != null) {
      _selectedCategory = widget.category;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final DateTime? startDate = args['startDate'] is DateTime ? args['startDate'] as DateTime : null;
        final DateTime? endDate = args['endDate'] is DateTime ? args['endDate'] as DateTime : null;
        final bool businessOnly = args['businessOnly'] is bool ? args['businessOnly'] as bool : false;
        final bool personalOnly = args['personalOnly'] is bool ? args['personalOnly'] as bool : false;

        setState(() {
          _startDate = startDate;
          _endDate = endDate;
          _showBusinessOnly = businessOnly;
          _showPersonalOnly = personalOnly && !businessOnly;
        });

        _applyFilters();
      }
    });
    
    // Load transactions
    final viewModel = Provider.of<TransactionViewModel>(context, listen: false);
    _syncFromViewModel(viewModel);
    _viewModelListener = () {
      if (!mounted) return;
      _syncFromViewModel(viewModel);
    };
    viewModel.addListener(_viewModelListener!);
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

  @override
  void dispose() {
    if (_viewModelListener != null) {
      final viewModel = Provider.of<TransactionViewModel>(context, listen: false);
      viewModel.removeListener(_viewModelListener!);
    }
    super.dispose();
  }
  
  void _syncFromViewModel(TransactionViewModel viewModel) {
    setState(() {
      _transactions = viewModel.transactions;
      _isLoading = viewModel.isLoading;
      _applyFilters();
    });
  }
  
  void _applyFilters() {
    List<models.Transaction> filtered = List.from(_transactions);
    
    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (transaction.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    
    // Apply date range filter
    if (_startDate != null) {
      filtered = filtered.where((transaction) {
        return transaction.date.isAfter(_startDate!) || 
               transaction.date.isAtSameMomentAs(_startDate!);
      }).toList();
    }
    
    if (_endDate != null) {
      filtered = filtered.where((transaction) {
        return transaction.date.isBefore(_endDate!) || 
               transaction.date.isAtSameMomentAs(_endDate!);
      }).toList();
    }
    
    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((transaction) {
        return transaction.category == _selectedCategory;
      }).toList();
    }
    
    // Payment method filter removed: field does not exist in Transaction model.
    
    // Apply transaction type filter
    if (_showIncomeOnly) {
      filtered = filtered.where((transaction) {
        return transaction.amount > 0;
      }).toList();
    } else if (_showExpensesOnly) {
      filtered = filtered.where((transaction) {
        return transaction.amount < 0;
      }).toList();
    }

    // Apply business vs personal context filter
    if (_showBusinessOnly) {
      filtered = filtered.where((transaction) => transaction.isBusiness).toList();
    } else if (_showPersonalOnly) {
      filtered = filtered.where((transaction) => !transaction.isBusiness).toList();
    }
    
    setState(() {
      _filteredTransactions = filtered;
    });
  }
  
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Date range filter
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _startDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _startDate != null
                                  ? DateFormat('MMM d, yyyy').format(_startDate!)
                                  : 'Select',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _endDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _endDate != null
                                  ? DateFormat('MMM d, yyyy').format(_endDate!)
                                  : 'Select',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Transaction type filter
                  const Text(
                    'Transaction Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Income'),
                          value: _showIncomeOnly,
                          onChanged: (value) {
                            setModalState(() {
                              _showIncomeOnly = value ?? false;
                              if (_showIncomeOnly) {
                                _showExpensesOnly = false;
                              }
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Expenses'),
                          value: _showExpensesOnly,
                          onChanged: (value) {
                            setModalState(() {
                              _showExpensesOnly = value ?? false;
                              if (_showExpensesOnly) {
                                _showIncomeOnly = false;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Context',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Business only'),
                          value: _showBusinessOnly,
                          onChanged: (value) {
                            setModalState(() {
                              _showBusinessOnly = value ?? false;
                              if (_showBusinessOnly) {
                                _showPersonalOnly = false;
                              }
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Personal only'),
                          value: _showPersonalOnly,
                          onChanged: (value) {
                            setModalState(() {
                              _showPersonalOnly = value ?? false;
                              if (_showPersonalOnly) {
                                _showBusinessOnly = false;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setModalState(() {
                            _startDate = null;
                            _endDate = null;
                            _selectedCategory = widget.category;
                            _showIncomeOnly = false;
                            _showExpensesOnly = false;
                            _showBusinessOnly = false;
                            _showPersonalOnly = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                        ),
                        child: const Text('Reset'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  void _showTransactionDetails(models.Transaction transaction) {
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
              _detailRow('Amount', transaction.amount.toKenyaDualCurrency()),
              _detailRow('Category', transaction.category),
              _detailRow('Date', DateFormat('MMMM d, yyyy').format(transaction.date)),
              // Payment method display removed: field does not exist in Transaction model.
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
                      );
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
                      // Capture view model before async gap to avoid using BuildContext later
                      final viewModel = Provider.of<TransactionViewModel>(context, listen: false);
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
                            // Delete via TransactionViewModel; its stream will update the list
                            await viewModel.deleteTransaction(transaction.firestoreId!);
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategory != null 
            ? '$_selectedCategory Transactions' 
            : 'All Transactions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          
          // Transactions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedCategory != null
                                  ? 'No $_selectedCategory transactions found'
                                  : 'No transactions found',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add a new transaction to get started',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _filteredTransactions[index];
                          
                          // Format amount with currency symbol
                          final amountText = transaction.amount < 0
                              ? transaction.amount.toKenyaDualCurrency()
                              : '+${transaction.amount.toKenyaDualCurrency()}';
                          
                          // Format date
                          final dateText = DateFormat('MMM d, yyyy').format(transaction.date);
                          
                          // Get icon based on category
                          final IconData icon = _getCategoryIcon(transaction.category);
                          
                          return AnimatedTransactionItem(
                            title: transaction.title,
                            subtitle: transaction.category,
                            amount: amountText,
                            date: dateText,
                            icon: icon,
                            onTap: () => _showTransactionDetails(transaction),
                          ).animate().fadeIn(duration: 300.ms);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: AnimatedButtons.floatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                initialCategory: _selectedCategory,
              ),
            ),
          );
        },
        icon: Icons.add,
        tooltip: 'Add Transaction',
      ),
    );
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
}
