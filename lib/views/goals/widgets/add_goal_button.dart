import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

class AddGoalButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddGoalButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppTheme.accentColor,
      foregroundColor: Colors.white,
      tooltip: 'Add Goal',
      child: const Icon(Icons.add),
    );
  }
}
