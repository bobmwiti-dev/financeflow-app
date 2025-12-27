import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../themes/app_theme.dart';

/// A pie chart widget with smooth animations
class AnimatedPieChart extends StatefulWidget {
  final Map<String, double> data;
  final Map<String, Color>? colorMap;
  final String title;
  final bool showLegend;
  final bool showPercentages;
  final double radius;
  final DateTime? selectedMonth;
  
  const AnimatedPieChart({
    required this.data,
    this.colorMap,
    this.title = '',
    this.showLegend = true,
    this.showPercentages = true,
    this.radius = 100,
    this.selectedMonth,
    super.key,
  });
  
  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart> with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  int? _tappedIndex;
  bool _isChartHovered = false;
  int? _legendHoveredIndex;

  void _onSegmentTap(int? index) {
    setState(() {
      _tappedIndex = index;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _tappedIndex = null;
      });
    });
  }

  late AnimationController _controller;
  late Animation<double> _animation;
  late Map<String, Color> _effectiveColorMap;
  
  // Predefined colors for pie segments
  static const List<Color> _defaultColors = [
    AppTheme.accentColor,
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFFFFCA28),
    Color(0xFF66BB6A),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
  ];
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    
    _initializeColors();
    _controller.forward();
  }
  
  void _initializeColors() {
    _effectiveColorMap = {};
    
    if (widget.colorMap != null) {
      _effectiveColorMap = Map.from(widget.colorMap!);
    }
    
    // Assign colors to categories that don't have one yet
    int colorIndex = 0;
    for (final category in widget.data.keys) {
      if (!_effectiveColorMap.containsKey(category)) {
        _effectiveColorMap[category] = _defaultColors[colorIndex % _defaultColors.length];
        colorIndex++;
      }
    }
  }
  
  @override
  void didUpdateWidget(AnimatedPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data || widget.colorMap != oldWidget.colorMap) {
      _initializeColors();
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
    // Calculate total for percentages
    final double total = widget.data.values.fold(0, (sum, value) => sum + value);
    
    if (widget.data.isEmpty || total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No data available',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Interactive Pie Chart with enhanced animations
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            if (mounted) {
              setState(() => _isChartHovered = true);
            }
          },
          onExit: (_) {
            if (mounted) {
              setState(() => _isChartHovered = false);
            }
          },
          child: GestureDetector(
            onTap: () {
              _controller.reverse().then((_) => _controller.forward());
              _onSegmentTap(null);
            },
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return AnimatedScale(
                  scale: _isChartHovered || _tappedIndex != null ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: _isChartHovered ? 20 : 12,
                          spreadRadius: _isChartHovered ? 4 : 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: widget.radius * 2,
                      height: widget.radius * 2,
                      child: CustomPaint(
                        painter: PieChartPainter(
                          data: widget.data,
                          colorMap: _effectiveColorMap,
                          progress: _animation.value,
                          showPercentages: widget.showPercentages,
                          total: total,
                          hoveredIndex: _hoveredIndex ?? _legendHoveredIndex,
                          tappedIndex: _tappedIndex,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ).animate()
          .fadeIn(duration: 800.ms)
          .scale(
            begin: const Offset(0.6, 0.6), 
            end: const Offset(1, 1), 
            curve: Curves.elasticOut, 
            duration: 1500.ms
          ),
        
        // Center text showing total
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return AnimatedOpacity(
              opacity: _animation.value > 0.7 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Map<String, Color> colorMap;
  final double progress;
  final bool showPercentages;
  final double total;
  final int? hoveredIndex;
  final int? tappedIndex;

  PieChartPainter({
    required this.data,
    required this.colorMap,
    required this.progress,
    required this.showPercentages,
    required this.total,
    this.hoveredIndex,
    this.tappedIndex,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    
    // Draw background circle if empty
    if (data.isEmpty || total <= 0) {
      final Paint emptyPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 50)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, radius, emptyPaint);
      return;
    }
    
    // Draw pie segments
    double startAngle = -math.pi / 2; // Start from top (12 o'clock position)
    final keys = data.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      final category = keys[i];
      final value = data[category]!;
      final double sweepAngle = (value / total) * 2 * math.pi * progress;

      // Segment pop-out effect
      final bool isHighlighted = hoveredIndex == i || tappedIndex == i;
      final double popOut = isHighlighted ? 12.0 : 0.0;
      final double middleAngle = startAngle + sweepAngle / 2;
      final Offset segmentCenter = Offset(
        center.dx + popOut * math.cos(middleAngle),
        center.dy + popOut * math.sin(middleAngle),
      );

      // Gradient fill
      final Paint segmentPaint = Paint()
        ..shader = SweepGradient(
          center: FractionalOffset.center,
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [
            (colorMap[category] ?? Colors.grey).withAlpha((0.95 * 255).toInt()),
            (colorMap[category] ?? Colors.grey).withAlpha((0.7 * 255).toInt()),
          ],
        ).createShader(Rect.fromCircle(center: segmentCenter, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: segmentCenter, radius: radius),
        startAngle,
        sweepAngle,
        true,
        segmentPaint,
      );

      // Draw percentage text if enabled
      if (showPercentages && progress > 0.5 && (value / total) > 0.1) {
        final double percentage = (value / total) * 100;
        // Position text in the middle of the segment
        final double textRadius = radius * 0.7 + popOut;
        final double x = segmentCenter.dx + textRadius * math.cos(middleAngle);
        final double y = segmentCenter.dy + textRadius * math.sin(middleAngle);

        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Center text on the calculated position
        textPainter.paint(
          canvas,
          Offset(
            x - textPainter.width / 2,
            y - textPainter.height / 2,
          ),
        );
      }

      startAngle += sweepAngle;
    }
    
    // Animate center hole for donut chart effect
    final Paint holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final double donutRadius = radius * (0.5 * progress.clamp(0.0, 1.0));
    if (donutRadius > 0) {
      canvas.drawCircle(center, donutRadius, holePaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.data != data ||
           oldDelegate.progress != progress ||
           oldDelegate.colorMap != colorMap;
  }
}
