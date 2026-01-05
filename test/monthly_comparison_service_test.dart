import 'package:flutter_test/flutter_test.dart';

import 'package:financeflow_app/services/monthly_comparison_service.dart';

void main() {
  group('MonthlyComparisonService', () {
    test('normalizeMonth sets day to 1', () {
      final m = MonthlyComparisonService.normalizeMonth(DateTime(2025, 3, 18));
      expect(m, DateTime(2025, 3, 1));
    });

    test('previousMonth handles year roll-over', () {
      final prev = MonthlyComparisonService.previousMonth(DateTime(2025, 1, 5));
      expect(prev, DateTime(2024, 12, 1));
    });

    test('sameMonthLastYear keeps month, subtracts year', () {
      final lastYear = MonthlyComparisonService.sameMonthLastYear(DateTime(2025, 7, 31));
      expect(lastYear, DateTime(2024, 7, 1));
    });
  });
}
