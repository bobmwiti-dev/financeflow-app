import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A simple logging service for the application that uses proper logging
/// techniques instead of direct print statements.
class Logger {
  final String _tag;
  
  /// Creates a new logger instance with the given tag
  Logger(this._tag);
  
  /// Log an informational message
  void info(String message) {
    _log('INFO', message);
  }
  
  /// Log a warning message
  void warning(String message) {
    _log('WARNING', message);
  }
  
  /// Log an error message
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message);
    if (error != null) {
      developer.log('$error', name: _tag, error: error, stackTrace: stackTrace);
    }
  }
  
  /// Log a debug message
  void debug(String message) {
    // Only log debug messages in debug mode
    if (kDebugMode) {
      _log('DEBUG', message);
    }
  }
  
  void _log(String level, String message) {
    developer.log(message, name: '$_tag-$level');
  }
}
