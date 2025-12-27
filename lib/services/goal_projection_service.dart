import 'dart:math';

import '../models/goal_model.dart';

/// Utility service to run Monte-Carlo style projections for long-term goals.
///
/// The simulation assumes periodic contributions (monthly by default) and
/// log-normal investment returns derived from an expected annual return and
/// annual volatility.
class GoalProjectionService {
  static final GoalProjectionService instance = GoalProjectionService._internal();
  GoalProjectionService._internal();

  /// Runs a Monte-Carlo simulation and returns the probability of the goal
  /// balance meeting or exceeding the target amount by the target date.
  ///
  /// [goal] – target & current saved amounts.
  /// [contribution] – periodic contribution amount.
  /// [contributionFrequency] – contributions per year (e.g. 12 for monthly).
  /// [expectedReturn] – expected annual return in decimal (0.07 = 7%).
  /// [volatility] – annual std-dev of returns (0.12 = 12%).
  /// [iterations] – number of simulation paths (e.g. 1000).
  Future<double> probabilityOfSuccess({
    required Goal goal,
    required double contribution,
    int contributionFrequency = 12,
    double expectedReturn = 0.06,
    double volatility = 0.12,
    int iterations = 1000,
  }) async {
    if (goal.targetDate == null) return 0.0;
    final years = _yearsBetween(DateTime.now(), goal.targetDate!);
    if (years <= 0) return goal.currentAmount >= goal.targetAmount ? 1.0 : 0.0;

    final steps = (years * contributionFrequency).round();
    final dt = 1 / contributionFrequency; // time step in years

    int successCount = 0;
    final rand = Random.secure();

    for (int i = 0; i < iterations; i++) {
      double balance = goal.currentAmount;
      for (int step = 0; step < steps; step++) {
        // Contribution at period start
        balance += contribution;
        // Geometric Brownian motion step
        final z = _randomNormal(rand);
        final growth = (expectedReturn - 0.5 * pow(volatility, 2)) * dt +
            volatility * sqrt(dt) * z;
        balance *= exp(growth);
        if (balance >= goal.targetAmount) {
          successCount++;
          break; // exit early for efficiency
        }
      }
    }

    return successCount / iterations;
  }

  /// Generates a vector of simulated ending balances to build percentile
  /// bands for charts.
  Future<List<double>> endingBalanceDistribution({
    required Goal goal,
    required double contribution,
    int contributionFrequency = 12,
    double expectedReturn = 0.06,
    double volatility = 0.12,
    int iterations = 1000,
  }) async {
    if (goal.targetDate == null) return [];
    final years = _yearsBetween(DateTime.now(), goal.targetDate!);
    final steps = (years * contributionFrequency).round();
    final dt = 1 / contributionFrequency;

    final balances = <double>[];
    final rand = Random.secure();

    for (int i = 0; i < iterations; i++) {
      double balance = goal.currentAmount;
      for (int step = 0; step < steps; step++) {
        balance += contribution;
        final z = _randomNormal(rand);
        final growth = (expectedReturn - 0.5 * pow(volatility, 2)) * dt +
            volatility * sqrt(dt) * z;
        balance *= exp(growth);
      }
      balances.add(balance);
    }
    return balances;
  }

  // ────────────────────────────────────────────────────────────────────────────
  double _yearsBetween(DateTime a, DateTime b) {
    return b.difference(a).inDays / 365.25;
  }

  // Polar Box-Muller transform for standard normal generation
  double _randomNormal(Random rng) {
    double u, v, s;
    do {
      u = rng.nextDouble() * 2 - 1;
      v = rng.nextDouble() * 2 - 1;
      s = u * u + v * v;
    } while (s >= 1 || s == 0);
    final factor = sqrt(-2 * log(s) / s);
    return u * factor;
  }
}
