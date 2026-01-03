import 'package:provider/provider.dart';
import 'package:financeflow_app/viewmodels/bill_viewmodel.dart';
import 'package:financeflow_app/viewmodels/insights_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _requestedInsights = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = Provider.of<BillViewModel>(context, listen: false);
    if (_billViewModel != vm) {
      _billViewModel = vm;
      _upcomingFuture = _billViewModel!.getUpcomingBills(limit: 10);
    }

    if (!_requestedInsights) {
      _requestedInsights = true;
      final insightsVm = Provider.of<InsightsViewModel>(context, listen: false);
      insightsVm.loadInsights();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Bill>>(
      future: _upcomingFuture,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snapshot.hasError) {
          return _buildBaseSurface(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading upcoming bills: ${snapshot.error}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildBaseSurface(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 40,
                          color: colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No upcoming bills found.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
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
          return _buildBaseSurface(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 40,
                          color: colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No bills or subscriptions in the next 7 days.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildBaseSurface(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Bills & Subscriptions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Consumer<InsightsViewModel>(
                          builder: (context, insightsVm, _) {
                            final now = DateTime.now();
                            final subscriptionInsights = insightsVm.insights.where((insight) {
                              final data = insight.data;
                              if (data == null) return false;
                              final hasSubFields = data['payee'] != null && data['amount'] != null;
                              final typeLower = insight.type.toLowerCase();
                              final isSubscriptionInsight =
                                  typeLower.contains('subscription') || typeLower.contains('recommendation');
                              final isRecent = insight.date.isAfter(now.subtract(const Duration(days: 60)));
                              return hasSubFields && isSubscriptionInsight && isRecent;
                            }).toList();

                            if (subscriptionInsights.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final colorScheme = Theme.of(context).colorScheme;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'New subscriptions detected',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (bills.length > 3) // Or some other logic if you want 'View All' always
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.pushNamed(context, AppConstants.scheduledPaymentsRoute);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 12),
                          ],
                        ),
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
                        backgroundColor: colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.receipt_long,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(
                        bill.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            bill.amount.toKenyaDualCurrency(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.error,
                            ),
                          ),
                          const SizedBox(height:4),
                          _buildStatusChip(bill),
                        ],
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
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

  Widget _buildBaseSurface({required Widget child}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
      child: child,
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildStatusChip(Bill bill) {
    final status = _computeStatus(bill);
    final colorScheme = Theme.of(context).colorScheme;
    Color background;
    Color foreground;
    IconData icon;

    switch (status) {
      case 'Auto-pay':
        background = colorScheme.secondaryContainer;
        foreground = colorScheme.onSecondaryContainer;
        icon = Icons.autorenew;
        break;
      case 'Negotiable':
        background = colorScheme.tertiaryContainer;
        foreground = colorScheme.onTertiaryContainer;
        icon = Icons.tune;
        break;
      case 'Consider cancelling':
        background = colorScheme.errorContainer;
        foreground = colorScheme.onErrorContainer;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        background = colorScheme.surfaceContainerHighest;
        foreground = colorScheme.onSurfaceVariant;
        icon = Icons.arrow_forward_ios;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: foreground.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
