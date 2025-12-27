import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/income_viewmodel.dart';
import '../../../viewmodels/emergency_fund_viewmodel.dart';

/// Emergency Fund card showing current emergency savings, target amount,
/// progress percentage, and helpful tips for building emergency funds.
class EmergencyFundCard extends StatelessWidget {
  const EmergencyFundCard({
    super.key,
    this.targetMonths = 6, // Default 6 months of expenses
  });

  final int targetMonths;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Consumer2<EmergencyFundViewModel, IncomeViewModel>(
      builder: (context, emergencyFundViewModel, incomeViewModel, child) {
        final emergencyFund = emergencyFundViewModel.emergencyFund;
        final monthlyIncome = incomeViewModel.getTotalIncome();
        final estimatedMonthlyExpenses = monthlyIncome * 0.7;
        
        final targetAmount = emergencyFund?.targetAmount ?? (estimatedMonthlyExpenses * targetMonths);
        final currentAmount = emergencyFund?.currentAmount ?? 0.0;
        final progressPercentage = emergencyFund?.progressPercentage ?? 0.0;
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, emergencyFundViewModel),
                const SizedBox(height: 16),
                _buildAmountSection(context, currency, currentAmount.toDouble(), targetAmount.toDouble()),
                const SizedBox(height: 16),
                _buildProgressSection(context, progressPercentage.toDouble()),
                const SizedBox(height: 12),
                _buildStatusMessage(context, progressPercentage.toDouble(), targetMonths),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, EmergencyFundViewModel viewModel) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.security,
            color: Colors.orange.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Emergency Fund',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _showAddFundsDialog(context, viewModel),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSection(BuildContext context, NumberFormat currency, double currentAmount, double targetAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currency.format(currentAmount),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$targetMonths months target',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, double progressPercentage) {
    final isComplete = progressPercentage >= 100;
    final progressColor = isComplete ? Colors.green : Colors.orange;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progressPercentage.toStringAsFixed(0)}% Complete',
              style: TextStyle(
                color: progressColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              '$targetMonths months target',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercentage / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(BuildContext context, double progressPercentage, int targetMonths) {
    final isComplete = progressPercentage >= 100;
    final isGoodProgress = progressPercentage >= 50;
    
    String message;
    IconData icon;
    Color color;
    
    if (isComplete) {
      message = 'Great job! Your emergency fund is fully funded.';
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (isGoodProgress) {
      message = 'Good start! Keep building your emergency fund.';
      icon = Icons.trending_up;
      color = Colors.orange;
    } else {
      message = 'Start building your emergency fund for financial security.';
      icon = Icons.warning_amber;
      color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to add/withdraw funds
  void _showAddFundsDialog(BuildContext context, EmergencyFundViewModel viewModel) {
    final TextEditingController amountController = TextEditingController();
    bool isAdding = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isAdding ? 'Add to Emergency Fund' : 'Withdraw from Emergency Fund'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => isAdding = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdding ? Theme.of(context).primaryColor : Colors.grey.shade300,
                        foregroundColor: isAdding ? Colors.white : Colors.black54,
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => isAdding = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isAdding ? Theme.of(context).primaryColor : Colors.grey.shade300,
                        foregroundColor: !isAdding ? Colors.white : Colors.black54,
                      ),
                      child: const Text('Withdraw'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (\$)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                  hintText: isAdding ? 'Enter amount to add' : 'Enter amount to withdraw',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = amountController.text.trim();
                if (amountText.isEmpty) return;
                
                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                Navigator.of(context).pop();
                
                bool success;
                if (isAdding) {
                  success = await viewModel.addAmount(amount);
                } else {
                  success = await viewModel.withdrawAmount(amount);
                }
                
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAdding 
                            ? 'Successfully added \$${amount.toStringAsFixed(2)} to emergency fund'
                            : 'Successfully withdrew \$${amount.toStringAsFixed(2)} from emergency fund'
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAdding 
                            ? 'Failed to add funds. Please try again.'
                            : 'Failed to withdraw funds. Please try again.'
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isAdding ? 'Add Funds' : 'Withdraw'),
            ),
          ],
        ),
      ),
    );
  }
}
