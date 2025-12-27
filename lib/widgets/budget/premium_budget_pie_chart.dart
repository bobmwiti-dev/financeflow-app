import 'dart:math' as math;
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
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  bool _isHovering = false;
  
  // Premium color palette with gradients
  final List<List<Color>> _premiumGradients = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)], // Purple gradient
    [const Color(0xFFF093FB), const Color(0xFFF5576C)], // Pink gradient
    [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // Blue gradient
    [const Color(0xFF43E97B), const Color(0xFF38F9D7)], // Green gradient
    [const Color(0xFFFA709A), const Color(0xFFFEE140)], // Sunset gradient
    [const Color(0xFF30CFD0), const Color(0xFF330867)], // Ocean gradient
    [const Color(0xFFA8EDEA), const Color(0xFFFED6E3)], // Soft gradient
    [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)], // Rose gradient
    [const Color(0xFFFBC2EB), const Color(0xFFA6C1EE)], // Lavender gradient
    [const Color(0xFFFDCBF1), const Color(0xFFE6DEE9)], // Mist gradient
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = widget.budgets.fold(0.0, (sum, b) => sum + b.spent);
    final totalBudgeted = widget.budgets.fold(0.0, (sum, b) => sum + b.amount);
    final percentageUsed = totalBudgeted > 0 ? (totalSpent / totalBudgeted * 100) : 0.0;
    
    return Column(
      children: [
        // Premium header with stats
        _buildPremiumHeader(totalSpent, totalBudgeted, percentageUsed),
        
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
                // Multi-layer animated background
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.blue.withValues(alpha: 0.1),
                              Colors.purple.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Shimmer effect layer
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment(-1.0 + _shimmerAnimation.value, -1.0),
                          end: Alignment(1.0 + _shimmerAnimation.value, 1.0),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    );
                  },
                ),
                
                // The enhanced pie chart
                AnimatedBuilder(
                  animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value * (_isHovering ? _pulseAnimation.value : 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.8),
                              blurRadius: 15,
                              offset: const Offset(0, -8),
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
                
                // Enhanced center display with pulse
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: _buildEnhancedCenterDisplay(percentageUsed),
                    );
                  },
                ),
              ],
            ),
          ),
        ).animate()
          .fadeIn(duration: 800.ms)
          .scale(begin: const Offset(0.7, 0.7), duration: 800.ms, curve: Curves.easeOutBack)
          .shimmer(duration: 1500.ms, delay: 500.ms),
        
        const SizedBox(height: 20),
        
        // Legend with interactions
        _buildInteractiveLegend(),
      ],
    );
  }

  Widget _buildPremiumHeader(double totalSpent, double totalBudgeted, double percentageUsed) {
    final remaining = totalBudgeted - totalSpent;
    final isOverBudget = remaining < 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
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
            Colors.orange,
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
            Colors.blue,
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
            isOverBudget ? Colors.red : Colors.green,
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

  Widget _buildEnhancedCenterDisplay(double percentageUsed) {
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
                colors: percentageUsed > 100 
                    ? [Colors.red, Colors.orange]
                    : percentageUsed > 80 
                        ? [Colors.orange, Colors.amber]
                        : [Colors.blue, Colors.green],
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
      ],
    ).animate()
      .fadeIn(delay: 800.ms, duration: 500.ms)
      .scale(delay: 800.ms, duration: 500.ms);
  }

  List<PieChartSectionData> _buildEnhancedSections() {
    if (widget.budgets.isEmpty) {
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

    return widget.budgets.asMap().entries.map((entry) {
      final index = entry.key;
      final budget = entry.value;
      final isTouched = index == touchedIndex;
      final gradientColors = _premiumGradients[index % _premiumGradients.length];
      final isOverBudget = budget.spent > budget.amount;
      
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
        value: budget.amount,
        title: isTouched ? '\$${budget.amount.toStringAsFixed(0)}' : '',
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
            : Colors.green;
    
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
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.budgets.length,
        itemBuilder: (context, index) {
          final budget = widget.budgets[index];
          final gradientColors = _premiumGradients[index % _premiumGradients.length];
          final isSelected = index == touchedIndex;
          
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
                    value: (budget.percentUsed / 100).clamp(0.0, 1.0),
                    backgroundColor: isSelected 
                        ? Colors.white.withValues(alpha:0.3)
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isSelected 
                          ? Colors.white
                          : budget.percentUsed > 100 
                              ? Colors.red 
                              : budget.percentUsed > 80 
                                  ? Colors.orange 
                                  : Colors.green,
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
