import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../themes/app_theme.dart';
import '../../utils/enhanced_animations.dart';

/// A card that displays personalized financial insights with actionable recommendations
class SmartInsightsCard extends StatelessWidget {
  final List<FinancialInsight> insights;
  final VoidCallback? onViewAllInsights;
  final Function(FinancialInsight insight)? onInsightAction;

  const SmartInsightsCard({
    super.key,
    required this.insights,
    this.onViewAllInsights,
    this.onInsightAction,
  });

  @override
  Widget build(BuildContext context) {
    final sortedInsights = List<FinancialInsight>.from(insights)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with title and view all button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.accentColor,
                      size: 20,
                    )
                    .animate()
                    .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut),
                    const SizedBox(width: 8),
                    Text(
                      'Smart Insights',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (onViewAllInsights != null)
                  TextButton(
                    onPressed: onViewAllInsights,
                    child: Text(
                      'View All',
                      style: TextStyle(color: AppTheme.accentColor),
                    ),
                  ),
              ],
            )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 400))
            .slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            
            // Insights list or empty state
            sortedInsights.isEmpty
                ? _buildEmptyState(context)
                : Column(
                    children: List.generate(
                      sortedInsights.length > 3 ? 3 : sortedInsights.length,
                      (index) => _buildInsightItem(
                        context,
                        sortedInsights[index],
                        index,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 800))
    .moveY(begin: 30, end: 0, curve: Curves.easeOutQuint);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: Colors.amber.shade300,
          )
          .animate()
          .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'No insights yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Continue adding transactions to get personalized financial insights',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      )
      .animate()
      .fadeIn()
      .slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildInsightItem(BuildContext context, FinancialInsight insight, int index) {
    // Set card color based on insight type
    Color insightColor;
    switch (insight.type) {
      case InsightType.alert:
        insightColor = Colors.red.shade700;
        break;
      case InsightType.warning:
        insightColor = Colors.orange.shade700;
        break;
      case InsightType.recommendation:
        insightColor = Colors.blue.shade700;
        break;
      case InsightType.positive:
        insightColor = Colors.green.shade700;
        break;
      default:
        insightColor = AppTheme.accentColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: insightColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insightColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insight header
          Row(
            children: [
              // Icon for insight type
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: insightColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getInsightIcon(insight.type),
                  color: insightColor,
                  size: 14,
                ),
              )
              .animate(delay: Duration(milliseconds: 100 * (index + 1)))
              .scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut),
              
              const SizedBox(width: 8),
              
              // Insight title with animated entrance
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: insightColor,
                    fontSize: 14,
                  ),
                ),
              ),
              
              // Shimmer highlight for important insights
              if (insight.priority > 5) ...[  
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: insightColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Important',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: insightColor,
                    ),
                  ),
                )
                .animate(delay: Duration(milliseconds: 200 * (index + 1)))
                .fadeIn()
                .shimmer(
                  duration: const Duration(milliseconds: 1800),
                  color: insightColor.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Insight description
          Text(
            insight.description,
            style: const TextStyle(fontSize: 13),
          ),
          
          if (insight.actionText != null && onInsightAction != null) ...[
            const SizedBox(height: 12),
            
            // Action button
            EnhancedAnimations.scaleOnTap(
              onTap: () => onInsightAction!(insight),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: insightColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        insight.actionText!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: insightColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: insightColor,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .animate(delay: Duration(milliseconds: 300 * (index + 1)))
            .fadeIn()
            .slideY(begin: 0.3, end: 0),
          ],
        ],
      ),
    )
    .animate(delay: Duration(milliseconds: 200 + (index * 150)))
    .fadeIn()
    .slideX(begin: 0.1, end: 0);
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.alert:
        return Icons.error_outline;
      case InsightType.warning:
        return Icons.warning_amber_rounded;
      case InsightType.recommendation:
        return Icons.lightbulb_outline;
      case InsightType.positive:
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }
}

/// Types of financial insights
enum InsightType {
  alert,
  warning,
  recommendation,
  positive,
  general,
}

/// Model class for financial insights
class FinancialInsight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final int priority; // 1-10, with 10 being highest priority
  final String? actionText;
  final String? category;
  final DateTime generatedDate;
  final Map<String, dynamic>? metadata;

  const FinancialInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.priority = 5,
    this.actionText,
    this.category,
    required this.generatedDate,
    this.metadata,
  });
}
