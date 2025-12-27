import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/enhanced_animations.dart';

/// A collection of custom page transitions to enhance the app navigation experience
class PageTransitions {
  /// Creates a slide transition from right to left
  static PageRoute<T> slideTransition<T>(
    Widget page, {
    String? routeName,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      settings: routeName != null ? RouteSettings(name: routeName) : null,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeOutQuint;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: EnhancedAnimations.standardDuration,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Creates a fade transition with a slight scale effect and elevated feel
  static PageRoute<T> fadeScaleTransition<T>(
    Widget page, {
    String? routeName,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      settings: routeName != null ? RouteSettings(name: routeName) : null,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeOutQuint;

        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: EnhancedAnimations.standardDuration,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Creates a transition that slides up from the bottom with a fade
  static PageRoute<T> slideUpTransition<T>(
    Widget page, {
    String? routeName,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      settings: routeName != null ? RouteSettings(name: routeName) : null,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(0.0, 0.3);
        var end = Offset.zero;
        var curve = Curves.easeOutQuint;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
      transitionDuration: EnhancedAnimations.standardDuration,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Creates a fancy animated reveal transition with a custom circular shape
  static PageRoute<T> circularRevealTransition<T>(
    Widget page, {
    String? routeName,
    bool fullscreenDialog = false,
    Alignment alignment = Alignment.center,
  }) {
    return PageRouteBuilder<T>(
      settings: routeName != null ? RouteSettings(name: routeName) : null,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return CircularRevealTransition(
          animation: animation,
          centerAlignment: alignment,
          child: child,
        );
      },
      transitionDuration: EnhancedAnimations.standardDuration,
      fullscreenDialog: fullscreenDialog,
    );
  }
}

/// Enum for flip direction
enum FlipDirection {
  horizontal,
  vertical,
}

/// Custom spring curve for bouncy animations
class SpringCurve extends Curve {
  final double damping;
  final double stiffness;
  final double mass;
  final double velocity;
  
  const SpringCurve({
    required this.damping,
    required this.stiffness,
    required this.mass,
    required this.velocity,
  });
  
  @override
  double transform(double t) {
    // Simple spring physics approximation
    final beta = damping / (2 * math.sqrt(stiffness * mass));
    final omega = math.sqrt(stiffness / mass);
    
    if (beta < 1.0) {
      // Underdamped spring (bouncy)
      final omegaD = omega * math.sqrt(1.0 - beta * beta);
      final A = 1.0;
      final B = (beta * omega + velocity) / omegaD;
      
      return 1.0 - math.exp(-beta * omega * t) * 
             (A * math.cos(omegaD * t) + B * math.sin(omegaD * t));
    } else {
      // Critically damped or overdamped (no bounce)
      return 1.0 - (1.0 + t) * math.exp(-t);
    }
  }
}

/// A widget that animates the reveal of its child using a circular shape
class CircularRevealTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Alignment centerAlignment;

  const CircularRevealTransition({
    super.key,
    required this.child,
    required this.animation,
    this.centerAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipPath(
          clipper: CircularRevealClipper(
            fraction: animation.value,
            centerAlignment: centerAlignment,
          ),
          child: child,
        );
      },
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.5, 1.0),
        ),
        child: child,
      ),
    );
  }
}

/// A clipper that creates a circular reveal effect
class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Alignment centerAlignment;

  CircularRevealClipper({
    required this.fraction,
    this.centerAlignment = Alignment.center,
  });

  @override
  Path getClip(Size size) {
    final Offset center = centerAlignment.alongSize(size);
    final radius = size.height > size.width 
        ? size.height * 1.2 
        : size.width * 1.2;
    
    final path = Path();
    path.addOval(
      Rect.fromCircle(
        center: center,
        radius: radius * fraction,
      ),
    );
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
