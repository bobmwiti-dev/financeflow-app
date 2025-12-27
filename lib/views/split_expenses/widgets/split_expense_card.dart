import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/split_expense_model.dart';
import '../../../themes/app_theme.dart';

class SplitExpenseCard extends StatelessWidget {
  final SplitExpenseModel expense;
  final VoidCallback onTap;

  const SplitExpenseCard({
    super.key,
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // Determine the status color
    Color statusColor;
    switch (expense.status) {
      case SplitExpenseStatus.fullyPaid:
        statusColor = AppTheme.successColor;
        break;
      case SplitExpenseStatus.partiallyPaid:
        statusColor = AppTheme.warningColor;
        break;
      case SplitExpenseStatus.pending:
        statusColor = AppTheme.infoColor;
        break;
      case SplitExpenseStatus.declined:
        statusColor = AppTheme.errorColor;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Created by ${expense.createdByName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat.yMMMd().format(expense.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(expense.totalAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha((255 * 0.1).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(expense.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildParticipantsRow(),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: expense.percentPaid / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${expense.percentPaid.toStringAsFixed(0)}% paid',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Remaining: ${currencyFormat.format(expense.amountRemaining)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: expense.amountRemaining > 0
                          ? AppTheme.warningColor
                          : AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    IconData iconData;
    Color iconColor;
    
    // Determine icon based on category
    switch (expense.category?.toLowerCase() ?? '') {
      case 'food & dining':
        iconData = Icons.restaurant;
        iconColor = Colors.orange;
        break;
      case 'housing':
        iconData = Icons.home;
        iconColor = Colors.blue;
        break;
      case 'entertainment':
        iconData = Icons.movie;
        iconColor = Colors.purple;
        break;
      case 'transportation':
        iconData = Icons.directions_car;
        iconColor = Colors.green;
        break;
      case 'utilities':
        iconData = Icons.lightbulb;
        iconColor = Colors.amber;
        break;
      case 'shopping':
        iconData = Icons.shopping_bag;
        iconColor = Colors.pink;
        break;
      default:
        iconData = Icons.receipt_long;
        iconColor = AppTheme.accentColor;
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withAlpha((255 * 0.1).round()),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildParticipantsRow() {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          ...List.generate(
            expense.participants.length > 4 
                ? 4 
                : expense.participants.length,
            (index) {
              final participant = expense.participants[index];
              return Align(
                widthFactor: 0.7,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: participant.hasPaid 
                      ? AppTheme.successColor.withAlpha((255 * 0.2).round()) 
                      : Colors.grey.shade200,
                  child: participant.hasPaid
                      ? const Icon(
                          Icons.check,
                          color: AppTheme.successColor,
                          size: 16,
                        )
                      : Text(
                          participant.name[0],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              );
            },
          ),
          if (expense.participants.length > 4)
            Align(
              widthFactor: 0.7,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  '+${expense.participants.length - 4}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${expense.participants.length} participants',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(SplitExpenseStatus status) {
    switch (status) {
      case SplitExpenseStatus.fullyPaid:
        return 'Fully Paid';
      case SplitExpenseStatus.partiallyPaid:
        return 'Partially Paid';
      case SplitExpenseStatus.pending:
        return 'Pending';
      case SplitExpenseStatus.declined:
        return 'Declined';
    }
  }
}
