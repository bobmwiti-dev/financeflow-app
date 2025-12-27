import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/enhanced_animations.dart';
import '../../views/income/income_form_screen.dart';

/// A grid of quick action buttons for common financial tasks
/// Designed to provide easy access to key features from the dashboard
class QuickActionsPanel extends StatelessWidget {
  final VoidCallback? onPayBills;
  final VoidCallback? onSetBudgetAlert;
  final VoidCallback? onTransferFunds;
  final VoidCallback? onSchedulePayment;

  const QuickActionsPanel({
    super.key,
    this.onPayBills,
    this.onSetBudgetAlert,
    this.onTransferFunds,
    this.onSchedulePayment,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 400))
            .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: _buildActionButtons(context),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 800))
    .moveY(begin: 30, end: 0, curve: Curves.easeOutQuint);
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.receipt_long,
        label: 'Pay Bills',
        color: Colors.blue.shade700,
        onTap: () {
          HapticFeedback.mediumImpact();
          if (onPayBills != null) onPayBills!();
        },
      ),
      _ActionItem(
        icon: Icons.notifications_active,
        label: 'Budget Alert',
        color: Colors.orange.shade700,
        onTap: () {
          HapticFeedback.mediumImpact();
          if (onSetBudgetAlert != null) onSetBudgetAlert!();
        },
      ),
      _ActionItem(
        icon: Icons.sync_alt,
        label: 'Transfer',
        color: Colors.green.shade700,
        onTap: () {
          HapticFeedback.mediumImpact();
          if (onTransferFunds != null) onTransferFunds!();
        },
      ),
      _ActionItem(
        icon: Icons.schedule,
        label: 'Schedule',
        color: Colors.purple.shade700,
        onTap: () {
          HapticFeedback.mediumImpact();
          if (onSchedulePayment != null) onSchedulePayment!();
        },
      ),
      _ActionItem(
        icon: Icons.attach_money,
        label: 'Add Income',
        color: Colors.green.shade600,
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IncomeFormScreen()),
          );
        },
      ),
    ];

    // Apply staggered animations to the buttons
    return List.generate(
      actions.length,
      (index) => actions[index]
          .animate(delay: Duration(milliseconds: 100 * (index + 1)))
          .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut)
          .fadeIn(duration: const Duration(milliseconds: 400)),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedAnimations.scaleOnTap(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
