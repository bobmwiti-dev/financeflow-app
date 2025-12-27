import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../themes/app_theme.dart';

/// A custom animated loading indicator for the FinanceFlow app
class AnimatedLoadingIndicator extends StatelessWidget {
  /// The size of the loading indicator
  final double size;
  
  /// The color of the loading indicator (defaults to primary color)
  final Color? color;
  
  /// The stroke width of the loading indicator
  final double strokeWidth;
  
  /// Creates an animated loading indicator
  const AnimatedLoadingIndicator({
    super.key,
    this.size = 50.0,
    this.color,
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppTheme.primaryColor;
    final secondaryColor = AppTheme.accentColor;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle
          _buildCircle(
            size: size,
            color: primaryColor.withValues(alpha: 0.3),
            strokeWidth: strokeWidth,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: const Duration(seconds: 3)),
          
          // Middle circle
          _buildCircle(
            size: size * 0.75,
            color: primaryColor.withValues(alpha: 0.5),
            strokeWidth: strokeWidth,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: const Duration(seconds: 2), begin: 0.5),
          
          // Inner circle
          _buildCircle(
            size: size * 0.5,
            color: secondaryColor,
            strokeWidth: strokeWidth,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: const Duration(seconds: 1), begin: 0.25),
          
          // Center dot
          Container(
            width: size * 0.15,
            height: size * 0.15,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: const Duration(milliseconds: 600),
              ),
        ],
      ),
    );
  }
  
  Widget _buildCircle({
    required double size,
    required Color color,
    required double strokeWidth,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: strokeWidth,
        ),
      ),
      child: Center(
        child: Container(
          width: strokeWidth * 2,
          height: strokeWidth * 2,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// A pulsating dot indicator for loading states
class PulsatingDot extends StatelessWidget {
  final Color color;
  final double size;
  
  const PulsatingDot({
    super.key,
    required this.color,
    this.size = 10.0,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        )
        .fadeIn(duration: const Duration(milliseconds: 300));
  }
}

/// A row of pulsating dots for loading states
class PulsatingDots extends StatelessWidget {
  final Color color;
  final int count;
  final double size;
  final double spacing;
  
  const PulsatingDots({
    super.key,
    required this.color,
    this.count = 3,
    this.size = 10.0,
    this.spacing = 5.0,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: PulsatingDot(
            color: color,
            size: size,
          )
              .animate(delay: Duration(milliseconds: 150 * index))
              .fadeIn(duration: const Duration(milliseconds: 300))
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              ),
        ),
      ),
    );
  }
}
