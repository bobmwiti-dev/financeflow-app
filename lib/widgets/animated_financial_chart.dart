import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/enhanced_animations.dart';
import '../themes/app_theme.dart';

/// Enum defining the types of financial charts available
enum ChartType {
  line,
  bar,
  pie,
  donut,
  area,
  radar
}

/// A unified animated financial chart component that renders different chart types
class AnimatedFinancialChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final ChartType type;
  final double height;
  final Function(Map<String, dynamic>)? onTap;
  final String? title;
  final bool animate;

  const AnimatedFinancialChart({
    super.key,
    required this.data,
    required this.type,
    this.height = 300,
    this.onTap,
    this.title,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check for empty or invalid data and display message
    if (data.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1 * 255),
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
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No data available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (type == ChartType.line || type == ChartType.bar)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Data will appear here soon',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ),
          ],
        ).animate().fadeIn(duration: 500.ms),
      );
    }
    
    // Add an additional safeguard for any possible errors
    try {
      Widget chart;
      
      switch (type) {
        case ChartType.pie:
          chart = _buildPieChart(context);
          break;
        case ChartType.donut:
          chart = _buildDonutChart(context);
          break;
        case ChartType.line:
          chart = _buildLineChart(context);
          break;
        case ChartType.bar:
          chart = _buildBarChart(context);
          break;
        case ChartType.area:
          chart = _buildAreaChart(context);
          break;
        case ChartType.radar:
          chart = _buildRadarChart(context);
          break;
      }
      
      // Apply animation if needed
      if (animate) {
        chart = chart.animate().fade(duration: 500.ms).scale(duration: 400.ms);
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          SizedBox(
            height: height,
            child: chart,
          ),
        ],
      );
    } catch (e) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 40,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5 * 255),
              ),
              const SizedBox(height: 8),
              Text(
                'An error occurred',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6 * 255),
                ),
              ),
            ],
          ),
        ),
      ).animate().fade(duration: 300.ms);
    }
    
  }
  
  // Build a pie chart visualization
  Widget _buildPieChart(BuildContext context) {
    // Simplified implementation for now
    return CustomPaint(
      painter: _PieChartPainter(
        data: data,
        onTapSegment: onTap,
      ),
      size: Size.infinite,
    );
  }
  
  // Build a donut chart visualization
  Widget _buildDonutChart(BuildContext context) {
    // Similar to pie chart but with inner circle cutout
    return CustomPaint(
      painter: _PieChartPainter(
        data: data,
        onTapSegment: onTap,
        innerRadiusPercent: 0.5, // Inner cutout for donut style
      ),
      size: Size.infinite,
    );
  }
  
  // Build a line chart visualization
  Widget _buildLineChart(BuildContext context) {
    // Extract numeric data points from map data
    final List<double> dataPoints = data
        .map((item) => (item['amount'] as num).toDouble())
        .toList();
        
    return AnimatedLineChart(
      dataPoints: dataPoints,
      height: height,
      animate: animate,
    );
  }
  
  // Build a bar chart visualization
  Widget _buildBarChart(BuildContext context) {
    // Convert map data to bar chart entries
    final List<BarChartEntry> entries = data
        .map((item) => BarChartEntry(
              label: item['category'] as String,
              value: (item['amount'] as num).toDouble(),
              color: ColorExtension.getColorForCategory(item['category'] as String),
            ))
        .toList();
        
    return AnimatedBarChart(
      data: entries,
      height: height,
      animate: animate,
    );
  }
  
  // Build an area chart visualization
  Widget _buildAreaChart(BuildContext context) {
    // Similar to line chart but with filled area below
    final List<double> dataPoints = data
        .map((item) => (item['amount'] as num).toDouble())
        .toList();
        
    return AnimatedLineChart(
      dataPoints: dataPoints,
      height: height,
      showGradient: true, // Show gradient fill below line
      animate: animate,
    );
  }
  
  // Build a radar chart visualization
  Widget _buildRadarChart(BuildContext context) {
    // Placeholder for radar chart implementation
    return Center(
      child: Text('Radar chart coming soon'),
    );
  }
}

// Using the existing BarChartEntry class defined below

