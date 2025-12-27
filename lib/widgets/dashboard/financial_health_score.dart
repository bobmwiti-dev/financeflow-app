import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:sparkline/sparkline.dart';


/// A visual representation of the user's overall financial health
/// with key contributing metrics and improvement suggestions
class FinancialHealthScoreCard extends StatefulWidget {
  final double score; // 0-100 financial health score
  final List<ScoreMetric> contributingMetrics;
  final double? previousScore; // Previous period score for comparison
  final VoidCallback? onImproveScore;

  const FinancialHealthScoreCard({
    super.key,
    required this.score,
    required this.contributingMetrics,
    this.previousScore,
    this.onImproveScore,
  });

  @override
  State<FinancialHealthScoreCard> createState() => _FinancialHealthScoreCardState();
}

class _FinancialHealthScoreCardState extends State<FinancialHealthScoreCard> {
  bool _isPressed = false;
  late final ConfettiController _confettiController;
  double _currentScore = 0.0;
  double _targetScore = 0.0;
  Color? _currentColor;
  Color? _targetColor;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _currentScore = widget.score;
    _targetScore = widget.score;
    _currentColor = _getScoreColor(context, widget.score);
    _targetColor = _currentColor;
    // Play confetti after first frame if conditions are met so it doesn't block build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldCelebrate()) {
        _confettiController.play();
      }
    });
  }

  @override
  void didUpdateWidget(FinancialHealthScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      setState(() {
        _targetScore = widget.score;
        _targetColor = _getScoreColor(context, widget.score);
        _isAnimating = true;
      });

      // After animation duration, update current values
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _currentScore = _targetScore;
            _currentColor = _targetColor;
            _isAnimating = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access widget values locally for convenience
    final double score = widget.score;
    final double? previousScore = widget.previousScore;
    final scoreDiff = previousScore != null ? score - previousScore : 0.0;
    final hasTrend = previousScore != null;

    // If we're not animating, use the current values
    if (!_isAnimating) {
      _currentScore = score;
      _currentColor = _getScoreColor(context, score);
    }



    final String semanticsLabel = 'Financial health score: ${score.toInt()} out of 100. ';
    final String trendLabel = scoreDiff == 0
        ? 'No change since last month.'
        : 'Trending ${scoreDiff > 0 ? 'up' : 'down'} by ${scoreDiff.abs().toStringAsFixed(1)} points since last month.';

    return Semantics(
      label: '$semanticsLabel$trendLabel',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Calculated from savings rate, debt-to-income, credit utilisation, and more.',
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            HapticFeedback.lightImpact();
            _showDetailsBottomSheet(context);
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: 150.ms,
            curve: Curves.easeOut,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Main card content with animated shadow and gradient
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: _isPressed ? 8 : 2,
                  shadowColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: _currentScore, end: _targetScore),
                    duration: 1200.ms,
                    builder: (context, animatedScore, _) {
                      return Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              _currentColor!.withAlpha(25),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () { /* Tap handled by GestureDetector */ },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header section
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Financial Health',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (hasTrend)
                                      _buildTrendIndicator(context, scoreDiff),
                                  ],
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: -0.1, end: 0),
                                
                                const SizedBox(height: 16),
                                
                                // Main content with score circle and metrics
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Health score circular indicator
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: _currentScore, end: _targetScore),
                                      duration: 1200.ms,
                                      curve: Curves.easeOutCubic,
                                      builder: (context, animatedScore, _) {
                                        final t = (_targetScore - _currentScore).abs() < 0.01 ? 1.0 : (animatedScore - _currentScore) / (_targetScore - _currentScore);
                                        final startColor = _currentColor!;
                                        final animatedColor = Color.lerp(startColor, _targetColor!, t)!;
                                        return SizedBox(
                                          width: 110,
                                          height: 110,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                value: animatedScore / 100,
                                                strokeWidth: 10,
                                                backgroundColor: Colors.grey[200],
                                                valueColor: ColorTween(begin: startColor, end: _targetColor!).animate(AlwaysStoppedAnimation(t)),
                                              ),
                                              Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      animatedScore.toInt().toString(),
                                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                        color: animatedColor,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      _getScoreLabel(animatedScore),
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: animatedColor.withAlpha(200),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    // Contributing metrics list
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Key Factors',
                                            style: Theme.of(context).textTheme.labelLarge,
                                          ),
                                          const SizedBox(height: 8),
                                          ...List.generate(
                                            widget.contributingMetrics.length > 3 ? 3 : widget.contributingMetrics.length,
                                            (index) => _buildMetricItem(context, widget.contributingMetrics[index], index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Action button
                                if (widget.onImproveScore != null) ...[
                                  const SizedBox(height: 20),
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: widget.onImproveScore,
                                      icon: const Icon(Icons.trending_up),
                                      label: const Text('Improve Score'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _currentColor!,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                    ).animate(delay: 800.ms).fadeIn(duration: 400.ms).slideY(begin: 0.5),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .moveY(begin: 30, end: 0, curve: Curves.easeOutQuint),

                // Confetti overlay
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.orange,
                    Colors.pink,
                    Colors.purple,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, double scoreDiff) {
    final isPositive = scoreDiff > 0;
    final isNeutral = scoreDiff == 0;
    final color = isPositive
        ? Theme.of(context).colorScheme.primary
        : isNeutral
            ? Colors.grey
            : Theme.of(context).colorScheme.error;
    final icon = isPositive ? Icons.trending_up : isNeutral ? Icons.trending_flat : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${scoreDiff.abs().toStringAsFixed(1)} pts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    )
    .animate(delay: 600.ms)
    .fadeIn(duration: 400.ms)
    .slideX(begin: 0.5, duration: 800.ms, curve: Curves.elasticOut)
    // Add conditional looping animation after the initial entrance
    .then(delay: 200.ms)
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .then(duration: 1500.ms)
    .shimmer(
        color: isPositive
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6)
            : isNeutral
                ? Colors.transparent
                : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.6),
        duration: 1500.ms);
  }

  Widget _buildMetricItem(BuildContext context, ScoreMetric metric, int index) {
    final Color metricColor;
    
    // Set color based on metric score
    if (metric.score >= 80) {
      metricColor = Colors.green.shade700;
    } else if (metric.score >= 60) {
      metricColor = Colors.blue.shade700;
    } else if (metric.score >= 40) {
      metricColor = Colors.amber.shade700;
    } else if (metric.score >= 20) {
      metricColor = Colors.orange.shade700;
    } else {
      metricColor = Colors.red.shade700;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: metricColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      metric.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${metric.score.toInt()}/100',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: metricColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: metric.score / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(metricColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ],
      ),
    )
    .animate(delay: Duration(milliseconds: 500 + (index * 100)))
    .fadeIn()
    .slideX(begin: 0.1, end: 0);
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }
  bool _shouldCelebrate() {
    // Celebrate if crossing 80 threshold upward, or perfect score.
    final prev = widget.previousScore ?? 0.0;
    return (prev < 80 && widget.score >= 80) || widget.score >= 100;
  }

  // Helper to map score to colour consistently using Material 3 ColorScheme
  Color _getScoreColor(BuildContext context, double score) {
    final colors = Theme.of(context).colorScheme;
    if (score >= 80) return colors.primary; // Excellent
    if (score >= 60) return colors.tertiary; // Good
    if (score >= 40) return colors.secondary; // Fair
    if (score >= 20) return colors.errorContainer; // Poor
    return colors.error; // Critical
  }

  void _showDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FinancialHealthDetailsSheet(
        metrics: widget.contributingMetrics,
        // Placeholder data for sparkline
        scoreHistory: const [72.0, 75.0, 74.0, 78.0, 81.0, 80.0],
      ),
    );
  }
}

