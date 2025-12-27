import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../utils/enhanced_animations.dart';
import '../../utils/currency_extensions.dart';

/// A summary of recurring transactions showing subscriptions and regular expenses
/// with visual indicators for financial health and optimization suggestions
class RecurringTransactionsSummary extends StatefulWidget {
  final List<RecurringTransaction> transactions;
  final double monthlyIncome;
  final double recommendedPercentage; // Max percentage of income for recurring costs
  final Function(RecurringTransaction)? onTransactionTap;
  final VoidCallback? onViewAll;
  final VoidCallback? onOptimize;

  const RecurringTransactionsSummary({
    super.key,
    required this.transactions,
    required this.monthlyIncome,
    this.recommendedPercentage = 0.5, // 50% by default
    this.onTransactionTap,
    this.onViewAll,
    this.onOptimize,
  });

  @override
  State<RecurringTransactionsSummary> createState() => _RecurringTransactionsSummaryState();
}

class _RecurringTransactionsSummaryState extends State<RecurringTransactionsSummary> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final totalRecurring = widget.transactions.fold(
        0.0, (sum, item) => sum + item.amount);
    final percentOfIncome = widget.monthlyIncome > 0
        ? totalRecurring / widget.monthlyIncome
        : 0.0;
    
    // Determine status color based on percentage of income
    final isHealthy = percentOfIncome <= widget.recommendedPercentage;
    final statusColor = isHealthy ? Colors.green.shade700 : Colors.red.shade700;
    
    // Sort transactions by amount (highest first)
    final sortedTransactions = List<RecurringTransaction>.from(widget.transactions)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    
    // Determine how many transactions to show based on expansion state
    final displayCount = _isExpanded
        ? sortedTransactions.length
        : sortedTransactions.length > 3 ? 3 : sortedTransactions.length;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recurring Expenses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (widget.onViewAll != null)
                  TextButton(
                    onPressed: widget.onViewAll,
                    child: const Text('View All'),
                  ),
              ],
            )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 400))
            .slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            
            // Health indicator section
            _buildHealthIndicator(totalRecurring, percentOfIncome, statusColor, isHealthy),
            
            const SizedBox(height: 16),
            
            // Transactions list
            sortedTransactions.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      // Transactions list (limited by displayCount)
                      ...List.generate(
                        displayCount,
                        (index) => _buildTransactionItem(sortedTransactions[index], index),
                      ),
                      
                      // Show/hide button
                      if (sortedTransactions.length > 3)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_isExpanded ? 'Show Less' : 'Show All'),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
            // Optimization button
            if (!isHealthy && widget.onOptimize != null)
              Center(
                child: EnhancedAnimations.animatedButton(
                  ElevatedButton.icon(
                    onPressed: widget.onOptimize,
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Optimize Expenses'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  delayMillis: 500,
                ),
              ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 800))
    .moveY(begin: 30, end: 0, curve: Curves.easeOutQuint);
  }

  Widget _buildHealthIndicator(
    double totalRecurring,
    double percentOfIncome,
    Color statusColor,
    bool isHealthy,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with total and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalRecurring.toCurrency(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      isHealthy ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHealthy ? 'Healthy' : 'High',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .shimmer(
                delay: const Duration(milliseconds: 800),
                duration: const Duration(milliseconds: 2000),
                color: statusColor.withValues(alpha: 0.5),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress bar showing percentage of income
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(percentOfIncome * 100).toStringAsFixed(1)}% of Income',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    'Target: ${(widget.recommendedPercentage * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  // Background track
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Filled portion
                  FractionallySizedBox(
                    widthFactor: percentOfIncome > 1.0 ? 1.0 : percentOfIncome,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn()
                  .slideX(begin: -1.0, end: 0.0, curve: Curves.easeOutQuart, duration: const Duration(milliseconds: 1000)),
                  // Target marker
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.8 * widget.recommendedPercentage - 32,
                    child: Container(
                      width: 2,
                      height: 8,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 400))
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.repeat,
            size: 48,
            color: Colors.grey.shade300,
          )
          .animate()
          .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'No recurring transactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add recurring expenses to track your subscriptions and bills',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(RecurringTransaction transaction, int index) {
    return EnhancedAnimations.scaleOnTap(
      onTap: () {
        HapticFeedback.selectionClick();
        if (widget.onTransactionTap != null) {
          widget.onTransactionTap!(transaction);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: transaction.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                transaction.icon ?? Icons.repeat,
                color: transaction.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${transaction.frequencyDescription} • ${transaction.category}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
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
                  transaction.amount.toCurrency(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  transaction.nextDueDate != null
                      ? 'Next: ${DateFormat('MMM d').format(transaction.nextDueDate!)}'
                      : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
    .animate(delay: Duration(milliseconds: 100 * index))
    .fadeIn()
    .slideY(begin: 0.1, end: 0);
  }
}

/// Model class for recurring transactions
class RecurringTransaction {
  final String id;
  final String name;
  final double amount;
  final String category;
  final String frequency; // monthly, weekly, quarterly, yearly
  final Color color;
  final IconData? icon;
  final DateTime? nextDueDate;
  final bool isEssential;

  const RecurringTransaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.color,
    this.icon,
    this.nextDueDate,
    this.isEssential = false,
  });

  String get frequencyDescription {
    switch (frequency.toLowerCase()) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
      case 'annual':
        return 'Yearly';
      default:
        return frequency;
    }
  }
}
