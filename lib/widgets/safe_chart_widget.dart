import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logging/logging.dart';

/// A widget that safely wraps chart components to prevent rendering errors
/// when data is missing or malformed
class SafeChartWidget extends StatelessWidget {
  final Widget Function() builder;
  final String title;
  final double height;
  final bool isEmpty;
  final String emptyMessage;
  final VoidCallback? onRetry;
  
  static final _logger = Logger('SafeChartWidget');

  const SafeChartWidget({
    super.key,
    required this.builder,
    required this.title,
    this.height = 200.0,
    this.isEmpty = false,
    this.emptyMessage = 'No data available',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return _buildEmptyState(context);
    }

    try {
      return builder();
    } catch (e, stack) {
      _logger.warning('Error building chart "$title": $e\n$stack');
      return _buildErrorState(context);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 42,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            emptyMessage,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.red[100]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 42,
            color: Colors.red[300],
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to display chart',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'There was a problem loading this data',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
