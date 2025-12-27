/// Data model representing a point-in-time snapshot of the user's net-worth.
class NetWorthSnapshot {
  final double total; // Total net-worth value
  final double delta; // Change over previous day (absolute, can be negative)
  final Map<String, double> breakdown; // e.g. {'Bank': 15000, 'Brokerage': 32000}
  final DateTime timestamp;

  const NetWorthSnapshot({
    required this.total,
    required this.delta,
    required this.breakdown,
    required this.timestamp,
  });

  bool get isPositiveChange => delta >= 0;

  double get deltaPercent => total == 0 ? 0 : delta / (total - delta) * 100;
}
