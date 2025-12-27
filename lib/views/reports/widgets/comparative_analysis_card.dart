import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/time_period_model.dart';
import '../../../models/transaction_model.dart';
import '../../../models/income_source_model.dart';
import '../../../services/period_analysis_service.dart';
import '../../../themes/app_theme.dart';
import 'report_card.dart';

class ComparativeAnalysisCard extends StatefulWidget {
  final TimePeriod selectedPeriod;
  final List<Transaction> allTransactions;
  final List<IncomeSource> allIncomeSources;

  const ComparativeAnalysisCard({
    super.key,
    required this.selectedPeriod,
    required this.allTransactions,
    required this.allIncomeSources,
  });

  @override
  State<ComparativeAnalysisCard> createState() => _ComparativeAnalysisCardState();
}

class _ComparativeAnalysisCardState extends State<ComparativeAnalysisCard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMetric = 0; // 0: Expenses, 1: Income, 2: Savings

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      title: '📊 Comparative Analysis - ${widget.selectedPeriod.displayName}',
      child: Column(
        children: [
          // Metric Selector Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  _selectedMetric = index;
                });
              },
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Income'),
                Tab(text: 'Savings'),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Analysis Content
          _buildAnalysisContent(),
        ],
      ),
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildAnalysisContent() {
    final analyzeIncome = _selectedMetric == 1;
    final analyzeSavings = _selectedMetric == 2;
    
    // Get trend analysis data
    final trendData = PeriodAnalysisService.analyzeTrend(
      currentPeriod: widget.selectedPeriod,
      allTransactions: widget.allTransactions,
      allIncomeSources: widget.allIncomeSources,
      periodsToAnalyze: 6,
      analyzeIncome: analyzeIncome,
    );
    
    // Get velocity data
    final velocityData = PeriodAnalysisService.calculateFinancialVelocity(
      currentPeriod: widget.selectedPeriod,
      allTransactions: widget.allTransactions,
      allIncomeSources: widget.allIncomeSources,
    );
    
    // Get period comparison
    PeriodComparisonData comparison;
    if (analyzeSavings) {
      comparison = velocityData['savings_velocity'] as PeriodComparisonData;
    } else if (analyzeIncome) {
      comparison = velocityData['income_velocity'] as PeriodComparisonData;
    } else {
      comparison = velocityData['expense_velocity'] as PeriodComparisonData;
    }

    return Column(
      children: [
        // Period-over-Period Comparison
        _buildComparisonSection(comparison),
        
        const SizedBox(height: 20),
        
        // Trend Chart
        SizedBox(
          height: 250,
          child: _buildTrendChart(trendData),
        ),
        
        const SizedBox(height: 20),
        
        // Insights and Patterns
        _buildInsightsSection(trendData, velocityData),
      ],
    );
  }

  Widget _buildComparisonSection(PeriodComparisonData comparison) {
    final previousPeriod = widget.selectedPeriod.getPreviousPeriod();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            comparison.isIncrease 
                ? (_selectedMetric == 1 ? Colors.green : Colors.red).withValues(alpha: 0.1)
                : (_selectedMetric == 1 ? Colors.red : Colors.green).withValues(alpha: 0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: comparison.isIncrease 
              ? (_selectedMetric == 1 ? Colors.green : Colors.red).withValues(alpha: 0.3)
              : (_selectedMetric == 1 ? Colors.red : Colors.green).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildComparisonItem(
                  'Current ${_getMetricName()}',
                  comparison.currentValue,
                  AppTheme.primaryColor,
                  Icons.calendar_today,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.compare_arrows,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              Expanded(
                child: _buildComparisonItem(
                  'Previous ${_getMetricName()}',
                  comparison.previousValue,
                  Colors.grey[600]!,
                  Icons.history,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Change Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _getChangeColor(comparison).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getChangeColor(comparison).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getChangeIcon(comparison),
                  color: _getChangeColor(comparison),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getChangeText(comparison),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getChangeColor(comparison),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getChangeColor(comparison),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${comparison.changePercentage.abs().toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          
          Text(
            'vs ${previousPeriod.displayName}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String title, double value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrendChart(TrendAnalysisData trendData) {
    if (trendData.values.isEmpty) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No trend data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = trendData.values.reduce((a, b) => a > b ? a : b);
    final spots = trendData.values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMetricName()} Trend',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTrendColor(trendData.trendDirection).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTrendIcon(trendData.trendDirection),
                      size: 12,
                      color: _getTrendColor(trendData.trendDirection),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTrendText(trendData.trendDirection),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getTrendColor(trendData.trendDirection),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? (maxValue / 4) : 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < trendData.periods.length) {
                          final period = trendData.periods[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _formatPeriodLabel(period),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0) return const SizedBox();
                        final amount = value >= 1000 
                            ? '\$${(value / 1000).toStringAsFixed(0)}K' 
                            : '\$${value.toInt()}';
                        return Text(
                          amount,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey[300]!),
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _getMetricColor(),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: _getMetricColor(),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getMetricColor().withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final period = index < trendData.periods.length 
                            ? trendData.periods[index] 
                            : null;
                        return LineTooltipItem(
                          '${period?.displayName ?? 'Unknown'}\n\$${spot.y.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(TrendAnalysisData trendData, Map<String, dynamic> velocityData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Key Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Insights List
          ..._generateInsights(trendData, velocityData).map((insight) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _generateInsights(TrendAnalysisData trendData, Map<String, dynamic> velocityData) {
    final insights = <String>[];
    final metricName = _getMetricName().toLowerCase();
    
    // Trend insight
    if (trendData.trendDirection == 'strong_upward') {
      insights.add('Your $metricName shows a strong upward trend over the last ${trendData.periods.length} periods.');
    } else if (trendData.trendDirection == 'strong_downward') {
      insights.add('Your $metricName has been decreasing significantly over the last ${trendData.periods.length} periods.');
    } else if (trendData.trendDirection == 'stable') {
      insights.add('Your $metricName has remained relatively stable over the last ${trendData.periods.length} periods.');
    }
    
    // Volatility insight
    if (trendData.volatility > trendData.averageValue * 0.3) {
      insights.add('Your $metricName shows high volatility, indicating irregular patterns.');
    } else if (trendData.volatility < trendData.averageValue * 0.1) {
      insights.add('Your $metricName is very consistent with low volatility.');
    }
    
    // Average insight
    insights.add('Your average $metricName is \$${trendData.averageValue.toStringAsFixed(0)} per ${widget.selectedPeriod.type.name}.');
    
    // Velocity insight
    if (_selectedMetric == 0) { // Expenses
      final expenseVelocity = velocityData['expense_velocity'] as PeriodComparisonData;
      final burnRate = velocityData['burn_rate'] as double;
      
      if (expenseVelocity.changePercentage.abs() > 20) {
        insights.add('Your spending velocity has changed by ${expenseVelocity.changePercentage.toStringAsFixed(1)}% compared to last period.');
      }
      
      insights.add('Your current daily burn rate is \$${burnRate.toStringAsFixed(0)}.');
    } else if (_selectedMetric == 2) { // Savings
      final savingsVelocity = velocityData['savings_velocity'] as PeriodComparisonData;
      final runway = velocityData['runway'] as double;
      
      if (savingsVelocity.changePercentage.abs() > 20) {
        insights.add('Your savings rate has changed by ${savingsVelocity.changePercentage.toStringAsFixed(1)}% compared to last period.');
      }
      
      if (runway != double.infinity && runway > 0) {
        insights.add('At current spending levels, your savings would last ${runway.toStringAsFixed(1)} months.');
      }
    }
    
    return insights;
  }

  String _getMetricName() {
    switch (_selectedMetric) {
      case 0:
        return 'Expenses';
      case 1:
        return 'Income';
      case 2:
        return 'Savings';
      default:
        return 'Expenses';
    }
  }

  Color _getMetricColor() {
    switch (_selectedMetric) {
      case 0:
        return AppTheme.expenseColor;
      case 1:
        return AppTheme.incomeColor;
      case 2:
        return Colors.green;
      default:
        return AppTheme.expenseColor;
    }
  }

  Color _getChangeColor(PeriodComparisonData comparison) {
    if (_selectedMetric == 1) { // Income
      return comparison.isIncrease ? Colors.green : Colors.red;
    } else { // Expenses or Savings
      return comparison.isIncrease ? Colors.red : Colors.green;
    }
  }

  IconData _getChangeIcon(PeriodComparisonData comparison) {
    return comparison.isIncrease ? Icons.trending_up : Icons.trending_down;
  }

  String _getChangeText(PeriodComparisonData comparison) {
    final action = comparison.isIncrease ? 'increased' : 'decreased';
    return '${_getMetricName()} $action by \$${comparison.changeAmount.abs().toStringAsFixed(0)}';
  }

  Color _getTrendColor(String trendDirection) {
    switch (trendDirection) {
      case 'strong_upward':
      case 'upward':
        return _selectedMetric == 1 ? Colors.green : Colors.red;
      case 'strong_downward':
      case 'downward':
        return _selectedMetric == 1 ? Colors.red : Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trendDirection) {
    switch (trendDirection) {
      case 'strong_upward':
      case 'upward':
        return Icons.trending_up;
      case 'strong_downward':
      case 'downward':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  String _getTrendText(String trendDirection) {
    switch (trendDirection) {
      case 'strong_upward':
        return 'Strong ↗';
      case 'upward':
        return 'Rising ↗';
      case 'strong_downward':
        return 'Strong ↘';
      case 'downward':
        return 'Falling ↘';
      default:
        return 'Stable →';
    }
  }

  String _formatPeriodLabel(TimePeriod period) {
    switch (period.type) {
      case TimePeriodType.weekly:
        return 'W${period.startDate.day}';
      case TimePeriodType.monthly:
        return DateFormat('MMM').format(period.startDate);
      case TimePeriodType.quarterly:
        final quarter = ((period.startDate.month - 1) ~/ 3) + 1;
        return 'Q$quarter';
      case TimePeriodType.yearly:
        return period.startDate.year.toString();
    }
  }
}
