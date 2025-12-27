import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Service to monitor network connectivity status and provide offline support
class ConnectivityService extends ChangeNotifier {
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _logger = Logger('ConnectivityService');
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  bool _isOnline = true;
  bool _isInitialized = false;
  
  /// Whether the device is currently online
  bool get isOnline => _isOnline;
  
  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;
  
  /// Initialize the connectivity service and start monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check initial connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResult);
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      
      _isInitialized = true;
      _logger.info('Connectivity service initialized');
    } catch (e) {
      _logger.severe('Failed to initialize connectivity service: $e');
      // Default to online if we can't check connectivity
      _isOnline = true;
    }
  }
  
  /// Update the connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    
    // Update online status
    _isOnline = result != ConnectivityResult.none;
    
    // Log status changes
    if (wasOnline != _isOnline) {
      _logger.info('Connection status changed: ${_isOnline ? 'Online' : 'Offline'}');
      notifyListeners();
    }
  }
  
  /// Dispose of resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _logger.info('Connectivity service disposed');
    super.dispose();
  }
}