/// Painter for pie charts
class _PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Function(Map<String, dynamic>)? onTapSegment;
  final double innerRadiusPercent;
  
  _PieChartPainter({
    required this.data,
    this.onTapSegment,
    this.innerRadiusPercent = 0.0, // 0 for pie, >0 for donut
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 : size.height / 2;
    
    // Calculate total value for percentage calculations
    final total = data.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );
    
    // Track the starting angle for each segment
    double startAngle = 0;
    
    // Draw each segment
    for (final item in data) {
      final value = (item['amount'] as num).toDouble();
      final sweepAngle = (value / total) * 2 * 3.14159; // Convert to radians
      
      final segmentPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = ColorExtension.getColorForCategory(item['category'] as String);
      
      // Draw the segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        segmentPaint,
      );
      
      // If it's a donut chart, draw the inner cutout
      if (innerRadiusPercent > 0) {
        final innerRadius = radius * innerRadiusPercent;
        final cutoutPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white;
        
        canvas.drawCircle(center, innerRadius, cutoutPaint);
      }
      
      // Update the start angle for the next segment
      startAngle += sweepAngle;
    }
  }
  
  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.innerRadiusPercent != innerRadiusPercent;
  }
}

/// Extension to get colors for different categories
class ColorExtension {
  static Color getColorForCategory(String category) {
    // Map category names to consistent colors
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'housing':
        return Colors.green;
      case 'utilities':
        return Colors.purple;
      case 'entertainment':
        return Colors.pink;
      case 'healthcare':
        return Colors.red;
      case 'education':
        return Colors.indigo;
      case 'shopping':
        return Colors.teal;
      case 'travel':
        return Colors.amber;
      case 'income':
        return Colors.lightGreen;
      default:
        // Generate a color based on the category string for consistency
        return Color(category.hashCode | 0xFF000000);
    }
  }
}

/// An animated line chart for financial data visualization
class AnimatedLineChart extends StatelessWidget {
  final List<double> dataPoints;
  final double height;
  final bool showGradient;
  final Color lineColor;
  final String? label;
  final bool animate;

  const AnimatedLineChart({
    super.key,
    required this.dataPoints,
    this.height = 120,
    this.showGradient = true,
    this.lineColor = AppTheme.primaryColor,
    this.label,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget chart = SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LineChartPainter(
          dataPoints: dataPoints,
          lineColor: lineColor,
          showGradient: showGradient,
          animationProgress: animate ? 0 : 1.0, // Start with 0 progress if animating
        ),
        size: Size.infinite,
      ),
    );

    // Apply animation if requested
    if (animate) {
      chart = chart
          .animate()
          .custom(
            duration: EnhancedAnimations.standardDuration,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _LineChartPainter(
                  dataPoints: dataPoints,
                  lineColor: lineColor,
                  showGradient: showGradient,
                  animationProgress: value,
                ),
                size: Size(double.infinity, height),
              );
            },
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[  
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
        ],
        chart,
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;
  final bool showGradient;
  final double animationProgress;

  _LineChartPainter({
    required this.dataPoints,
    required this.lineColor,
    required this.showGradient,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    // Find min and max values for scaling
    final double minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final double maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final double range = (maxValue - minValue) == 0 ? 1 : (maxValue - minValue);

    // Calculate horizontal and vertical spacing
    final double horizontalSpacing = size.width / (dataPoints.length - 1);
    // Add some padding at the top and bottom
    final double verticalPadding = size.height * 0.1;
    final double availableHeight = size.height - (2 * verticalPadding);

    // Create path for the line
    final path = Path();
    final List<Offset> points = [];

    // Calculate points based on animation progress
    final int pointsToShow = (dataPoints.length * animationProgress).round();

    for (int i = 0; i < pointsToShow; i++) {
      final double x = i * horizontalSpacing;
      final double normalizedValue = (dataPoints[i] - minValue) / range;
      final double y = size.height - verticalPadding - (normalizedValue * availableHeight);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw the path
    canvas.drawPath(path, paint);

    // Draw gradient if requested
    if (showGradient && points.isNotEmpty) {
      final gradientPath = Path();
      gradientPath.addPath(path, Offset.zero);
      gradientPath.lineTo(points.last.dx, size.height);
      gradientPath.lineTo(0, size.height);
      gradientPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.0),
        ],
      );

      final gradientPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(gradientPath, gradientPaint);
    }

