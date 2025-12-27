import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../themes/app_theme.dart';
import '../utils/enhanced_animations.dart';

/// Static utility class for creating animated buttons easily
class AnimatedButtons {
  /// Creates a primary button with animation
  static Widget primaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    Color? color,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    return AnimatedPrimaryButton(
      text: label,
      onPressed: onPressed,
      icon: icon,
      color: color,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }
  
  /// Creates a secondary button with animation
  static Widget secondaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    Color? color,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    return AnimatedPrimaryButton(
      text: label,
      onPressed: onPressed,
      icon: icon,
      color: color ?? Colors.grey.shade200,
      isLoading: isLoading,
      fullWidth: fullWidth,
      elevated: false,
    );
  }
  
  /// Creates a text button with animation
  static Widget textButton({
    required String text,
    required VoidCallback onPressed,
    Color? color,
    bool underlined = false,
  }) {
    return AnimatedTextButton(
      text: text,
      onPressed: onPressed,
      color: color,
      underlined: underlined,
    );
  }
  
  /// Creates a floating action button with animation
  static Widget floatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
    Color? backgroundColor,
  }) {
    return AnimatedFloatingActionButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
    );
  }
}

/// A collection of animated buttons for the FinanceFlow app
/// These buttons provide visual feedback and modern interactions

/// A primary animated button with scale and highlight effects
class AnimatedPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final bool isLoading;
  final bool fullWidth;
  final double height;
  final bool elevated;

  const AnimatedPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 50,
    this.elevated = true,
  });

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: EnhancedAnimations.microDuration,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isLoading) return;
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isLoading) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    if (widget.isLoading) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppTheme.primaryColor;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: widget.fullWidth ? double.infinity : null,
            height: widget.height,
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: widget.elevated ? [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.3),
                  blurRadius: 8 - (_animationController.value * 4),
                  offset: Offset(0, 4 - (_animationController.value * 2)),
                ),
              ] : null,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _isPressed ? buttonColor.withValues(alpha: 0.9) : buttonColor,
                  Color.lerp(buttonColor, Colors.black, _isPressed ? 0.15 : 0.1) ?? buttonColor,
                ],
              ),
            ),
            transform: Matrix4.identity()..scale(1.0 - (_animationController.value * 0.04)),
            child: child,
          );
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[  
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A floating action button with animations and haptic feedback
class AnimatedFloatingActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;
  final bool mini;
  final bool extendedAnimation;

  const AnimatedFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.backgroundColor,
    this.tooltip,
    this.mini = false,
    this.extendedAnimation = true,
  });

  @override
  State<AnimatedFloatingActionButton> createState() => _AnimatedFloatingActionButtonState();
}

class _AnimatedFloatingActionButtonState extends State<AnimatedFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppTheme.primaryColor;
    Widget fab = FloatingActionButton(
      mini: widget.mini,
      backgroundColor: buttonColor,
      onPressed: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      tooltip: widget.tooltip,
      elevation: 4,
      child: Icon(widget.icon, color: Colors.white),
    );

    if (widget.extendedAnimation) {
      fab = fab
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
          );
    }

    return fab;
  }
}

/// An animated icon button with ripple effect
class AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final bool showBackground;
  final String? tooltip;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
    this.showBackground = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppTheme.primaryColor;

    Widget button = Material(
      color: showBackground ? buttonColor.withValues(alpha: 0.1) : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        splashColor: buttonColor.withValues(alpha: 0.2),
        highlightColor: buttonColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            color: buttonColor,
            size: size,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button
        .animate()
        .scaleXY(
          begin: 0.9,
          end: 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.elasticOut,
        );
  }
}

/// A toggle button with animation for on/off states
class AnimatedToggleButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final double width;
  final double height;
  final IconData? activeIcon;
  final IconData? inactiveIcon;

  const AnimatedToggleButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.width = 60,
    this.height = 30,
    this.activeIcon,
    this.inactiveIcon,
  });

  @override
  Widget build(BuildContext context) {
    final toggleColor = activeColor ?? AppTheme.primaryColor;
    final toggleInactiveColor = inactiveColor ?? Colors.grey.shade400;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: value ? toggleColor : toggleInactiveColor,
          boxShadow: [
            BoxShadow(
              color: (value ? toggleColor : toggleInactiveColor).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: value ? width - height + 2 : 2,
              top: 2,
              child: Container(
                width: height - 4,
                height: height - 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: value && activeIcon != null
                      ? Icon(activeIcon, size: 14, color: toggleColor)
                      : !value && inactiveIcon != null
                          ? Icon(inactiveIcon, size: 14, color: toggleInactiveColor)
                          : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An animated text button with subtle hover and tap effects
class AnimatedTextButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final bool underlined;

  const AnimatedTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.underlined = false,
  });

  @override
  State<AnimatedTextButton> createState() => _AnimatedTextButtonState();
}

class _AnimatedTextButtonState extends State<AnimatedTextButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.color ?? theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true;
        _controller.forward();
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
        _controller.reverse();
      }),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                widget.text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: primaryColor,
                  decoration: widget.underlined || _isHovered
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
                ),
              ).animate(
                controller: _controller,
                effects: [
                  ScaleEffect(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.05, 1.05),
                    curve: Curves.easeOut,
                  ),
                  ShimmerEffect(
                    color: primaryColor.withValues(alpha: 0.2),
                    delay: 50.ms,
                    duration: 700.ms,
                    curve: Curves.easeInOut,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A segmented control button with animated transitions
class AnimatedSegmentedControl<T> extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onSegmentTapped;
  final Color? activeColor;
  final double height;
  final double borderRadius;

  const AnimatedSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentTapped,
    this.activeColor,
    this.height = 44,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final segmentColor = activeColor ?? AppTheme.primaryColor;
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade200;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        children: [
          // Animated selection indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuint,
            left: selectedIndex * (MediaQuery.of(context).size.width - 32) / segments.length,
            top: 4,
            bottom: 4,
            width: (MediaQuery.of(context).size.width - 32) / segments.length,
            child: Container(
              decoration: BoxDecoration(
                color: segmentColor,
                borderRadius: BorderRadius.circular(borderRadius - 2),
                boxShadow: [
                  BoxShadow(
                    color: segmentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Segment buttons
          Row(
            children: List.generate(
              segments.length,
              (index) => Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (index != selectedIndex) {
                      HapticFeedback.selectionClick();
                      onSegmentTapped(index);
                    }
                  },
                  child: Center(
                    child: Text(
                      segments[index],
                      style: TextStyle(
                        color: index == selectedIndex
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight:
                            index == selectedIndex ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
