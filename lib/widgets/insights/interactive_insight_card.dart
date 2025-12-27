import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InteractiveInsightCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color primaryColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showTrend;
  final double? trendValue;
  final bool isPositiveTrend;

  const InteractiveInsightCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.primaryColor,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showTrend = false,
    this.trendValue,
    this.isPositiveTrend = true,
  });

  @override
  State<InteractiveInsightCard> createState() => _InteractiveInsightCardState();
}

class _InteractiveInsightCardState extends State<InteractiveInsightCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  late AnimationController _countController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _countAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _countController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _countAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    ));

    // Start count animation
    _countController.forward();
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * (_isHovered ? _pulseAnimation.value : 1.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.1),
                      blurRadius: _isHovered ? 25 : 15,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildValue(),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 8),
                      _buildSubtitle(),
                    ],
                    if (widget.showTrend && widget.trendValue != null) ...[
                      const SizedBox(height: 12),
                      _buildTrendIndicator(),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.primaryColor.withValues(alpha: 0.1),
                widget.primaryColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.primaryColor,
            size: 24,
          ),
        ).animate(delay: 200.ms)
          .scale(duration: 400.ms, curve: Curves.elasticOut),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }

  Widget _buildValue() {
    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        // Extract numeric value for animation
        final numericValue = _extractNumericValue(widget.value);
        final animatedValue = numericValue * _countAnimation.value;
        final displayValue = _formatAnimatedValue(widget.value, animatedValue);

        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              widget.primaryColor,
              widget.primaryColor.withValues(alpha: 0.7),
            ],
          ).createShader(bounds),
          child: Text(
            displayValue,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return Text(
      widget.subtitle!,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    ).animate(delay: 400.ms)
      .fadeIn(duration: 400.ms)
      .slideX(begin: 0.2, duration: 400.ms);
  }

  Widget _buildTrendIndicator() {
    final trendColor = widget.isPositiveTrend ? Colors.green : Colors.red;
    final trendIcon = widget.isPositiveTrend ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: trendColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trendIcon,
            color: trendColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.trendValue!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: trendColor,
            ),
          ),
        ],
      ),
    ).animate(delay: 600.ms)
      .fadeIn(duration: 400.ms)
      .scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut);
  }

  double _extractNumericValue(String value) {
    // Extract numeric value from strings like "$1,234.56" or "42 days"
    final regex = RegExp(r'[\d,]+\.?\d*');
    final match = regex.firstMatch(value);
    if (match != null) {
      final numStr = match.group(0)!.replaceAll(',', '');
      return double.tryParse(numStr) ?? 0.0;
    }
    return 0.0;
  }

  String _formatAnimatedValue(String originalValue, double animatedValue) {
    if (originalValue.contains('\$')) {
      return '\$${animatedValue.toStringAsFixed(2)}';
    } else if (originalValue.contains('days')) {
      return '${animatedValue.toInt()} days';
    } else if (originalValue.contains('%')) {
      return '${animatedValue.toStringAsFixed(1)}%';
    }
    return animatedValue.toStringAsFixed(0);
  }
}

class PremiumInsightGrid extends StatelessWidget {
  final List<InteractiveInsightCard> cards;
  final int crossAxisCount;
  final double spacing;

  const PremiumInsightGrid({
    super.key,
    required this.cards,
    this.crossAxisCount = 2,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.2,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return cards[index].animate(delay: Duration(milliseconds: index * 100))
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOutCubic);
      },
    );
  }
}

class SmartInsightCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const SmartInsightCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Learn More',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideX(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic);
  }
}
