import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/cash_flow_service.dart';
import '../../widgets/dashboard/interactive_cash_flow_timeline.dart';

/// Screen that shows all upcoming predicted income/expense events in a scrollable timeline.
class UpcomingEventsScreen extends StatefulWidget {
  const UpcomingEventsScreen({super.key});

  @override
  State<UpcomingEventsScreen> createState() => _UpcomingEventsScreenState();
}

class _UpcomingEventsScreenState extends State<UpcomingEventsScreen> {
  bool _isLoading = true;
  List<PredictedEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final events = await CashFlowService.instance.getUpcomingEvents(limit: 60);
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Events')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('No upcoming events found.'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Interactive timeline (14-day window starting today)
                        InteractiveCashFlowTimeline(
                          events: _events
                              .map((e) => CashFlowEvent(
                                    id: '',
                                    title: e.title,
                                    amount: e.amount,
                                    date: e.date,
                                    isIncome: e.isIncome,
                                    category: '',
                                    isRecurring: e.isRecurring,
                                  ))
                              .toList(),
                          visibleDays: 30,
                          onEventTap: (ev) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(ev.title),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date: ${DateFormat.yMMMEd().format(ev.date)}'),
                                    Text('Amount: \$${ev.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            color: ev.isIncome ? Colors.green : Colors.red)),
                                    if (ev.isRecurring) const Text('Recurring'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Simple list of all events sorted
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _events.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final e = _events[index];
                            final dateStr = DateFormat.yMMMd().format(e.date);
                            final amountStr = (e.isIncome ? '+' : '-') + e.amount.toStringAsFixed(2);
                            final amountColor = e.isIncome ? Colors.green : Colors.red;
                            return ListTile(
                              leading: Icon(
                                e.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                color: amountColor,
                              ),
                              title: Text(e.title),
                              subtitle: Text(dateStr),
                              trailing: Text(
                                '\$$amountStr',
                                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ),
    );
  }
}
