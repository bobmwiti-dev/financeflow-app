import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A beautifully animated circular progress indicator with interactive elements
/// and visual feedback that brings financial data to life.
class AnimatedCircularProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color primaryColor;
  final Color? backgroundColor;
  final IconData? icon;
  final String? centerText;
  final TextStyle? centerTextStyle;
  final String? label;
  final VoidCallback? onTap;
  final int animationDelayMs;

  const AnimatedCircularProgressIndicator({
    super.key,
    required this.progress,
    this.size = 150.0,
    this.strokeWidth = 10.0,
    required this.primaryColor,
    this.backgroundColor,
    this.icon,
    this.centerText,
    this.centerTextStyle,
    this.label,
    this.onTap,
    this.animationDelayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? 
        Theme.of(context).colorScheme.surface;
        
    // The container for the progress indicator
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveBackgroundColor,
              ),
            )
            .animate(delay: Duration(milliseconds: animationDelayMs))
            .scale(duration: const Duration(milliseconds: 600), curve: Curves.easeOutBack),
            
            // Progress arc - animated to gradually reveal
            _AnimatedProgressArc(
              progress: progress,
              strokeWidth: strokeWidth,
              color: primaryColor,
              size: size,
              delayMs: animationDelayMs + 300,
            ),
            
            // Center content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[  
                  Icon(
                    icon!,
                    size: size * 0.25,
                    color: primaryColor,
                  )
                  .animate(delay: Duration(milliseconds: animationDelayMs + 600))
                  .fadeIn()
                  .scale(curve: Curves.elasticOut),
                  SizedBox(height: size * 0.05),
                ],
                if (centerText != null) ...[  
                  Text(
                    centerText!,
                    style: centerTextStyle ?? TextStyle(
                      fontSize: size * 0.18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate(delay: Duration(milliseconds: animationDelayMs + 700))
                  .fadeIn()
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuint),
                ],
              ],
            ),
            
            // Label below the progress indicator
            if (label != null)
              Positioned(
                bottom: 0,
                child: Text(
                  label!,
                  style: TextStyle(
                    fontSize: size * 0.1,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                )
                .animate(delay: Duration(milliseconds: animationDelayMs + 800))
                .fadeIn()
                .slideY(begin: 0.5, end: 0),
              ),
              
            // Interactive ripple effect on hover/tap
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: onTap,
                  splashColor: primaryColor.withValues(alpha: 0.2),
                  highlightColor: primaryColor.withValues(alpha: 0.1),
                  child: Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal budget progress bar with animated filling
class AnimatedBudgetProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color color;
  final Color? backgroundColor;
  final String? label;
  final String? valueLabel;
  final int animationDelayMs;
  final bool showPercentage;

  const AnimatedBudgetProgressBar({
    super.key,
    required this.progress,
    this.height = 12.0,
    required this.color,
    this.backgroundColor,
    this.label,
    this.valueLabel,
    this.animationDelayMs = 0,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? 
        Theme.of(context).colorScheme.surfaceContainerHighest;
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[  
          Text(
            label!,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          )
          .animate(delay: Duration(milliseconds: animationDelayMs))
          .fadeIn()
          .slideX(begin: -0.1, end: 0),
          const SizedBox(height: 6),
        ],
        Stack(
          children: [
            // Background bar
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: effectiveBackgroundColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            
            // Animated progress bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                // Gradient for more visual appeal
                gradient: LinearGradient(
                  colors: [
                    color,
                    Color.lerp(color, Colors.white, 0.3)!,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                // Add subtle shadow for depth
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // Use ClipRect to animate the width
              child: ClipRect(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                )
                .animate(delay: Duration(milliseconds: animationDelayMs + 300))
                .custom(
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutQuart,
                  builder: (context, animationValue, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: animationValue * progress,
                      child: child,
                    );
                  }
                ),
              ),
            ),
            
            // Add shimmer effect for polish
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
              ),
            )
            .animate(delay: Duration(milliseconds: animationDelayMs + 1200))
            .shimmer(
              size: 2,
              angle: 0,
              duration: const Duration(milliseconds: 2000),
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
        
        if (valueLabel != null || showPercentage) ...[  
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (valueLabel != null)
                Text(
                  valueLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                )
                .animate(delay: Duration(milliseconds: animationDelayMs + 600))
                .fadeIn(),
              if (showPercentage)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                )
                .animate(delay: Duration(milliseconds: animationDelayMs + 600))
                .fadeIn(),
            ],
          ),
        ],
      ],
    );
  }
}

/// A custom arc painter for the circular progress indicator
class _AnimatedProgressArc extends StatelessWidget {
  final double progress;
  final double strokeWidth;
  final Color color;
  final double size;
  final int delayMs;

  const _AnimatedProgressArc({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.size,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ProgressArcPainter(
        strokeWidth: strokeWidth,
        color: color,
      ),
    )
    .animate(delay: Duration(milliseconds: delayMs))
    .custom(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutQuart,
      builder: (context, animationValue, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: _ProgressArcPainter(
            progress: animationValue * progress,
            strokeWidth: strokeWidth,
            color: color,
          ),
        );
      }
    );
  }
}

/// Painter for drawing the circular progress arc
class _ProgressArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _ProgressArcPainter({
    this.progress = 0.0,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    // The arc starts from the top (270 degrees) and moves clockwise
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90 degrees in radians (start from top)
      progress * 6.2832, // 2π radians for full circle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color;
  }
}
