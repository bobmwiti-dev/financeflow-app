import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Transport mode enumeration
enum TransportMode {
  matatu,
  uber,
  bolt,
  taxi,
  boda,
  personalCar,
  walking,
  cycling,
  bus,
  train,
}

/// Nairobi route information
class NairobiRoute {
  final String routeId;
  final String fromLocation;
  final String toLocation;
  final double distanceKm;
  final int estimatedTimeMinutes;
  final List<String> landmarks;
  final String routeName; // e.g., "CBD to Westlands", "Thika Road"
  final bool isMainRoute;

  NairobiRoute({
    required this.routeId,
    required this.fromLocation,
    required this.toLocation,
    required this.distanceKm,
    required this.estimatedTimeMinutes,
    required this.landmarks,
    required this.routeName,
    this.isMainRoute = false,
  });

  factory NairobiRoute.fromMap(Map<String, dynamic> map) {
    return NairobiRoute(
      routeId: map['routeId'] as String,
      fromLocation: map['fromLocation'] as String,
      toLocation: map['toLocation'] as String,
      distanceKm: (map['distanceKm'] as num).toDouble(),
      estimatedTimeMinutes: map['estimatedTimeMinutes'] as int,
      landmarks: List<String>.from(map['landmarks']),
      routeName: map['routeName'] as String,
      isMainRoute: map['isMainRoute'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'distanceKm': distanceKm,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'landmarks': landmarks,
      'routeName': routeName,
      'isMainRoute': isMainRoute,
    };
  }
}

/// Transport cost analysis for a specific route and mode
class TransportCostAnalysis {
  final String analysisId;
  final NairobiRoute route;
  final TransportMode mode;
  final double averageCost;
  final double minCost;
  final double maxCost;
  final int tripCount;
  final double costPerKm;
  final double costPerMinute;
  final DateTime lastUpdated;
  final Map<String, dynamic> additionalCosts; // parking, fuel, etc.
  final double reliabilityScore; // 0-100
  final double comfortScore; // 0-100
  final double speedScore; // 0-100

  TransportCostAnalysis({
    required this.analysisId,
    required this.route,
    required this.mode,
    required this.averageCost,
    required this.minCost,
    required this.maxCost,
    required this.tripCount,
    required this.costPerKm,
    required this.costPerMinute,
    required this.lastUpdated,
    required this.additionalCosts,
    required this.reliabilityScore,
    required this.comfortScore,
    required this.speedScore,
  });

  /// Get overall value score (cost vs quality)
  double get valueScore {
    final qualityScore = (reliabilityScore + comfortScore + speedScore) / 3;
    final costScore = math.max(0, 100 - (averageCost / 10)); // Lower cost = higher score
    return (qualityScore + costScore) / 2;
  }

  /// Get transport mode display name
  String get modeDisplayName {
    switch (mode) {
      case TransportMode.matatu: return 'Matatu';
      case TransportMode.uber: return 'Uber';
      case TransportMode.bolt: return 'Bolt';
      case TransportMode.taxi: return 'Taxi';
      case TransportMode.boda: return 'Boda Boda';
      case TransportMode.personalCar: return 'Personal Car';
      case TransportMode.walking: return 'Walking';
      case TransportMode.cycling: return 'Cycling';
      case TransportMode.bus: return 'Bus';
      case TransportMode.train: return 'Train';
    }
  }

  /// Get cost category
  String get costCategory {
    if (averageCost <= 50) return 'Budget';
    if (averageCost <= 200) return 'Moderate';
    if (averageCost <= 500) return 'Premium';
    return 'Luxury';
  }
}

/// Matatu vs Uber comparison analysis
class MatatuVsUberAnalysis {
  final String comparisonId;
  final NairobiRoute route;
  final TransportCostAnalysis matatuAnalysis;
  final TransportCostAnalysis uberAnalysis;
  final double costDifference;
  final double timeDifference;
  final String recommendation;
  final Map<String, dynamic> factors;
  final DateTime generatedAt;

  MatatuVsUberAnalysis({
    required this.comparisonId,
    required this.route,
    required this.matatuAnalysis,
    required this.uberAnalysis,
    required this.costDifference,
    required this.timeDifference,
    required this.recommendation,
    required this.factors,
    required this.generatedAt,
  });

  /// Get cost savings percentage
  double get costSavingsPercentage {
    if (uberAnalysis.averageCost == 0) return 0;
    return ((uberAnalysis.averageCost - matatuAnalysis.averageCost) / uberAnalysis.averageCost) * 100;
  }

