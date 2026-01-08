import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/currency_extensions.dart';
import '../../models/budget_model.dart';

class PremiumBudgetPieChart extends StatefulWidget {
  final List<Budget> budgets;
  final Function(String category, double newAmount)? onBudgetChanged;
  final double totalBudget;

  const PremiumBudgetPieChart({
    super.key,
    required this.budgets,
    this.onBudgetChanged,
    required this.totalBudget,
  });

  @override
  State<PremiumBudgetPieChart> createState() => _PremiumBudgetPieChartState();
}

class _PremiumBudgetPieChartState extends State<PremiumBudgetPieChart> 
    with TickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;
  
  // Premium color palette with gradients
  final List<List<Color>> _premiumGradients = [
    [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // indigo -> violet
    [const Color(0xFF06B6D4), const Color(0xFF3B82F6)], // cyan -> blue
    [const Color(0xFF10B981), const Color(0xFF34D399)], // emerald -> mint
    [const Color(0xFFF59E0B), const Color(0xFFF97316)], // amber -> orange
    [const Color(0xFFEF4444), const Color(0xFFF97316)], // red -> orange
    [const Color(0xFFEC4899), const Color(0xFFF472B6)], // pink -> rose
    [const Color(0xFF22C55E), const Color(0xFF84CC16)], // green -> lime
    [const Color(0xFF14B8A6), const Color(0xFF06B6D4)], // teal -> cyan
    [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)], // sky -> light blue
    [const Color(0xFFA855F7), const Color(0xFF6366F1)], // purple -> indigo
    [const Color(0xFFFB7185), const Color(0xFFEC4899)], // salmon -> pink
    [const Color(0xFF4ADE80), const Color(0xFF10B981)], // light green -> emerald
  ];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalSpent = widget.budgets.fold(0.0, (sum, b) => sum + b.spent);
    final fallbackBudgeted = widget.budgets.fold(0.0, (sum, b) => sum + b.amount);
    final totalBudgeted = widget.totalBudget > 0 ? widget.totalBudget : fallbackBudgeted;
    final percentageUsed = totalBudgeted > 0
        ? (totalSpent / totalBudgeted * 100)
        : (totalSpent > 0 ? 100.0 : 0.0);
    
    return Column(
      children: [
        // Premium header with stats
        _buildPremiumHeader(totalSpent, totalBudgeted),
        
        const SizedBox(height: 20),
        
        // Enhanced pie chart with advanced animations
        SizedBox(
          height: 320,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.12),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
                
                // The enhanced pie chart
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value * (_isHovering ? 1.02 : 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    _scaleController.reverse();
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  _scaleController.forward();
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: touchedIndex >= 0 ? 6 : 3,
                            centerSpaceRadius: 55,
                            sections: _buildEnhancedSections(),
                            startDegreeOffset: -90,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                _buildEnhancedCenterDisplay(
                  percentageUsed,
                  totalSpent: totalSpent,
                  totalBudgeted: totalBudgeted,
                ),
              ],
            ),
          ),
        ).animate()
          .fadeIn(duration: 800.ms)
          .scale(begin: const Offset(0.7, 0.7), duration: 800.ms, curve: Curves.easeOutBack),
        
        const SizedBox(height: 20),
        
        // Legend with interactions
        _buildInteractiveLegend(),
      ],
    );
  }

  Widget _buildPremiumHeader(double totalSpent, double totalBudgeted) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remaining = totalBudgeted - totalSpent;
    final isOverBudget = remaining < 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Spent',
            totalSpent.toCurrency(),
            Icons.trending_down,
            const Color(0xFF8B5CF6),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          _buildStatItem(
            'Budget',
            totalBudgeted.toCurrency(),
            Icons.account_balance_wallet,
            const Color(0xFF6366F1),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          _buildStatItem(
            'Remaining',
            remaining.abs().toCurrency(),
            isOverBudget ? Icons.warning : Icons.check_circle,
            isOverBudget ? Colors.red : const Color(0xFF6366F1),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 200.ms, duration: 500.ms)
      .slideY(begin: -0.2, duration: 500.ms);
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedCenterDisplay(
    double percentageUsed, {
    required double totalSpent,
    required double totalBudgeted,
  }) {
    final isOverBudget = totalBudgeted > 0 && totalSpent > totalBudgeted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${percentageUsed.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: isOverBudget
                    ? [Colors.red, Colors.orange]
                    : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              ).createShader(const Rect.fromLTWH(0, 0, 100, 50)),
          ),
        ),
        Text(
          'Used',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          totalSpent.toCurrency(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ).animate()
      .fadeIn(delay: 800.ms, duration: 500.ms)
      .scale(delay: 800.ms, duration: 500.ms);
  }

  List<PieChartSectionData> _buildEnhancedSections() {
    final effectiveBudgets = widget.budgets.where((b) => b.amount > 0 || b.spent > 0).toList();
    if (effectiveBudgets.isEmpty) {
      return [
        PieChartSectionData(
          gradient: LinearGradient(
            colors: [Colors.grey.shade300, Colors.grey.shade400],
          ),
          value: 100,
          title: 'No Data',
          radius: 65,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    return effectiveBudgets.asMap().entries.map((entry) {
      final index = entry.key;
      final budget = entry.value;
      final isTouched = index == touchedIndex;
      final gradientColors = _premiumGradients[index % _premiumGradients.length];
      final isOverBudget = budget.spent > budget.amount;
      final sectionValue = budget.amount > 0 ? budget.amount : budget.spent;
      final separatorColor = Theme.of(context).colorScheme.surface.withValues(alpha: 0.95);
      
      return PieChartSectionData(
        gradient: LinearGradient(
          colors: isTouched 
              ? [
                  gradientColors[0],
                  gradientColors[1],
                  gradientColors[0].withValues(alpha: 0.8),
                ]
              : gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: isTouched ? [0.0, 0.5, 1.0] : [0.0, 1.0],
        ),
        borderSide: BorderSide(
          color: separatorColor,
          width: isTouched ? 3 : 2,
        ),
        value: sectionValue,
        title: isTouched ? budget.amount.toCurrency() : '',
        radius: isTouched ? 80 : 65,
        titleStyle: TextStyle(
          fontSize: isTouched ? 18 : 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(1, 1),
              blurRadius: 3,
            ),
            Shadow(
              color: gradientColors[0].withValues(alpha: 0.3),
              offset: const Offset(-1, -1),
              blurRadius: 2,
            ),
          ],
        ),
        badgeWidget: isTouched ? _buildEnhancedBadge(budget, isOverBudget) : null,
        badgePositionPercentageOffset: 1.4,
      );
    }).toList();
  }

  Widget _buildEnhancedBadge(Budget budget, bool isOverBudget) {
    final percentUsed = budget.amount > 0 ? (budget.spent / budget.amount * 100) : 0.0;
    final iconData = isOverBudget 
        ? Icons.warning 
        : percentUsed > 80 
            ? Icons.info 
            : Icons.check_circle;
    final iconColor = isOverBudget 
        ? Colors.red 
        : percentUsed > 80 
            ? Colors.orange 
            : const Color(0xFF6366F1);
    
    const size = 32.0;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: size * 0.6,
      ),
    ).animate()
      .scale(duration: 400.ms, curve: Curves.elasticOut)
      .shimmer(duration: 1000.ms, delay: 200.ms);
  }

  Widget _buildInteractiveLegend() {
    final effectiveBudgets = widget.budgets.where((b) => b.amount > 0 || b.spent > 0).toList();
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: effectiveBudgets.length,
        itemBuilder: (context, index) {
          final budget = effectiveBudgets[index];
          final gradientColors = _premiumGradients[index % _premiumGradients.length];
          final isSelected = index == touchedIndex;
          final percentUsed = budget.amount > 0 ? (budget.spent / budget.amount * 100) : 0.0;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                touchedIndex = isSelected ? -1 : index;
                if (!isSelected) {
                  _scaleController.forward();
                } else {
                  _scaleController.reverse();
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? LinearGradient(colors: gradientColors)
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.transparent : gradientColors[0],
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? gradientColors[0] : Colors.black)
                        .withValues(alpha:0.2),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    budget.category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    budget.amount.toCurrency(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : gradientColors[0],
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (percentUsed / 100).clamp(0.0, 1.0),
                    backgroundColor: isSelected 
                        ? Colors.white.withValues(alpha:0.3)
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isSelected 
                          ? Colors.white
                          : percentUsed > 100 
                              ? Colors.red 
                              : percentUsed > 80 
                                  ? Colors.orange 
                                  : const Color(0xFF6366F1),
                    ),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn(duration: 500.ms)
            .slideX(begin: 0.2, duration: 500.ms);
        },
      ),
    );
  }
}
