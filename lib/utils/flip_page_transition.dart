import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enum for flip direction
enum FlipDirection {
  horizontal,
  vertical,
}

/// A page transition that creates a 3D flip effect
class FlipPageTransition<T> extends PageRouteBuilder<T> {
  final Widget page;
  final FlipDirection direction;
  
  FlipPageTransition({
    required this.page,
    this.direction = FlipDirection.horizontal,
    String? routeName,
    super.fullscreenDialog,
  }) : super(
          settings: routeName != null ? RouteSettings(name: routeName) : null,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final animationCurve = Curves.easeOutBack;
            
            // Create curved animation for smoother transitions
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: animationCurve,
            );
            
            double rotationValue;
            if (direction == FlipDirection.horizontal) {
              rotationValue = curvedAnimation.value * math.pi; // 180 degrees flip horizontally
            } else {
              rotationValue = curvedAnimation.value * math.pi; // 180 degrees flip vertically
            }
            
            var perspectiveValue = 0.001; // Perspective effect strength
            
            var transform = Matrix4.identity()
              ..setEntry(3, 2, perspectiveValue) // Add perspective
              ..setEntry(3, 3, 1.0);
              
            if (direction == FlipDirection.horizontal) {
              transform.rotateY(rotationValue);
            } else {
              transform.rotateX(rotationValue);
            }
            
            // Only show the front half of the animation to avoid seeing the backside
            var showFront = (animation.value <= 0.5);
            var opacity = showFront ? 1.0 : 0.0;
            
            // At the halfway point, we flip to the actual page
            var childToShow = showFront ? Container(color: Colors.transparent) : child;
            
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 50),
              opacity: opacity,
              child: Transform(
                transform: transform,
                alignment: Alignment.center,
                child: childToShow,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        );
}
