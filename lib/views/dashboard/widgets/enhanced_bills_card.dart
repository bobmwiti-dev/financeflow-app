import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import '../../../models/bill_reminder_model.dart';
import '../../../services/bill_service.dart';
import '../../../utils/category_icons.dart';
import '../../../utils/currency_extensions.dart';

/// Enhanced Bills & Subscriptions card with smart icons, interactive features, and urgency indicators
/// Dynamic filtering, animations, and intelligent bill categorization
class EnhancedBillsCard extends StatefulWidget {
  final VoidCallback? onViewAllBills;
  final Function(BillReminder)? onBillTap;
  final Function(BillReminder)? onMarkAsPaid;

  const EnhancedBillsCard({
    super.key,
    this.onViewAllBills,
    this.onBillTap,
    this.onMarkAsPaid,
  });

  @override
  State<EnhancedBillsCard> createState() => _EnhancedBillsCardState();
}

class _EnhancedBillsCardState extends State<EnhancedBillsCard> 
    with TickerProviderStateMixin {
  final Logger _logger = Logger('EnhancedBillsCard');
  late AnimationController _slideController;
  String _selectedFilter = 'Upcoming';
  final List<String> _filters = ['All', 'Upcoming', 'Overdue', 'Paid'];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: BillService.instance.getUpcomingBills(),
      builder: (context, snapshot) {
        final bills = <BillReminder>[];
        
        if (snapshot.hasData) {
          for (final billData in snapshot.data!) {
            try {
              bills.add(BillReminder(
                id: billData['id'] ?? '',
                title: billData['name'] ?? 'Unknown Bill',
                amount: (billData['amount'] as num?)?.toDouble() ?? 0.0,
                dueDate: (billData['dueDate'] as dynamic)?.toDate() ?? DateTime.now(),
                category: billData['category'] ?? 'Other',
                isPaid: billData['isPaid'] ?? false,
              ));
            } catch (e) {
              _logger.warning('Error parsing bill data: $e');
            }
          }
        }

        final filteredBills = _getFilteredBills(bills);
        final urgentBills = _getUrgentBills(bills);
        final totalUpcoming = bills.where((b) => !b.isPaid && b.dueDate.isAfter(DateTime.now())).length;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.98),
                colorScheme.surface.withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(urgentBills.length, totalUpcoming),
                _buildUrgencyIndicator(urgentBills),
                _buildFilterChips(),
                _buildBillsList(filteredBills, snapshot.connectionState == ConnectionState.waiting),
                _buildFooter(),
              ],
            ),
          ),
        ).animate()
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildHeader(int urgentCount, int totalUpcoming) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bills & Subscriptions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                totalUpcoming == 0
                    ? 'You\'re all caught up'
                    : '$totalUpcoming upcoming bill${totalUpcoming == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (urgentCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.onErrorContainer,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$urgentCount urgent',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyIndicator(List<BillReminder> urgentBills) {
    if (urgentBills.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.error.withValues(alpha: 0.08),
            colorScheme.tertiary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high, color: colorScheme.error, size: 18),
              const SizedBox(width: 8),
              Text(
                'Urgent Bills Requiring Attention',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...urgentBills.take(2).map((bill) => _buildUrgentBillItem(bill)),
          if (urgentBills.length > 2)
            Text(
              '+ ${urgentBills.length - 2} more urgent bills',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 12,
                color: colorScheme.error,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUrgentBillItem(BillReminder bill) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final daysOverdue = DateTime.now().difference(bill.dueDate).inDays;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.red[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${bill.title} - ${bill.amount.toKenyaDualCurrency()}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            daysOverdue > 0 ? '${daysOverdue}d overdue' : 'Due today',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              backgroundColor: colorScheme.surfaceContainerLowest,
              selectedColor: colorScheme.primary.withValues(alpha: 0.16),
              checkmarkColor: colorScheme.primary,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBillsList(List<BillReminder> bills, bool isLoading) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (bills.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return _buildBillTile(bill, index);
      },
    );
  }

  Widget _buildBillTile(BillReminder bill, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final daysUntilDue = bill.dueDate.difference(now).inDays;
    
    // Determine urgency level and colors
    Color urgencyColor;
    String urgencyText;
    IconData urgencyIcon;
    
    if (bill.isPaid) {
      urgencyColor = colorScheme.primary;
      urgencyText = 'Paid';
      urgencyIcon = Icons.check_circle;
    } else if (daysUntilDue < 0) {
      urgencyColor = colorScheme.error;
      urgencyText = '${-daysUntilDue}d overdue';
      urgencyIcon = Icons.error;
    } else if (daysUntilDue == 0) {
      urgencyColor = colorScheme.tertiary;
      urgencyText = 'Due today';
      urgencyIcon = Icons.today;
    } else if (daysUntilDue == 1) {
      urgencyColor = colorScheme.tertiary;
      urgencyText = 'Due tomorrow';
      urgencyIcon = Icons.schedule;
    } else if (daysUntilDue <= 3) {
      urgencyColor = colorScheme.secondary;
      urgencyText = 'Due in ${daysUntilDue}d';
      urgencyIcon = Icons.schedule;
    } else {
      urgencyColor = colorScheme.outlineVariant;
      urgencyText = 'Due ${DateFormat.MMMd().format(bill.dueDate)}';
      urgencyIcon = Icons.schedule;
    }

    // Get smart brand icon and color (prioritizes brand detection over category)
    final categoryIcon = CategoryIcons.getBrandIcon(bill.title);
    final categoryColor = CategoryIcons.getBrandColor(bill.title);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: bill.isPaid ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bill.isPaid
              ? colorScheme.primary.withValues(alpha:0.25)
              : (daysUntilDue <= 0
                  ? colorScheme.error.withValues(alpha:0.35)
                  : colorScheme.outlineVariant.withValues(alpha:0.4)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onBillTap?.call(bill);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
                children: [
                  // Smart Category Icon with Animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          categoryColor.withValues(alpha: 0.1),
                          categoryColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: 28,
                        ),
                        if (!bill.isPaid && daysUntilDue <= 1)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Bill Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            decoration: bill.isPaid ? TextDecoration.lineThrough : null,
                            color: bill.isPaid ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Urgency Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: urgencyColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: urgencyColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    urgencyIcon,
                                    size: 12,
                                    color: urgencyColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    urgencyText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: urgencyColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Category Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                bill.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: categoryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount and Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bill.amount.toKenyaDualCurrency(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.1,
                          color: bill.isPaid ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                          decoration: bill.isPaid ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!bill.isPaid && widget.onMarkAsPaid != null)
                        GestureDetector(
                          onTap: () => widget.onMarkAsPaid!(bill),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary.withValues(alpha: 0.1),
                                  colorScheme.primary.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Mark Paid',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ).animate()
                            .scale(begin: const Offset(0.95, 0.95), duration: 200.ms)
                            .then()
                            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), duration: 200.ms)
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    ).animate(delay: (index * 100).ms)
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic)
        .scale(begin: const Offset(0.95, 0.95), duration: 400.ms);
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateTitle(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pushNamed(context, '/add_bill');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Bill'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Smart bill tracking & reminders',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (widget.onViewAllBills != null)
            TextButton(
              onPressed: widget.onViewAllBills,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<BillReminder> _getFilteredBills(List<BillReminder> bills) {
    switch (_selectedFilter) {
      case 'Upcoming':
        return bills.where((b) => !b.isPaid && b.dueDate.isAfter(DateTime.now())).toList();
      case 'Overdue':
        return bills.where((b) => !b.isPaid && b.dueDate.isBefore(DateTime.now())).toList();
      case 'Paid':
        return bills.where((b) => b.isPaid).toList();
      default:
        return bills;
    }
  }

  List<BillReminder> _getUrgentBills(List<BillReminder> bills) {
    final now = DateTime.now();
    return bills.where((bill) {
      if (bill.isPaid) return false;
      final daysUntilDue = bill.dueDate.difference(now).inDays;
      return daysUntilDue <= 1; // Due today or overdue
    }).toList();
  }

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 'Upcoming':
        return 'No upcoming bills';
      case 'Overdue':
        return 'No overdue bills';
      case 'Paid':
        return 'No paid bills';
      default:
        return 'No bills yet';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedFilter) {
      case 'Upcoming':
        return 'All your bills are up to date!';
      case 'Overdue':
        return 'Great! You\'re on top of your bills.';
      case 'Paid':
        return 'Paid bills will appear here.';
      default:
        return 'Add your bills to track due dates and never miss a payment.';
    }
  }
}
