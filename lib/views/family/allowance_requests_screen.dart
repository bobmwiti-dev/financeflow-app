import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/allowance_request_model.dart';
import '../../viewmodels/allowance_request_viewmodel.dart';
import '../../themes/app_theme.dart';

class AllowanceRequestsScreen extends StatelessWidget {
  final String primaryUserId;
  final String memberId;
  final String memberName;

  const AllowanceRequestsScreen({
    super.key,
    required this.primaryUserId,
    required this.memberId,
    required this.memberName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AllowanceRequestViewModel(primaryUserId: primaryUserId, memberId: memberId)..startListening(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showCreateRequestDialog(context);
          },
          tooltip: 'Request Allowance',
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          title: Text('$memberName\'s Requests'),
        ),
        body: Consumer<AllowanceRequestViewModel>(
          builder: (context, vm, _) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withAlpha((0.06 * 255).toInt()),
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.selectionClick();
                  vm.startListening();
                },
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.requests.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: vm.requests.length,
                            itemBuilder: (context, index) {
                              final req = vm.requests[index];
                              return _buildRequestCard(context, vm, req);
                            },
                          ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
              ),
              child: Icon(
                Icons.request_quote,
                color: AppTheme.primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No allowance requests yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create the first request.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateRequestDialog(BuildContext context) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final vm = Provider.of<AllowanceRequestViewModel>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> submit() async {
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              final reason = reasonController.text.trim();

              if (amount <= 0) {
                HapticFeedback.vibrate();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a valid amount greater than 0'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }

              if (reason.isEmpty) {
                HapticFeedback.vibrate();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please provide a reason for the request'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }

              setState(() => isSubmitting = true);
              HapticFeedback.selectionClick();

              try {
                final success = await vm.requestAllowance(
                  amount: amount,
                  reason: reason,
                  memberName: memberName,
                );

                if (!ctx.mounted) return;

                Navigator.pop(ctx);

                if (success) {
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Allowance request submitted successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else {
                  HapticFeedback.vibrate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(vm.error ?? 'Failed to create allowance request'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                HapticFeedback.vibrate();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
          title: const Text('Request Allowance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                ),
                onSubmitted: (_) {
                  if (!isSubmitting) submit();
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
                onSubmitted: (_) {
                  if (!isSubmitting) submit();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx);
                    },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: AnimatedSwitcher(
                duration: AppTheme.mediumAnimationDuration,
                child: isSubmitting
                    ? const SizedBox(
                        key: ValueKey('submitting'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit',
                        key: ValueKey('submit'),
                      ),
              ),
            ),
          ],
            );
          },
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, AllowanceRequestViewModel vm, AllowanceRequest req) {
    final currency = NumberFormat.currency(symbol: '\$');
    final createdAt = DateFormat('MMM d, yyyy – h:mm a').format(req.createdAt);
    Color statusColor;
    IconData statusIcon;
    switch (req.status) {
      case 'approved':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'declined':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.amber;
        statusIcon = Icons.hourglass_top;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: AppTheme.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  req.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Text(currency.format(req.amount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(req.reason),
            if (req.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        final success = await vm.approveRequest(req.id!);
                        if (!success && context.mounted) {
                          HapticFeedback.vibrate();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vm.error ?? 'Failed to approve request'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } else if (success) {
                          HapticFeedback.heavyImpact();
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        final success = await vm.declineRequest(req.id!);
                        if (!success && context.mounted) {
                          HapticFeedback.vibrate();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vm.error ?? 'Failed to decline request'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } else if (success) {
                          HapticFeedback.heavyImpact();
                        }
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Decline'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
