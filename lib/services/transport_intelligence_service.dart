import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transport_intelligence_model.dart';
import '../models/transaction_model.dart' as app_models;

/// Service for analyzing transport costs and providing optimization recommendations
class TransportIntelligenceService {
  static const String _logName = 'TransportIntelligenceService';
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Nairobi route database - major routes and their characteristics
  static final Map<String, NairobiRoute> _nairobiRoutes = {
    'cbd_westlands': NairobiRoute(
      routeId: 'cbd_westlands',
      fromLocation: 'CBD',
      toLocation: 'Westlands',
      distanceKm: 8.5,
      estimatedTimeMinutes: 25,
      landmarks: ['Museum Hill', 'Parklands', 'Westgate Mall'],
      routeName: 'CBD to Westlands',
      isMainRoute: true,
    ),
    'cbd_karen': NairobiRoute(
      routeId: 'cbd_karen',
      fromLocation: 'CBD',
      toLocation: 'Karen',
      distanceKm: 18.2,
      estimatedTimeMinutes: 45,
      landmarks: ['Langata Road', 'Galleria Mall', 'Karen Blixen'],
      routeName: 'CBD to Karen',
      isMainRoute: true,
    ),
    'cbd_kiambu': NairobiRoute(
      routeId: 'cbd_kiambu',
      fromLocation: 'CBD',
      toLocation: 'Kiambu',
      distanceKm: 22.0,
      estimatedTimeMinutes: 50,
      landmarks: ['Thika Road', 'Ruiru', 'Kiambu Town'],
      routeName: 'Thika Road to Kiambu',
      isMainRoute: true,
    ),
    'cbd_kasarani': NairobiRoute(
      routeId: 'cbd_kasarani',
      fromLocation: 'CBD',
      toLocation: 'Kasarani',
      distanceKm: 15.5,
      estimatedTimeMinutes: 35,
      landmarks: ['Moi Avenue', 'Kasarani Stadium', 'Clay City'],
      routeName: 'CBD to Kasarani',
      isMainRoute: true,
    ),
    'cbd_embakasi': NairobiRoute(
      routeId: 'cbd_embakasi',
      fromLocation: 'CBD',
      toLocation: 'Embakasi',
      distanceKm: 12.8,
      estimatedTimeMinutes: 30,
      landmarks: ['Jogoo Road', 'Donholm', 'Pipeline'],
      routeName: 'CBD to Embakasi',
      isMainRoute: true,
    ),
  };

  /// Generate comprehensive transport intelligence analysis
  static Future<TransportIntelligenceSummary> generateTransportAnalysis() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      developer.log('Generating transport intelligence analysis', name: _logName);

      // Get transport-related transactions
      final transportTransactions = await _getTransportTransactions(userId);
      
      // Analyze transport patterns
      final modeBreakdown = _analyzeModeBreakdown(transportTransactions);
      final totalMonthlyCost = _calculateMonthlyTransportCost(transportTransactions);
      
      // Generate route comparisons
      final routeComparisons = await _generateRouteComparisons(transportTransactions);
      
      // Analyze fuel efficiency if applicable
      final fuelAnalysis = await _analyzeFuelEfficiency(userId, transportTransactions);
      
      // Generate budget recommendations
      final budgetRecommendation = _generateBudgetRecommendations(
        transportTransactions, modeBreakdown, routeComparisons
      );
      
      // Calculate efficiency score
      final efficiencyScore = _calculateTransportEfficiencyScore(
        modeBreakdown, routeComparisons, fuelAnalysis
      );
      
      // Generate insights and recommendations
      final insights = _generateTransportInsights(
        modeBreakdown, routeComparisons, budgetRecommendation
      );
      final recommendations = _generateActionableRecommendations(
        routeComparisons, budgetRecommendation, fuelAnalysis
      );

