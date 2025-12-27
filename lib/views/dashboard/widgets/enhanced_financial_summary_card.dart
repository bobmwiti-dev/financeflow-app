import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../themes/app_theme.dart';

/// Enhanced Financial Summary Card with competitive features
class EnhancedFinancialSummaryCard extends StatefulWidget {
  final double income;
  final double expenses;
  final double balance;
  final Map<String, double> categoryTotals;
  final List<double> monthlyIncomeHistory;
  final List<double> monthlyExpenseHistory;
  final double previousMonthIncome;
  final double previousMonthExpenses;
  final bool isRefreshing;
  
  const EnhancedFinancialSummaryCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.balance,
    required this.categoryTotals,
    this.monthlyIncomeHistory = const [],
    this.monthlyExpenseHistory = const [],
    this.previousMonthIncome = 0,
    this.previousMonthExpenses = 0,
    this.isRefreshing = false,
  });

  @override
  State<EnhancedFinancialSummaryCard> createState() => _EnhancedFinancialSummaryCardState();
}

class _EnhancedFinancialSummaryCardState extends State<EnhancedFinancialSummaryCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  int _selectedChartIndex = 0; // 0: Bar Chart, 1: Trend Chart, 2: Category Pie Chart
  bool _showInsights = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
    _chartController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Card(
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha:0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildFinancialHealthScore(),
                      const SizedBox(height: 20),
                      _buildSummaryMetrics(),
                      const SizedBox(height: 24),
                      _buildChartSelector(),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: _buildSelectedChart(),
                      ),
                      if (_showInsights) ...[
                        const SizedBox(height: 20),
                        _buildAIInsights(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                _showInsights ? Icons.insights : Icons.insights_outlined,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _showInsights = !_showInsights;
                });
              },
              tooltip: 'Toggle Insights',
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
              onSelected: (value) {
                switch (value) {
                  case 'export':
                    _showExportDialog();
                    break;
                  case 'compare':
                    _showComparisonView();
                    break;
                  case 'forecast':
                    _showForecastView();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 20),
                      SizedBox(width: 8),
                      Text('Export Data'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'compare',
                  child: Row(
                    children: [
                      Icon(Icons.compare_arrows, size: 20),
                      SizedBox(width: 8),
                      Text('Compare Periods'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'forecast',
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 20),
                      SizedBox(width: 8),
                      Text('Cash Flow Forecast'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Placeholder methods for future chunks
  Widget _buildFinancialHealthScore() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Center(
        child: Text(
          'Financial Health Score - Coming in Chunk 2',
          style: TextStyle(color: Colors.blue.shade700),
        ),
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Center(
        child: Text(
          'Enhanced Summary Metrics - Coming in Chunk 3',
          style: TextStyle(color: Colors.green.shade700),
        ),
      ),
    );
  }

  Widget _buildChartSelector() {
    return Row(
      children: [
        Text(
          'Analytics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildChartSelectorButton('Overview', 0, Icons.bar_chart),
              _buildChartSelectorButton('Trends', 1, Icons.show_chart),
              _buildChartSelectorButton('Categories', 2, Icons.pie_chart),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartSelectorButton(String label, int index, IconData icon) {
    final isSelected = _selectedChartIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartIndex = index;
        });
        _chartController.reset();
        _chartController.forward();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Center(
        child: Text(
          'Multi-Chart Analytics - Coming in Chunk 4',
          style: TextStyle(color: Colors.orange.shade700),
        ),
      ),
    );
  }

  Widget _buildAIInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Center(
        child: Text(
          'AI Insights & Recommendations - Coming in Chunk 5',
          style: TextStyle(color: Colors.purple.shade700),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms);
  }

  // Placeholder methods for menu actions
  void _showExportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }

  void _showComparisonView() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comparison feature coming soon!')),
    );
  }

  void _showForecastView() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forecast feature coming soon!')),
    );
  }
}
