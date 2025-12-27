import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../themes/app_theme.dart';
import '../../utils/enhanced_animations.dart';
import '../../utils/currency_extensions.dart';

/// A widget that displays upcoming payment due dates
/// with urgency indicators and action buttons
class UpcomingPaymentsWidget extends StatelessWidget {
  final List<UpcomingPayment> payments;
  final VoidCallback? onViewAll;
  final Function(UpcomingPayment payment)? onPayNow;

  const UpcomingPaymentsWidget({
    super.key,
    required this.payments,
    this.onViewAll,
    this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    final sortedPayments = List<UpcomingPayment>.from(payments)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

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
            // Header section with title and view all button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Payments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      'View All',
                      style: TextStyle(color: AppTheme.accentColor),
                    ),
                  ),
              ],
            )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 400))
            .slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            
            // Payment list with animated items
            sortedPayments.isEmpty
                ? _buildEmptyState(context)
                : Column(
                    children: List.generate(
                      sortedPayments.length > 3 ? 3 : sortedPayments.length,
                      (index) => _buildPaymentItem(
                        context,
                        sortedPayments[index],
                        index,
                      ),
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

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.green.shade300,
          )
          .animate()
          .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'No upcoming payments!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'All clear for now. Great job!',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      )
      .animate()
      .fadeIn()
      .slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildPaymentItem(BuildContext context, UpcomingPayment payment, int index) {
    // Determine status color based on due date
    final now = DateTime.now();
    final daysUntilDue = payment.dueDate.difference(now).inDays;
    
    Color statusColor;
    if (payment.isPaid) {
      statusColor = Colors.green.shade700; // Paid
    } else if (payment.dueDate.isBefore(now)) {
      statusColor = Colors.red.shade700; // Overdue
    } else if (daysUntilDue <= 3) {
      statusColor = Colors.orange.shade700; // Due soon
    } else {
      statusColor = Colors.blue.shade700; // Upcoming
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          )
          .animate(delay: Duration(milliseconds: 300 + (index * 100)))
          .scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.elasticOut),
          
          const SizedBox(width: 12),
          
          // Payment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      payment.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      payment.amount.toCurrency(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getStatusText(payment, daysUntilDue),
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(payment.dueDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Pay now button if not paid
          if (!payment.isPaid && onPayNow != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 32,
              child: EnhancedAnimations.animatedButton(
                TextButton(
                  onPressed: () => onPayNow!(payment),
                  style: TextButton.styleFrom(
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    'Pay Now',
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
                delayMillis: 400 + (index * 100),
              ),
            ),
          ],
        ],
      ),
    )
    .animate(delay: Duration(milliseconds: 200 + (index * 100)))
    .fadeIn()
    .slideX(begin: 0.1, end: 0);
  }

  String _getStatusText(UpcomingPayment payment, int daysUntilDue) {
    if (payment.isPaid) {
      return 'Paid';
    } else if (payment.dueDate.isBefore(DateTime.now())) {
      return 'Overdue';
    } else if (daysUntilDue == 0) {
      return 'Due Today';
    } else if (daysUntilDue == 1) {
      return 'Due Tomorrow';
    } else if (daysUntilDue <= 3) {
      return 'Due in $daysUntilDue days';
    } else {
      return 'Upcoming';
    }
  }
}

/// Model class for an upcoming payment
class UpcomingPayment {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final String? category;
  final String? accountId;

  const UpcomingPayment({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.category,
    this.accountId,
  });
}
