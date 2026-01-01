import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../viewmodels/transaction_viewmodel_fixed.dart';
import 'transaction_form_screen.dart';
import '../../utils/category_icons.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final isExpense = widget.transaction.amount < 0;
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');
    final dateFormat = DateFormat(AppConstants.dateFormat);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final accent = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionFormScreen(
                    transaction: widget.transaction,
                    isExpense: isExpense,
                  ),
                ),
              );
              if (!context.mounted) return;
              if (result == true) {
                // Refresh and return to previous screen
                Navigator.pop(context, true);
              } else if (result == 'deleted') {
                // Handle deletion
                Navigator.pop(context, 'deleted');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPremiumHeader(
                context,
                isExpense: isExpense,
                currencyFormat: currencyFormat,
                dateFormat: dateFormat,
                accent: accent,
                primary: primary,
              ),
              const SizedBox(height: 16),
              _buildDetailsCard(context, isExpense, currencyFormat, dateFormat),
              if (widget.transaction.description != null && widget.transaction.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDescriptionCard(context),
              ],
              const SizedBox(height: 12),
              _buildActionsCard(context, isExpense),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(
    BuildContext context, {
    required bool isExpense,
    required NumberFormat currencyFormat,
    required DateFormat dateFormat,
    required Color accent,
    required Color primary,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = _getCategoryColor(widget.transaction.category);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withAlpha((0.95 * 255).toInt()),
            colorScheme.secondary.withAlpha((0.85 * 255).toInt()),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.10 * 255).toInt()),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.16 * 255).toInt()),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CategoryIcons.getBrandCircleWidget(
                  widget.transaction.title,
                  size: 56.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateFormat.format(widget.transaction.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha((0.85 * 255).toInt()),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  currencyFormat.format(widget.transaction.amount.abs()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.14 * 255).toInt()),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withAlpha((0.22 * 255).toInt()),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExpense ? Icons.trending_down : Icons.trending_up,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isExpense ? 'Expense' : 'Income',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPill(
                context,
                label: widget.transaction.category,
                icon: Icons.sell_outlined,
                fg: categoryColor,
                bg: Colors.white,
              ),
              if (widget.transaction.isBusiness)
                _buildPill(
                  context,
                  label: 'Business / Side-hustle',
                  icon: Icons.work_outline,
                  fg: Colors.deepPurple,
                  bg: Colors.white,
                ),
              _buildPill(
                context,
                label: isExpense ? 'Money out' : 'Money in',
                icon: Icons.account_balance_wallet_outlined,
                fg: accent,
                bg: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color fg,
    required Color bg,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withAlpha((0.95 * 255).toInt()),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context, 
    bool isExpense, 
    NumberFormat currencyFormat, 
    DateFormat dateFormat
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha((0.6 * 255).toInt())),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailTile(
              context,
              icon: isExpense ? Icons.trending_down : Icons.trending_up,
              label: 'Transaction type',
              value: isExpense ? 'Expense' : 'Income',
              valueColor: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
            ),
            const SizedBox(height: 4),
            _buildDetailTile(
              context,
              icon: Icons.payments_outlined,
              label: 'Amount',
              value: currencyFormat.format(widget.transaction.amount.abs()),
              valueColor: null,
            ),
            const SizedBox(height: 4),
            _buildDetailTile(
              context,
              icon: Icons.event_outlined,
              label: 'Date',
              value: dateFormat.format(widget.transaction.date),
              valueColor: null,
            ),
            const SizedBox(height: 4),
            _buildDetailTile(
              context,
              icon: Icons.sell_outlined,
              label: 'Category',
              value: widget.transaction.category,
              valueColor: _getCategoryColor(widget.transaction.category),
            ),
            if (widget.transaction.isBusiness) ...[
              const SizedBox(height: 4),
              _buildDetailTile(
                context,
                icon: Icons.work_outline,
                label: 'Context',
                value: 'Business / Side-hustle',
                valueColor: Colors.deepPurple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha((0.55 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha((0.6 * 255).toInt())),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.transaction.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, bool isExpense) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha((0.6 * 255).toInt())),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  _duplicateTransaction(context);
                },
                icon: const Icon(Icons.content_copy),
                label: const Text('Duplicate transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text(
            'Are you sure you want to delete this transaction? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // Handle delete transaction
                _deleteTransaction(context);
              },
              style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTransaction(BuildContext context) async {
    if (!context.mounted) return;
    
    try {
      final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
      
      // Check if transaction has an ID
      if (widget.transaction.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete transaction: Invalid transaction ID'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context); // Close dialog
        return;
      }
      
      // Delete the transaction
      await transactionViewModel.deleteTransaction(widget.transaction.id!);
      
      if (!context.mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.transaction.title}" deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context); // Close dialog
      Navigator.pop(context, 'deleted'); // Return to previous screen with result
    } catch (e) {
      if (!context.mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      Navigator.pop(context); // Close dialog
    }
  }

  void _duplicateTransaction(BuildContext context) {
    // Create a new transaction with the same details but a new date
    final duplicatedTransaction = Transaction(
      title: widget.transaction.title,
      amount: widget.transaction.amount,
      date: DateTime.now(), // Use current date for the duplicate
      category: widget.transaction.category,
      description: widget.transaction.description,
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      accountId: widget.transaction.accountId,
      type: widget.transaction.type,
      isBusiness: widget.transaction.isBusiness,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          transaction: duplicatedTransaction,
          isExpense: widget.transaction.amount < 0,
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
