import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_config.dart';
import '../models/dashboard_widget_config.dart' hide DashboardConfig;

class DashboardService {
  // Singleton pattern
  static final DashboardService _instance = DashboardService._internal();
  static DashboardService get instance => _instance;
  DashboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user ID
  String? get _userId => _auth.currentUser?.uid;

  // Reference to user's dashboard config
  DocumentReference<Map<String, dynamic>> get _dashboardConfigRef =>
      _firestore.collection('users').doc(_userId).collection('settings').doc('dashboard');

  // Get dashboard configuration
  Future<DashboardConfig?> getDashboardConfig() async {
    if (_userId == null) return null;

    try {
      final docSnapshot = await _dashboardConfigRef.get();
      if (docSnapshot.exists) {
        return DashboardConfig.fromJson(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting dashboard config: $e');
      return null;
    }
  }

  // Save dashboard configuration
  Future<void> saveDashboardConfig(DashboardConfig config) async {
    if (_userId == null) return;

    try {
      await _dashboardConfigRef.set(config.toJson());
    } catch (e) {
      debugPrint('Error saving dashboard config: $e');
    }
  }
  
  // Update a single widget's configuration
  Future<void> updateWidgetConfig(DashboardWidgetConfig widget) async {
    if (_userId == null) return;
    
    try {
      final config = await getDashboardConfig();
      if (config != null) {
        final index = config.widgets.indexWhere((w) => w.id == widget.id);
        if (index != -1) {
          final updatedWidgets = List<DashboardWidgetConfig>.from(config.widgets);
          updatedWidgets[index] = widget;
          await saveDashboardConfig(config.copyWith(widgets: updatedWidgets));
        } else {
          final updatedWidgets = List<DashboardWidgetConfig>.from(config.widgets)..add(widget);
          await saveDashboardConfig(config.copyWith(widgets: updatedWidgets));
        }
      }
    } catch (e) {
      debugPrint('Error updating widget config: $e');
    }
  }
  
  // Delete a widget from the dashboard
  Future<void> deleteWidget(String widgetId) async {
    if (_userId == null) return;
    
    try {
      final config = await getDashboardConfig();
      if (config != null) {
        final updatedWidgets = config.widgets.where((w) => w.id != widgetId).toList();
        await saveDashboardConfig(config.copyWith(widgets: updatedWidgets));
      }
    } catch (e) {
      debugPrint('Error deleting widget: $e');
    }
  }
  
  // Reorder widgets in the dashboard
  Future<void> reorderWidgets(List<DashboardWidgetConfig> widgets) async {
    if (_userId == null) return;
    
    try {
      final config = await getDashboardConfig();
      if (config != null) {
        await saveDashboardConfig(config.copyWith(widgets: widgets));
      }
    } catch (e) {
      debugPrint('Error reordering widgets: $e');
    }
  }
}
