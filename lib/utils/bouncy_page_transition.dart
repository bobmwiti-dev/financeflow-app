import 'package:flutter/material.dart';

/// A page transition that creates a bouncy elastic effect
class BouncyPageTransition<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  BouncyPageTransition({
    required this.page,
    String? routeName,
    super.fullscreenDialog = false,
  }) : super(
          settings: routeName != null ? RouteSettings(name: routeName) : null,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Create a custom spring curve for bouncy effect
            const curve = Curves.elasticOut;
            
            var slideAnimation = Tween<Offset>(
              begin: const Offset(1.5, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: curve));
            
            var scaleAnimation = Tween<double>(
              begin: 0.6,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: curve));
            
            var opacityAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
            
            return FadeTransition(
              opacity: opacityAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 700),
        );
}
