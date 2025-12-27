import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/time_period_model.dart';
import '../../../themes/app_theme.dart';

class AdvancedPeriodSelector extends StatefulWidget {
  final TimePeriod selectedPeriod;
  final Function(TimePeriod) onPeriodChanged;
  final bool showComparison;

  const AdvancedPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.showComparison = true,
  });

  @override
  State<AdvancedPeriodSelector> createState() => _AdvancedPeriodSelectorState();
}

class _AdvancedPeriodSelectorState extends State<AdvancedPeriodSelector>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TimePeriod _currentPeriod;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentPeriod = widget.selectedPeriod;
    
    // Set initial tab based on current period type
    switch (_currentPeriod.type) {
      case TimePeriodType.weekly:
        _tabController.index = 0;
        break;
      case TimePeriodType.monthly:
        _tabController.index = 1;
        break;
      case TimePeriodType.quarterly:
        _tabController.index = 2;
        break;
      case TimePeriodType.yearly:
        _tabController.index = 3;
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    TimePeriod newPeriod;
    
    switch (index) {
      case 0:
        newPeriod = TimePeriod.currentWeek();
        break;
      case 1:
        newPeriod = TimePeriod.currentMonth();
        break;
      case 2:
        newPeriod = TimePeriod.currentQuarter();
        break;
      case 3:
        newPeriod = TimePeriod.currentYear();
        break;
      default:
        newPeriod = TimePeriod.currentMonth();
    }
    
    setState(() {
      _currentPeriod = newPeriod;
    });
    
    widget.onPeriodChanged(newPeriod);
  }

  void _navigatePeriod(bool forward) {
    TimePeriod newPeriod;
    
    if (forward) {
      // Navigate to next period
      switch (_currentPeriod.type) {
        case TimePeriodType.weekly:
          final nextStart = _currentPeriod.startDate.add(const Duration(days: 7));
          final nextEnd = _currentPeriod.endDate.add(const Duration(days: 7));
          newPeriod = TimePeriod(
            type: TimePeriodType.weekly,
            startDate: nextStart,
            endDate: nextEnd,
            displayName: TimePeriod.formatWeeklyPeriod(nextStart, nextEnd),
          );
          break;
        case TimePeriodType.monthly:
          final nextMonth = DateTime(_currentPeriod.startDate.year, _currentPeriod.startDate.month + 1, 1);
          final nextEnd = DateTime(nextMonth.year, nextMonth.month + 1, 0, 23, 59, 59);
          newPeriod = TimePeriod(
            type: TimePeriodType.monthly,
            startDate: nextMonth,
            endDate: nextEnd,
            displayName: TimePeriod.formatMonthlyPeriod(nextMonth),
          );
          break;
        case TimePeriodType.quarterly:
          final nextQuarter = _getNextQuarter(_currentPeriod.startDate);
          newPeriod = TimePeriod(
            type: TimePeriodType.quarterly,
            startDate: nextQuarter['start']!,
            endDate: nextQuarter['end']!,
            displayName: TimePeriod.formatQuarterlyPeriod(nextQuarter['start']!),
          );
          break;
        case TimePeriodType.yearly:
          final nextYear = DateTime(_currentPeriod.startDate.year + 1, 1, 1);
          final nextEnd = DateTime(_currentPeriod.startDate.year + 1, 12, 31, 23, 59, 59);
          newPeriod = TimePeriod(
            type: TimePeriodType.yearly,
            startDate: nextYear,
            endDate: nextEnd,
            displayName: TimePeriod.formatYearlyPeriod(nextYear),
          );
          break;
      }
    } else {
      // Navigate to previous period
      newPeriod = _currentPeriod.getPreviousPeriod();
    }
    
    setState(() {
      _currentPeriod = newPeriod;
    });
    
    widget.onPeriodChanged(newPeriod);
  }

  Map<String, DateTime> _getNextQuarter(DateTime currentQuarterStart) {
    final currentQuarter = ((currentQuarterStart.month - 1) ~/ 3) + 1;
    
    if (currentQuarter == 4) {
      // Next quarter is Q1 of next year
      final nextYear = currentQuarterStart.year + 1;
      final start = DateTime(nextYear, 1, 1);
      final end = DateTime(nextYear, 3, 31, 23, 59, 59);
      return {'start': start, 'end': end};
    } else {
      // Next quarter is in the same year
      final nextQuarter = currentQuarter + 1;
      final startMonth = (nextQuarter - 1) * 3 + 1;
      final start = DateTime(currentQuarterStart.year, startMonth, 1);
      final end = DateTime(currentQuarterStart.year, startMonth + 2 + 1, 0, 23, 59, 59);
      return {'start': start, 'end': end};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppTheme.primaryColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Type Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: _onTabChanged,
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
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              tabs: const [
                Tab(text: 'Week'),
                Tab(text: 'Month'),
                Tab(text: 'Quarter'),
                Tab(text: 'Year'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Period Navigation
          Row(
            children: [
              // Previous Period Button
              _buildNavigationButton(
                icon: Icons.chevron_left,
                onPressed: () => _navigatePeriod(false),
                tooltip: 'Previous ${_currentPeriod.type.name}',
              ),
              
              const SizedBox(width: 12),
              
              // Current Period Display
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                        AppTheme.primaryColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _currentPeriod.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateRange(_currentPeriod),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Next Period Button
              _buildNavigationButton(
                icon: Icons.chevron_right,
                onPressed: () => _navigatePeriod(true),
                tooltip: 'Next ${_currentPeriod.type.name}',
              ),
            ],
          ),
          
          // Comparison Period Info (if enabled)
          if (widget.showComparison) ...[
            const SizedBox(height: 12),
            _buildComparisonInfo(),
          ],
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: -0.2, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: AppTheme.primaryColor,
          iconSize: 20,
        ),
      ),
    );
  }

  Widget _buildComparisonInfo() {
    final previousPeriod = _currentPeriod.getPreviousPeriod();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.compare_arrows,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            'vs ${previousPeriod.displayName}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Comparison',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(TimePeriod period) {
    final startFormat = '${period.startDate.day}/${period.startDate.month}/${period.startDate.year}';
    final endFormat = '${period.endDate.day}/${period.endDate.month}/${period.endDate.year}';
    
    if (period.type == TimePeriodType.weekly) {
      return '$startFormat - $endFormat';
    } else if (period.type == TimePeriodType.monthly) {
      return '${period.startDate.day}/${period.startDate.month} - ${period.endDate.day}/${period.endDate.month}/${period.endDate.year}';
    } else if (period.type == TimePeriodType.quarterly) {
      return '$startFormat - $endFormat';
    } else {
      return '${period.startDate.year}';
    }
  }
}