      return TransportIntelligenceSummary(
        summaryId: _generateSummaryId(),
        userId: userId,
        generatedAt: DateTime.now(),
        totalMonthlyTransportCost: totalMonthlyCost,
        modeBreakdown: modeBreakdown,
        routeComparisons: routeComparisons,
        fuelAnalysis: fuelAnalysis,
        budgetRecommendation: budgetRecommendation,
        keyInsights: insights,
        actionableRecommendations: recommendations,
        transportEfficiencyScore: efficiencyScore,
      );

    } catch (e) {
      developer.log('Error generating transport analysis: $e', name: _logName);
      rethrow;
    }
  }

  /// Generate Matatu vs Uber comparison for specific routes
  static Future<List<MatatuVsUberAnalysis>> _generateRouteComparisons(
    List<app_models.Transaction> transportTransactions,
  ) async {
    final comparisons = <MatatuVsUberAnalysis>[];

    // Group transactions by detected routes
    final routeTransactions = _groupTransactionsByRoute(transportTransactions);

    for (final entry in routeTransactions.entries) {
      final routeId = entry.key;
      final transactions = entry.value;
      
      if (!_nairobiRoutes.containsKey(routeId)) continue;
      final route = _nairobiRoutes[routeId]!;

      // Separate Matatu and Uber transactions
      final matatuTxs = transactions.where((tx) => 
        _isMatatu(tx.description ?? '') || _isMatatu(tx.title)).toList();
      final uberTxs = transactions.where((tx) => 
        _isUber(tx.description ?? '') || _isUber(tx.title)).toList();

      if (matatuTxs.isNotEmpty && uberTxs.isNotEmpty) {
        final matatuAnalysis = _analyzeTransportMode(
          route, TransportMode.matatu, matatuTxs
        );
        final uberAnalysis = _analyzeTransportMode(
          route, TransportMode.uber, uberTxs
        );

        final comparison = _createMatatuVsUberComparison(
          route, matatuAnalysis, uberAnalysis
        );
        comparisons.add(comparison);
      }
    }

    return comparisons;
  }

  /// Analyze transport mode costs and characteristics
  static TransportCostAnalysis _analyzeTransportMode(
    NairobiRoute route,
    TransportMode mode,
    List<app_models.Transaction> transactions,
  ) {
    final costs = transactions.map((tx) => tx.amount).toList();
    final averageCost = costs.reduce((a, b) => a + b) / costs.length;
    final minCost = costs.reduce(math.min);
    final maxCost = costs.reduce(math.max);

    // Calculate scores based on mode characteristics
    final scores = _getTransportModeScores(mode, route);

    return TransportCostAnalysis(
      analysisId: '${mode.toString()}_${route.routeId}_${DateTime.now().millisecondsSinceEpoch}',
      route: route,
      mode: mode,
      averageCost: averageCost,
      minCost: minCost,
      maxCost: maxCost,
      tripCount: transactions.length,
      costPerKm: averageCost / route.distanceKm,
      costPerMinute: averageCost / route.estimatedTimeMinutes,
      lastUpdated: DateTime.now(),
      additionalCosts: _getAdditionalCosts(mode),
      reliabilityScore: scores['reliability']!,
      comfortScore: scores['comfort']!,
      speedScore: scores['speed']!,
    );
  }

  /// Create Matatu vs Uber comparison
  static MatatuVsUberAnalysis _createMatatuVsUberComparison(
    NairobiRoute route,
    TransportCostAnalysis matatuAnalysis,
    TransportCostAnalysis uberAnalysis,
  ) {
    final costDifference = uberAnalysis.averageCost - matatuAnalysis.averageCost;
    final timeDifference = matatuAnalysis.route.estimatedTimeMinutes - 
                          uberAnalysis.route.estimatedTimeMinutes;

    final recommendation = _generateRouteRecommendation(
      matatuAnalysis, uberAnalysis, costDifference
    );

    return MatatuVsUberAnalysis(
      comparisonId: 'comparison_${route.routeId}_${DateTime.now().millisecondsSinceEpoch}',
      route: route,
      matatuAnalysis: matatuAnalysis,
      uberAnalysis: uberAnalysis,
      costDifference: costDifference,
      timeDifference: timeDifference.toDouble(),
      recommendation: recommendation,
      factors: {
        'costSavings': costDifference,
        'timeDifference': timeDifference,
        'comfortDifference': uberAnalysis.comfortScore - matatuAnalysis.comfortScore,
        'reliabilityDifference': uberAnalysis.reliabilityScore - matatuAnalysis.reliabilityScore,
      },
      generatedAt: DateTime.now(),
    );
  }

  /// Analyze fuel efficiency for personal vehicles
  static Future<FuelEfficiencyAnalysis?> _analyzeFuelEfficiency(
    String userId,
    List<app_models.Transaction> transportTransactions,
  ) async {
    // Look for fuel-related transactions
    final fuelTransactions = transportTransactions.where((tx) =>
      _isFuelTransaction(tx.description ?? '') || _isFuelTransaction(tx.title)
    ).toList();

    if (fuelTransactions.length < 3) return null; // Need minimum data

    // Extract fuel station information
    final stationComparison = <String, List<double>>{};
    final fuelTxs = <FuelTransaction>[];

    for (final tx in fuelTransactions) {
      final stationName = _extractFuelStationName(tx.description ?? '');
      final pricePerLiter = _estimateFuelPrice(tx.amount, tx.date);
      final liters = tx.amount / pricePerLiter;

      stationComparison.putIfAbsent(stationName, () => []).add(pricePerLiter);
      
      fuelTxs.add(FuelTransaction(
        transactionId: tx.id ?? '',
        date: tx.date,
        stationName: stationName,
        liters: liters,
        pricePerLiter: pricePerLiter,
        totalCost: tx.amount,
        odometerReading: 0, // Would need additional data
        fuelType: 'Petrol', // Default assumption
      ));
    }

    // Calculate averages for each station
    final stationAvgPrices = <String, double>{};
    for (final entry in stationComparison.entries) {
      final avgPrice = entry.value.reduce((a, b) => a + b) / entry.value.length;
      stationAvgPrices[entry.key] = avgPrice;
    }

    final totalFuelCost = fuelTransactions.map((tx) => tx.amount).reduce((a, b) => a + b);
    final avgFuelPrice = stationAvgPrices.values.reduce((a, b) => a + b) / stationAvgPrices.length;
    
    // Estimate efficiency (would be more accurate with odometer data)
    const estimatedKmPerLiter = 12.0; // Average for Kenyan vehicles
    final totalLiters = totalFuelCost / avgFuelPrice;
    final estimatedDistance = totalLiters * estimatedKmPerLiter;

    return FuelEfficiencyAnalysis(
      analysisId: 'fuel_analysis_${DateTime.now().millisecondsSinceEpoch}',
      vehicleId: 'user_vehicle',
      vehicleModel: 'Unknown',
      totalFuelCost: totalFuelCost,
      totalDistanceKm: estimatedDistance,
      fuelEfficiencyKmPerLiter: estimatedKmPerLiter,
      costPerKm: totalFuelCost / estimatedDistance,
      averageFuelPrice: avgFuelPrice,
      fuelTransactions: fuelTxs,
      analysisStartDate: fuelTransactions.map((tx) => tx.date).reduce((a, b) => a.isBefore(b) ? a : b),
      analysisEndDate: fuelTransactions.map((tx) => tx.date).reduce((a, b) => a.isAfter(b) ? a : b),
      stationComparison: stationAvgPrices,
    );
  }

  /// Generate budget recommendations
  static TransportBudgetRecommendation _generateBudgetRecommendations(
    List<app_models.Transaction> transactions,
    Map<TransportMode, double> modeBreakdown,
    List<MatatuVsUberAnalysis> routeComparisons,
  ) {
    final currentSpending = transactions.map((tx) => tx.amount).fold(0.0, (a, b) => a + b);
    
    // Calculate potential savings from route optimizations
    double potentialSavings = 0;
    final routeOptimizations = <RouteOptimization>[];
    
    for (final comparison in routeComparisons) {
      if (comparison.matatuAnalysis.averageCost < comparison.uberAnalysis.averageCost) {
        final savings = comparison.costDifference;
        potentialSavings += savings;
        
        routeOptimizations.add(RouteOptimization(
          routeId: comparison.route.routeId,
          route: comparison.route,
          currentMode: TransportMode.uber,
          recommendedMode: TransportMode.matatu,
          currentCost: comparison.uberAnalysis.averageCost,
          recommendedCost: comparison.matatuAnalysis.averageCost,
          monthlySavings: savings * 20, // Assume 20 trips per month
          reason: 'Matatu is ${(comparison.costSavingsPercentage).toStringAsFixed(0)}% cheaper',
          confidence: 0.8,
        ));
      }
    }

    final recommendedBudget = currentSpending - potentialSavings;
    
    return TransportBudgetRecommendation(
      recommendationId: 'budget_rec_${DateTime.now().millisecondsSinceEpoch}',
      userId: _auth.currentUser?.uid ?? '',
      currentMonthlySpending: currentSpending,
      recommendedBudget: recommendedBudget,
      potentialSavings: potentialSavings,
      optimizationStrategies: _generateOptimizationStrategies(routeComparisons),
      modeBreakdown: modeBreakdown,
      routeOptimizations: routeOptimizations,
      generatedAt: DateTime.now(),
    );
  }

  /// Helper methods for transport analysis
  static Future<List<app_models.Transaction>> _getTransportTransactions(String userId) async {
    // This would fetch transport-related transactions from Firestore
    // For now, return empty list - would be implemented with actual data
    return [];
  }

  static Map<TransportMode, double> _analyzeModeBreakdown(List<app_models.Transaction> transactions) {
    final breakdown = <TransportMode, double>{};
    
    for (final tx in transactions) {
      final mode = _detectTransportMode(tx);
      breakdown[mode] = (breakdown[mode] ?? 0) + tx.amount;
    }
    
    return breakdown;
  }

  static double _calculateMonthlyTransportCost(List<app_models.Transaction> transactions) {
    if (transactions.isEmpty) return 0;
    
    final totalCost = transactions.map((tx) => tx.amount).reduce((a, b) => a + b);
    final daysCovered = DateTime.now().difference(
      transactions.map((tx) => tx.date).reduce((a, b) => a.isBefore(b) ? a : b)
    ).inDays;
    
    return (totalCost / daysCovered) * 30.44; // Average days per month
  }

  static TransportMode _detectTransportMode(app_models.Transaction transaction) {
    final text = '${transaction.title} ${transaction.description ?? ''}'.toLowerCase();
    
    if (text.contains('uber')) return TransportMode.uber;
    if (text.contains('bolt')) return TransportMode.bolt;
    if (text.contains('matatu') || text.contains('bus')) return TransportMode.matatu;
    if (text.contains('boda')) return TransportMode.boda;
    if (text.contains('taxi')) return TransportMode.taxi;
    if (text.contains('fuel') || text.contains('petrol')) return TransportMode.personalCar;
    
    return TransportMode.matatu; // Default assumption
  }

  static Map<String, List<app_models.Transaction>> _groupTransactionsByRoute(List<app_models.Transaction> transactions) {
    // This would use location data or transaction descriptions to group by routes
    // For now, return a simple grouping
    return {'cbd_westlands': transactions};
  }

  static bool _isMatatu(String text) {
    return text.toLowerCase().contains('matatu') || 
           text.toLowerCase().contains('bus') ||
           text.toLowerCase().contains('stage');
  }

  static bool _isUber(String text) {
    return text.toLowerCase().contains('uber');
  }

  static bool _isFuelTransaction(String text) {
    return text.toLowerCase().contains('fuel') ||
           text.toLowerCase().contains('petrol') ||
           text.toLowerCase().contains('shell') ||
           text.toLowerCase().contains('total') ||
           text.toLowerCase().contains('kenol');
  }

  static Map<String, double> _getTransportModeScores(TransportMode mode, NairobiRoute route) {
    switch (mode) {
      case TransportMode.matatu:
        return {'reliability': 70.0, 'comfort': 60.0, 'speed': 65.0};
      case TransportMode.uber:
        return {'reliability': 85.0, 'comfort': 90.0, 'speed': 80.0};
      case TransportMode.bolt:
        return {'reliability': 80.0, 'comfort': 85.0, 'speed': 80.0};
      case TransportMode.boda:
        return {'reliability': 75.0, 'comfort': 40.0, 'speed': 90.0};
      default:
        return {'reliability': 70.0, 'comfort': 70.0, 'speed': 70.0};
    }
  }

  static Map<String, dynamic> _getAdditionalCosts(TransportMode mode) {
    switch (mode) {
      case TransportMode.personalCar:
        return {'parking': 100.0, 'maintenance': 500.0};
      case TransportMode.uber:
        return {'surge_pricing': 50.0};
      default:
        return {};
    }
  }

  static String _generateRouteRecommendation(
    TransportCostAnalysis matatu,
    TransportCostAnalysis uber,
    double costDifference,
  ) {
    if (costDifference > 100) {
      return 'Use Matatu to save KSh ${costDifference.toStringAsFixed(0)} per trip';
    } else if (costDifference < -50) {
      return 'Uber offers better value considering comfort and reliability';
    } else {
      return 'Both options are reasonably priced - choose based on your priorities';
    }
  }

  static double _calculateTransportEfficiencyScore(
    Map<TransportMode, double> modeBreakdown,
    List<MatatuVsUberAnalysis> comparisons,
    FuelEfficiencyAnalysis? fuelAnalysis,
  ) {
    double score = 70.0; // Base score
    
    // Bonus for using cost-effective modes
    final totalSpending = modeBreakdown.values.fold(0.0, (a, b) => a + b);
    if (totalSpending > 0) {
      final matatuPercentage = (modeBreakdown[TransportMode.matatu] ?? 0) / totalSpending;
      score += matatuPercentage * 20; // Up to 20 points for using matatu
    }
    
    // Bonus for fuel efficiency
    if (fuelAnalysis != null) {
      if (fuelAnalysis.fuelEfficiencyKmPerLiter > 12) score += 10;
    }
    
    return math.min(score, 100.0);
  }

  static List<String> _generateTransportInsights(
    Map<TransportMode, double> modeBreakdown,
    List<MatatuVsUberAnalysis> comparisons,
    TransportBudgetRecommendation budget,
  ) {
    final insights = <String>[];
    
    // Mode breakdown insights
    final totalSpending = modeBreakdown.values.fold(0.0, (a, b) => a + b);
    if (totalSpending > 0) {
      final primaryMode = modeBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      insights.add('You spend ${((primaryMode.value / totalSpending) * 100).toStringAsFixed(0)}% of transport budget on ${primaryMode.key.toString().split('.').last}');
    }
    
    // Savings insights
    if (budget.potentialSavings > 0) {
      insights.add('You could save KSh ${budget.potentialSavings.toStringAsFixed(0)} monthly by optimizing transport choices');
    }
    
    // Route-specific insights
    for (final comparison in comparisons.take(2)) {
      if (comparison.costSavingsPercentage > 30) {
        insights.add('${comparison.route.routeName}: Matatu saves ${comparison.costSavingsPercentage.toStringAsFixed(0)}% vs Uber');
      }
    }
    
    return insights;
  }

  static List<String> _generateActionableRecommendations(
    List<MatatuVsUberAnalysis> comparisons,
    TransportBudgetRecommendation budget,
    FuelEfficiencyAnalysis? fuelAnalysis,
  ) {
    final recommendations = <String>[];
    
    // Route optimization recommendations
    for (final optimization in budget.routeOptimizations.take(2)) {
      recommendations.add('${optimization.route.routeName}: Switch to ${optimization.recommendedMode.toString().split('.').last} to save KSh ${optimization.monthlySavings.toStringAsFixed(0)}/month');
    }
    
    // Fuel efficiency recommendations
    if (fuelAnalysis != null && fuelAnalysis.potentialMonthlySavings > 100) {
      recommendations.add('Use ${fuelAnalysis.cheapestStation} for fuel to save KSh ${fuelAnalysis.potentialMonthlySavings.toStringAsFixed(0)}/month');
    }
    
    return recommendations;
  }

  static List<String> _generateOptimizationStrategies(List<MatatuVsUberAnalysis> comparisons) {
    final strategies = <String>[];
    
    strategies.add('Use Matatu during peak hours for better reliability');
    strategies.add('Choose Uber for late night trips for safety');
    strategies.add('Consider walking for short distances under 2km');
    strategies.add('Use ride-sharing apps during off-peak for better rates');
    
    return strategies;
  }

  static String _extractFuelStationName(String description) {
    final text = description.toLowerCase();
    if (text.contains('shell')) return 'Shell';
    if (text.contains('total')) return 'Total';
    if (text.contains('kenol')) return 'Kenol';
    if (text.contains('kobil')) return 'Kobil';
    return 'Unknown Station';
  }

  static double _estimateFuelPrice(double amount, DateTime date) {
    // Estimate fuel price based on date and amount
    // This would ideally use historical fuel price data
    return 150.0; // Default KSh per liter
  }

  static String _generateSummaryId() {
    return 'transport_summary_${DateTime.now().millisecondsSinceEpoch}';
  }
}
