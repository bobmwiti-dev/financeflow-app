import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../themes/app_theme.dart';

/// A bar chart widget with smooth animations
class AnimatedBarChart extends StatefulWidget {
  final List<double> data;
  final List<String> labels;
  final String title;
  final bool showValues;
  final Color barColor;
  final double maxValue;
  
  const AnimatedBarChart({
    required this.data,
    required this.labels,
    this.title = '',
    this.showValues = true,
    this.barColor = AppTheme.accentColor,
    this.maxValue = 0, // If 0, will calculate from data
    super.key,
  });
  
  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _barAnimations;
  late double _effectiveMaxValue;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _initializeAnimations();
    _controller.forward();
  }
  
  void _initializeAnimations() {
    // Calculate max value if not provided
    _effectiveMaxValue = widget.maxValue > 0 
        ? widget.maxValue 
        : widget.data.isEmpty ? 1.0 : widget.data.reduce((a, b) => a > b ? a : b);
    
    // Create animations for each bar
    _barAnimations = widget.data.map((value) {
      return Tween<double>(begin: 0, end: value).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
      );
    }).toList();
  }
  
  @override
  void didUpdateWidget(AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data || widget.maxValue != oldWidget.maxValue) {
      _initializeAnimations();
      _controller.reset();
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty || _effectiveMaxValue == 0) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 700))
              .slideX(begin: -0.2, end: 0),
          ),
        SizedBox(
          height: 220,
          child: GestureDetector(
            onTap: () {
              _controller.reverse().then((_) => _controller.forward());
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: BarChartPainter(
                        values: _barAnimations.map((anim) => anim.value).toList(),
                        labels: widget.labels,
                        maxValue: _effectiveMaxValue,
                        showValues: widget.showValues,
                        barColor: widget.barColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxValue;
  final bool showValues;
  final Color barColor;
  
  BarChartPainter({
    required this.values,
    required this.labels,
    required this.maxValue,
    required this.showValues,
    required this.barColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final double barWidth = size.width / (values.length * 2 + 1);
    final double height = size.height * 0.85; // Leave room for labels
    final double bottomPadding = size.height * 0.15;
    
    // Draw horizontal grid lines
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 40)
      ..strokeWidth = 1;
    
    const int gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final double y = height - (height * i / gridLines) + 10;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
      
      // Draw grid line values
      if (i > 0) {
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: ((maxValue * i / gridLines).round()).toString(),
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 150),
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(0, y - textPainter.height),
        );
      }
    }
    
    // Draw bars
    final Paint barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < values.length; i++) {
      final double value = values[i];
      final double normalizedValue = value / maxValue;
      final double barHeight = normalizedValue * height;
      
      final double left = (i * 2 + 1) * barWidth;
      final double top = height - barHeight + 10;
      final double right = left + barWidth;
      final double bottom = height + 10;
      
      // Draw bar with rounded top corners
      final RRect barRect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, top, right, bottom),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      
      canvas.drawRRect(barRect, barPaint);
      
      // Draw value on top of bar if enabled
      if (showValues) {
        final TextPainter valuePainter = TextPainter(
          text: TextSpan(
            text: value.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        valuePainter.layout();
        valuePainter.paint(
          canvas,
          Offset(
            left + (barWidth - valuePainter.width) / 2,
            top - valuePainter.height - 4,
          ),
        );
      }
      
      // Draw label below bar
      if (i < labels.length) {
        final TextPainter labelPainter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 10,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(
            left + (barWidth - labelPainter.width) / 2,
            height + bottomPadding - labelPainter.height,
          ),
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
           oldDelegate.maxValue != maxValue ||
           oldDelegate.barColor != barColor ||
           oldDelegate.showValues != showValues;
  }
}
