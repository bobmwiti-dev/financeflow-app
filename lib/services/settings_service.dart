import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

/// Simple wrapper around [SharedPreferences] for frequently used app settings.
class SettingsService {
  static final SettingsService instance = SettingsService._internal();
  final Logger _logger = Logger('SettingsService');
  SharedPreferences? _prefs;

  SettingsService._internal();

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ---------------- Pay-day -----------------
  static const String _keyPayDayDom = 'pay_day_dom';

  Future<int> getPayDayDom() async {
    await init();
    return _prefs!.getInt(_keyPayDayDom) ?? 25; // default 25th
  }

  Future<void> setPayDayDom(int dayOfMonth) async {
    if (dayOfMonth < 1 || dayOfMonth > 31) {
      _logger.warning('Invalid pay-day DOM: $dayOfMonth');
      return;
    }
    await init();
    await _prefs!.setInt(_keyPayDayDom, dayOfMonth);
  }
}
