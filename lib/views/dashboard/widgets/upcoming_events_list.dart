import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/cash_flow_service.dart';


/// Compact card that shows the next few predicted cash-flow events (income or expense).
/// Similar to Simplifi's "Upcoming" section.
class UpcomingEventsList extends StatelessWidget {
  final List<PredictedEvent> events;
  final bool isLoading;
  final VoidCallback onViewAll;

  const UpcomingEventsList({
    super.key,
    required this.events,
    required this.isLoading,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (events.isEmpty)
              const Text('No upcoming events found.')
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: events.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final e = events[index];
                  final dateStr = DateFormat.MMMd().format(e.date);
                  final amountStr = (e.isIncome ? '+' : '-') + e.amount.toStringAsFixed(2);
                  final amountColor = e.isIncome ? Colors.green : Colors.red;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      e.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: amountColor,
                    ),
                    title: Text(
                      e.title.isNotEmpty ? e.title : (e.isIncome ? 'Income' : 'Expense'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      children: [
                        Text(dateStr),
                        if (e.isRecurring) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.autorenew, size: 14, color: Colors.blueGrey),
                        ]
                      ],
                    ),
                    trailing: Text(
                      '\$$amountStr',
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
