import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that animates list items when they are added, removed, or updated.
/// This provides a more engaging user experience for real-time data changes.
class AnimatedDataList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, Animation<double>) itemBuilder;
  final Duration duration;
  final Curve curve;
  final bool showItemRemovalAnimation;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? emptyWidget;
  final Function(T)? itemKey;
  final String Function(T)? keyExtractor;

  const AnimatedDataList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.showItemRemovalAnimation = true,
    this.scrollController,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.emptyWidget,
    this.itemKey,
    this.keyExtractor,
  });

  @override
  AnimatedDataListState<T> createState() => AnimatedDataListState<T>();
}

class AnimatedDataListState<T> extends State<AnimatedDataList<T>> with TickerProviderStateMixin {
  final List<_AnimatedItem<T>> _animatedItems = [];
  final Map<Key, _AnimatedItem<T>> _itemMap = {};

  @override
  void initState() {
    super.initState();
    _updateItems();
  }

  @override
  void didUpdateWidget(AnimatedDataList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateItems();
  }

  void _updateItems() {
    final newItemMap = <Key, _AnimatedItem<T>>{};
    final List<_AnimatedItem<T>> newAnimatedItems = [];

    // Process new items
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final key = widget.keyExtractor != null
          ? ValueKey(widget.keyExtractor!(item))
          : widget.itemKey != null
              ? ValueKey(widget.itemKey!(item))
              : ValueKey(item.hashCode);

      if (_itemMap.containsKey(key)) {
        // Item exists, update it
        final existingItem = _itemMap[key]!;
        existingItem.item = item;
        // Make sure the animation is completed (no need to set value directly)
        if (!existingItem.controller.isCompleted) {
          existingItem.controller.forward();
        }
        newAnimatedItems.add(existingItem);
        newItemMap[key] = existingItem;
      } else {
        // New item, create animation
        final controller = AnimationController(
          duration: widget.duration,
          vsync: this,
        );
        final animation = CurvedAnimation(
          parent: controller,
          curve: widget.curve,
        );

        final animatedItem = _AnimatedItem<T>(
          key: key,
          item: item,
          controller: controller,
          animation: animation,
        );

        controller.forward();
        newAnimatedItems.add(animatedItem);
        newItemMap[key] = animatedItem;
      }
    }

    // Handle removed items
    if (widget.showItemRemovalAnimation) {
      for (final existingItem in _animatedItems) {
        if (!newItemMap.containsKey(existingItem.key)) {
          // Item was removed, animate it out
          existingItem.controller.reverse().then((_) {
            existingItem.controller.dispose();
          });
          newAnimatedItems.add(existingItem);
        }
      }
    }

    // Update state
    _animatedItems.clear();
    _animatedItems.addAll(newAnimatedItems);
    _itemMap.clear();
    _itemMap.addAll(newItemMap);
  }

  @override
  void dispose() {
    for (final item in _animatedItems) {
      item.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: _animatedItems.length,
      itemBuilder: (context, index) {
        final animatedItem = _animatedItems[index];
        return AnimatedBuilder(
          animation: animatedItem.animation,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: animatedItem.animation,
              child: FadeTransition(
                opacity: animatedItem.animation,
                child: widget.itemBuilder(context, animatedItem.item, animatedItem.animation),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnimatedItem<T> {
  final Key key;
  T item;
  final AnimationController controller;
  final Animation<double> animation;

  _AnimatedItem({
    required this.key,
    required this.item,
    required this.controller,
    required this.animation,
  });
}

/// A widget that animates when its data changes, with a pulse effect.
class AnimatedDataItem extends StatefulWidget {
  final Widget child;
  final Object? value;
  final Duration duration;
  final Curve curve;

  const AnimatedDataItem({
    super.key,
    required this.child,
    required this.value,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.elasticOut,
  });

  @override
  AnimatedDataItemState createState() => AnimatedDataItemState();
}

class AnimatedDataItemState extends State<AnimatedDataItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Object? _oldValue;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void didUpdateWidget(AnimatedDataItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _oldValue) {
      _controller.forward(from: 0.0);
      _oldValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// A widget that shows a shimmer loading effect while data is being loaded.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFFFFFFF),
  });

  @override
  ShimmerLoadingState createState() => ShimmerLoadingState();
}

class ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
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
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final gradient = LinearGradient(
          colors: [
            widget.baseColor,
            widget.highlightColor,
            widget.baseColor,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: _SlidingGradientTransform(
            slidePercent: _controller.value,
          ),
        );

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return gradient.createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0.0,
      0.0,
    );
  }
}

/// A widget that animates when a new item is added to a list.
class AnimatedAddition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedAddition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
  });

  @override
  AnimatedAdditionState createState() => AnimatedAdditionState();
}

class AnimatedAdditionState extends State<AnimatedAddition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      child: FadeTransition(
        opacity: _animation,
        child: widget.child,
      ),
    );
  }
}

/// A widget that shows a sync indicator when data is being synchronized with the cloud.
class CloudSyncIndicator extends StatefulWidget {
  final bool isSyncing;
  final Color color;
  final double size;
  final Duration duration;

  const CloudSyncIndicator({
    super.key,
    required this.isSyncing,
    this.color = Colors.blue,
    this.size = 24.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  CloudSyncIndicatorState createState() => CloudSyncIndicatorState();
}

class CloudSyncIndicatorState extends State<CloudSyncIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    if (widget.isSyncing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CloudSyncIndicator oldWidget) {
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
    if (!widget.isSyncing) {
      return Icon(
        Icons.cloud_done,
        color: widget.color,
        size: widget.size,
      );
    }

    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Icon(
            Icons.sync,
            color: widget.color,
            size: widget.size,
          ),
        );
      },
    );
  }
}