  /// Get recommended mode based on various factors
  TransportMode get recommendedMode {
    // Consider cost, time, comfort, and reliability
    final matatuScore = _calculateModeScore(matatuAnalysis);
    final uberScore = _calculateModeScore(uberAnalysis);
    
    return matatuScore > uberScore ? TransportMode.matatu : TransportMode.uber;
  }

  double _calculateModeScore(TransportCostAnalysis analysis) {
    // Weight: Cost 40%, Time 30%, Comfort 15%, Reliability 15%
    final costScore = math.max(0, 100 - (analysis.averageCost / 10));
    final timeScore = analysis.speedScore;
    final comfortScore = analysis.comfortScore;
    final reliabilityScore = analysis.reliabilityScore;
    
    return (costScore * 0.4) + (timeScore * 0.3) + (comfortScore * 0.15) + (reliabilityScore * 0.15);
  }

  /// Get situational recommendations
  Map<String, String> get situationalRecommendations {
    return {
      'Budget Priority': matatuAnalysis.averageCost < uberAnalysis.averageCost ? 'Matatu' : 'Uber',
      'Time Priority': matatuAnalysis.speedScore > uberAnalysis.speedScore ? 'Matatu' : 'Uber',
      'Comfort Priority': matatuAnalysis.comfortScore > uberAnalysis.comfortScore ? 'Matatu' : 'Uber',
      'Reliability Priority': matatuAnalysis.reliabilityScore > uberAnalysis.reliabilityScore ? 'Matatu' : 'Uber',
      'Rainy Weather': 'Uber', // Always recommend Uber for bad weather
      'Peak Hours': matatuAnalysis.reliabilityScore > 70 ? 'Matatu' : 'Uber',
      'Late Night': 'Uber', // Safety priority
    };
  }
}

/// Fuel efficiency tracking for personal vehicles
class FuelEfficiencyAnalysis {
  final String analysisId;
  final String vehicleId;
  final String vehicleModel;
  final double totalFuelCost;
  final double totalDistanceKm;
  final double fuelEfficiencyKmPerLiter;
  final double costPerKm;
  final double averageFuelPrice;
  final List<FuelTransaction> fuelTransactions;
  final DateTime analysisStartDate;
  final DateTime analysisEndDate;
  final Map<String, double> stationComparison; // Station name -> avg price

  FuelEfficiencyAnalysis({
    required this.analysisId,
    required this.vehicleId,
    required this.vehicleModel,
    required this.totalFuelCost,
    required this.totalDistanceKm,
    required this.fuelEfficiencyKmPerLiter,
    required this.costPerKm,
    required this.averageFuelPrice,
    required this.fuelTransactions,
    required this.analysisStartDate,
    required this.analysisEndDate,
    required this.stationComparison,
  });

  /// Get fuel efficiency rating
  String get efficiencyRating {
    if (fuelEfficiencyKmPerLiter >= 15) return 'Excellent';
    if (fuelEfficiencyKmPerLiter >= 12) return 'Good';
    if (fuelEfficiencyKmPerLiter >= 9) return 'Average';
    if (fuelEfficiencyKmPerLiter >= 6) return 'Poor';
    return 'Very Poor';
  }

