import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/insight_model.dart';
import '../services/insights_service.dart';

class InsightsViewModel extends ChangeNotifier {
  final InsightsService _insightsService = InsightsService.instance;
  List<Insight> _insights = [];
  bool _isLoading = false;
  bool _isGenerating = false; // Will be used for both generating insights and calculating "In My Pocket"

  double? _inMyPocketAmount;

  final Logger logger = Logger('InsightsViewModel');

  List<Insight> get insights => _insights;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  double? get inMyPocketAmount => _inMyPocketAmount;

  int get unreadCount => _insights.where((insight) => !insight.isRead).length;

  // Get insights grouped by type
  Map<String, List<Insight>> get insightsByType {
    Map<String, List<Insight>> result = {};
    
    for (var insight in _insights) {
      if (!result.containsKey(insight.type)) {
        result[insight.type] = [];
      }
      result[insight.type]!.add(insight);
    }
    
    return result;
  }

  // Load insights from database
  Future<void> loadInsights() async {
    _isLoading = true;
    notifyListeners();

    try {
      _insights = await _insightsService.getInsights();
    } catch (e) {
      logger.info('Error loading insights: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate insights for a specific month
  Future<void> generateInsightsForMonth(DateTime month) async {
    _isGenerating = true;
    notifyListeners();
    try {
      final newInsights = await _insightsService.generateInsightsForMonth(month);
      // Save new insights to the database
      for (var insight in newInsights) {
        await _insightsService.saveInsight(insight);
      }

      // Instead of calling loadInsights(), fetch all insights again to refresh the list
      // This avoids nested loading states (isGenerating -> isLoading)
      _insights = await _insightsService.getInsights();
    } catch (e) {
      logger.info('Error generating insights for month: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Generate new insights
  Future<void> generateInsights() async {
    _isGenerating = true;
    notifyListeners();

    try {
      final newInsights = await _insightsService.generateInsights();
      
      // Save new insights to database
      for (var insight in newInsights) {
        await _insightsService.saveInsight(insight);
      }
      
      // Reload insights
      await loadInsights();
    } catch (e) {
      logger.info('Error generating insights: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Fetch the 'In My Pocket' amount
  Future<void> fetchInMyPocketAmount() async {
    _isGenerating = true;
    notifyListeners();

    try {
      _inMyPocketAmount = await _insightsService.calculateInMyPocket();
      logger.info('Successfully calculated In My Pocket amount: $_inMyPocketAmount');
    } catch (e) {
      logger.severe('Error calculating In My Pocket amount: $e');
      _inMyPocketAmount = null; // Reset on error
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // Mark insight as read
  Future<void> markInsightAsRead(int id) async {
    try {
      await _insightsService.markAsRead(id);
      
      // Update local list
      final index = _insights.indexWhere((insight) => insight.id == id);
      if (index != -1) {
        _insights[index] = _insights[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      logger.warning('Error marking insight as read: $e');
    }
  }

  // Dismiss insight
  Future<void> dismissInsight(int id) async {
    try {
      await _insightsService.dismissInsight(id);
      
      // Remove from local list
      _insights.removeWhere((insight) => insight.id == id);
      notifyListeners();
    } catch (e) {
      logger.severe('Error dismissing insight: $e');
    }
  }

  // Get insights of a specific type
  List<Insight> getInsightsByType(String type) {
    return _insights.where((insight) => insight.type == type).toList();
  }

  // Get unread insights
  List<Insight> getUnreadInsights() {
    return _insights.where((insight) => !insight.isRead).toList();
  }

  // Get insights sorted by relevance
  List<Insight> getInsightsByRelevance() {
    final sorted = List<Insight>.from(_insights);
    sorted.sort((a, b) => (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0));
    return sorted;
  }

  // Get most recent insights
  List<Insight> getRecentInsights(int limit) {
    final sorted = List<Insight>.from(_insights);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }
}