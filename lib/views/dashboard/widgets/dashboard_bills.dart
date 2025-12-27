import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../models/bill.dart';

/// Dashboard bills widget showing upcoming bills and payment reminders
class DashboardBills extends StatelessWidget {
  final List<dynamic> bills;
  final int maxItems;
  final Function(Bill)? onBillTap;
  final Function(String)? onMarkAsPaid;

  const DashboardBills({
    super.key,
    required this.bills,
    this.maxItems = 3,
    this.onBillTap,
    this.onMarkAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    final upcomingBills = bills.isEmpty 
        ? [] 
        : bills
            .where((bill) => !bill.isPaid)
            .take(maxItems)
            .toList();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1 * 255),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Bills',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/bills');
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (upcomingBills.isEmpty)
              _buildEmptyState()
            else
              ...upcomingBills.asMap().entries.map(
                (entry) => _buildBillItem(
                  context,
                  entry.value,
                  delay: 100.ms + (entry.key * 50).ms,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget when no bills are available
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming bills',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add bills and reminders to track your upcoming payments',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  /// Build a bill item in the list
  Widget _buildBillItem(
    BuildContext context, 
    Bill bill,
    {required Duration delay}
  ) {
    final dateFormat = DateFormat('MMM d');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // Get status color based on due date
    Color statusColor;
    String statusText;
    
    if (bill.isPaid) {
      statusColor = Colors.green;
      statusText = 'Paid';
    } else if (bill.daysRemaining < 0) {
      statusColor = Colors.red;
      statusText = 'Overdue';
    } else if (bill.daysRemaining == 0) {
      statusColor = Colors.orange;
      statusText = 'Due Today';
    } else if (bill.daysRemaining <= 3) {
      statusColor = Colors.amber;
      statusText = 'Due Soon';
    } else {
      statusColor = Colors.blue;
      statusText = 'Upcoming';
    }
    
    return InkWell(
      onTap: () {
        if (onBillTap != null) {
          onBillTap!(bill);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1 * 255),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                bill.getIcon(),
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Due ${dateFormat.format(bill.dueDate)} • ${bill.category}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(bill.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1 * 255),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (!bill.isPaid && onMarkAsPaid != null) Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: Icon(
                  Icons.check_circle_outline,
                  color: Colors.grey[400],
                  size: 22,
                ),
                onPressed: () {
                  onMarkAsPaid!(bill.id);
                },
                tooltip: 'Mark as paid',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay, duration: 300.ms).slideX(begin: 0.2, end: 0);
  }
}
