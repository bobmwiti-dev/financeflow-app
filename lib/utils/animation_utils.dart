import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animation utilities for the FinanceFlow app
class AnimationUtils {
  /// Default duration for most animations
  static const Duration defaultDuration = Duration(milliseconds: 300);
  
  /// Longer duration for more complex animations
  static const Duration longDuration = Duration(milliseconds: 500);
  
  /// Very short duration for micro-interactions
  static const Duration quickDuration = Duration(milliseconds: 150);
  
  /// Standard curve for most animations
  static const Curve defaultCurve = Curves.easeInOut;
  
  /// Bouncy curve for playful animations
  static const Curve bouncyCurve = Curves.elasticOut;
  
  /// Apply a fade-in and slide-up animation to a widget
  static Widget fadeSlideIn(Widget child, {Duration? delay}) {
    return child
        .animate(delay: delay ?? Duration.zero)
        .fade(duration: defaultDuration)
        .slideY(begin: 0.2, end: 0, duration: defaultDuration, curve: defaultCurve);
  }
  
  /// Apply a scale animation for buttons and interactive elements
  static Widget scaleOnHover(Widget child) {
    return child
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: longDuration,
          curve: Curves.easeInOut,
        );
  }
  
  /// Apply a shimmer effect for loading states
  static Widget shimmer(Widget child) {
    return child
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .shimmer(
          duration: Duration(seconds: 2),
          color: Colors.white.withValues(alpha: 0.5),
        );
  }
  
  /// Apply a pulse animation for notifications or alerts
  static Widget pulse(Widget child) {
    return child
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: Duration(milliseconds: 600),
        );
  }
  
  /// Create a staggered animation for lists
  static List<Widget> staggeredList(List<Widget> children, {int? startIndex, Duration? staggerDuration}) {
    final start = startIndex ?? 0;
    final stagger = staggerDuration ?? const Duration(milliseconds: 50);
    
    return List.generate(
      children.length,
      (index) => children[index]
          .animate()
          .fade(
            duration: defaultDuration,
            delay: stagger * (index + start),
          )
          .slideY(
            begin: 0.1,
            end: 0,
            duration: defaultDuration,
            delay: stagger * (index + start),
            curve: defaultCurve,
          ),
    );
  }
}

/// Extension methods for AnimationController
extension AnimationControllerExtension on AnimationController {
  /// Play animation forward if it's not already playing
  void playIfNotPlaying() {
    if (!isAnimating && value < 1.0) {
      forward();
    }
  }
  
  /// Reset and play animation
  void resetAndPlay() {
    reset();
    forward();
  }
}
