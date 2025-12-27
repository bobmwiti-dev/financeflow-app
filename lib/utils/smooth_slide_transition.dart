import 'package:flutter/material.dart';
import 'enhanced_animations.dart';

/// Enum for slide direction
enum SlideDirection {
  rightToLeft,
  leftToRight,
  bottomToTop,
  topToBottom,
}

/// A smooth slide transition with subtle elevation and shadow effects
/// Creates a premium feeling transition between screens
class SmoothSlideTransition<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;
  final Curve curve;

  SmoothSlideTransition({
    required this.page,
    this.direction = SlideDirection.rightToLeft,
    this.curve = Curves.easeOutQuint,
    String? routeName,
    super.fullscreenDialog,
  }) : super(
          settings: routeName != null ? RouteSettings(name: routeName) : null,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Define start position based on direction
            Offset begin;
            switch (direction) {
              case SlideDirection.rightToLeft:
                begin = const Offset(1.0, 0.0);
                break;
              case SlideDirection.leftToRight:
                begin = const Offset(-1.0, 0.0);
                break;
              case SlideDirection.bottomToTop:
                begin = const Offset(0.0, 1.0);
                break;
              case SlideDirection.topToBottom:
                begin = const Offset(0.0, -1.0);
                break;
            }

            // Create curved animation
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            // Slide animation
            final slideAnimation = Tween(
              begin: begin,
              end: Offset.zero,
            ).animate(curvedAnimation);

            // Scale animation for subtle 3D effect
            final scaleAnimation = Tween(
              begin: 0.96,
              end: 1.0,
            ).animate(curvedAnimation);

            // Opacity animation for smooth fade-in
            final opacityAnimation = Tween(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
            ));

            // Shadow animation for elevation effect
            final elevationAnimation = Tween(
              begin: 0.0,
              end: 8.0,
            ).animate(curvedAnimation);

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: opacityAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(38), // 0.15 * 255 = 38.25 ≈ 38
                          blurRadius: elevationAnimation.value,
                          spreadRadius: elevationAnimation.value / 4,
                          offset: Offset(0, elevationAnimation.value / 2),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
          transitionDuration: EnhancedAnimations.standardDuration,
        );
}
