import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../widgets/animated_transaction_card.dart';
import '../../utils/enhanced_animations.dart';

/// A screen that displays a list of transactions with animated cards and swipe actions
class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  @override
  void initState() {
    super.initState();
    // Load transactions when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionViewModel>(context, listen: false).loadTransactionsByMonth(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
              _showFilterOptions(context);
            },
          ),
          // Sort button
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Show sort options
              _showSortOptions(context);
            },
          ),
        ],
      ),
      body: Consumer<TransactionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return _buildLoadingState();
          }
          
          if (viewModel.transactions.isEmpty) {
            return _buildEmptyState();
          }
          
          return _buildTransactionsList(viewModel);
        },
      ),
      floatingActionButton: EnhancedAnimations.modernHoverEffect(
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to add transaction screen safely
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushNamed('/add_transaction');
              });
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Build the loading state with animated skeleton cards
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        final card = Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Skeleton for category icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Skeleton for description and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
                
                // Skeleton for amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 16,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        
        // Apply shimmer effect using EnhancedAnimations
        return EnhancedAnimations.shimmerLoading(card, index: index);
      },
    );
  }

  // Build empty state with animation
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EnhancedAnimations.animatedIcon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          
          const SizedBox(height: 16),
          
          EnhancedAnimations.fadeInText(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            delayMillis: 300,
          ),
          
          const SizedBox(height: 8),
          
          EnhancedAnimations.fadeInText(
            'Tap the + button to add your first transaction',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            delayMillis: 500,
          ),
          
          const SizedBox(height: 24),
          
          EnhancedAnimations.animatedButton(
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/add_transaction');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            delayMillis: 700,
          ),
        ],
      ),
    );
  }

  // Build the transactions list with animated cards
  Widget _buildTransactionsList(TransactionViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.transactions.length,
      itemBuilder: (context, index) {
        final transaction = viewModel.transactions[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AnimatedTransactionCard(
            transaction: transaction,
            index: index,
            onTap: () {
              // Navigate to transaction details
              _showTransactionDetails(transaction);
            },
            onEdit: (transaction) {
              // Navigate to edit transaction
              _navigateToEditTransaction(transaction);
            },
            onDelete: (transaction) {
              // First, show a confirmation dialog
              _showDeleteConfirmationDialog(transaction, viewModel);
            },
          ),
        );
      },
    );
  }

  // Show delete confirmation dialog and handle deletion
  Future<void> _showDeleteConfirmationDialog(Transaction transaction, TransactionViewModel viewModel) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    // If confirmed, delete the transaction and show snackbar
    if (result == true && mounted) {
      // Delete transaction
      await viewModel.deleteTransaction(transaction.id ?? '');
      
      // Show snackbar if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Add back the transaction
                viewModel.addTransaction(transaction);
              },
            ),
          ),
        );
      }
    }
  }

  // Show transaction details in a bottom sheet
  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              
              const Divider(),
              
              // Details
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDetailItem('Description', transaction.description ?? ''),
                    _buildDetailItem('Amount', '\$${transaction.amount.abs().toStringAsFixed(2)}'),
                    _buildDetailItem('Category', transaction.category),
                    _buildDetailItem('Date', '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'),
                    _buildDetailItem('Status', transaction.status.name),
                    // Note: Add notes field if needed in the Transaction model
                    // if (transaction.notes != null && transaction.notes!.isNotEmpty)
                    //   _buildDetailItem('Notes', transaction.notes!),
                    // Note: Add isRecurring field if needed in the Transaction model
                    // if (transaction.isRecurring)
                    //   _buildDetailItem('Recurring', 'Yes'),
                  ],
                ),
              ),
              
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navigateToEditTransaction(transaction);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper to build detail item
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to edit transaction
  void _navigateToEditTransaction(Transaction transaction) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamed(
          '/edit_transaction',
          arguments: transaction,
        );
      });
    }
  }

  // Show filter options
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(context, 'All Transactions', Icons.list_alt),
              _buildFilterOption(context, 'Income', Icons.arrow_upward, color: Colors.green),
              _buildFilterOption(context, 'Expenses', Icons.arrow_downward, color: Colors.red),
              _buildFilterOption(context, 'Paid', Icons.check_circle, color: Colors.green),
              _buildFilterOption(context, 'Unpaid', Icons.pending, color: Colors.orange),
            ],
          ),
        );
      },
    );
  }

  // Build filter option
  Widget _buildFilterOption(BuildContext context, String title, IconData icon, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: () {
        // Only pop if possible to avoid navigation errors
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // Apply filter
        // This would be implemented in the viewmodel
      },
    );
  }

  // Show sort options
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSortOption(context, 'Date (Newest First)', Icons.calendar_today),
              _buildSortOption(context, 'Date (Oldest First)', Icons.calendar_today),
              _buildSortOption(context, 'Amount (Highest First)', Icons.attach_money),
              _buildSortOption(context, 'Amount (Lowest First)', Icons.attach_money),
              _buildSortOption(context, 'Category', Icons.category),
            ],
          ),
        );
      },
    );
  }

  // Build sort option
  Widget _buildSortOption(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        // Only pop if possible to avoid navigation errors
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // Apply sort
        // This would be implemented in the viewmodel
      },
    );
  }
}
