import 'package:flutter/material.dart';

class AddGoalButton extends StatelessWidget {
  final VoidCallback onPressed;

  static const Color _accentColor = Color(0xFF6366F1);

  const AddGoalButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: _accentColor,
      foregroundColor: Colors.white,
      tooltip: 'Add Goal',
      child: const Icon(Icons.add),
    );
  }
}
