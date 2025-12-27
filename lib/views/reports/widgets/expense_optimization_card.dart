import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/transaction_model.dart';
import '../../../models/time_period_model.dart';
import '../../../utils/currency_extensions.dart';
import 'report_card.dart';

class ExpenseOptimizationCard extends StatefulWidget {
  final TimePeriod selectedPeriod;
  final List<Transaction> allTransactions;

  const ExpenseOptimizationCard({
    super.key,
    required this.selectedPeriod,
    required this.allTransactions,
  });

  @override
  State<ExpenseOptimizationCard> createState() => _ExpenseOptimizationCardState();
}

class _ExpenseOptimizationCardState extends State<ExpenseOptimizationCard>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  
  List<OptimizationOpportunity> _opportunities = [];
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    
    _analyzeOptimizations();
  }

  @override
  void didUpdateWidget(ExpenseOptimizationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod ||
        oldWidget.allTransactions.length != widget.allTransactions.length) {
      _analyzeOptimizations();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  void _analyzeOptimizations() async {
    setState(() {
      _isAnalyzing = true;
    });

    _scanController.reset();
    _scanController.forward();

    // Simulate analysis time for better UX
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    final periodTransactions = widget.allTransactions
        .where((tx) => widget.selectedPeriod.containsDate(tx.date))
        .toList();

    final opportunities = _generateOptimizations(periodTransactions);

    if (mounted) {
      setState(() {
        _opportunities = opportunities;
        _isAnalyzing = false;
      });
    }
  }

  List<OptimizationOpportunity> _generateOptimizations(List<Transaction> transactions) {
    final opportunities = <OptimizationOpportunity>[];

    // 1. Grocery Store Optimization
    opportunities.addAll(_analyzeGroceryOptimization(transactions));
    
    // 2. Subscription Optimization
    opportunities.addAll(_analyzeSubscriptionOptimization(transactions));
    
    // 3. Transport Optimization (Kenya-specific)
    opportunities.addAll(_analyzeTransportOptimization(transactions));
    
    // 4. Bulk Purchase Recommendations
    opportunities.addAll(_analyzeBulkPurchaseOpportunities(transactions));
    
    // 5. Utility Optimization
    opportunities.addAll(_analyzeUtilityOptimization(transactions));
    
    // 6. Dining Optimization
    opportunities.addAll(_analyzeDiningOptimization(transactions));

    // Sort by potential savings (highest first)
    opportunities.sort((a, b) => b.potentialSavings.compareTo(a.potentialSavings));
    
    // Return top 5 opportunities
    return opportunities.take(5).toList();
  }

  List<OptimizationOpportunity> _analyzeGroceryOptimization(List<Transaction> transactions) {
    final groceryStores = <String, List<Transaction>>{};
    
    // Group transactions by grocery store
    for (final tx in transactions) {
      final title = tx.title.toLowerCase();
      if (title.contains('nakumatt') || title.contains('grocery') || 
          title.contains('supermarket') || tx.category.toLowerCase().contains('grocery')) {
        
        String store = 'Unknown Store';
        if (title.contains('nakumatt')) {
          store = 'Nakumatt';
        } else if (title.contains('tuskys')) {
          store = 'Tuskys';
        } else if (title.contains('carrefour')) {
          store = 'Carrefour';
        } else if (title.contains('naivas')) {
          store = 'Naivas';
        } else if (title.contains('quickmart')) {
          store = 'Quickmart';
        }
        
        groceryStores.putIfAbsent(store, () => []).add(tx);
      }
    }

    final opportunities = <OptimizationOpportunity>[];
    
    if (groceryStores.length >= 2) {
      final storeAverages = groceryStores.map((store, txs) {
        final avgAmount = txs.fold(0.0, (sum, tx) => sum + tx.amount.abs()) / txs.length;
        return MapEntry(store, avgAmount);
      });
      
      final cheapestStore = storeAverages.entries.reduce((a, b) => a.value < b.value ? a : b);
      final expensiveStores = storeAverages.entries.where((e) => e.key != cheapestStore.key).toList();
      
      for (final expensiveStore in expensiveStores) {
        final potentialSavings = (expensiveStore.value - cheapestStore.value) * 
            groceryStores[expensiveStore.key]!.length;
        
        if (potentialSavings > 100) {
          opportunities.add(OptimizationOpportunity(
            title: 'Switch to ${cheapestStore.key} for Groceries',
            description: 'Average ${cheapestStore.value.toKenyaCurrency()} vs ${expensiveStore.value.toKenyaCurrency()} at ${expensiveStore.key}',
            potentialSavings: potentialSavings,
            category: 'Grocery Shopping',
            icon: Icons.shopping_cart,
            color: Colors.green,
            actionType: OptimizationActionType.storeSwitch,
            confidence: 85,
          ));
        }
      }
    }

    return opportunities;
  }

  List<OptimizationOpportunity> _analyzeSubscriptionOptimization(List<Transaction> transactions) {
    final subscriptions = transactions.where((tx) => 
        tx.title.toLowerCase().contains('subscription') ||
        tx.title.toLowerCase().contains('netflix') ||
        tx.title.toLowerCase().contains('spotify') ||
        tx.title.toLowerCase().contains('showmax') ||
        tx.title.toLowerCase().contains('dstv') ||
        tx.title.toLowerCase().contains('monthly')).toList();

    final opportunities = <OptimizationOpportunity>[];
    
    // Group by subscription type
    final subscriptionGroups = <String, List<Transaction>>{};
    for (final tx in subscriptions) {
      final title = tx.title.toLowerCase();
      String type = 'Other';
      
      if (title.contains('netflix')) {
        type = 'Netflix';
      } else if (title.contains('spotify')) {
        type = 'Spotify';
      } else if (title.contains('showmax')) {
        type = 'Showmax';
      } else if (title.contains('dstv')) {
        type = 'DSTV';
      }
      
      subscriptionGroups.putIfAbsent(type, () => []).add(tx);
    }

    // Check for duplicate streaming services
    final streamingServices = subscriptionGroups.entries
        .where((e) => ['Netflix', 'Showmax', 'DSTV'].contains(e.key))
        .toList();
    
    if (streamingServices.length > 1) {
      final totalStreamingCost = streamingServices
          .fold(0.0, (sum, entry) => sum + entry.value.fold(0.0, (s, tx) => s + tx.amount.abs()));
      
      opportunities.add(OptimizationOpportunity(
        title: 'Consolidate Streaming Services',
        description: 'You have ${streamingServices.length} streaming services costing ${totalStreamingCost.toKenyaCurrency()}/month',
        potentialSavings: totalStreamingCost * 0.4, // 40% savings by keeping 1-2 services
        category: 'Subscriptions',
        icon: Icons.tv,
        color: Colors.purple,
        actionType: OptimizationActionType.subscriptionCancel,
        confidence: 90,
      ));
    }

    // Check for unused subscriptions (no transactions in last 2 months)
    final now = DateTime.now();
    final twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);
    
    for (final entry in subscriptionGroups.entries) {
      final recentUsage = entry.value.where((tx) => tx.date.isAfter(twoMonthsAgo)).length;
      if (recentUsage == 0 && entry.value.isNotEmpty) {
        final monthlyCost = entry.value.last.amount.abs();
        opportunities.add(OptimizationOpportunity(
          title: 'Cancel Unused ${entry.key} Subscription',
          description: 'No usage detected in last 2 months',
          potentialSavings: monthlyCost * 12, // Annual savings
          category: 'Subscriptions',
          icon: Icons.cancel,
          color: Colors.red,
          actionType: OptimizationActionType.subscriptionCancel,
          confidence: 95,
        ));
      }
    }

    return opportunities;
  }

  List<OptimizationOpportunity> _analyzeTransportOptimization(List<Transaction> transactions) {
    final opportunities = <OptimizationOpportunity>[];
    
    final uberTransactions = transactions.where((tx) => 
        tx.title.toLowerCase().contains('uber') ||
        tx.title.toLowerCase().contains('bolt') ||
        tx.title.toLowerCase().contains('taxi')).toList();
    
    // Note: matatu transactions analyzed for context but not directly used in current optimization

    if (uberTransactions.isNotEmpty) {
      final avgUberCost = uberTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs()) / uberTransactions.length;
      // Total uber cost calculated for potential future analysis
      
      // Estimate matatu cost (typically 30-50% of Uber cost in Nairobi)
      final estimatedMatatuCost = avgUberCost * 0.4;
      final potentialSavings = (avgUberCost - estimatedMatatuCost) * uberTransactions.length;
      
      if (potentialSavings > 500) {
        opportunities.add(OptimizationOpportunity(
          title: 'Use Matatu for Regular Routes',
          description: 'Save ~${potentialSavings.toKenyaCurrency()} by using matatu instead of ride-hailing',
          potentialSavings: potentialSavings,
          category: 'Transport',
          icon: Icons.directions_bus,
          color: Colors.blue,
          actionType: OptimizationActionType.behaviorChange,
          confidence: 75,
        ));
      }
    }

    // Check for expensive fuel purchases
    final fuelTransactions = transactions.where((tx) => 
        tx.title.toLowerCase().contains('fuel') ||
        tx.title.toLowerCase().contains('petrol') ||
        tx.title.toLowerCase().contains('shell') ||
        tx.title.toLowerCase().contains('total')).toList();
    
    if (fuelTransactions.isNotEmpty) {
      final avgFuelCost = fuelTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs()) / fuelTransactions.length;
      
      if (avgFuelCost > 3000) {
        opportunities.add(OptimizationOpportunity(
          title: 'Consider Fuel-Efficient Alternatives',
          description: 'High fuel costs (${avgFuelCost.toKenyaCurrency()}/fill). Consider carpooling or public transport',
          potentialSavings: avgFuelCost * 0.3 * fuelTransactions.length,
          category: 'Transport',
          icon: Icons.local_gas_station,
          color: Colors.orange,
          actionType: OptimizationActionType.behaviorChange,
          confidence: 60,
        ));
      }
    }

    return opportunities;
  }

  List<OptimizationOpportunity> _analyzeBulkPurchaseOpportunities(List<Transaction> transactions) {
    final opportunities = <OptimizationOpportunity>[];
    
    // Analyze frequent small purchases
    final categoryFrequency = <String, List<Transaction>>{};
    
    for (final tx in transactions) {
      if (tx.amount.abs() < 500) { // Small purchases
        categoryFrequency.putIfAbsent(tx.category, () => []).add(tx);
      }
    }

    for (final entry in categoryFrequency.entries) {
      if (entry.value.length >= 5) { // 5 or more small purchases
        final totalSpent = entry.value.fold(0.0, (sum, tx) => sum + tx.amount.abs());
        final avgAmount = totalSpent / entry.value.length;
        
        // Estimate 10-15% savings through bulk purchasing
        final potentialSavings = totalSpent * 0.125;
        
        if (potentialSavings > 200) {
          opportunities.add(OptimizationOpportunity(
            title: 'Bulk Purchase ${entry.key}',
            description: '${entry.value.length} small purchases (${avgAmount.toKenyaCurrency()} avg). Consider bulk buying',
            potentialSavings: potentialSavings,
            category: entry.key,
            icon: Icons.inventory,
            color: Colors.teal,
            actionType: OptimizationActionType.bulkPurchase,
            confidence: 70,
          ));
        }
      }
    }

    return opportunities;
  }

  List<OptimizationOpportunity> _analyzeUtilityOptimization(List<Transaction> transactions) {
    final opportunities = <OptimizationOpportunity>[];
    
    final utilityTransactions = transactions.where((tx) => 
        tx.title.toLowerCase().contains('kplc') ||
        tx.title.toLowerCase().contains('electricity') ||
        tx.title.toLowerCase().contains('water') ||
        tx.category.toLowerCase().contains('utilities')).toList();

    if (utilityTransactions.isNotEmpty) {
      final avgUtilityCost = utilityTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs()) / utilityTransactions.length;
      
      // High utility costs in Kenya context
      if (avgUtilityCost > 5000) {
        opportunities.add(OptimizationOpportunity(
          title: 'Reduce Utility Consumption',
          description: 'High utility costs (${avgUtilityCost.toKenyaCurrency()}/month). Consider energy-saving measures',
          potentialSavings: avgUtilityCost * 0.2 * utilityTransactions.length,
          category: 'Utilities',
          icon: Icons.electrical_services,
          color: Colors.amber,
          actionType: OptimizationActionType.behaviorChange,
          confidence: 65,
        ));
      }
    }

    return opportunities;
  }

  List<OptimizationOpportunity> _analyzeDiningOptimization(List<Transaction> transactions) {
    final opportunities = <OptimizationOpportunity>[];
    
    final diningTransactions = transactions.where((tx) => 
        tx.category.toLowerCase().contains('dining') ||
        tx.category.toLowerCase().contains('restaurant') ||
        tx.title.toLowerCase().contains('restaurant') ||
        tx.title.toLowerCase().contains('cafe')).toList();

    if (diningTransactions.length >= 8) { // Frequent dining out
      final totalDining = diningTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
      final avgMealCost = totalDining / diningTransactions.length;
      
      // Estimate 40% savings by cooking at home
      final potentialSavings = totalDining * 0.4;
      
      if (potentialSavings > 1000) {
        opportunities.add(OptimizationOpportunity(
          title: 'Cook More Meals at Home',
          description: '${diningTransactions.length} restaurant visits (${avgMealCost.toKenyaCurrency()}/meal). Cook at home to save',
          potentialSavings: potentialSavings,
          category: 'Dining',
          icon: Icons.restaurant_menu,
          color: Colors.deepOrange,
          actionType: OptimizationActionType.behaviorChange,
          confidence: 80,
        ));
      }
    }

    return opportunities;
  }

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      title: '💡 Expense Optimization - ${widget.selectedPeriod.displayName}',
      child: _isAnalyzing ? _buildAnalyzingState() : _buildOptimizationsContent(),
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildAnalyzingState() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: _scanAnimation.value,
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.search,
                        size: 40,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing Expense Patterns',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding opportunities to save money...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _scanAnimation.value,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationsContent() {
    if (_opportunities.isEmpty) {
      return _buildNoOptimizationsState();
    }

    final totalPotentialSavings = _opportunities.fold(0.0, (sum, opp) => sum + opp.potentialSavings);

    return Column(
      children: [
        // Summary Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.1),
                Colors.orange.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.savings,
                  color: Colors.green[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Potential Savings',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      totalPotentialSavings.toKenyaCurrency(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      '${_opportunities.length} optimization opportunities found',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Opportunities List
        ..._opportunities.asMap().entries.map((entry) {
          final index = entry.key;
          final opportunity = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOptimizationTile(opportunity, index),
          );
        }),
      ],
    );
  }

  Widget _buildOptimizationTile(OptimizationOpportunity opportunity, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: opportunity.color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: opportunity.color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: opportunity.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  opportunity.icon,
                  color: opportunity.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      opportunity.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    opportunity.potentialSavings.toKenyaCurrency(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    '${opportunity.confidence}% confidence',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            opportunity.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: opportunity.color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  _getActionIcon(opportunity.actionType),
                  size: 14,
                  color: opportunity.color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getActionText(opportunity.actionType),
                    style: TextStyle(
                      fontSize: 11,
                      color: opportunity.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 100))
      .slideX(begin: 0.2, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildNoOptimizationsState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Great Job!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No major optimization opportunities found.\nYour spending looks efficient!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(OptimizationActionType actionType) {
    switch (actionType) {
      case OptimizationActionType.storeSwitch:
        return Icons.store;
      case OptimizationActionType.subscriptionCancel:
        return Icons.cancel;
      case OptimizationActionType.behaviorChange:
        return Icons.psychology;
      case OptimizationActionType.bulkPurchase:
        return Icons.shopping_basket;
    }
  }

  String _getActionText(OptimizationActionType actionType) {
    switch (actionType) {
      case OptimizationActionType.storeSwitch:
        return 'Consider switching stores for better prices';
      case OptimizationActionType.subscriptionCancel:
        return 'Review and cancel unused subscriptions';
      case OptimizationActionType.behaviorChange:
        return 'Small behavior changes can lead to big savings';
      case OptimizationActionType.bulkPurchase:
        return 'Buy in bulk to reduce per-unit costs';
    }
  }
}

class OptimizationOpportunity {
  final String title;
  final String description;
  final double potentialSavings;
  final String category;
  final IconData icon;
  final Color color;
  final OptimizationActionType actionType;
  final int confidence; // 0-100

  OptimizationOpportunity({
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.category,
    required this.icon,
    required this.color,
    required this.actionType,
    required this.confidence,
  });
}

enum OptimizationActionType {
  storeSwitch,
  subscriptionCancel,
  behaviorChange,
  bulkPurchase,
}