/// Bottom sheet widget for showing detailed financial health metrics.
class _FinancialHealthDetailsSheet extends StatelessWidget {
  final List<ScoreMetric> metrics;
  final List<double> scoreHistory;

  const _FinancialHealthDetailsSheet({required this.metrics, required this.scoreHistory});

  Color _getScoreColor(BuildContext context, double score) {
    final colors = Theme.of(context).colorScheme;
    if (score >= 80) return colors.primary;
    if (score >= 60) return colors.tertiary;
    if (score >= 40) return colors.secondary;
    if (score >= 20) return colors.errorContainer;
    return colors.error;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text('Financial Health Details', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              Text('Score History (Last 6 Months)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha:0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Sparkline(
                      data: scoreHistory,
                      lineWidth: 2.0,
                      lineColor: Theme.of(context).colorScheme.primary,
                      pointsMode: PointsMode.all,
                      pointSize: 5.0,
                      pointColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('All Contributing Factors', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...metrics.map((metric) => ListTile(
                leading: CircleAvatar(backgroundColor: _getScoreColor(context, metric.score), radius: 5),
                title: Text(metric.name),
                trailing: Text('${metric.score.toInt()}/100', style: TextStyle(color: _getScoreColor(context, metric.score), fontWeight: FontWeight.bold)),
              )),
              const SizedBox(height: 24),
              Text('Personalized Tips', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              const ListTile(
                leading: Icon(Icons.lightbulb_outline, color: Colors.amber),
                title: Text('Your credit utilization is high.'),
                subtitle: Text('Consider paying down your credit card balance by at least 10% to see a score improvement.'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ScoreMetric {
  final String id;
  final String name;
  final double score; // 0-100 score for this metric
  final String? description;
  final double? previousScore; // For trend calculation

  const ScoreMetric({
    required this.id,
    required this.name,
    required this.score,
    this.description,
    this.previousScore,
  });
}
