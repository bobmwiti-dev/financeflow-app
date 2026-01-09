import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../themes/app_theme.dart';

class GoalCard extends StatelessWidget {
  final String? heroTag;
  final String name;
  final double currentAmount;
  final double targetAmount;
  final DateTime targetDate;
  final String category;
  final VoidCallback onTap;
  final VoidCallback onAddFunds;

  static const double _radius = AppTheme.borderRadius;
  static const Color _accentColor = AppTheme.primaryColor;

  const GoalCard({
    super.key,
    this.heroTag,
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

    final content = _PressScale(
      child: Container(
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
          boxShadow: AppTheme.boxShadow,
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
      ),
    );

    if (heroTag == null) return content;

    return Hero(
      tag: heroTag!,
      child: Material(
        type: MaterialType.transparency,
        child: content,
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

class _PressScale extends StatefulWidget {
  final Widget child;

  const _PressScale({
    required this.child,
  });

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (!mounted) return;
        setState(() => _pressed = true);
      },
      onPointerUp: (_) {
        if (!mounted) return;
        setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        if (!mounted) return;
        setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: AppTheme.shortAnimationDuration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