    // Draw dots at each data point
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.dataPoints != dataPoints ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.showGradient != showGradient;
  }
}

/// An animated bar chart for financial data visualization
class AnimatedBarChart extends StatelessWidget {
  final List<BarChartEntry> data;
  final double height;
  final bool animate;
  final String? label;

  const AnimatedBarChart({
    super.key,
    required this.data,
    this.height = 200,
    this.animate = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    Widget chart = SizedBox(
      height: height,
      child: CustomPaint(
        painter: _BarChartPainter(
          data: data,
          animationProgress: animate ? 0 : 1.0,
          textColor: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
        ),
        size: Size.infinite,
      ),
    );

    // Apply animation if requested
    if (animate) {
      chart = chart
          .animate()
          .custom(
            duration: EnhancedAnimations.standardDuration,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _BarChartPainter(
                  data: data,
                  animationProgress: value,
                  textColor: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                ),
                size: Size(double.infinity, height),
              );
            },
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[  
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
        ],
        chart,
      ],
    );
  }
}

class BarChartEntry {
  final String label;
  final double value;
  final Color color;

  BarChartEntry({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _BarChartPainter extends CustomPainter {
  final List<BarChartEntry> data;
  final double animationProgress;
  final Color textColor;

  _BarChartPainter({
    required this.data,
    required this.animationProgress,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double barWidth = size.width / data.length - 16; // Leave some spacing
    final textStyle = TextStyle(color: textColor, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw bars and labels
    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final barHeight = size.height * 0.75 * (entry.value / maxValue) * animationProgress;
      final startX = i * (size.width / data.length) + 8; // Center each bar

      // Draw bar
      final barPaint = Paint()
        ..color = entry.color
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            entry.color,
            entry.color.withValues(alpha: 0.7),
          ],
        ).createShader(Rect.fromLTWH(
          startX,
          size.height - barHeight,
          barWidth,
          barHeight,
        ));

      // Draw rounded rectangle for bar
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX,
          size.height - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(barRect, barPaint);

      // Draw label below bar
      textPainter.text = TextSpan(text: entry.label, style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          startX + (barWidth / 2) - (textPainter.width / 2),
          size.height - barHeight - 16,
        ),
      );

      // Draw value on top of bar
      textPainter.text = TextSpan(
        text: entry.value.toStringAsFixed(0),
        style: textStyle.copyWith(fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          startX + (barWidth / 2) - (textPainter.width / 2),
          size.height - barHeight - 30,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.data != data;
  }
}

/// A circular progress chart with animation
class AnimatedCircularChart extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final Color color;
  final Color backgroundColor;
  final String label;
  final bool animate;
  final Widget? centerWidget;

  const AnimatedCircularChart({
    super.key,
    required this.value,
    required this.label,
    this.size = 150,
    this.color = AppTheme.primaryColor,
    this.backgroundColor = Colors.grey,
    this.animate = true,
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget chart = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _CircularChartPainter(
              value: animate ? 0 : value,
              color: color,
              backgroundColor: backgroundColor.withValues(alpha: 0.2),
            ),
            size: Size.square(size),
          ),
          // Center content
          centerWidget ?? Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: size / 5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );

    // Apply animation if requested
    if (animate) {
      chart = chart
          .animate()
          .custom(
            duration: EnhancedAnimations.standardDuration,
            curve: Curves.easeOutQuad,
            builder: (context, progress, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    painter: _CircularChartPainter(
                      value: value * progress,
                      color: color,
                      backgroundColor: backgroundColor.withValues(alpha: 0.2),
                    ),
                    size: Size.square(size),
                  ),
                  // Animated text
                  Text(
                    '${((value * progress) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: size / 5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              );
            },
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        chart,
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

class _CircularChartPainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color color;
  final Color backgroundColor;

  _CircularChartPainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10; // Leave some padding
    const startAngle = -90 * (3.14159 / 180); // Start from the top (in radians)
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
      
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
      
    final sweepAngle = value * 2 * 3.14159; // Full circle is 2*pi radians
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularChartPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
