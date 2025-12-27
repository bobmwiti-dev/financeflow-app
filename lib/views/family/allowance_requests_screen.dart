import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../models/allowance_request_model.dart';
import '../../viewmodels/allowance_request_viewmodel.dart';
import '../../themes/app_theme.dart';

class AllowanceRequestsScreen extends StatelessWidget {
  static final Logger _logger = Logger('AllowanceRequestsScreen');
  
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateRequestDialog(context),
          tooltip: 'Request Allowance',
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          title: Text('$memberName\'s Requests'),
        ),
        body: Consumer<AllowanceRequestViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.requests.isEmpty) {
              return const Center(child: Text('No allowance requests'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.requests.length,
              itemBuilder: (context, index) {
                final req = vm.requests[index];
                return _buildRequestCard(context, vm, req);
              },
            );
          },
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
        return AlertDialog(
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
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
_logger.info('Submit button pressed for allowance request');
                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                final reason = reasonController.text.trim();
                _logger.info('Parsed amount: \$$amount, reason: "$reason"');
                
                // Validation
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount greater than 0'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a reason for the request'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                try {
                  final success = await vm.requestAllowance(
                    amount: amount, 
                    reason: reason, 
                    memberName: memberName
                  );
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Allowance request submitted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(vm.error ?? 'Failed to create allowance request'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            )
          ],
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
                        final success = await vm.approveRequest(req.id!);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vm.error ?? 'Failed to approve request'),
                              backgroundColor: Colors.red,
                            ),
                          );
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
                        final success = await vm.declineRequest(req.id!);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vm.error ?? 'Failed to decline request'),
                              backgroundColor: Colors.red,
                            ),
                          );
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
