import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/currency_extensions.dart';

/// An interactive donut chart showing money distribution across categories
/// with animated segments and interactive tooltips
class MoneyDistributionVisualization extends StatefulWidget {
  final List<SpendingCategory> categories;
  final String title;
  final String? subtitle;
  final Function(SpendingCategory)? onCategoryTap;

  const MoneyDistributionVisualization({
    super.key,
    required this.categories,
    this.title = 'Money Distribution',
    this.subtitle,
    this.onCategoryTap,
  });

  @override
  State<MoneyDistributionVisualization> createState() => _MoneyDistributionVisualizationState();
}

class _MoneyDistributionVisualizationState extends State<MoneyDistributionVisualization> with SingleTickerProviderStateMixin {
  int? _selectedCategoryIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    return widget.categories.fold(0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.subtitle != null) ...[  
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Chart and legend
            widget.categories.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.2,
                        child: Row(
                          children: [
                            // Donut chart
                            Expanded(
                              flex: 2,
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: _DonutChartPainter(
                                      categories: widget.categories,
                                      animationValue: _animation.value,
                                      selectedIndex: _selectedCategoryIndex,
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // Category legend
                            Expanded(
                              flex: 3,
                              child: _buildCategoryLegend(),
                            ),
                          ],
                        ),
                      ),
                      
                      // Total amount
                      const SizedBox(height: 16),
                      Text(
                        'Total: ${_calculateTotal().toCurrency()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 800))
    .slideY(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No spending data available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add transactions to see your spending distribution',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend() {
    return ListView.builder(
      itemCount: widget.categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final category = widget.categories[index];
        final isSelected = _selectedCategoryIndex == index;
        final total = _calculateTotal();
        final percentage = total > 0 ? (category.amount / total * 100).toDouble() : 0.0;
        
        return _buildLegendItem(
          category: category,
          percentage: percentage,
          index: index,
          isSelected: isSelected,
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideX(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildLegendItem({
    required SpendingCategory category,
    required double percentage,
    required int index,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          // Toggle selection
          _selectedCategoryIndex = isSelected ? null : index;
        });
        
        if (widget.onCategoryTap != null) {
          widget.onCategoryTap!(category);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? category.color.withValues(alpha: 0.2) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: category.color.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Category color indicator
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            
            // Category details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        category.amount.toCurrency(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for drawing the donut chart
class _DonutChartPainter extends CustomPainter {
  final List<SpendingCategory> categories;
  final double animationValue;
  final int? selectedIndex;
  
  _DonutChartPainter({
    required this.categories,
    required this.animationValue,
    this.selectedIndex,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.8 / 2;
    final innerRadius = radius * 0.6; // Creates the donut hole
    
    // Calculate total for percentages
    final total = categories.fold(0.0, (sum, item) => sum + item.amount);
    
    // Start drawing from the top (negative Y axis, -90 degrees)
    double startAngle = -90 * (3.14159 / 180);
    
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final isSelected = selectedIndex == i;
      
      // Calculate sweep angle based on percentage
      final percentage = category.amount / total;
      final sweepAngle = percentage * 2 * 3.14159 * animationValue;
      
      // Create paint for segment
      final paint = Paint()
        ..color = category.color.withValues(
            alpha: isSelected ? 1.0 : 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? radius - innerRadius + 4 : radius - innerRadius;
      
      // Draw segment with animation
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      // Update start angle for next segment
      startAngle += sweepAngle;
    }
    
    // Draw inner circle to create donut hole
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = Colors.white,
    );
  }
  
  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.selectedIndex != selectedIndex;
  }
}

/// Model class for spending categories
class SpendingCategory {
  final String id;
  final String name;
  final double amount;
  final Color color;
  final IconData? icon;

  const SpendingCategory({
    required this.id,
    required this.name,
    required this.amount,
    required this.color,
    this.icon,
  });
}
