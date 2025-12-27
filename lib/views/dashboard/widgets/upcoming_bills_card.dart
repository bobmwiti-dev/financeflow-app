import 'package:provider/provider.dart';
import 'package:financeflow_app/viewmodels/bill_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:financeflow_app/utils/currency_extensions.dart';
import 'package:financeflow_app/models/bill_model.dart';
import 'package:financeflow_app/constants/app_constants.dart'; // For routes

class UpcomingBillsCard extends StatefulWidget {
  const UpcomingBillsCard({super.key});

  @override
  State<UpcomingBillsCard> createState() => _UpcomingBillsCardState();
}

class _UpcomingBillsCardState extends State<UpcomingBillsCard> {
  late Future<List<Bill>> _upcomingFuture;
  BillViewModel? _billViewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = Provider.of<BillViewModel>(context, listen: false);
    if (_billViewModel != vm) {
      _billViewModel = vm;
      _upcomingFuture = _billViewModel!.getUpcomingBills(limit: 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Bill>>(
      future: _upcomingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snapshot.hasError) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading upcoming bills: ${snapshot.error}'),
            )
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bills & Subscriptions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 40, color: Theme.of(context).disabledColor),
                        const SizedBox(height: 8),
                        Text('No upcoming bills found.', style: TextStyle(color: Theme.of(context).disabledColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final now = DateTime.now();
        final bills = snapshot.data!
            .where((b) => b.dueDate.difference(now).inDays <= 7 && b.dueDate.isAfter(now.subtract(const Duration(days:1))))
            .toList();
        if (bills.isEmpty) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bills & Subscriptions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 40, color: Theme.of(context).disabledColor),
                        const SizedBox(height: 8),
                        Text('No bills or subscriptions in the next 7 days.', style: TextStyle(color: Theme.of(context).disabledColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bills & Subscriptions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (bills.length > 3) // Or some other logic if you want 'View All' always
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppConstants.scheduledPaymentsRoute);
                        },
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    final dueDate = bill.dueDate;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.onSecondaryContainer),
                      ),
                      title: Text(bill.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('Due: ${DateFormat('MMM d, yyyy').format(dueDate)}'),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            bill.amount.toCurrency(),
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(height:4),
                          _buildStatusChip(bill),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppConstants.transactionDetailsRoute,
                          arguments: bill.id,
                        );
                      },
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(Bill bill) {
    final status = _computeStatus(bill);
    Color color;
    Color textColor;

    switch (status) {
      case 'Auto-pay':
        color = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'Negotiable':
        color = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      default:
        color = Colors.red.shade100;
        textColor = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w500)),
    );
  }

  String _computeStatus(Bill bill) {
    if (bill.autoPay) {
      return 'Auto-pay';
    }

    const negotiableCategories = ['utilities', 'internet', 'phone', 'insurance'];
    if (negotiableCategories.contains(bill.category?.toLowerCase())) {
      return 'Negotiable';
    }

    const subscriptionKeywords = ['netflix', 'spotify', 'showmax', 'amazon', 'dstv', 'gym'];
    if (bill.isRecurring && (bill.category?.toLowerCase() == 'subscription' || subscriptionKeywords.any(bill.name.toLowerCase().contains))) {
      return 'Consider cancelling';
    }

    return 'Pay'; // Default status for other bills
  }
}