  /// Get cheapest fuel station
  String? get cheapestStation {
    if (stationComparison.isEmpty) return null;
    return stationComparison.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  /// Get most expensive fuel station
  String? get mostExpensiveStation {
    if (stationComparison.isEmpty) return null;
    return stationComparison.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Calculate potential savings by switching stations
  double get potentialMonthlySavings {
    if (stationComparison.length < 2) return 0;
    
    final cheapest = stationComparison.values.reduce(math.min);
    final mostExpensive = stationComparison.values.reduce(math.max);
    final priceDifference = mostExpensive - cheapest;
    
    // Estimate monthly fuel consumption
    final monthlyDistance = totalDistanceKm / 
        (analysisEndDate.difference(analysisStartDate).inDays / 30.44);
    final monthlyLiters = monthlyDistance / fuelEfficiencyKmPerLiter;
    
    return monthlyLiters * priceDifference;
  }
}

/// Individual fuel transaction
class FuelTransaction {
  final String transactionId;
  final DateTime date;
  final String stationName;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final double odometerReading;
  final String fuelType; // Petrol, Diesel

  FuelTransaction({
    required this.transactionId,
    required this.date,
    required this.stationName,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    required this.odometerReading,
    required this.fuelType,
  });

  factory FuelTransaction.fromMap(Map<String, dynamic> map) {
    return FuelTransaction(
      transactionId: map['transactionId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      stationName: map['stationName'] as String,
      liters: (map['liters'] as num).toDouble(),
      pricePerLiter: (map['pricePerLiter'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
      odometerReading: (map['odometerReading'] as num).toDouble(),
      fuelType: map['fuelType'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'date': Timestamp.fromDate(date),
      'stationName': stationName,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'totalCost': totalCost,
      'odometerReading': odometerReading,
      'fuelType': fuelType,
    };
  }
}

/// Transport budget recommendations
class TransportBudgetRecommendation {
  final String recommendationId;
  final String userId;
  final double currentMonthlySpending;
  final double recommendedBudget;
  final double potentialSavings;
  final List<String> optimizationStrategies;
  final Map<TransportMode, double> modeBreakdown;
  final List<RouteOptimization> routeOptimizations;
  final DateTime generatedAt;

  TransportBudgetRecommendation({
    required this.recommendationId,
    required this.userId,
    required this.currentMonthlySpending,
    required this.recommendedBudget,
    required this.potentialSavings,
    required this.optimizationStrategies,
    required this.modeBreakdown,
    required this.routeOptimizations,
    required this.generatedAt,
  });

  /// Get savings percentage
  double get savingsPercentage {
    if (currentMonthlySpending == 0) return 0;
    return (potentialSavings / currentMonthlySpending) * 100;
  }

  /// Get budget status
  String get budgetStatus {
    if (potentialSavings > currentMonthlySpending * 0.3) return 'High Savings Potential';
    if (potentialSavings > currentMonthlySpending * 0.15) return 'Moderate Savings Potential';
    if (potentialSavings > currentMonthlySpending * 0.05) return 'Low Savings Potential';
    return 'Optimized';
  }
}

/// Route-specific optimization recommendation
class RouteOptimization {
  final String routeId;
  final NairobiRoute route;
  final TransportMode currentMode;
  final TransportMode recommendedMode;
  final double currentCost;
  final double recommendedCost;
  final double monthlySavings;
  final String reason;
  final double confidence;

  RouteOptimization({
    required this.routeId,
    required this.route,
    required this.currentMode,
    required this.recommendedMode,
    required this.currentCost,
    required this.recommendedCost,
    required this.monthlySavings,
    required this.reason,
    required this.confidence,
  });

  /// Get savings percentage for this route
  double get savingsPercentage {
    if (currentCost == 0) return 0;
    return ((currentCost - recommendedCost) / currentCost) * 100;
  }
}

/// Comprehensive transport intelligence summary
class TransportIntelligenceSummary {
  final String summaryId;
  final String userId;
  final DateTime generatedAt;
  final double totalMonthlyTransportCost;
  final Map<TransportMode, double> modeBreakdown;
  final List<MatatuVsUberAnalysis> routeComparisons;
  final FuelEfficiencyAnalysis? fuelAnalysis;
  final TransportBudgetRecommendation budgetRecommendation;
  final List<String> keyInsights;
  final List<String> actionableRecommendations;
  final double transportEfficiencyScore; // 0-100

  TransportIntelligenceSummary({
    required this.summaryId,
    required this.userId,
    required this.generatedAt,
    required this.totalMonthlyTransportCost,
    required this.modeBreakdown,
    required this.routeComparisons,
    this.fuelAnalysis,
    required this.budgetRecommendation,
    required this.keyInsights,
    required this.actionableRecommendations,
    required this.transportEfficiencyScore,
  });

  /// Get most used transport mode
  TransportMode get primaryTransportMode {
    if (modeBreakdown.isEmpty) return TransportMode.matatu;
    return modeBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get total potential monthly savings
  double get totalPotentialSavings {
    return budgetRecommendation.potentialSavings +
           (fuelAnalysis?.potentialMonthlySavings ?? 0);
  }

  /// Get transport efficiency status
  String get efficiencyStatus {
    if (transportEfficiencyScore >= 80) return 'Excellent';
    if (transportEfficiencyScore >= 60) return 'Good';
    if (transportEfficiencyScore >= 40) return 'Fair';
    if (transportEfficiencyScore >= 20) return 'Poor';
    return 'Needs Improvement';
  }
}

