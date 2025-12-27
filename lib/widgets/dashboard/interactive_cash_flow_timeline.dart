import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../utils/enhanced_animations.dart';

/// An interactive timeline showing upcoming cash flows (income and expenses)
/// with visual indicators and smooth animations
class InteractiveCashFlowTimeline extends StatefulWidget {
  final List<CashFlowEvent> events;
  final DateTime? startDate;
  final int visibleDays;
  final Function(CashFlowEvent)? onEventTap;

  const InteractiveCashFlowTimeline({
    super.key,
    required this.events,
    this.startDate,
    this.visibleDays = 14,
    this.onEventTap,
  });

  @override
  State<InteractiveCashFlowTimeline> createState() => _InteractiveCashFlowTimelineState();
}

class _InteractiveCashFlowTimelineState extends State<InteractiveCashFlowTimeline> {
  late ScrollController _scrollController;
  late List<DateTime> _timelineDates;
  late List<CashFlowEvent> _sortedEvents;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeTimeline();
  }
  
  @override
  void didUpdateWidget(InteractiveCashFlowTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events || 
        oldWidget.startDate != widget.startDate ||
        oldWidget.visibleDays != widget.visibleDays) {
      _initializeTimeline();
    }
  }
  
  void _initializeTimeline() {
    // Use current date if startDate is null
    final effectiveStartDate = widget.startDate ?? DateTime.now();
    
    // Create dates for the timeline
    _timelineDates = List.generate(
      widget.visibleDays,
      (index) => DateTime(
        effectiveStartDate.year,
        effectiveStartDate.month,
        effectiveStartDate.day + index,
      ),
    );
    
    // Sort events by date
    _sortedEvents = List.from(widget.events);
    _sortedEvents.sort((a, b) => a.date.compareTo(b.date));
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cash Flow Timeline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Scroll left button
                    EnhancedAnimations.scaleOnTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _scrollController.animateTo(
                          _scrollController.offset - 200,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios, size: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Scroll right button
                    EnhancedAnimations.scaleOnTap(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _scrollController.animateTo(
                          _scrollController.offset + 200,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios, size: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Timeline visualization
            SizedBox(
              height: 150,
              child: _buildTimeline(),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 600))
    .slideY(begin: 0.05, end: 0);
  }
  
  Widget _buildTimeline() {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _timelineDates.map((date) {
          return _buildDateColumn(date);
        }).toList(),
      ),
    );
  }
  
  Widget _buildDateColumn(DateTime date) {
    // Get events for this date
    final dayEvents = _sortedEvents.where(
      (event) => event.date.year == date.year &&
                  event.date.month == date.month &&
                  event.date.day == date.day
    ).toList();
    
    // Calculate net cash flow for the day
    double netCashFlow = 0;
    for (var event in dayEvents) {
      netCashFlow += event.isIncome ? event.amount : -event.amount;
    }
    
    // Determine if this is today
    final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                    
    // Build the column for this date
    return Container(
      width: 85,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isToday 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEE').format(date), // Day of week
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(date), // Month and day
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          
          // Events container
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: dayEvents.isEmpty
                  ? const Center(child: Text('No events', style: TextStyle(fontSize: 10)))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // List of events for this day (limit to 2)
                        ...dayEvents.take(2).map((event) => _buildEventItem(event)),
                        
                        // Show count if more than 2 events
                        if (dayEvents.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+${dayEvents.length - 2} more',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          
                        // Net flow indicator
                        const Spacer(),
                        _buildNetFlowIndicator(netCashFlow),
                      ],
                    ),
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 400))
    .moveY(begin: 20, end: 0, curve: Curves.easeOutQuint);
  }
  
  Widget _buildEventItem(CashFlowEvent event) {
    return EnhancedAnimations.scaleOnTap(
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.onEventTap != null) {
          widget.onEventTap!(event);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: event.isIncome 
              ? Colors.green.shade700.withValues(alpha: 0.15)
              : Colors.red.shade700.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              event.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              size: 10,
              color: event.isIncome ? Colors.green.shade700 : Colors.red.shade700,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                '\$${event.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: event.isIncome ? Colors.green.shade700 : Colors.red.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNetFlowIndicator(double netCashFlow) {
    final isPositive = netCashFlow > 0;
    final color = isPositive ? Colors.green.shade700 : Colors.red.shade700;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${isPositive ? '+' : ''}\$${netCashFlow.abs().toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Model class for cash flow events
class CashFlowEvent {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String category;
  final bool isRecurring;

  const CashFlowEvent({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.category,
    this.isRecurring = false,
  });
}
