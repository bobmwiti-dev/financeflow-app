import 'dart:math';

import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart' as models;
import 'transaction_service.dart';

/// Lightweight engine for building day-by-day balance forecasts.
///
/// 1. Detects recurring transactions automatically (≥ 3 identical merchant+amount
///    combos spaced at a regular interval).
/// 2. Injects the next expected instances of those recurrings into the forecast.
/// 3. Adds an averaged discretionary daily spend based on the last 30 days.
/// 4. Returns a list of [ProjectedBalanceEntry] suitable for graphing in the
///    dashboard.
class CashFlowService {
  // ────────────────────────────────────────────────────────────────────────────
  // Singleton boilerplate
  // ────────────────────────────────────────────────────────────────────────────
  CashFlowService._internal();
  static final CashFlowService _instance = CashFlowService._internal();
  factory CashFlowService() => _instance;
  static CashFlowService get instance => _instance;

  final Logger _logger = Logger('CashFlowService');

  // Public API
  // ---------------------------------------------------------------------------
  /// Builds a daily balance projection starting today for [horizonDays].
  ///
  /// If [currentBalance] is not supplied, the running balance is initialised to
  /// 0 – the UI can overlay the real ledger balance if available.
  Future<List<ProjectedBalanceEntry>> buildForecast({
    required double currentBalance,
    int horizonDays = 30,
  }) async {
    // 1) Grab recent history (last 12 months or 1 000 tx – whichever smaller).
    final history = await TransactionService.instance.getRecentTransactions(1000);
    if (history.isEmpty) {
      _logger.warning('No transaction history found; returning flat projection');
      return _generateFlatProjection(currentBalance, horizonDays);
    }

    // 2) Detect recurring patterns.
    final recurringPatterns = _detectRecurring(history);

    // 3) Average discretionary spend (expenses not matched to recurring).
    final avgDiscretionaryDaily = _averageDailyDiscretionary(history, recurringPatterns);

    // 4) Generate future predicted events.
    final eventsByDate = _projectFutureEvents(recurringPatterns, horizonDays);

    // 5) Build the running balance list.
    final today = DateTime.now();
    final results = <ProjectedBalanceEntry>[];
    double running = currentBalance;

    for (int i = 0; i < horizonDays; i++) {
      final date = DateTime(today.year, today.month, today.day + i);
      final dayEvents = eventsByDate[DateFormat('yyyy-MM-dd').format(date)] ?? [];

      double totalIncome = 0;
      double totalExpense = 0;

      for (final ev in dayEvents) {
        if (ev.isIncome) {
          running += ev.amount;
          totalIncome += ev.amount;
        } else {
          running -= ev.amount;
          totalExpense += ev.amount;
        }
      }

      // Apply discretionary spending except today for income day events that already include variable? We still subtract.
      running -= avgDiscretionaryDaily;
      totalExpense += avgDiscretionaryDaily;

      results.add(ProjectedBalanceEntry(
        date: date,
        balance: running,
        expectedIncome: totalIncome,
        expectedExpense: totalExpense,
      ));
    }

    return results;
  }

  // DETECTION ────────────────────────────────────────────────────────────────
  List<RecurringPattern> _detectRecurring(List<models.Transaction> history) {
    // Group by merchant/amount cluster.
    final Map<String, List<models.Transaction>> groups = {};

    for (final tx in history) {
      final merchant = tx.title.trim().toLowerCase();
      // Cluster amount by rounding to nearest 1 (or 0.01 if required)
      final int amtKey = (tx.amount.abs()).round();
      final key = '${merchant}_$amtKey';
      groups.putIfAbsent(key, () => []).add(tx);
    }

    final List<RecurringPattern> patterns = [];

    for (final entry in groups.entries) {
      final transactions = entry.value;
      if (transactions.length < 3) continue; // need at least three data points

      // Sort by date ascending
      transactions.sort((a, b) => a.date.compareTo(b.date));

      // Compute day-intervals between consecutive instances
      final intervals = <int>[];
      for (int i = 1; i < transactions.length; i++) {
        intervals.add(transactions[i].date.difference(transactions[i - 1].date).inDays);
      }

      // Get median interval
      if (intervals.isEmpty) continue;
      intervals.sort();
      final median = intervals[intervals.length ~/ 2];
      final stdDev = _stdDev(intervals.map((e) => e.toDouble()).toList());

      // Heuristics: interval 5–8 days → weekly; 25–35 → monthly; 350–380 → yearly
      if (stdDev > 3) continue; // not regular enough
      if (median < 5 || median > 380) continue;

      final last = transactions.last;
      final nextDue = last.date.add(Duration(days: median));

      patterns.add(RecurringPattern(
        merchant: last.title,
        amount: last.amount.abs(),
        isIncome: last.type == models.TransactionType.income,
        frequencyDays: median,
        nextDue: nextDue,
        confidence: _confidenceScore(intervals, stdDev),
      ));
    }

    _logger.fine('Detected ${patterns.length} recurring patterns');
    return patterns;
  }

