import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// A widget that displays a loading overlay with customizable animation
class LoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;
  final Color color;
  final String? message;
  final bool showBackground;
  final Duration animationDuration;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.color = Colors.blue,
    this.message,
    this.showBackground = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  LoadingOverlayState createState() => LoadingOverlayState();
}

class LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          AnimatedOpacity(
            opacity: widget.isLoading ? 1.0 : 0.0,
            duration: widget.animationDuration,
            child: Container(
              color: widget.showBackground
                  ? Colors.black.withAlpha(50)
                  : Colors.transparent,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _controller.value * 2 * math.pi,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.color,
                                width: 4,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                              gradient: SweepGradient(
                                colors: [
                                  widget.color.withAlpha(50),
                                  widget.color,
                                ],
                                stops: const [0.75, 1.0],
                                transform: GradientRotation(_controller.value * 2 * math.pi),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.message != null) ...[                      
                      const SizedBox(height: 16),
                      Text(
                        widget.message!,
                        style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate()
                        .fadeIn(duration: const Duration(milliseconds: 300))
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A widget that displays a data loading animation with a pulsing effect
class DataLoadingIndicator extends StatelessWidget {
  final bool isLoading;
  final double size;
  final Color color;
  final String? message;

  const DataLoadingIndicator({
    super.key,
    required this.isLoading,
    this.size = 40.0,
    this.color = Colors.blue,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.1, 1.1),
              duration: const Duration(milliseconds: 800),
            )
            .then()
            .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(0.8, 0.8),
              duration: const Duration(milliseconds: 800),
            ),
        if (message != null) ...[          
          const SizedBox(height: 12),
          Text(
            message!,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
