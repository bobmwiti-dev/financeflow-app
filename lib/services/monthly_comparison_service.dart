class MonthlyComparisonService {
  static DateTime normalizeMonth(DateTime month) {
    return DateTime(month.year, month.month, 1);
  }

  static DateTime previousMonth(DateTime month) {
    final m = normalizeMonth(month);
    return DateTime(m.year, m.month - 1, 1);
  }

  static DateTime sameMonthLastYear(DateTime month) {
    final m = normalizeMonth(month);
    return DateTime(m.year - 1, m.month, 1);
  }
}
