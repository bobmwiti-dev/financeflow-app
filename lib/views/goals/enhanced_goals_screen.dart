import 'package:flutter/material.dart';

/// Deprecated screen retained as a lightweight stub to avoid breaking imports.
class EnhancedGoalsScreen extends StatelessWidget {
  const EnhancedGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: const Center(child: Text('Please use the new GoalsScreen.')),
    );
  }
}
 