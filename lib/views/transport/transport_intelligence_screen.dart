import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/transport_intelligence_service.dart';
import '../../models/transport_intelligence_model.dart';
import '../../widgets/animated_button.dart';

class TransportIntelligenceScreen extends StatefulWidget {
  const TransportIntelligenceScreen({super.key});

  @override
  State<TransportIntelligenceScreen> createState() => _TransportIntelligenceScreenState();
}

class _TransportIntelligenceScreenState extends State<TransportIntelligenceScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger('TransportIntelligenceScreen');
  
  bool _isLoading = true;
  TransportIntelligenceSummary? _transportSummary;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTransportIntelligence();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransportIntelligence() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await TransportIntelligenceService.generateTransportAnalysis();
      setState(() {
        _transportSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading transport intelligence: $e');
      setState(() {
        _errorMessage = 'Failed to load transport analysis: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Intelligence'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransportIntelligence,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _transportSummary == null
                  ? _buildNoDataView()
                  : _buildTransportView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text('Analyzing your transport patterns...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error Loading Transport Analysis',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AnimatedButton(
            onPressed: _loadTransportIntelligence,
            text: 'Retry',
            color: Colors.blue,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Transport Data Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some transport transactions to see intelligent insights',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AnimatedButton(
            onPressed: () => Navigator.pushNamed(context, '/add_transaction'),
            text: 'Add Transport Expense',
            color: Colors.blue,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildTransportView() {
    return Column(
      children: [
        // Key Insights Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Transport Intelligence',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Efficiency Score: ${_transportSummary!.transportEfficiencyScore.toStringAsFixed(0)}% - ${_transportSummary!.efficiencyStatus}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ..._transportSummary!.keyInsights.take(3).map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        
        // Tab Bar
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue.shade600,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Routes', icon: Icon(Icons.route)),
            Tab(text: 'Fuel', icon: Icon(Icons.local_gas_station)),
            Tab(text: 'Budget', icon: Icon(Icons.account_balance_wallet)),
          ],
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildRoutesTab(),
              _buildFuelTab(),
              _buildBudgetTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final formatter = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Cost Overview
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Monthly Cost',
                  formatter.format(_transportSummary!.totalMonthlyTransportCost),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Potential Savings',
                  formatter.format(_transportSummary!.totalPotentialSavings),
                  Icons.savings,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Primary Mode',
                  _transportSummary!.primaryTransportMode.toString().split('.').last.toUpperCase(),
                  Icons.directions_bus,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Efficiency',
                  '${_transportSummary!.transportEfficiencyScore.toStringAsFixed(0)}%',
                  Icons.eco,
                  _getEfficiencyColor(_transportSummary!.transportEfficiencyScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Transport Mode Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transport Mode Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _transportSummary!.modeBreakdown.isNotEmpty
                        ? _buildModeBreakdownChart()
                        : const Center(child: Text('No transport mode data available')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Actionable Recommendations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Recommendations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._transportSummary!.actionableRecommendations.map((rec) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Comparisons',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_transportSummary!.routeComparisons.isEmpty)
            const Center(
              child: Text('No route comparison data available'),
            )
          else
            ..._transportSummary!.routeComparisons.map((comparison) => 
              _buildRouteComparisonCard(comparison)
            ),
        ],
      ),
    );
  }

  Widget _buildFuelTab() {
    final fuelAnalysis = _transportSummary!.fuelAnalysis;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fuel Efficiency Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (fuelAnalysis == null)
            const Center(
              child: Text('No fuel data available'),
            )
          else
            _buildFuelAnalysisCard(fuelAnalysis),
        ],
      ),
    );
  }

  Widget _buildBudgetTab() {
    final budget = _transportSummary!.budgetRecommendation;
    final formatter = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Recommendations',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Budget Overview
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Current Spending',
                  formatter.format(budget.currentMonthlySpending),
                  Icons.trending_up,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Recommended Budget',
                  formatter.format(budget.recommendedBudget),
                  Icons.track_changes,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Savings Potential
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Savings Potential',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.savings, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        '${formatter.format(budget.potentialSavings)} (${budget.savingsPercentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    budget.budgetStatus,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Optimization Strategies
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optimization Strategies',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...budget.optimizationStrategies.map((strategy) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(strategy)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildRouteComparisonCard(MatatuVsUberAnalysis comparison) {
    final formatter = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comparison.route.routeName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${comparison.route.distanceKm}km • ${comparison.route.estimatedTimeMinutes} mins',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.directions_bus, color: Colors.orange.shade600),
                      const SizedBox(height: 4),
                      const Text('Matatu', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(formatter.format(comparison.matatuAnalysis.averageCost)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${comparison.costSavingsPercentage.toStringAsFixed(0)}% cheaper',
                      style: TextStyle(
                        color: comparison.costSavingsPercentage > 0 ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.local_taxi, color: Colors.blue.shade600),
                      const SizedBox(height: 4),
                      const Text('Uber', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(formatter.format(comparison.uberAnalysis.averageCost)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      comparison.recommendation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildFuelAnalysisCard(FuelEfficiencyAnalysis fuelAnalysis) {
    final formatter = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Efficiency',
                '${fuelAnalysis.fuelEfficiencyKmPerLiter.toStringAsFixed(1)} km/L',
                Icons.eco,
                _getEfficiencyColor(fuelAnalysis.fuelEfficiencyKmPerLiter * 5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Cost per KM',
                formatter.format(fuelAnalysis.costPerKm),
                Icons.attach_money,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fuel Station Comparison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (fuelAnalysis.cheapestStation != null)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.green.shade600, size: 16),
                      const SizedBox(width: 8),
                      Text('Cheapest: ${fuelAnalysis.cheapestStation}'),
                    ],
                  ),
                const SizedBox(height: 8),
                if (fuelAnalysis.potentialMonthlySavings > 0)
                  Row(
                    children: [
                      Icon(Icons.savings, color: Colors.green.shade600, size: 16),
                      const SizedBox(width: 8),
                      Text('Potential savings: ${formatter.format(fuelAnalysis.potentialMonthlySavings)}/month'),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeBreakdownChart() {
    final data = _transportSummary!.modeBreakdown.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: '${((entry.value / _transportSummary!.totalMonthlyTransportCost) * 100).toStringAsFixed(0)}%',
        color: _getModeColor(entry.key),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: data,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Color _getEfficiencyColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getModeColor(TransportMode mode) {
    switch (mode) {
      case TransportMode.matatu: return Colors.orange;
      case TransportMode.uber: return Colors.blue;
      case TransportMode.bolt: return Colors.green;
      case TransportMode.personalCar: return Colors.purple;
      case TransportMode.boda: return Colors.red;
      default: return Colors.grey;
    }
  }
}
