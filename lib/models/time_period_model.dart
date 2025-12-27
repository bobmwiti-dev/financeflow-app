enum TimePeriodType {
  weekly,
  monthly,
  quarterly,
  yearly,
}

class TimePeriod {
  final TimePeriodType type;
  final DateTime startDate;
  final DateTime endDate;
  final String displayName;

  TimePeriod({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.displayName,
  });

  // Get the previous period for comparison
  TimePeriod getPreviousPeriod() {
    switch (type) {
      case TimePeriodType.weekly:
        final prevStart = startDate.subtract(const Duration(days: 7));
        final prevEnd = endDate.subtract(const Duration(days: 7));
        return TimePeriod(
          type: type,
          startDate: prevStart,
          endDate: prevEnd,
          displayName: formatWeeklyPeriod(prevStart, prevEnd),
        );
      case TimePeriodType.monthly:
        final prevMonth = DateTime(startDate.year, startDate.month - 1, 1);
        final prevEnd = DateTime(prevMonth.year, prevMonth.month + 1, 0);
        return TimePeriod(
          type: type,
          startDate: prevMonth,
          endDate: prevEnd,
          displayName: formatMonthlyPeriod(prevMonth),
        );
      case TimePeriodType.quarterly:
        final prevQuarter = _getPreviousQuarter(startDate);
        return TimePeriod(
          type: type,
          startDate: prevQuarter['start']!,
          endDate: prevQuarter['end']!,
          displayName: formatQuarterlyPeriod(prevQuarter['start']!),
        );
      case TimePeriodType.yearly:
        final prevYear = DateTime(startDate.year - 1, 1, 1);
        final prevEnd = DateTime(startDate.year - 1, 12, 31);
        return TimePeriod(
          type: type,
          startDate: prevYear,
          endDate: prevEnd,
          displayName: formatYearlyPeriod(prevYear),
        );
    }
  }

  // Get multiple previous periods for trend analysis
  List<TimePeriod> getPreviousPeriods(int count) {
    final periods = <TimePeriod>[];
    var currentPeriod = this;
    
    for (int i = 0; i < count; i++) {
      currentPeriod = currentPeriod.getPreviousPeriod();
      periods.add(currentPeriod);
    }
    
    return periods;
  }

  // Check if a date falls within this period
  bool containsDate(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
           date.isBefore(endDate.add(const Duration(days: 1)));
  }

  // Static factory methods
  static TimePeriod currentWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return TimePeriod(
      type: TimePeriodType.weekly,
      startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
      endDate: DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
      displayName: formatWeeklyPeriod(weekStart, weekEnd),
    );
  }

  static TimePeriod currentMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return TimePeriod(
      type: TimePeriodType.monthly,
      startDate: monthStart,
      endDate: monthEnd,
      displayName: formatMonthlyPeriod(monthStart),
    );
  }

  static TimePeriod currentQuarter() {
    final now = DateTime.now();
    final quarterStart = _getQuarterStart(now);
    final quarterEnd = _getQuarterEnd(quarterStart);
    
    return TimePeriod(
      type: TimePeriodType.quarterly,
      startDate: quarterStart,
      endDate: quarterEnd,
      displayName: formatQuarterlyPeriod(quarterStart),
    );
  }

  static TimePeriod currentYear() {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
    
    return TimePeriod(
      type: TimePeriodType.yearly,
      startDate: yearStart,
      endDate: yearEnd,
      displayName: formatYearlyPeriod(yearStart),
    );
  }

  // Helper methods for formatting
  static String formatWeeklyPeriod(DateTime start, DateTime end) {
    if (start.month == end.month) {
      return 'Week ${start.day}-${end.day} ${getMonthName(start.month)} ${start.year}';
    } else {
      return 'Week ${start.day} ${getMonthName(start.month)} - ${end.day} ${getMonthName(end.month)} ${start.year}';
    }
  }

  static String formatMonthlyPeriod(DateTime date) {
    return '${getMonthName(date.month)} ${date.year}';
  }

  static String formatQuarterlyPeriod(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    return 'Q$quarter ${date.year}';
  }

  static String formatYearlyPeriod(DateTime date) {
    return '${date.year}';
  }

  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Quarter calculation helpers
  static DateTime _getQuarterStart(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    final startMonth = (quarter - 1) * 3 + 1;
    return DateTime(date.year, startMonth, 1);
  }

  static DateTime _getQuarterEnd(DateTime quarterStart) {
    final endMonth = quarterStart.month + 2;
    return DateTime(quarterStart.year, endMonth + 1, 0, 23, 59, 59);
  }

  static Map<String, DateTime> _getPreviousQuarter(DateTime currentQuarterStart) {
    final currentQuarter = ((currentQuarterStart.month - 1) ~/ 3) + 1;
    
    if (currentQuarter == 1) {
      // Previous quarter is Q4 of previous year
      final prevYear = currentQuarterStart.year - 1;
      final start = DateTime(prevYear, 10, 1);
      final end = DateTime(prevYear, 12, 31, 23, 59, 59);
      return {'start': start, 'end': end};
    } else {
      // Previous quarter is in the same year
      final prevQuarter = currentQuarter - 1;
      final startMonth = (prevQuarter - 1) * 3 + 1;
      final start = DateTime(currentQuarterStart.year, startMonth, 1);
      final end = DateTime(currentQuarterStart.year, startMonth + 2 + 1, 0, 23, 59, 59);
      return {'start': start, 'end': end};
    }
  }

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimePeriod &&
        other.type == type &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(type, startDate, endDate);
}
