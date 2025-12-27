import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const ReportCard({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (actions != null) ...actions!,
                if (actions == null)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Show more options
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
