import 'package:logging/logging.dart';

/// Lightweight analytics logger. In production this can be wired to Firebase
/// Analytics or any 3rd-party provider. For now it simply writes structured
/// events to the console.
class AnalyticsService {
  static final Logger _logger = Logger('Analytics');

  static void logEvent(String name, Map<String, Object?> parameters) {
    _logger.info('Analytics event: $name – $parameters');
  }
}
