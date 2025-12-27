import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final bool animate;
  
  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    
    return child
      .animate()
      .fadeIn(
        duration: 400.ms, 
        delay: (50 * index).ms,
      )
      .slideY(
        begin: 0.1, 
        end: 0, 
        duration: 400.ms, 
        delay: (50 * index).ms,
        curve: Curves.easeOutCubic,
      );
  }
}
