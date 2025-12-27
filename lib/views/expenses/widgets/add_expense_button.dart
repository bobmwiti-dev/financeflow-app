import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';
import '../../../views/transactions/transaction_form_screen.dart';

class AddExpenseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddExpenseButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Add Expense'),
      backgroundColor: AppTheme.accentColor,
      foregroundColor: Colors.white,
    );
  }
}
