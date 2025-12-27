import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../themes/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../viewmodels/transaction_viewmodel_fixed.dart' as vm;
import '../../models/transaction_model.dart' as app_models;
import '../../utils/category_icons.dart';

class SpendingHeatmapData {
  final double totalSpending;
  final List<SpendingTransaction> transactions;
  final double amount;
  final DateTime date;
  
  SpendingHeatmapData({
    required this.totalSpending,
    required this.transactions,
    required this.amount,
    required this.date,
  });
  
  double getIntensityLevel(double maxSpending) {
    return maxSpending > 0 ? (amount / maxSpending).clamp(0.0, 1.0) : 0.0;
  }
  
  Color getHeatColor(double maxSpending) {
    final intensity = getIntensityLevel(maxSpending);
    return _getColorForIntensity(intensity);
  }
  
  // Static method to get color for a specific intensity level (used by legend)
  static Color getHeatColorForIntensity(double intensity) {
    return _getColorForIntensity(intensity);
  }
  
  static Color _getColorForIntensity(double intensity) {
    if (intensity == 0) return Colors.grey.shade100;
    
    // Create a smooth gradient from green to red based on intensity
    if (intensity <= 0.2) {
      return Color.lerp(Colors.grey.shade100, Colors.green.shade300, intensity * 5)!;
    } else if (intensity <= 0.4) {
      return Color.lerp(Colors.green.shade300, Colors.yellow.shade400, (intensity - 0.2) * 5)!;
    } else if (intensity <= 0.6) {
      return Color.lerp(Colors.yellow.shade400, Colors.orange.shade400, (intensity - 0.4) * 5)!;
    } else if (intensity <= 0.8) {
      return Color.lerp(Colors.orange.shade400, Colors.red.shade400, (intensity - 0.6) * 5)!;
    } else {
      return Color.lerp(Colors.red.shade400, Colors.red.shade700, (intensity - 0.8) * 5)!;
    }
  }
  
  bool isWeekend() {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}

class SpendingTransaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final IconData icon;
  
  SpendingTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
  });
}

class FilterOptions {
  final DateTimeRange? dateRange;
  final List<String> selectedCategories;
  final double? minAmount;
  final double? maxAmount;
  final bool showOnlyHighSpending;
  
  const FilterOptions({
    this.dateRange,
    this.selectedCategories = const [],
    this.minAmount,
    this.maxAmount,
    this.showOnlyHighSpending = false,
  });
}

class EnhancedFilterDialog extends StatelessWidget {
  final FilterOptions initialFilters;
  final List<String> availableCategories;
  