  // Average discretionary spend (expenses not linked to recurring) over last 30 days.
  double _averageDailyDiscretionary(List<models.Transaction> history, List<RecurringPattern> patterns) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final recurringKeys = patterns.map((p) => _recKey(p.merchant, p.amount)).toSet();

    double totalExpense = 0;
    int countDays = 30;

    for (final tx in history) {
      if (tx.date.isBefore(cutoff)) continue;
      if (tx.type != models.TransactionType.expense) continue;
      final key = _recKey(tx.title, tx.amount.abs());
      if (recurringKeys.contains(key)) continue; // skip recurring ones
      totalExpense += tx.amount.abs();
    }

    return totalExpense / countDays;
  }

  // PROJECT FUTURE EVENTS ────────────────────────────────────────────────────
  Map<String, List<PredictedEvent>> _projectFutureEvents(List<RecurringPattern> patterns, int horizonDays) {
    final today = DateTime.now();
    final endDate = today.add(Duration(days: horizonDays));

    final Map<String, List<PredictedEvent>> byDate = {};

    for (final p in patterns) {
      var due = p.nextDue;
      while (!due.isAfter(endDate)) {
        final key = DateFormat('yyyy-MM-dd').format(due);
        byDate.putIfAbsent(key, () => []).add(PredictedEvent(
          title: p.merchant,
          amount: p.amount,
          date: due,
          isIncome: p.isIncome,
          isRecurring: true,
        ));
        due = due.add(Duration(days: p.frequencyDays));
      }
    }

    return byDate;
  }

  // HELPERS ──────────────────────────────────────────────────────────────────
  List<ProjectedBalanceEntry> _generateFlatProjection(double currentBalance, int horizonDays) {
    final today = DateTime.now();
    return List.generate(horizonDays, (index) {
      final date = DateTime(today.year, today.month, today.day + index);
      return ProjectedBalanceEntry(
        date: date,
        balance: currentBalance,
        expectedIncome: 0,
        expectedExpense: 0,
      );
    });
  }

  double _stdDev(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  double _confidenceScore(List<int> intervals, double stdDev) {
    // Simple heuristic: more occurrences + low deviation increases confidence (0-1)
    final base = intervals.length / 12; // 12 occurrences gives 1.0 base
    final deviationPenalty = min(stdDev / 4, 1); // stdDev >4 → full penalty
    return (base * (1 - deviationPenalty)).clamp(0.2, 1.0);
  }

    /// Returns the next [limit] upcoming predicted events sorted soonest first.
  Future<List<PredictedEvent>> getUpcomingEvents({int limit = 7}) async {
    final history = await TransactionService.instance.getRecentTransactions(1000);
    if (history.isEmpty) return [];

    final patterns = _detectRecurring(history);
    final eventsByDate = _projectFutureEvents(patterns, 365);
    final sortedDates = eventsByDate.keys.toList()..sort();
    final List<PredictedEvent> result = [];
    for (final dateStr in sortedDates) {
      final date = DateTime.parse(dateStr);
      if (date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))) continue;
      result.addAll(eventsByDate[dateStr]!);
      if (result.length >= limit) break;
    }
    return result.take(limit).toList();
  }

  String _recKey(String merchant, double amount) {
    return '${merchant.trim().toLowerCase()}_${amount.abs().round()}';
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helper data classes
// ────────────────────────────────────────────────────────────────────────────

class RecurringPattern {
  final String merchant;
  final double amount;
  final bool isIncome;
  final int frequencyDays;
  DateTime nextDue;
  final double confidence;

  RecurringPattern({
    required this.merchant,
    required this.amount,
    required this.isIncome,
    required this.frequencyDays,
    required this.nextDue,
    required this.confidence,
  });
}

class PredictedEvent {
  final String title;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final bool isRecurring;

  PredictedEvent({
    required this.title,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.isRecurring = false,
  });
}

class ProjectedBalanceEntry {
  final DateTime date;
  final double balance;
  final double expectedIncome;
  final double expectedExpense;

  ProjectedBalanceEntry({
    required this.date,
    required this.balance,
    required this.expectedIncome,
    required this.expectedExpense,
  });
}
