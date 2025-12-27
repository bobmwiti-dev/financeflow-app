import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class SpendingPattern {
  final String pattern;
  final String description;
  final IconData icon;
  final Color color;
  final double confidence;
  final List<String> recommendations;

  SpendingPattern({
    required this.pattern,
    required this.description,
    required this.icon,
    required this.color,
    required this.confidence,
    required this.recommendations,
  });
}

class SmartSpendingAnalyzer extends StatefulWidget {
  final Map<DateTime, dynamic> spendingData;
  final DateTime focusedMonth;

  const SmartSpendingAnalyzer({
    super.key,
    required this.spendingData,
    required this.focusedMonth,
  });

  @override
  State<SmartSpendingAnalyzer> createState() => _SmartSpendingAnalyzerState();
}

class _SmartSpendingAnalyzerState extends State<SmartSpendingAnalyzer>
    with TickerProviderStateMixin {
  late AnimationController _analysisController;
  late Animation<double> _analysisAnimation;
  List<SpendingPattern> _patterns = [];
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    _analysisController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _analysisAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _analysisController,
      curve: Curves.easeOutCubic,
    ));

    _analyzeSpendingPatterns();
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  Future<void> _analyzeSpendingPatterns() async {
    // Simulate AI analysis
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final patterns = _generateSpendingPatterns();
    
    setState(() {
      _patterns = patterns;
      _isAnalyzing = false;
    });
    
    _analysisController.forward();
  }

  List<SpendingPattern> _generateSpendingPatterns() {
    final patterns = <SpendingPattern>[];
    
    // Analyze spending data
    final monthData = widget.spendingData.values.where((data) => data.amount > 0).toList();
    if (monthData.isEmpty) return patterns;

    final totalSpending = monthData.fold(0.0, (sum, data) => sum + data.amount);
    final avgDailySpending = totalSpending / monthData.length;
    
    // Weekend vs Weekday pattern
    double weekendTotal = 0;
    double weekdayTotal = 0;
    int weekendCount = 0;
    int weekdayCount = 0;

    for (final data in monthData) {
      if (data.date.weekday >= 6) {
        weekendTotal += data.amount;
        weekendCount++;
      } else {
        weekdayTotal += data.amount;
        weekdayCount++;
      }
    }

    final weekendAvg = weekendCount > 0 ? weekendTotal / weekendCount : 0;
    final weekdayAvg = weekdayCount > 0 ? weekdayTotal / weekdayCount : 0;

    if (weekendAvg > weekdayAvg * 1.5) {
      patterns.add(SpendingPattern(
        pattern: 'Weekend Spender',
        description: 'You spend ${(weekendAvg / weekdayAvg).toStringAsFixed(1)}x more on weekends. Consider setting weekend budgets.',
        icon: Icons.weekend,
        color: Colors.orange,
        confidence: 0.85,
        recommendations: [
          'Set a weekend spending limit',
          'Plan weekend activities in advance',
          'Use cash for weekend expenses',
        ],
      ));
    }

    // High spending days pattern
    final highSpendingDays = monthData.where((data) => data.amount > avgDailySpending * 2).length;
    if (highSpendingDays > 3) {
      patterns.add(SpendingPattern(
        pattern: 'Impulse Spending',
        description: 'You have $highSpendingDays high-spending days this month. This suggests impulse purchases.',
        icon: Icons.flash_on,
        color: Colors.red,
        confidence: 0.78,
        recommendations: [
          'Wait 24 hours before large purchases',
          'Create a shopping list',
          'Set daily spending alerts',
        ],
      ));
    }

    // Consistent spending pattern
    final spendingVariance = _calculateVariance(monthData.map((d) => (d.amount as num).toDouble()).toList());
    if (spendingVariance < avgDailySpending * 0.5) {
      patterns.add(SpendingPattern(
        pattern: 'Consistent Spender',
        description: 'Your spending is very consistent. Great job maintaining discipline!',
        icon: Icons.trending_flat,
        color: Colors.green,
        confidence: 0.92,
        recommendations: [
          'Continue your disciplined approach',
          'Consider increasing savings rate',
          'Explore investment opportunities',
        ],
      ));
    }

    // Month-end spending pattern
    final lastWeekSpending = monthData.where((data) {
      final daysInMonth = DateTime(widget.focusedMonth.year, widget.focusedMonth.month + 1, 0).day;
      return data.date.day > daysInMonth - 7;
    }).fold(0.0, (sum, data) => sum + data.amount);

    if (lastWeekSpending > totalSpending * 0.4) {
      patterns.add(SpendingPattern(
        pattern: 'Month-End Rush',
        description: 'You spend heavily in the last week of the month. Budget distribution could be improved.',
        icon: Icons.schedule,
        color: Colors.purple,
        confidence: 0.73,
        recommendations: [
          'Distribute spending evenly',
          'Set weekly spending targets',
          'Track progress mid-month',
        ],
      ));
    }

    return patterns;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 15,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (_isAnalyzing) _buildAnalyzingState() else _buildAnalysisResults(),
        ],
      ),
    ).animate()
      .fadeIn(duration: 800.ms)
      .slideY(begin: 0.3, duration: 800.ms, curve: Curves.easeOutBack);
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.psychology,
            color: Colors.white,
            size: 28,
          ),
        ).animate(delay: 200.ms)
          .scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ).createShader(bounds),
                child: const Text(
                  'AI Spending Analysis',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Intelligent insights from your spending patterns',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 40,
          ),
        ).animate(onPlay: (controller) => controller.repeat())
          .rotate(duration: 2000.ms)
          .then()
          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 1000.ms)
          .then()
          .scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0), duration: 1000.ms),
        const SizedBox(height: 24),
        const Text(
          'Analyzing your spending patterns...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Our AI is examining your financial behavior',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAnalysisResults() {
    if (_patterns.isEmpty) {
      return _buildNoPatterns();
    }

    return AnimatedBuilder(
      animation: _analysisAnimation,
      builder: (context, child) {
        return Column(
          children: [
            for (int i = 0; i < _patterns.length; i++)
              Opacity(
                opacity: _analysisAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - _analysisAnimation.value) * 50),
                  child: _buildPatternCard(_patterns[i]),
                ),
              ).animate(delay: Duration(milliseconds: i * 200))
                .fadeIn(duration: 500.ms)
                .slideX(begin: 0.3, duration: 500.ms),
          ],
        );
      },
    );
  }

  Widget _buildNoPatterns() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.insights,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        const Text(
          'Not enough data for analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add more transactions to get personalized insights',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPatternCard(SpendingPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            pattern.color.withValues(alpha: 0.05),
            pattern.color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pattern.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pattern.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  pattern.icon,
                  color: pattern.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.pattern,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: pattern.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(pattern.confidence * 100).toInt()}% confidence',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            pattern.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recommendations:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...pattern.recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: pattern.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