  const EnhancedFilterDialog({
    super.key,
    required this.initialFilters,
    required this.availableCategories,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Options'),
      content: const Text('Filter dialog would be implemented here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(initialFilters),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class SpendingHeatmapScreen extends StatefulWidget {
  const SpendingHeatmapScreen({super.key});

  @override
  State<SpendingHeatmapScreen> createState() => _SpendingHeatmapScreenState();
}

class _SpendingHeatmapScreenState extends State<SpendingHeatmapScreen>
    with TickerProviderStateMixin {
  late Map<DateTime, SpendingHeatmapData> _spendingData;
  late double _maxDailySpending;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _selectedIndex = 10;
  final Logger logger = Logger('SpendingHeatmapScreen');

  // Premium UI Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late TabController _tabController;
  
  // Advanced Filter State (for future use)
  // View Mode State
  int _selectedViewMode = 0; // 0: Heatmap, 1: Analytics, 2: Patterns
  
  // Performance optimization
  final Map<String, dynamic> _cachedAnalytics = {};
  

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
    _loadInitialData();
  }

  void _initializeControllers() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _tabController = TabController(length: 3, vsync: this);
    
    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeData() {
    _spendingData = {};
    _maxDailySpending = 0;
    _focusedDay = DateTime(2025, 1, 1);
    _selectedDay = DateTime(2025, 1, 1);
  }

  void _loadInitialData() {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionViewModel = Provider.of<vm.TransactionViewModel>(context, listen: false);
      
      Future.wait([
        transactionViewModel.loadAllTransactions(),
      ]).then((_) {
        logger.info('Loaded ${transactionViewModel.allTransactions.length} total transactions');
        
        // Check if we have data for January 2025
        bool hasJan2025Data = false;
        
        if (transactionViewModel.allTransactions.isNotEmpty) {
          final jan2025Transactions = transactionViewModel.allTransactions.where((tx) => 
            tx.date.year == 2025 && tx.date.month == 1).toList();
          
          if (jan2025Transactions.isNotEmpty) {
            logger.info('Found ${jan2025Transactions.length} transactions for January 2025');
            hasJan2025Data = true;
          }
        }
        
        if (!hasJan2025Data) {
          // Find the most recent month with transaction data
          DateTime? mostRecentDate;
          
          if (transactionViewModel.allTransactions.isNotEmpty) {
            final mostRecentTx = transactionViewModel.allTransactions.reduce((a, b) => 
              a.date.isAfter(b.date) ? a : b);
            mostRecentDate = mostRecentTx.date;
          }
          
          if (mostRecentDate != null) {
            final newSelectedMonth = DateTime(mostRecentDate.year, mostRecentDate.month, 1);
            logger.info('No January 2025 data, using most recent: ${newSelectedMonth.year}-${newSelectedMonth.month}');
            
            if (mounted) {
              setState(() {
                _focusedDay = newSelectedMonth;
                _selectedDay = newSelectedMonth;
              });
            }
          }
        }
        
        final selectedMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
        transactionViewModel.loadTransactionsByMonth(selectedMonth);
      }).catchError((error) {
        logger.severe('Error loading heatmap data: $error');
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildPremiumAppBar(),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: Consumer<vm.TransactionViewModel>(
        builder: (context, txVm, _) {
          // Ensure we have loaded all transactions for comprehensive view
          if (txVm.allTransactions.isEmpty && !txVm.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              txVm.loadAllTransactions();
            });
          }
          
          // Ensure we load transactions for the focused month if needed
          final focusedMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
          if (txVm.selectedMonth.year != focusedMonth.year ||
              txVm.selectedMonth.month != focusedMonth.month) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              txVm.loadTransactionsByMonth(focusedMonth);
            });
          }
          
          if (txVm.isLoading) {
            return _buildLoadingState();
          }
          
          // Use allTransactions for comprehensive data, but aggregate will filter by month
          _aggregateTransactions(txVm.allTransactions);
          
          return RefreshIndicator(
            onRefresh: () => _refreshData(txVm),
            child: Column(
              children: [
                _buildViewModeSelector(),
                Expanded(
                  child: _buildSelectedView(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _aggregateTransactions(List<app_models.Transaction> transactions) {
    logger.info('Aggregating ${transactions.length} transactions for heatmap');
    
    // Clear previous data
    _spendingData.clear();
    double max = 0;
    
    // Use all transactions for comprehensive view, but filter by focused month
    final focusedMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    
    for (final tx in transactions) {
      if (!tx.isExpense) continue;
      
      // Only include transactions from the focused month
      if (tx.date.isBefore(focusedMonth) || tx.date.isAfter(nextMonth.subtract(const Duration(days: 1)))) {
        continue;
      }
      
      final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final current = _spendingData[dayKey]?.amount ?? 0;
      final newAmount = current + tx.amount.abs();
      
      _spendingData[dayKey] = SpendingHeatmapData(
        totalSpending: newAmount,
        date: dayKey,
        amount: newAmount,
        transactions: [
          ..._spendingData[dayKey]?.transactions ?? [], 
          SpendingTransaction(
            id: tx.id ?? '',
            title: tx.title,
            amount: tx.amount.abs(),
            date: tx.date,
            category: tx.category,
            icon: Icons.receipt,
          )
        ],
      );
      
      if (newAmount > max) max = newAmount;
    }
    
    _maxDailySpending = max;
    logger.info('Aggregated spending data: ${_spendingData.length} days, max daily: \$${_maxDailySpending.toStringAsFixed(2)}');
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    final String route = NavigationService.routeForDrawerIndex(index);

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    logger.info('Day selected: ${selectedDay.toIso8601String()}, focused: ${focusedDay.toIso8601String()}');
    
    if (!isSameDay(_focusedDay, focusedDay)) {
      // If the user taps a day in a different month, load that month
      final firstOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
      logger.info('Loading transactions for new month: ${firstOfMonth.toIso8601String()}');
      Provider.of<vm.TransactionViewModel>(context, listen: false)
          .loadTransactionsByMonth(firstOfMonth);
    }
    
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.7),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCalendarHeader(),
                  const SizedBox(height: 16),
                  TableCalendar(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2025, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: _onDaySelected,
                    onFormatChanged: _onFormatChanged,
                    onPageChanged: (focusedDay) {
                      HapticFeedback.lightImpact();
                      logger.info('Calendar page changed to: ${focusedDay.toIso8601String()}');
                      setState(() {
                        _focusedDay = focusedDay;
                        _selectedDay = DateTime(focusedDay.year, focusedDay.month, 1);
                      });
                      final firstOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
                      logger.info('Loading transactions for page change: ${firstOfMonth.toIso8601String()}');
                      Provider.of<vm.TransactionViewModel>(context, listen: false)
                          .loadTransactionsByMonth(firstOfMonth);
                    },
                    headerVisible: false, // We'll use our custom header
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 0,
                      weekendTextStyle: TextStyle(color: Colors.red.shade400),
                      holidayTextStyle: TextStyle(color: Colors.red.shade400),
                      outsideDaysVisible: false,
                      cellMargin: const EdgeInsets.all(2),
                      defaultDecoration: const BoxDecoration(),
                      selectedDecoration: const BoxDecoration(),
                      todayDecoration: const BoxDecoration(),
                      weekendDecoration: const BoxDecoration(),
                      holidayDecoration: const BoxDecoration(),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, _) {
                        return _buildEnhancedCalendarDay(date);
                      },
                      selectedBuilder: (context, date, _) {
                        return _buildEnhancedCalendarDay(date, isSelected: true);
                      },
                      todayBuilder: (context, date, _) {
                        return _buildEnhancedCalendarDay(date, isToday: true);
                      },
                      outsideBuilder: (context, date, _) {
                        return _buildEnhancedCalendarDay(date, isOutside: true);
                      },
                      markerBuilder: (context, date, events) {
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 800.ms, curve: Curves.easeOutQuart)
      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.chevron_left,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ).animate()
            .scale(duration: 150.ms, curve: Curves.easeOut)
            .then()
            .scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0)),
        ),
        Column(
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_focusedDay),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_spendingData.length} days with spending',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.chevron_right,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ).animate()
            .scale(duration: 150.ms, curve: Curves.easeOut)
            .then()
            .scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0)),
        ),
      ],
    );
  }

  Widget _buildEnhancedCalendarDay(DateTime date, {bool isSelected = false, bool isToday = false, bool isOutside = false}) {
    final spendingData = _spendingData[DateTime(date.year, date.month, date.day)];
    final hasSpending = spendingData != null && spendingData.amount > 0;
    final intensity = hasSpending ? spendingData.getIntensityLevel(_maxDailySpending) : 0.0;
    
    // Debug logging for color issues
    if (hasSpending && date.day <= 5) {
      logger.info('Day ${date.day}: Amount=\$${spendingData.amount}, Max=\$$_maxDailySpending, Intensity=$intensity');
    }
    
    // Calculate colors and styling
    Color backgroundColor = Colors.transparent;
    Color textColor = const Color(0xFF64748B);
    Color borderColor = Colors.transparent;
    List<Color> gradientColors = [Colors.transparent, Colors.transparent];
    
    if (isOutside) {
      textColor = Colors.grey.shade300;
    } else if (hasSpending) {
      final heatColor = spendingData.getHeatColor(_maxDailySpending);
      gradientColors = [
        heatColor.withValues(alpha: 0.8),
        heatColor.withValues(alpha: 0.6),
      ];
      backgroundColor = heatColor.withValues(alpha: isSelected ? 0.9 : 0.7);
      textColor = intensity >= 3 ? Colors.white : const Color(0xFF1E293B);
    }
    
    if (isSelected) {
      borderColor = AppTheme.primaryColor;
      if (!hasSpending) {
        gradientColors = [
          AppTheme.primaryColor.withValues(alpha: 0.2),
          AppTheme.primaryColor.withValues(alpha: 0.1),
        ];
        textColor = AppTheme.primaryColor;
      }
    }
    
    if (isToday && !isSelected) {
      borderColor = AppTheme.primaryColor.withValues(alpha: 0.5);
      if (!hasSpending) {
        textColor = AppTheme.primaryColor;
      }
    }

    return GestureDetector(
      onTap: isOutside ? null : () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDay = date;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: gradientColors[0] != Colors.transparent 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              )
            : null,
          color: gradientColors[0] == Colors.transparent ? backgroundColor : null,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != Colors.transparent 
            ? Border.all(color: borderColor, width: 2)
            : null,
          boxShadow: hasSpending && !isOutside ? [
            BoxShadow(
              color: spendingData.getHeatColor(intensity).withValues(alpha: 0.3),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
              spreadRadius: isSelected ? 1 : 0,
            ),
          ] : null,
        ),
        child: SizedBox(
          height: 48,
          child: Stack(
            children: [
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (hasSpending && !isOutside) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              spendingData.getHeatColor(intensity),
                              spendingData.getHeatColor(intensity).withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Spending amount indicator (top-right)
              if (hasSpending && !isOutside)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${spendingData.amount.toInt()}',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 300.ms, delay: 100.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                ),
              
              // Pulse animation for today
              if (isToday && !isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(duration: 1000.ms)
                    .then()
                    .fadeOut(duration: 1000.ms),
                ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms, delay: Duration(milliseconds: (date.day * 20).clamp(0, 500)))
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }


  Widget _buildSelectedDayDetails() {
    final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final spendingData = _spendingData[selectedDate];

    if (spendingData == null || spendingData.amount <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green.shade300,
              ),
              const SizedBox(height: 8),
              Text(
                'No spending on ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Great job keeping your expenses down!',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM d, yyyy').format(selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Total: \$${spendingData.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: spendingData.transactions.length,
            itemBuilder: (context, index) {
              final transaction = spendingData.transactions[index];
              return _buildTransactionItem(transaction).animate()
                .fadeIn(duration: const Duration(milliseconds: 300), delay: Duration(milliseconds: 50 * index))
                .slideX(begin: 0.2, end: 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(SpendingTransaction transaction) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CategoryIcons.getBrandCircleWidget(
        transaction.title,
        size: 40.0,
      ),
      title: Text(
        transaction.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        transaction.category,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Text(
        '\$${transaction.amount.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSpendingInsights() {
    // Get data for the focused month (not selected day)
    final selectedMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    
    logger.info('Building insights for ${DateFormat('MMMM yyyy').format(selectedMonth)} with ${_spendingData.length} spending data points');

    // Collect all spending data for the month
    final monthData = <SpendingHeatmapData>[];
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final data = _spendingData[date];
      if (data != null) {
        monthData.add(data);
      }
    }

    // Calculate monthly insights
    final totalSpending = monthData.fold(0.0, (sum, data) => sum + data.amount);
    final avgDailySpending = monthData.isEmpty ? 0.0 : totalSpending / monthData.length;
    final daysWithSpending = monthData.where((data) => data.amount > 0).length;
    final daysWithoutSpending = daysInMonth - daysWithSpending;

    // Find highest spending day
    SpendingHeatmapData? highestDay;
    if (monthData.isNotEmpty) {
      highestDay = monthData.reduce((a, b) => a.amount > b.amount ? a : b);
    }

    // Calculate weekday vs weekend spending
    double weekdayTotal = 0;
    double weekendTotal = 0;
    int weekdayCount = 0;
    int weekendCount = 0;

    for (final data in monthData) {
      if (data.isWeekend()) {
        weekendTotal += data.amount;
        weekendCount++;
      } else {
        weekdayTotal += data.amount;
        weekdayCount++;
      }
    }

    final weekdayAvg = weekdayCount > 0 ? (weekdayTotal / weekdayCount).toDouble() : 0.0;
    final weekendAvg = weekendCount > 0 ? (weekendTotal / weekendCount).toDouble() : 0.0;
    
    logger.info('Insights calculation - Month data: ${monthData.length} days, Total spending: \$${totalSpending.toStringAsFixed(2)}, Days with spending: $daysWithSpending');

    // Handle empty state
    if (monthData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.calendar_month,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No spending data for ${DateFormat('MMMM yyyy').format(selectedMonth)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see your spending heatmap',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights for ${DateFormat('MMMM yyyy').format(selectedMonth)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12), // Reduced spacing
          // First row of insight cards
          Row(
            children: [
              Flexible(
                child: _buildInsightCard(
                  'Total Spending',
                  '\$${totalSpending.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8), // Reduced spacing
              Flexible(
                child: _buildInsightCard(
                  'Avg. Daily',
                  '\$${avgDailySpending.toStringAsFixed(2)}',
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reduced spacing
          // Second row of insight cards
          Row(
            children: [
              Flexible(
                child: _buildInsightCard(
                  'Days with Spending',
                  '$daysWithSpending days',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8), // Reduced spacing
              Flexible(
                child: _buildInsightCard(
                  'No-Spend Days',
                  '$daysWithoutSpending days',
                  Icons.savings,
                  Colors.purple,
                ),
              ),
            ],
          ),
          if (highestDay != null) ...[
            const SizedBox(height: 12),
            _buildHighestSpendingDayCard(highestDay),
          ],
          const SizedBox(height: 12),
          _buildWeekdayVsWeekendCard(weekdayAvg, weekendAvg),
          const SizedBox(height: 12),
          _buildHeatmapLegend(),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10), // Reduced padding
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11, // Slightly smaller
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // Reduced spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 16, // Slightly smaller
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 300))
      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildHighestSpendingDayCard(SpendingHeatmapData highestDay) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.shade100,
            child: Text(
              highestDay.date.day.toString(),
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highest Spending Day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(highestDay.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${highestDay.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayVsWeekendCard(double weekdayAvg, double weekendAvg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekday vs Weekend Spending',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Weekday Avg.',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${weekdayAvg.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.blue.shade200,
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Weekend Avg.',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${weekendAvg.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            weekendAvg > weekdayAvg
                ? 'You spend ${(weekendAvg / weekdayAvg).toStringAsFixed(1)}x more on weekends!'
                : 'Your spending is fairly consistent throughout the week.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Generate" to analyze your spending patterns with AI',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                        AppTheme.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.palette,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Spending Intensity Scale',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Max: \$${_maxDailySpending.toInt()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                final intensityLevel = index / 5.0; // Convert 0-5 to 0.0-1.0
                final color = SpendingHeatmapData.getHeatColorForIntensity(intensityLevel);
                final isActive = index == 0 || index == 5;
                
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // Could show tooltip or explanation
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 28 : 24,
                        height: isActive ? 28 : 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              color.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: isActive ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: index == 0 
                          ? Icon(
                              Icons.remove,
                              color: Colors.grey.shade600,
                              size: 12,
                            )
                          : null,
                      ),
                      const SizedBox(height: 8),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isActive ? 12 : 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                          color: isActive ? const Color(0xFF1E293B) : const Color(0xFF475569),
                        ),
                        child: Text(
                          _getIntensityLabel(index),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            index == 0 ? '\$0' : '\$${(_maxDailySpending * 0.8).toInt()}+',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: index * 100))
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
              }),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap any day to see detailed spending breakdown and transactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 200.ms)
      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }

  String _getIntensityLabel(int index) {
    switch (index) {
      case 0:
        return 'None';
      case 1:
        return 'Low';
      case 2:
        return 'Mild';
      case 3:
        return 'Med';
      case 4:
        return 'High';
      case 5:
        return 'Max';
      default:
        return '';
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Spending Heatmap'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The Spending Heatmap helps you visualize your daily spending patterns. '
              'Darker colors indicate higher spending days.',
            ),
            SizedBox(height: 12),
            Text(
              'Use this tool to identify spending trends and make better financial decisions.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // Premium UI Methods
  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.white, Colors.white70],
        ).createShader(bounds),
        child: const Text(
          'Spending Intelligence',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.white),
          onPressed: _showAdvancedFilters,
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareHeatmap,
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: _showInfoDialog,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            ),
            SizedBox(height: 24),
            Text(
              'Loading spending intelligence...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData(vm.TransactionViewModel txVm) async {
    HapticFeedback.lightImpact();
    final focusedMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    await Future.wait([
      txVm.loadAllTransactions(),
      txVm.loadTransactionsByMonth(focusedMonth),
    ]);
    _invalidateCache();
  }

  void _invalidateCache() {
    _cachedAnalytics.clear();
  }

  Widget _buildViewModeSelector() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildModeButton('heatmap', Icons.calendar_view_month, 0),
            _buildModeButton('Analytics', Icons.analytics, 1),
            _buildModeButton('Patterns', Icons.psychology, 2),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: -0.3, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildModeButton(String label, IconData icon, int index) {
    final isSelected = _selectedViewMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedViewMode = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedViewMode) {
      case 0:
        return _buildHeatmapView();
      case 1:
        return _buildAnalyticsView();
      case 2:
        return _buildPatternsView();
      default:
        return _buildHeatmapView();
    }
  }

  Widget _buildHeatmapView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCalendar(),
          _buildSelectedDayDetails(),
          _buildSpendingInsights(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 40,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(
                    height: 280,
                    child: _buildSpendingTrendChart(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: _buildCategoryBreakdownChart(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: _buildWeekdayAnalysis(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPatternsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSpendingPatterns(),
          const SizedBox(height: 16),
          _buildBehavioralInsights(),
          const SizedBox(height: 16),
          _buildPredictiveAnalytics(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Real Charts Implementation
  Widget _buildSpendingTrendChart() {
    final monthlyData = _getMonthlySpendingTrend();
    
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Spending Trend',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${monthlyData.length} days • Peak: \$${_maxDailySpending.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tap to explore',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFF667EEA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: monthlyData.isEmpty
                  ? _buildEmptyChartState('No spending data available')
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _maxDailySpending > 0 ? _maxDailySpending / 5 : 50,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withValues(alpha: 0.15),
                              strokeWidth: 0.8,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '\$${value.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 5,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: monthlyData,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 5,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                  strokeColor: const Color(0xFF667EEA),
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF667EEA).withValues(alpha: 0.4),
                                  const Color(0xFF764BA2).withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                        ],
                        minX: 1,
                        maxX: DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day.toDouble(),
                        minY: 0,
                        maxY: _maxDailySpending > 0 ? _maxDailySpending * 1.1 : 100,
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) => const Color(0xFF1E293B),
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(8),
                            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                              return touchedBarSpots.map((barSpot) {
                                final day = barSpot.x.toInt();
                                final amount = barSpot.y;
                                return LineTooltipItem(
                                  'Day $day\n\$${amount.toStringAsFixed(2)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                            if (event is FlTapUpEvent && touchResponse != null) {
                              HapticFeedback.lightImpact();
                            }
                          },
                          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                            return spotIndexes.map((spotIndex) {
                              return TouchedSpotIndicatorData(
                                FlLine(
                                  color: const Color(0xFF667EEA),
                                  strokeWidth: 2,
                                ),
                                FlDotData(
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 8,
                                      color: Colors.white,
                                      strokeWidth: 3,
                                      strokeColor: const Color(0xFF667EEA),
                                    );
                                  },
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildCategoryBreakdownChart() {
    final categoryData = _getCategoryBreakdown();
    
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pie_chart, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: categoryData.isEmpty
                  ? _buildEmptyChartState('No category data available')
                  : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Stack(
                            children: [
                              PieChart(
                                PieChartData(
                                  sections: categoryData.take(6).map((data) {
                                    final total = categoryData.fold<double>(0, (sum, item) => sum + (item['amount'] as double));
                                    final percentage = total > 0 ? ((data['amount'] as double) / total * 100) : 0.0;
                                    return PieChartSectionData(
                                      color: data['color'] as Color,
                                      value: data['amount'] as double,
                                      title: '${percentage.toStringAsFixed(1)}%',
                                      radius: 70,
                                      titleStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      badgeWidget: null,
                                    );
                                  }).toList(),
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 45,
                                  startDegreeOffset: -90,
                                  pieTouchData: PieTouchData(
                                    enabled: true,
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      if (event is FlTapUpEvent) {
                                        HapticFeedback.lightImpact();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              // Center total amount
                              Positioned.fill(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '\$${categoryData.fold<double>(0, (sum, item) => sum + (item['amount'] as double)).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: categoryData.take(6).toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              final total = categoryData.fold<double>(0, (sum, item) => sum + (item['amount'] as double));
                              final percentage = total > 0 ? ((data['amount'] as double) / total * 100) : 0.0;
                              
                              return AnimatedContainer(
                                duration: Duration(milliseconds: 200 + (index * 50)),
                                curve: Curves.easeOutBack,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (data['color'] as Color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (data['color'] as Color).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            data['color'] as Color,
                                            (data['color'] as Color).withValues(alpha: 0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (data['color'] as Color).withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['category'] as String,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E293B),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${(data['amount'] as double).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate(delay: Duration(milliseconds: 100 * categoryData.indexOf(data)))
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.3, end: 0);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 100.ms)
      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildWeekdayAnalysis() {
    final weekdayData = _getWeekdayAnalysis();
    
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Weekday Spending Pattern',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: weekdayData.isEmpty
                  ? _buildEmptyChartState('No weekday data available')
                  : Column(
                      children: [
                        // Summary stats
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWeekdayStat('Highest', _getHighestWeekday(weekdayData), const Color(0xFF4ECDC4)),
                              Container(width: 1, height: 30, color: Colors.grey.shade300),
                              _buildWeekdayStat('Lowest', _getLowestWeekday(weekdayData), const Color(0xFF44A08D)),
                              Container(width: 1, height: 30, color: Colors.grey.shade300),
                              _buildWeekdayStat('Average', '\$${_getAverageWeekday(weekdayData)}', Colors.grey.shade600),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Enhanced bar chart
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: weekdayData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;
                              final maxAmount = weekdayData.map((e) => e['amount'] as double).reduce((a, b) => a > b ? a : b);
                              final height = maxAmount > 0 ? ((data['amount'] as double) / maxAmount) * 100 : 0.0;
                              final isWeekend = (data['day'] as String) == 'Saturday' || (data['day'] as String) == 'Sunday';
                              
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  // Could show detailed breakdown
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${(data['amount'] as double).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isWeekend ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 28,
                                      height: height.clamp(8.0, 100.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isWeekend 
                                            ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                                            : [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isWeekend ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4)).withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ).animate(delay: Duration(milliseconds: 100 * index))
                                      .slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutBack)
                                      .fadeIn(duration: 400.ms),
                                    const SizedBox(height: 6),
                                    Text(
                                      (data['day'] as String).substring(0, 3),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isWeekend ? const Color(0xFFFF6B6B) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 200.ms)
      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildWeekdayStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getHighestWeekday(List<Map<String, dynamic>> weekdayData) {
    if (weekdayData.isEmpty) return 'N/A';
    final highest = weekdayData.reduce((a, b) => 
      (a['amount'] as double) > (b['amount'] as double) ? a : b);
    return '${(highest['day'] as String).substring(0, 3)}\n\$${(highest['amount'] as double).toStringAsFixed(0)}';
  }

  String _getLowestWeekday(List<Map<String, dynamic>> weekdayData) {
    if (weekdayData.isEmpty) return 'N/A';
    final lowest = weekdayData.reduce((a, b) => 
      (a['amount'] as double) < (b['amount'] as double) ? a : b);
    return '${(lowest['day'] as String).substring(0, 3)}\n\$${(lowest['amount'] as double).toStringAsFixed(0)}';
  }

  String _getAverageWeekday(List<Map<String, dynamic>> weekdayData) {
    if (weekdayData.isEmpty) return '0';
    final total = weekdayData.fold<double>(0, (sum, item) => sum + (item['amount'] as double));
    final average = total / weekdayData.length;
    return average.toStringAsFixed(0);
  }

  Widget _buildSpendingPatterns() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Spending Patterns',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'AI-powered analysis of your spending behavior and patterns.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildBehavioralInsights() {
    final behavioralData = _getBehavioralInsights();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.insights, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Behavioral Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...behavioralData.map((insight) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: insight['color'].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: insight['color'].withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    insight['icon'],
                    color: insight['color'],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight['title'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: insight['color'],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight['description'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (insight['value'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: insight['color'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        insight['value'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: (100 * behavioralData.indexOf(insight)).round()))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.3, end: 0)),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 400.ms)
      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildPredictiveAnalytics() {
    final predictiveData = _getPredictiveAnalytics();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Predictive Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: predictiveData.map((prediction) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        prediction['color'].withValues(alpha: 0.1),
                        prediction['color'].withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: prediction['color'].withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        prediction['icon'],
                        color: prediction['color'],
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prediction['value'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: prediction['color'],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prediction['label'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: prediction['trendColor'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              prediction['trendIcon'],
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              prediction['trend'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 200 * predictiveData.indexOf(prediction)))
                  .fadeIn(duration: 500.ms)
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
              )).toList(),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 500.ms)
      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAdvancedFiltersSheet(),
    );
  }

  Widget _buildAdvancedFiltersSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Text('Advanced Filters\n(Coming Soon)',
            textAlign: TextAlign.center),
      ),
    );
  }

  void _shareHeatmap() {
    HapticFeedback.lightImpact();
    _showShareDialog();
  }

  // Data Processing Methods
  List<FlSpot> _getMonthlySpendingTrend() {
    final spots = <FlSpot>[];
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final spendingData = _spendingData[date];
      final amount = spendingData?.amount ?? 0.0;
      spots.add(FlSpot(day.toDouble(), amount));
    }
    
    return spots;
  }

  List<Map<String, dynamic>> _getCategoryBreakdown() {
    final categoryTotals = <String, double>{};
    final categoryColors = {
      'Food': const Color(0xFFFF6B6B),
      'Transport': const Color(0xFF4ECDC4),
      'Shopping': const Color(0xFF45B7D1),
      'Entertainment': const Color(0xFF96CEB4),
      'Utilities': const Color(0xFFFECA57),
      'Health': const Color(0xFFFF9FF3),
      'Other': const Color(0xFF74B9FF),
    };
    
    // Aggregate spending by category for the focused month
    for (final data in _spendingData.values) {
      for (final transaction in data.transactions) {
        final category = transaction.category.isNotEmpty ? transaction.category : 'Other';
        categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount;
      }
    }
    
    final totalSpending = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    if (totalSpending == 0) return [];
    
    return categoryTotals.entries.map((entry) {
      final percentage = (entry.value / totalSpending) * 100;
      return {
        'category': entry.key,
        'amount': entry.value,
        'percentage': percentage,
        'color': categoryColors[entry.key] ?? categoryColors['Other']!,
      };
    }).where((data) => (data['percentage'] as double) > 1) // Only show categories > 1%
      .toList()
      ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
  }

  List<Map<String, dynamic>> _getWeekdayAnalysis() {
    final weekdayTotals = <int, double>{};
    final weekdayCounts = <int, int>{};
    final weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    // Initialize all weekdays
    for (int i = 1; i <= 7; i++) {
      weekdayTotals[i] = 0.0;
      weekdayCounts[i] = 0;
    }
    
    // Aggregate spending by weekday
    for (final data in _spendingData.values) {
      if (data.amount > 0) {
        final weekday = data.date.weekday;
        weekdayTotals[weekday] = (weekdayTotals[weekday] ?? 0) + data.amount;
        weekdayCounts[weekday] = (weekdayCounts[weekday] ?? 0) + 1;
      }
    }
    
    // Calculate averages and return data
    return weekdayTotals.entries.map((entry) {
      final weekday = entry.key;
      final total = entry.value;
      final count = weekdayCounts[weekday] ?? 1;
      final average = count > 0 ? total / count : 0.0;
      
      return {
        'day': weekdayNames[weekday - 1],
        'amount': average,
        'total': total,
        'count': count,
      };
    }).toList();
  }

  Widget _buildEmptyChartState(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Share and Export Functionality
  void _showShareDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Share Spending Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildShareOption(
                    icon: Icons.image,
                    title: 'Export as Image',
                    subtitle: 'Save heatmap as PNG image',
                    onTap: _exportAsImage,
                  ),
                  _buildShareOption(
                    icon: Icons.table_chart,
                    title: 'Export as CSV',
                    subtitle: 'Download spending data as spreadsheet',
                    onTap: _exportAsCSV,
                  ),
                  _buildShareOption(
                    icon: Icons.picture_as_pdf,
                    title: 'Generate PDF Report',
                    subtitle: 'Create detailed spending report',
                    onTap: _exportAsPDF,
                  ),
                  _buildShareOption(
                    icon: Icons.share,
                    title: 'Share Summary',
                    subtitle: 'Share text summary via apps',
                    onTap: _shareTextSummary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate()
        .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 200.ms),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF667EEA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideX(begin: 0.3, end: 0);
  }

  void _exportAsImage() {
    _showExportProgress('Generating image...');
  }

  void _exportAsCSV() {
    _showExportProgress('Preparing CSV data...');
  }

  void _exportAsPDF() {
    _showExportProgress('Creating PDF report...');
  }

  void _shareTextSummary() {
    final monthName = DateFormat('MMMM yyyy').format(_focusedDay);
    final totalSpending = _spendingData.values.fold(0.0, (sum, data) => sum + data.amount);
    final daysWithSpending = _spendingData.values.where((data) => data.amount > 0).length;
    final avgDaily = daysWithSpending > 0 ? totalSpending / daysWithSpending : 0.0;
    
    final summary = '''
📊 My Spending Summary for $monthName

💰 Total Spent: \$${totalSpending.toStringAsFixed(2)}
📅 Active Days: $daysWithSpending days
📈 Daily Average: \$${avgDaily.toStringAsFixed(2)}

🎯 Generated by FinanceFlow - Your Smart Money Tracker
''';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Summary ready to share: $summary'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showExportProgress(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }





  // Behavioral Insights Data Processing
  List<Map<String, dynamic>> _getBehavioralInsights() {
    final insights = <Map<String, dynamic>>[];
    
    // Calculate spending frequency
    final totalDays = _spendingData.length;
    final spendingDays = _spendingData.values.where((data) => data.amount > 0).length;
    final spendingFrequency = totalDays > 0 ? (spendingDays / totalDays * 100) : 0.0;
    
    insights.add({
      'title': 'Spending Frequency',
      'description': 'You spend money on ${spendingFrequency.toStringAsFixed(0)}% of days',
      'value': '${spendingFrequency.toStringAsFixed(0)}%',
      'color': spendingFrequency > 70 ? Colors.red : spendingFrequency > 40 ? Colors.orange : Colors.green,
      'icon': Icons.calendar_today,
    });
    
    // Calculate average transaction size
    final allTransactions = _spendingData.values.expand((data) => data.transactions).toList();
    if (allTransactions.isNotEmpty) {
      final avgAmount = allTransactions.map((t) => t.amount).reduce((a, b) => a + b) / allTransactions.length;
      insights.add({
        'title': 'Average Transaction',
        'description': 'Your typical spending amount per transaction',
        'value': '\$${avgAmount.toStringAsFixed(0)}',
        'color': const Color(0xFF06B6D4),
        'icon': Icons.receipt_long,
      });
    }
    
    // Weekend vs Weekday spending
    double weekendSpending = 0;
    double weekdaySpending = 0;
    int weekendDays = 0;
    int weekdayDays = 0;
    
    for (final data in _spendingData.values) {
      if (data.date.weekday >= 6) { // Saturday = 6, Sunday = 7
        weekendSpending += data.amount;
        weekendDays++;
      } else {
        weekdaySpending += data.amount;
        weekdayDays++;
      }
    }
    
    final avgWeekendSpending = weekendDays > 0 ? weekendSpending / weekendDays : 0;
    final avgWeekdaySpending = weekdayDays > 0 ? weekdaySpending / weekdayDays : 0;
    
    if (avgWeekendSpending > 0 || avgWeekdaySpending > 0) {
      final isWeekendSpender = avgWeekendSpending > avgWeekdaySpending;
      insights.add({
        'title': isWeekendSpender ? 'Weekend Spender' : 'Weekday Spender',
        'description': isWeekendSpender 
            ? 'You spend ${((avgWeekendSpending / avgWeekdaySpending - 1) * 100).toStringAsFixed(0)}% more on weekends'
            : 'You spend more during weekdays than weekends',
        'value': isWeekendSpender ? 'Weekend' : 'Weekday',
        'color': isWeekendSpender ? Colors.purple : Colors.blue,
        'icon': isWeekendSpender ? Icons.weekend : Icons.work,
      });
    }
    
    return insights;
  }

  // Predictive Analytics Data Processing
  List<Map<String, dynamic>> _getPredictiveAnalytics() {
    final predictions = <Map<String, dynamic>>[];
    
    // Calculate monthly projection
    final currentMonthSpending = _spendingData.values.fold<double>(0, (sum, data) => sum + data.amount);
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final daysPassed = _focusedDay.day;
    final projectedMonthly = daysPassed > 0 ? (currentMonthSpending / daysPassed) * daysInMonth : 0;
    
    predictions.add({
      'value': '\$${projectedMonthly.toStringAsFixed(0)}',
      'label': 'Monthly Projection',
      'color': const Color(0xFF8B5CF6),
      'icon': Icons.trending_up,
      'trend': '${((projectedMonthly / currentMonthSpending - 1) * 100).toStringAsFixed(0)}%',
      'trendColor': projectedMonthly > currentMonthSpending ? Colors.red : Colors.green,
      'trendIcon': projectedMonthly > currentMonthSpending ? Icons.arrow_upward : Icons.arrow_downward,
    });
    
    // Calculate daily average
    final dailyAverage = daysPassed > 0 ? currentMonthSpending / daysPassed : 0;
    predictions.add({
      'value': '\$${dailyAverage.toStringAsFixed(0)}',
      'label': 'Daily Average',
      'color': const Color(0xFF06B6D4),
      'icon': Icons.today,
      'trend': 'Avg',
      'trendColor': const Color(0xFF64748B),
      'trendIcon': Icons.remove,
    });
    
    // Budget adherence prediction
    final budgetTarget = 900.0; // This should come from actual budget data
    final adherenceRate = budgetTarget > 0 ? (currentMonthSpending / budgetTarget * 100) : 0;
    predictions.add({
      'value': '${adherenceRate.toStringAsFixed(0)}%',
      'label': 'Budget Usage',
      'color': adherenceRate > 80 ? Colors.red : adherenceRate > 60 ? Colors.orange : Colors.green,
      'icon': Icons.account_balance_wallet,
      'trend': adherenceRate > 100 ? 'Over' : 'On Track',
      'trendColor': adherenceRate > 100 ? Colors.red : Colors.green,
      'trendIcon': adherenceRate > 100 ? Icons.warning : Icons.check,
    });
    
    return predictions;
  }

}
