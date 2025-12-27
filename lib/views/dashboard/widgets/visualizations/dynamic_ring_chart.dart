import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class DynamicRingChart extends StatefulWidget {
  final Map<String, double> data;
  final DateTime selectedMonth;
  final double radius;
  final double strokeWidth;
  final Function(String category)? onCategoryTap;

  const DynamicRingChart({
    super.key,
    required this.data,
    required this.selectedMonth,
    this.radius = 100,
    this.strokeWidth = 25,
    this.onCategoryTap,
  });

  @override
  State<DynamicRingChart> createState() => _DynamicRingChartState();
}

class _DynamicRingChartState extends State<DynamicRingChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _animation;
  late Animation<double> _pulseAnimation;
  
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    final total = widget.data.values.fold(0.0, (sum, value) => sum + value);
    final sortedEntries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.radius * 2 + 40,
          height: widget.radius * 2 + 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ring Chart
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _selectedIndex >= 0 ? _pulseAnimation.value : 1.0,
                    child: SizedBox(
                      width: widget.radius * 2,
                      height: widget.radius * 2,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: widget.radius - widget.strokeWidth,
                          sections: _buildRingSections(sortedEntries, total),
                          pieTouchData: PieTouchData(
                            enabled: true,
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _selectedIndex = -1;
                                  return;
                                }
                                _selectedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Center Content
              _buildCenterContent(total),
              
              // Interactive Overlay
              if (_selectedIndex >= 0) _buildSelectedCategoryOverlay(sortedEntries[_selectedIndex], total),
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildRingSections(List<MapEntry<String, double>> entries, double total) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEF4444), // Red
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF84CC16), // Lime
    ];

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryEntry = entry.value;
      final percentage = (categoryEntry.value / total) * 100;
      final isSelected = index == _selectedIndex;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: categoryEntry.value * _animation.value,
        title: '',
        radius: widget.strokeWidth + (isSelected ? 8 : 0),
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isSelected ? _buildBadge(categoryEntry.key, percentage) : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildBadge(String category, double percentage) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ).animate()
      .scale(duration: 300.ms, curve: Curves.elasticOut);
  }

  Widget _buildCenterContent(double total) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final sortedEntries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    String centerText;
    String centerSubtext;
    
    if (_selectedIndex >= 0 && _selectedIndex < sortedEntries.length) {
      final selectedEntry = sortedEntries[_selectedIndex];
      final percentage = total > 0 ? (selectedEntry.value / total) * 100 : 0;
      centerText = '${percentage.toStringAsFixed(1)}%';
      centerSubtext = selectedEntry.key;
    } else {
      centerText = currencyFormat.format(total);
      centerSubtext = 'Total Spend';
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: _selectedIndex >= 0 ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: _selectedIndex >= 0 ? Colors.blue[700] : Colors.grey[800],
          ),
          child: Text(centerText),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: _selectedIndex >= 0 ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
          child: Text(
            centerSubtext,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedCategoryOverlay(MapEntry<String, double> categoryEntry, double total) {
    final percentage = (categoryEntry.value / total) * 100;
    
    return Positioned(
      bottom: -10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              categoryEntry.key,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '\$${categoryEntry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ).animate()
        .scale(duration: 300.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 200.ms),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No Data',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
