import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/connectivity_service.dart';

/// A widget that displays the current sync status with a beautiful animation
class SyncStatusIndicator extends StatefulWidget {
  final bool isSyncing;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;

  const SyncStatusIndicator({
    super.key,
    required this.isSyncing,
    this.color = Colors.blue,
    this.size = 24.0,
    this.onTap,
    this.tooltip,
  });

  @override
  SyncStatusIndicatorState createState() => SyncStatusIndicatorState();
}

class SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isSyncing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SyncStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing != oldWidget.isSyncing) {
      if (widget.isSyncing) {
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
    final connectivityService = ConnectivityService.instance;
    final isOnline = connectivityService.isOnline;

    Widget icon;
    if (!isOnline) {
      // Offline icon
      icon = Icon(
        Icons.cloud_off,
        color: Colors.grey,
        size: widget.size,
      );
    } else if (widget.isSyncing) {
      // Syncing animation
      icon = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                Icons.sync,
                color: widget.color,
                size: widget.size,
              ),
            ),
          );
        },
      );
    } else {
      // Synced icon
      icon = Icon(
        Icons.cloud_done,
        color: widget.color,
        size: widget.size,
      );
    }

    // Add tooltip if provided
    if (widget.tooltip != null) {
      icon = Tooltip(
        message: widget.tooltip!,
        child: icon,
      );
    }

    // Add tap handler if provided
    if (widget.onTap != null) {
      icon = InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(widget.size),
        child: icon,
      );
    }

    return icon;
  }
}

/// A widget that displays a banner when the app is offline
class OfflineBanner extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final VoidCallback? onTap;

  const OfflineBanner({
    super.key,
    this.message = 'You are offline. Some features may be limited.',
    this.backgroundColor = Colors.orange,
    this.textColor = Colors.white,
    this.height = 36.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final connectivityService = ConnectivityService.instance;
    final isOnline = connectivityService.isOnline;

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                color: Colors.white,
                size: 16.0,
              ),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that wraps content and shows a loading indicator when syncing
class SyncAwareContainer extends StatelessWidget {
  final Widget child;
  final bool isSyncing;
  final Widget? loadingIndicator;
  final bool showOverlay;

  const SyncAwareContainer({
    super.key,
    required this.child,
    required this.isSyncing,
    this.loadingIndicator,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSyncing) {
      return child;
    }

    return Stack(
      children: [
        child,
        if (showOverlay)
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(26), 
              child: Center(
                child: loadingIndicator ??
                    const CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
