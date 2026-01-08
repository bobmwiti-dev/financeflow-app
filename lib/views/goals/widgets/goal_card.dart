import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../themes/app_theme.dart';

class GoalCard extends StatelessWidget {
  final String name;
  final double currentAmount;
  final double targetAmount;
  final DateTime targetDate;
  final String category;
  final VoidCallback onTap;
  final VoidCallback onAddFunds;

  static const double _radius = 24;
  static const Color _accentColor = Color(0xFF6366F1);

  const GoalCard({
    super.key,
    required this.name,
    required this.currentAmount,
    required this.targetAmount,
    required this.targetDate,
    required this.category,
    required this.onTap,
    required this.onAddFunds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final progress = (targetAmount > 0) ? (currentAmount / targetAmount) : 0.0;
    final daysLeft = targetDate.difference(DateTime.now()).inDays;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCircularProgress(progress),
                    const SizedBox(width: 16),
                    _buildGoalDetails(currencyFormat, daysLeft),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return AppTheme.errorColor;
    } else if (progress < 0.7) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.successColor;
    }
  }

  Widget _buildCircularProgress(double progress) {
    return CircularPercentIndicator(
      radius: 45.0,
      lineWidth: 8.0,
      animation: true,
      percent: progress,
      center: Text(
        "${(progress * 100).toStringAsFixed(1)}%",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ),
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: _getProgressColor(progress),
      backgroundColor: Colors.grey.shade200,
    );
  }

  Widget _buildGoalDetails(NumberFormat currencyFormat, int daysLeft) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              children: [
                TextSpan(
                  text: currencyFormat.format(currentAmount),
                  style: TextStyle(
                    color: _getProgressColor(currentAmount / (targetAmount == 0 ? 1 : targetAmount)),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: ' of ${currencyFormat.format(targetAmount)}'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            daysLeft > 0
                ? '$daysLeft days left'
                : 'Target date reached',
            style: TextStyle(
              fontSize: 12,
              color: daysLeft < 7 ? AppTheme.errorColor : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onTap,
          child: const Text('Details'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: onAddFunds,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Funds'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: _accentColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
