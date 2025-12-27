import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SpendingHeatmapData {
  final double totalSpending;
  final List<dynamic> transactions;
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
  
  bool isWeekend() {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}

class PremiumHeatmapCalendar extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final Map<DateTime, SpendingHeatmapData> spendingData;
  final double maxDailySpending;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(CalendarFormat format) onFormatChanged;
  final Function(DateTime focusedDay) onPageChanged;

  const PremiumHeatmapCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.spendingData,
    required this.maxDailySpending,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  @override
  State<PremiumHeatmapCalendar> createState() => _PremiumHeatmapCalendarState();
}

class _PremiumHeatmapCalendarState extends State<PremiumHeatmapCalendar>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  int? _hoveredDayIndex;

  // Premium gradient schemes for heat intensity
  final List<List<Color>> _heatGradients = [
    [const Color(0xFFE8F5E8), const Color(0xFFE8F5E8)], // No spending
    [const Color(0xFFB8E6B8), const Color(0xFF90EE90)], // Low spending
    [const Color(0xFF87CEEB), const Color(0xFF4682B4)], // Medium-low
    [const Color(0xFFFFB347), const Color(0xFFFF8C00)], // Medium
    [const Color(0xFFFF6B6B), const Color(0xFFFF4757)], // High
    [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Very high
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 15,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Shimmer background effect
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
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
            
            // Calendar content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPremiumHeader(),
                  const SizedBox(height: 16),
                  _buildEnhancedCalendar(),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 800.ms)
      .scale(begin: const Offset(0.9, 0.9), duration: 800.ms, curve: Curves.easeOutBack);
  }

  Widget _buildPremiumHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ).createShader(bounds),
              child: Text(
                DateFormat('MMMM yyyy').format(widget.focusedDay),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Spending Heatmap',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _buildFormatSelector(),
      ],
    );
  }

  Widget _buildFormatSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildFormatButton('Month', CalendarFormat.month),
          _buildFormatButton('2 Weeks', CalendarFormat.twoWeeks),
          _buildFormatButton('Week', CalendarFormat.week),
        ],
      ),
    );
  }

  Widget _buildFormatButton(String label, CalendarFormat format) {
    final isSelected = widget.calendarFormat == format;
    return GestureDetector(
      onTap: () => widget.onFormatChanged(format),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2023, 1, 1),
      lastDay: DateTime.utc(2025, 12, 31),
      focusedDay: widget.focusedDay,
      calendarFormat: widget.calendarFormat,
      selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
      onDaySelected: widget.onDaySelected,
      onFormatChanged: widget.onFormatChanged,
      onPageChanged: widget.onPageChanged,
      headerVisible: false, // We use our custom header
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
        markersMaxCount: 0,
        cellMargin: EdgeInsets.all(4),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) => _buildPremiumCalendarDay(date),
        selectedBuilder: (context, date, _) => _buildPremiumCalendarDay(date, isSelected: true),
        todayBuilder: (context, date, _) => _buildPremiumCalendarDay(date, isToday: true),
        outsideBuilder: (context, date, _) => _buildPremiumCalendarDay(date, isOutside: true),
      ),
    );
  }

  Widget _buildPremiumCalendarDay(
    DateTime date, {
    bool isSelected = false,
    bool isToday = false,
    bool isOutside = false,
  }) {
    final dayKey = DateTime(date.year, date.month, date.day);
    final spendingData = widget.spendingData[dayKey];
    final hasSpending = spendingData != null && spendingData.amount > 0;
    final intensity = hasSpending ? spendingData.getIntensityLevel(widget.maxDailySpending) : 0.0;

    // Determine gradient colors based on intensity
    List<Color> gradientColors = _heatGradients[0];
    if (hasSpending) {
      final gradientIndex = (intensity * (_heatGradients.length - 1)).round().clamp(1, _heatGradients.length - 1);
      gradientColors = _heatGradients[gradientIndex];
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredDayIndex = date.day),
      onExit: (_) => setState(() => _hoveredDayIndex = null),
      child: GestureDetector(
        onTap: isOutside ? null : () => widget.onDaySelected(date, widget.focusedDay),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final isHovered = _hoveredDayIndex == date.day;
            final shouldPulse = hasSpending && intensity > 0.7;
            final scale = isHovered ? 1.1 : (shouldPulse ? _pulseAnimation.value : 1.0);

            return Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: isOutside
                      ? null
                      : LinearGradient(
                          colors: isSelected
                              ? [
                                  const Color(0xFF667EEA),
                                  const Color(0xFF764BA2),
                                ]
                              : gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday
                      ? Border.all(
                          color: const Color(0xFF667EEA),
                          width: 2,
                        )
                      : null,
                  boxShadow: hasSpending && !isOutside
                      ? [
                          BoxShadow(
                            color: gradientColors.first.withValues(alpha: 0.3),
                            blurRadius: isSelected ? 12 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isOutside
                              ? Colors.grey.shade400
                              : (hasSpending || isSelected)
                                  ? Colors.white
                                  : Colors.grey.shade800,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 16,
                          shadows: hasSpending && !isOutside
                              ? [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      if (hasSpending && !isOutside) ...[
                        const SizedBox(height: 2),
                        Text(
                          '\$${spendingData.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(0.5, 0.5),
                                blurRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        if (intensity > 0.8) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ).animate(delay: Duration(milliseconds: date.day * 20))
      .fadeIn(duration: 400.ms)
      .scale(begin: const Offset(0.8, 0.8), duration: 400.ms);
  }
}
