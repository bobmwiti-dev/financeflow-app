import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction_model.dart';

/// An animated transaction card with swipe actions
/// Provides a modern, interactive way to display and manage transactions
class AnimatedTransactionCard extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final Function(Transaction)? onEdit;
  final Function(Transaction)? onDelete;
  final Function(Transaction)? onTogglePaid;
  final int index;

  const AnimatedTransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onTogglePaid,
    this.index = 0,
  });

  @override
  State<AnimatedTransactionCard> createState() => _AnimatedTransactionCardState();
}

class _AnimatedTransactionCardState extends State<AnimatedTransactionCard> {
  // Animation controller for custom effects
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Format the date
    final date = widget.transaction.date;
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    
    // Format the amount with currency symbol
    final amount = widget.transaction.amount;
    final isExpense = amount < 0;
    final formattedAmount = isExpense 
        ? '-\$${amount.abs().toStringAsFixed(2)}' 
        : '\$${amount.toStringAsFixed(2)}';
    
    // Determine status color and text
    final statusText = widget.transaction.status.toString().split('.').last;
    final statusColor = widget.transaction.status == TransactionStatus.completed
        ? Colors.green 
        : widget.transaction.status == TransactionStatus.partial
            ? Colors.orange 
            : widget.transaction.status == TransactionStatus.pending
                ? Colors.blue
                : widget.transaction.status == TransactionStatus.failed
                    ? Colors.red
                    : Colors.grey;

    // We'll add isRecurring property to the Transaction model later

    // Build the card content
    final cardContent = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.transaction.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(widget.transaction.category),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Description and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.transaction.description ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedAmount,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isExpense ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(51), // 20% opacity (0.2 * 255 = 51)
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // We'll implement recurring transaction UI later when we add this to the model
              /* Recurring transaction UI will go here */
            ],
          ),
        ),
      ),
    )
    // Apply scale animation when pressed
    .animate(target: _isPressed ? 1 : 0)
    .scale(begin: const Offset(1.0, 1.0), end: const Offset(0.98, 0.98), duration: const Duration(milliseconds: 150), curve: Curves.easeInOut);

    // Wrap with dismissible for swipe actions if callbacks are provided
    if (widget.onDelete != null || widget.onEdit != null || widget.onTogglePaid != null) {
      return Dismissible(
        key: ValueKey(widget.transaction.id),
        background: _buildSwipeActionBackground(
          alignment: Alignment.centerLeft,
          color: Colors.blue,
          icon: Icons.edit,
          label: 'Edit',
        ),
        secondaryBackground: _buildSwipeActionBackground(
          alignment: Alignment.centerRight,
          color: Colors.red,
          icon: Icons.delete,
          label: 'Delete',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd && widget.onEdit != null) {
            widget.onEdit!(widget.transaction);
          } else if (direction == DismissDirection.endToStart && widget.onDelete != null) {
            // Show confirmation dialog
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
            
            if (result == true) {
              widget.onDelete!(widget.transaction);
            }
          }
          return false; // Don't actually dismiss, we handle the action manually
        },
        child: cardContent,
      )
      // Apply entrance animation
      .animate(delay: Duration(milliseconds: 50 * widget.index))
      .fadeIn(duration: const Duration(milliseconds: 300))
      .move(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint
      );
    }
    
    // If no swipe actions, just return the animated card
    return cardContent
      .animate(delay: Duration(milliseconds: 50 * widget.index))
      .fadeIn(duration: const Duration(milliseconds: 300))
      .move(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint
      );
  }

  // Helper method to build swipe action background
  Widget _buildSwipeActionBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[  
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: Colors.white),
          if (alignment == Alignment.centerLeft) ...[  
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to get category color
  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'utilities':
        return Colors.teal;
      case 'health':
        return Colors.red;
      case 'education':
        return Colors.indigo;
      case 'income':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get category icon
  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'utilities':
        return Icons.power;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'income':
        return Icons.account_balance_wallet;
      default:
        return Icons.category;
    }
  }
}
