import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../themes/app_theme.dart';

/// Enhanced animations for the FinanceFlow app
/// Provides modern, polished animations for a premium feel
class EnhancedAnimations {
  /// Duration for micro-interactions
  static const Duration microDuration = Duration(milliseconds: 120);
  
  /// Duration for standard animations
  static const Duration standardDuration = Duration(milliseconds: 350);
  
  /// Duration for elaborate animations
  static const Duration elaborateDuration = Duration(milliseconds: 650);
  
  /// Apply a modern card entrance animation
  static Widget cardEntrance(Widget child, {int? index}) {
    final delay = index != null ? Duration(milliseconds: 50 * index) : Duration.zero;
    
    return child
      .animate(delay: delay)
      .fadeIn(duration: standardDuration)
      .slideY(
        begin: 0.1, 
        end: 0,
        curve: Curves.easeOutQuint,
        duration: standardDuration
      )
      .scaleXY(
        begin: 0.95, 
        end: 1.0,
        curve: Curves.easeOutQuint,
        duration: standardDuration
      );
  }
  
  /// Apply a shimmer loading effect to a widget
  static Widget shimmerLoading(Widget child, {int? index}) {
    final delay = index != null ? Duration(milliseconds: 50 * index) : Duration.zero;
    
    // Create a repeating shimmer effect
    return child
      .animate(delay: delay)
      .shimmer(duration: const Duration(milliseconds: 1200), color: Colors.white.withAlpha(127))
      .then(delay: const Duration(milliseconds: 600))
      .shimmer(duration: const Duration(milliseconds: 1200), color: Colors.white.withAlpha(127));
  }
  
  /// Create an animated icon with scale and shake effects
  static Widget animatedIcon(IconData icon, {double size = 24, Color? color}) {
    return Icon(
      icon,
      size: size,
      color: color,
    )
    .animate()
    .scale(duration: const Duration(milliseconds: 600), curve: Curves.easeOutBack)
    .then(delay: const Duration(milliseconds: 200))
    .shake(hz: 2, rotation: 0.02);
  }
  
  /// Create a text widget that fades in with a delay
  static Widget fadeInText(String text, {
    TextStyle? style, 
    TextAlign? textAlign,
    int delayMillis = 0,
  }) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
    )
    .animate()
    .fadeIn(
      delay: Duration(milliseconds: delayMillis), 
      duration: const Duration(milliseconds: 600)
    );
  }
  
  /// Create an animated button with fade in and slide effects
  static Widget animatedButton(Widget button, {int delayMillis = 0}) {
    return button
      .animate()
      .fadeIn(
        delay: Duration(milliseconds: delayMillis), 
        duration: const Duration(milliseconds: 600)
      )
      .slideY(
        begin: 0.3, 
        end: 0, 
        delay: Duration(milliseconds: delayMillis),
        duration: const Duration(milliseconds: 600), 
        curve: Curves.easeOutBack
      );
  }
  
  /// Apply a scale effect on tap with haptic feedback
  static Widget scaleOnTap({
    required Widget child,
    required VoidCallback onTap,
    double scaleValue = 0.95,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: child
          .animate(target: 0) // Start with the normal state
          .scaleXY(
            begin: 1.0,
            end: scaleValue,
            curve: Curves.easeOut,
            duration: microDuration,
          )
          .then() // Chain animations
          .scaleXY(
            begin: scaleValue,
            end: 1.0,
            curve: Curves.easeOut,
            duration: microDuration,
          ),
      ),
    );
  }
  
  /// Apply a modern hover effect for interactive elements
  static Widget modernHoverEffect({
    required Widget child,
    double scale = 1.03,
    double elevation = 4.0,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return _ModernHoverEffect(
      scale: scale,
      elevation: elevation,
      duration: duration,
      child: child,
    );
  }
  
  /// Create a widget with fade and slide animation
  static Widget fadeSlide({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Offset begin = const Offset(0, 0.05),
    Offset end = Offset.zero,
    Curve curve = Curves.easeOutCubic,
  }) {
    return child
      .animate()
      .fadeIn(duration: duration, curve: curve)
      .slide(begin: begin, end: end, duration: duration, curve: curve);
  }

  
  /// Apply a staggered animation for list items with variable effects
  static List<Widget> staggeredListEffects(List<Widget> children) {
    return List.generate(
      children.length,
      (index) => children[index]
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: standardDuration)
        .moveY(
          begin: 20, 
          end: 0,
          curve: Curves.easeOutQuint,
          duration: standardDuration,
        )
        .blurY(begin: 4, end: 0)
        .animate(delay: Duration(milliseconds: 100 * index))
        .shimmer(
          duration: standardDuration,
          color: AppTheme.accentColor.withValues(alpha: 0.1),
        ),
    );
  }
  
  /// Apply a breathing effect for important UI elements
  static Widget breathingAnimation(Widget child, {Color? glowColor}) {
    final color = glowColor ?? AppTheme.primaryColor;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Container()
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(
            begin: 0.8,
            end: 1.2,
            duration: elaborateDuration,
            curve: Curves.easeInOut,
          )
          .tint(
            color: color.withValues(alpha: 0.2),
            duration: elaborateDuration,
          ),
        child,
      ],
    );
  }
  
  /// Apply a sleek transition for page routes
  static PageRouteBuilder sleekPageTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: standardDuration,
      reverseTransitionDuration: microDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeOutQuint;
        
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return Stack(
          children: [
            SlideTransition(position: offsetAnimation, child: child),
            FadeTransition(
              opacity: ReverseAnimation(animation),
              child: Container(color: Colors.black54),
            ),
          ],
        );
      },
    );
  }
}

/// A stateful widget that implements the modern hover effect
class _ModernHoverEffect extends StatefulWidget {
  final Widget child;
  final double scale;
  final double elevation;
  final Duration duration;

  const _ModernHoverEffect({
    required this.child,
    required this.scale,
    required this.elevation,
    required this.duration,
  });

  @override
  State<_ModernHoverEffect> createState() => _ModernHoverEffectState();
}

class _ModernHoverEffectState extends State<_ModernHoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() => _isHovered = false);
        }
      },
      child: AnimatedContainer(
        duration: widget.duration,
        transform: _isHovered
          ? (Matrix4.identity()..scale(widget.scale, widget.scale, 1.0))
          : Matrix4.identity(),
        decoration: BoxDecoration(
          boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: widget.elevation,
                  spreadRadius: 1,
                )
              ]
            : const [],
        ),
        child: widget.child,
      ),
    );
  }
}
