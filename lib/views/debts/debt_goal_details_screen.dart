import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/debt_payoff_goal.dart';
import '../../models/debt_payment.dart';
import '../../viewmodels/debt_goals_viewmodel.dart';

class DebtGoalDetailsScreen extends StatefulWidget {
  final DebtPayoffGoal goal;

  const DebtGoalDetailsScreen({super.key, required this.goal});

  @override
  State<DebtGoalDetailsScreen> createState() => _DebtGoalDetailsScreenState();
}

class _DebtGoalDetailsScreenState extends State<DebtGoalDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goalId = int.tryParse(widget.goal.id ?? '') ?? -1;
      if (goalId != -1) {
        context.read<DebtGoalsViewModel>().loadPayments(goalId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2);
    final vm = context.watch<DebtGoalsViewModel>();
    final goalId = int.tryParse(widget.goal.id ?? '') ?? -1;
    final payments = vm.payments[goalId] ?? [];

    final remaining = widget.goal.currentBalance;
    final original = widget.goal.originalAmount;
    final paid = (original - remaining).clamp(0, original);
    final paidPercent = widget.goal.progressPercentage.clamp(0, 100);

    // payoff projection
    final months = vm.estimateMonthsToPayoff(widget.goal);
    final projectedDate = months > 0 ? DateTime.now().add(Duration(days: months * 30)) : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.goal.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPaymentDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Debt Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildInfoRow('Original Amount', currency.format(original)),
              _buildInfoRow('Remaining Balance', currency.format(remaining)),
              _buildInfoRow('Paid So Far', currency.format(paid)),
              _buildInfoRow('Interest Rate', '${widget.goal.interestRate.toStringAsFixed(2)}%'),
              _buildInfoRow('Minimum Monthly Payment', currency.format(widget.goal.minimumMonthlyPayment)),
              if (widget.goal.targetDate != null)
                _buildInfoRow('Target Date', DateFormat.yMMMd().format(widget.goal.targetDate!)),
              if (projectedDate != null)
                _buildInfoRow('Estimated Payoff', DateFormat.yMMMd().format(projectedDate)),
              const SizedBox(height: 24),
              LinearProgressIndicator(value: (paidPercent / 100).clamp(0, 1), minHeight: 10),
              const SizedBox(height: 8),
              Text('Progress: ${paidPercent.toStringAsFixed(1)}%'),
              const SizedBox(height: 24),
              Text('Payments', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              payments.isEmpty
                  ? const Text('No payments yet')
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payments.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) {
                        final p = payments[index];
                        return ListTile(
                          title: Text(currency.format(p.amount)),
                          subtitle: Text(DateFormat.yMMMd().format(p.date)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => vm.deletePayment(p.id!, goalId),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddPaymentDialog(BuildContext context) async {
    final vm = context.read<DebtGoalsViewModel>();
    final goalId = int.tryParse(widget.goal.id ?? '') ?? -1;
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(DateFormat.yMMMd().format(selectedDate))),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        selectedDate = picked;
                        // Force rebuild
                        (ctx as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountController.text.trim()) ?? 0;
                if (amt <= 0) return;
                vm.addPayment(DebtPayment(
                  goalId: goalId,
                  amount: amt,
                  date: selectedDate,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
