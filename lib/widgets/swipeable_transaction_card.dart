import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';  // Import for Ticker
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/enhanced_animations.dart';
import '../themes/app_theme.dart';

/// A modern swipeable transaction card with animated actions
/// Allows users to swipe left/right to reveal action buttons
class SwipeableTransactionCard extends StatefulWidget {
  final String title;
  final String date;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isExpense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final int index;

  const SwipeableTransactionCard({
    super.key, 
    required this.title,
    required this.date,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isExpense,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.index = 0,
  });

  @override
  State<SwipeableTransactionCard> createState() => _SwipeableTransactionCardState();
}

class _SwipeableTransactionCardState extends State<SwipeableTransactionCard> {
  final double _actionThreshold = 0.3; // Threshold to trigger actions
  
  // Controller for manual animation
  late AnimationController _controller;
  // Track if card is being dismissed
  bool _isBeingDismissed = false;
  // Track the swipe action direction (for feedback)
  DismissDirection? _swipeDirection;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: ticker);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Handle swipe action feedback
  void _onSlideUpdate(double progress) {
    if (progress >= _actionThreshold && !_isBeingDismissed) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isBeingDismissed = true;
        // Store direction for visual feedback
        if (progress < 0) {
          _swipeDirection = DismissDirection.startToEnd; // Edit action
        } else {
          _swipeDirection = DismissDirection.endToStart; // Delete action
        }
      });
    } else if (progress < _actionThreshold && _isBeingDismissed) {
      setState(() => _isBeingDismissed = false);
    } else if (progress == 0) {
      setState(() => _swipeDirection = null); // Reset on release
    }
  }

  @override
  Widget build(BuildContext context) {
    // Item content (the actual transaction card)
    final itemContent = _buildTransactionCard();
    
    // Apply staggered animation based on index
    final animatedItem = itemContent
        .animate(delay: Duration(milliseconds: 50 * widget.index))
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideX(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuint,
          duration: const Duration(milliseconds: 400),
        );
        
    // Add subtle rotation based on swipe direction for enhanced feedback
    final enhancedFeedbackItem = _swipeDirection != null
        ? animatedItem.animate(key: ValueKey(_swipeDirection))
            .rotate(
              begin: 0,
              end: _swipeDirection == DismissDirection.startToEnd ? 0.01 : -0.01,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 200),
            )
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(0.98, 0.98),
              curve: Curves.easeOut,
            )
        : animatedItem;

    // Wrap in dismissible for swipe actions
    return Dismissible(
      key: ValueKey('transaction-${widget.title}-${widget.date}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        // Execute the corresponding action
        if (direction == DismissDirection.endToStart && widget.onDelete != null) {
          widget.onDelete!();
          return true;
        } else if (direction == DismissDirection.startToEnd && widget.onEdit != null) {
          widget.onEdit!();
          // Don't actually dismiss for edit action
          return false;
        }
        return false;
      },
      onUpdate: (details) {
        _onSlideUpdate(details.progress);
      },
      // Edit action background (right to left swipe)
      background: _buildActionBackground(
        alignment: Alignment.centerLeft,
        color: Colors.blue.shade700,
        icon: Icons.edit,
        label: 'Edit',
      ),
      // Delete action background (left to right swipe)
      secondaryBackground: _buildActionBackground(
        alignment: Alignment.centerRight,
        color: Colors.red.shade700,
        icon: Icons.delete,
        label: 'Delete',
      ),
      // Use the enhanced feedback item that responds to swipe direction
      child: enhancedFeedbackItem,
    );
  }

  // Build the transaction card content
  Widget _buildTransactionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: widget.color.withValues(alpha: 0.1),
          highlightColor: widget.color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Transaction icon with background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 20),
                ),
                const SizedBox(width: 16),
                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.date,
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
                  widget.amount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isExpense ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build the action background that appears when swiping
  Widget _buildActionBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[  
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          if (alignment == Alignment.centerLeft) ...[  
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // Create a ticker provider for animations
  TickerProvider get ticker => _TickerProviderImpl();
}

// A simple ticker provider implementation
class _TickerProviderImpl implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}

/// A list of swipeable transaction cards with grouped header
class SwipeableTransactionList extends StatelessWidget {
  final List<SwipeableTransactionCard> transactions;
  final String title;
  final String? subtitle;
  final bool showDivider;
  final VoidCallback? onViewAll;

  const SwipeableTransactionList({
    super.key,
    required this.transactions,
    required this.title,
    this.subtitle,
    this.showDivider = true,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with animation
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
                )
                .animate()
                .fadeIn()
                .slideX(begin: -0.1, end: 0),
                if (subtitle != null) ...[  
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  )
                  .animate(delay: const Duration(milliseconds: 200))
                  .fadeIn()
                  .slideX(begin: -0.1, end: 0),
                ],
              ],
            ),
            // View all button with animation
            EnhancedAnimations.animatedButton(
              TextButton(
                onPressed: onViewAll,
                child: Text('View All', style: TextStyle(color: AppTheme.accentColor)),
              ),
              delayMillis: 300,
            ),
          ],
        ),
        if (showDivider) ...[  
          const Divider().animate().fadeIn(delay: const Duration(milliseconds: 400)),
          const SizedBox(height: 8),
        ],
        // Transaction list with staggered animations
        ...transactions,
      ],
    );
  }
}
