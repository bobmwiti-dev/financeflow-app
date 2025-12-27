import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/enhanced_animations.dart';
import '../themes/app_theme.dart';

/// An animated transaction list item with modern UI effects
class AnimatedTransactionItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String date;
  final String amount;
  final IconData icon;
  final Color? color;
  final bool? isExpense;
  final VoidCallback? onTap;
  final int index;

  const AnimatedTransactionItem({
    super.key, 
    required this.title,
    this.subtitle,
    required this.date,
    required this.amount,
    required this.icon,
    this.color,
    this.isExpense,
    this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Default color if not provided
    final itemColor = color ?? Theme.of(context).primaryColor;
    final isExpenseValue = isExpense ?? (amount.startsWith('-'));
    
    final itemContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: itemColor.withValues(alpha: 13), // 0.05 * 255 ≈ 13
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: itemColor.withValues(alpha: 26), // 0.1 * 255 ≈ 26
          highlightColor: itemColor.withValues(alpha: 13), // 0.05 * 255 ≈ 13
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Transaction icon with background
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 26), // 0.1 * 255 ≈ 26
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: itemColor, size: 20),
                ),
                const SizedBox(width: 16),
                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isExpenseValue ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Apply staggered animation based on index
    return itemContent
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideX(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuint,
          duration: const Duration(milliseconds: 400),
        );
  }
}

/// A grouped list of animated transaction items
class AnimatedTransactionList extends StatelessWidget {
  final List<AnimatedTransactionItem> transactions;
  final String title;
  final String? subtitle;
  final bool showDivider;

  const AnimatedTransactionList({
    super.key,
    required this.transactions,
    required this.title,
    this.subtitle,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[  
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
            // View all button
            TextButton(
              onPressed: () {},
              child: Text('View All', style: TextStyle(color: AppTheme.accentColor)),
            ),
          ],
        ),
        if (showDivider) ...[  
          const Divider(),
          const SizedBox(height: 8),
        ],
        // Transaction list
        ...transactions,
      ],
    );
  }
}

/// A transaction category badge with subtle animation
class TransactionCategoryBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isSelected;

  const TransactionCategoryBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedAnimations.scaleOnTap(
      onTap: onTap ?? () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha: 0.2) 
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected 
                ? color 
                : color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : color.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal scrollable list of transaction category badges
class TransactionCategoryList extends StatelessWidget {
  final List<TransactionCategoryBadge> categories;
  final double spacing;

  const TransactionCategoryList({
    super.key,
    required this.categories,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (context, index) => categories[index]
            .animate(delay: Duration(milliseconds: 50 * index))
            .fadeIn()
            .slideX(begin: 0.2, end: 0),
      ),
    );
  }
}
