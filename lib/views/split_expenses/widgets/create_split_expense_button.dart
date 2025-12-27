import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../themes/app_theme.dart';

class CreateSplitExpenseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CreateSplitExpenseButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppTheme.accentColor,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.group_add),
      label: const Text('Split Expense'),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 500))
      .slideY(begin: 0.5, end: 0);
  }
}
