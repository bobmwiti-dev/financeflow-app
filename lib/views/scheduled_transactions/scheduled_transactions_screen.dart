import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/scheduled_transaction_model.dart';
import '../../themes/app_theme.dart';
import 'widgets/scheduled_transaction_card.dart';
import 'widgets/create_scheduled_transaction_button.dart';

class ScheduledTransactionsScreen extends StatefulWidget {
  const ScheduledTransactionsScreen({super.key});

  @override
  State<ScheduledTransactionsScreen> createState() => _ScheduledTransactionsScreenState();
}

class _ScheduledTransactionsScreenState extends State<ScheduledTransactionsScreen> {
  List<ScheduledTransactionModel> _scheduledTransactions = [];
  bool _isLoading = true;
  String _filterType = 'All';
  
  final List<String> _filterOptions = ['All', 'Income', 'Expense', 'Transfer'];

  @override
  void initState() {
    super.initState();
    _loadScheduledTransactions();
  }

  Future<void> _loadScheduledTransactions() async {
    // In a real app, this would fetch from a repository
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
    setState(() {
      _scheduledTransactions = ScheduledTransactionModel.getSampleData();
      _isLoading = false;
    });
  }

  List<ScheduledTransactionModel> _getFilteredTransactions() {
    if (_filterType == 'All') {
      return _scheduledTransactions;
    }
    
    final TransactionType type = TransactionType.values.firstWhere(
      (e) => e.toString().split('.').last == _filterType.toLowerCase(),
    );
    
    return _scheduledTransactions.where((t) => t.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCard(),
                Expanded(
                  child: _buildTransactionsList(),
                ),
              ],
            ),
      floatingActionButton: CreateScheduledTransactionButton(
        onPressed: _showCreateTransactionDialog,
      ),
    );
  }

  Widget _buildSummaryCard() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // Calculate summary values
    final totalIncome = _scheduledTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpenses = _scheduledTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final monthlyIncome = totalIncome / 12;
    final monthlyExpenses = totalExpenses / 12;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recurring Transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _filterType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Monthly Income',
                  currencyFormat.format(monthlyIncome),
                  Icons.arrow_downward,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Monthly Expenses',
                  currencyFormat.format(monthlyExpenses),
                  Icons.arrow_upward,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Net Monthly',
                  currencyFormat.format(monthlyIncome - monthlyExpenses),
                  Icons.account_balance_wallet,
                  (monthlyIncome - monthlyExpenses) >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Total Scheduled',
                  '${_scheduledTransactions.length}',
                  Icons.calendar_today,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 400))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final filteredTransactions = _getFilteredTransactions();
    
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No scheduled transactions found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new scheduled transaction to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScheduledTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          return ScheduledTransactionCard(
            transaction: transaction,
            onTap: () => _showTransactionDetails(transaction),
          ).animate()
            .fadeIn(
              duration: const Duration(milliseconds: 300),
              delay: Duration(milliseconds: 50 * index),
            )
            .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(
                _filterOptions.length,
                (index) => ListTile(
                  leading: Icon(
                    _getFilterIcon(_filterOptions[index]),
                    color: _getFilterColor(_filterOptions[index]),
                  ),
                  title: Text(_filterOptions[index]),
                  selected: _filterType == _filterOptions[index],
                  selectedTileColor: AppTheme.accentColor.withAlpha((255 * 0.1).round()),
                  onTap: () {
                    setState(() {
                      _filterType = _filterOptions[index];
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getFilterIcon(String filterType) {
    switch (filterType) {
      case 'Income':
        return Icons.arrow_downward;
      case 'Expense':
        return Icons.arrow_upward;
      case 'Transfer':
        return Icons.swap_horiz;
      default:
        return Icons.all_inclusive;
    }
  }

  Color _getFilterColor(String filterType) {
    switch (filterType) {
      case 'Income':
        return Colors.green;
      case 'Expense':
        return Colors.red;
      case 'Transfer':
        return Colors.blue;
      default:
        return AppTheme.accentColor;
    }
  }

  void _showTransactionDetails(ScheduledTransactionModel transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: transaction.getTypeColor().withAlpha((255 * 0.1).round()),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            transaction.getTypeIcon(),
                            color: transaction.getTypeColor(),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                transaction.category,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(transaction.amount),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: transaction.getTypeColor(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailItem(
                      'Frequency',
                      transaction.getFrequencyText(),
                      Icons.repeat,
                    ),
                    _buildDetailItem(
                      'Next Due',
                      DateFormat.yMMMd().format(transaction.nextDue),
                      Icons.event,
                    ),
                    _buildDetailItem(
                      'Start Date',
                      DateFormat.yMMMd().format(transaction.startDate),
                      Icons.play_arrow,
                    ),
                    if (transaction.endDate != null)
                      _buildDetailItem(
                        'End Date',
                        DateFormat.yMMMd().format(transaction.endDate!),
                        Icons.stop,
                      ),
                    if (transaction.description != null && transaction.description!.isNotEmpty)
                      _buildDetailItem(
                        'Description',
                        transaction.description!,
                        Icons.description,
                      ),
                    if (transaction.type == TransactionType.transfer) ...[
                      _buildDetailItem(
                        'From Account',
                        transaction.accountId ?? 'Unknown',
                        Icons.account_balance,
                      ),
                      _buildDetailItem(
                        'To Account',
                        transaction.toAccountId ?? 'Unknown',
                        Icons.account_balance,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Edit transaction logic
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Skip next occurrence logic
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Next occurrence skipped'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Skip Next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Delete transaction logic
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction deleted'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    
    TransactionType selectedType = TransactionType.expense;
    TransactionFrequency selectedFrequency = TransactionFrequency.monthly;
    String selectedCategory = 'Bills & Utilities';
    DateTime selectedStartDate = DateTime.now();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create Scheduled Transaction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Rent Payment',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Transaction Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeOption(
                          'Expense',
                          TransactionType.expense,
                          selectedType,
                          (type) {
                            setState(() {
                              selectedType = type;
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildTypeOption(
                          'Income',
                          TransactionType.income,
                          selectedType,
                          (type) {
                            setState(() {
                              selectedType = type;
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildTypeOption(
                          'Transfer',
                          TransactionType.transfer,
                          selectedType,
                          (type) {
                            setState(() {
                              selectedType = type;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Frequency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TransactionFrequency>(
                      value: selectedFrequency,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: TransactionFrequency.values.map((frequency) {
                        String label;
                        switch (frequency) {
                          case TransactionFrequency.daily:
                            label = 'Daily';
                            break;
                          case TransactionFrequency.weekly:
                            label = 'Weekly';
                            break;
                          case TransactionFrequency.biweekly:
                            label = 'Every 2 weeks';
                            break;
                          case TransactionFrequency.monthly:
                            label = 'Monthly';
                            break;
                          case TransactionFrequency.quarterly:
                            label = 'Every 3 months';
                            break;
                          case TransactionFrequency.yearly:
                            label = 'Yearly';
                            break;
                          case TransactionFrequency.custom:
                            label = 'Custom';
                            break;
                        }
                        
                        return DropdownMenuItem(
                          value: frequency,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedFrequency = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Housing',
                        'Transportation',
                        'Food & Dining',
                        'Bills & Utilities',
                        'Entertainment',
                        'Health & Fitness',
                        'Shopping',
                        'Personal Care',
                        'Education',
                        'Income',
                        'Savings',
                        'Other',
                      ].map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Start Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        
                        if (pickedDate != null) {
                          setState(() {
                            selectedStartDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Text(DateFormat.yMMMd().format(selectedStartDate)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add details about this transaction',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Create scheduled transaction logic
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Scheduled transaction created'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Create'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeOption(
    String label,
    TransactionType type,
    TransactionType selectedType,
    Function(TransactionType) onSelected,
  ) {
    final isSelected = type == selectedType;
    
    Color color;
    IconData icon;
    
    switch (type) {
      case TransactionType.income:
        color = Colors.green;
        icon = Icons.arrow_downward;
        break;
      case TransactionType.expense:
        color = Colors.red;
        icon = Icons.arrow_upward;
        break;
      case TransactionType.transfer:
        color = Colors.blue;
        icon = Icons.swap_horiz;
        break;
    }
    
    return Expanded(
      child: InkWell(
        onTap: () => onSelected(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha((255 * 0.1).round()) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
