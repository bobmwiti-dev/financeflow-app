import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EnhancedBudgetButton extends StatelessWidget {
  const EnhancedBudgetButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 0,
      child: FloatingActionButton.extended(
        heroTag: 'enhancedBudget',
        onPressed: () {
          Navigator.pushNamed(context, '/enhanced_budget');
        },
        backgroundColor: Colors.deepPurple.shade500,
        foregroundColor: Colors.white,
        elevation: 4,
        label: const Text('Enhanced Budget'),
        icon: const Icon(Icons.pie_chart),
      ).animate()
        .fadeIn(duration: const Duration(milliseconds: 800))
        .slideX(begin: 0.5, end: 0.0),
    );
  }
}
