import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/navigation_service.dart';

// Import local files
import '../../models/insight_model.dart';
import '../../viewmodels/insights_viewmodel.dart';
import '../../themes/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 9; // AI Insights tab selected
  late TabController _tabController;
  bool _isGeneratingInsights = false;
  final List<String> _tabLabels = ['All', 'Spending', 'Saving', 'Investing'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // No need to update _selectedIndex here as it's for drawer navigation
      });
    });
    
    // Load insights when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInsights();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    if (!mounted) return;
    
    // Safely capture context before async gap
    final viewModel = Provider.of<InsightsViewModel>(context, listen: false);
    
    try {
      await viewModel.loadInsights();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load insights: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            elevation: 6,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    }
  }

  Future<void> _generateNewInsights() async {
    // Safely capture context before async gap
    final ScaffoldMessengerState? messenger = mounted ? ScaffoldMessenger.of(context) : null;
    final InsightsViewModel viewModel = Provider.of<InsightsViewModel>(context, listen: false);
    
    // Set loading state if still mounted
    if (!mounted) return;
    setState(() {
      _isGeneratingInsights = true;
    });
    
    try {
      // Perform async operation
      await viewModel.generateInsights();
      
      // Check if we're still mounted after async gap
      if (mounted && messenger != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('New insights generated'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        );
      }
    } catch (e) {
      // Check if we're still mounted after async gap
      if (mounted && messenger != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to generate insights: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            elevation: 6,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingInsights = false;
        });
      }
    }
  }

  // Helper method to handle navigation item selection
  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    String route = NavigationService.routeForDrawerIndex(index);

    // Close drawer if open
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Navigate only if not already on target route
    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  // Get appropriate icon for each insight type
  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'Spending Pattern':
        return FontAwesomeIcons.chartLine;
      case 'Budget Alert':
        return FontAwesomeIcons.triangleExclamation;
      case 'Saving Opportunity':
        return FontAwesomeIcons.piggyBank;
      case 'Financial Health':
        return FontAwesomeIcons.heartPulse;
      case 'Debt Management':
        return FontAwesomeIcons.creditCard;
      case 'Income Optimization':
        return FontAwesomeIcons.moneyBillTrendUp;
      case 'Goal Progress':
        return FontAwesomeIcons.bullseye;
      case 'Expense Anomaly':
        return FontAwesomeIcons.magnifyingGlassDollar;
      case 'Savings':
        return FontAwesomeIcons.piggyBank;
      case 'Spending Alert':
        return FontAwesomeIcons.triangleExclamation;
      case 'Budget':
        return FontAwesomeIcons.chartPie;
      case 'Investment':
        return FontAwesomeIcons.chartLine;
      case 'Income':
        return FontAwesomeIcons.moneyBillTrendUp;
      case 'Tax':
        return FontAwesomeIcons.fileInvoiceDollar;
      case 'Goal':
        return FontAwesomeIcons.bullseye;
      default:
        return FontAwesomeIcons.lightbulb;
    }
  }

  // Get appropriate color for each insight type
  Color _getInsightColor(String type) {
    switch (type) {
      case 'Spending Pattern':
        return Colors.blue;
      case 'Budget Alert':
        return Colors.orange;
      case 'Saving Opportunity':
        return Colors.green;
      case 'Financial Health':
        return Colors.purple;
      case 'Debt Management':
        return Colors.red;
      case 'Income Optimization':
        return Colors.teal;
      case 'Goal Progress':
        return Colors.amber;
      case 'Expense Anomaly':
        return Colors.deepOrange;
      case 'Savings':
        return Colors.green.shade700;
      case 'Spending Alert':
        return Colors.red.shade700;
      case 'Budget':
        return Colors.blue.shade700;
      case 'Investment':
        return Colors.purple.shade700;
      case 'Income':
        return Colors.teal.shade700;
      case 'Tax':
        return Colors.amber.shade800;
      case 'Goal':
        return Colors.indigo.shade700;
      default:
        return AppTheme.primaryColor;
    }
  }

  // Show insight details in a dialog
  Future<void> _showInsightDetails(Insight insight) async {
    // Cache context reference to avoid unsafe BuildContext usage 
    final currentContext = context;
    if (!mounted) return;
    
    final Color iconColor = _getInsightColor(insight.type);
    final IconData iconData = _getInsightIcon(insight.type);
    
    await showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.type,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    insight.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Recommendation section - using data from insight if available
                  if (insight.data != null && insight.data!['recommendation'] != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recommendation:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            insight.data!['recommendation'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Date at the bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Theme.of(dialogContext).colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat.yMMMd().format(insight.date),
                        style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                          color: Theme.of(dialogContext).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Action to implement the recommendation
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(
                  content: Text('Recommendation applied'),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Apply'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // Modern insight card with animations and gradient background
  Widget _buildInsightCard(Insight insight) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: () => _showInsightDetails(insight),
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                _getInsightColor(insight.type).withValues(alpha: 0.15), // Subtle background gradient
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getInsightColor(insight.type).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getInsightIcon(insight.type),
                        color: _getInsightColor(insight.type),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        insight.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  insight.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5, // Increase line height for better readability
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat.yMMMd().format(insight.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ) // Added missing parenthesis to close Card widget
      .animate()
        .fadeIn(duration: const Duration(milliseconds: 500));
  }

  // Helper function to build insights list
  Widget _buildInsightsList(List<Insight> insights) {
    if (insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No insights available yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate new insights to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateNewInsights,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Insights'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final insight = insights[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildInsightCard(insight),
        );
      },
    );
  }

  // Filter insights based on tab selection
  List<Insight> _getFilteredInsights(List<Insight> allInsights, int tabIndex) {
    if (tabIndex == 0) return allInsights; // All insights
    
    // Filter based on tab index
    switch (tabIndex) {
      case 1: // Spending
        return allInsights.where((insight) => 
          insight.type.contains('Spending') || 
          insight.type.contains('Budget') || 
          insight.type.contains('Expense')
        ).toList();
      case 2: // Saving
        return allInsights.where((insight) => 
          insight.type.contains('Saving') || 
          insight.type.contains('Savings')
        ).toList();
      case 3: // Investing
        return allInsights.where((insight) => 
          insight.type.contains('Investment') || 
          insight.type.contains('Goal')
        ).toList();
      default:
        return allInsights;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Generate New Insights',
            onPressed: _isGeneratingInsights 
              ? null 
              : _generateNewInsights,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: Consumer<InsightsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading insights...'),
                ],
              ),
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: List.generate(_tabLabels.length, (index) {
              return _buildInsightsList(_getFilteredInsights(viewModel.insights, index));
            }),
          );
        },
      ),
      floatingActionButton: _isGeneratingInsights
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: AppTheme.primaryColor,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : FloatingActionButton(
              onPressed: _generateNewInsights,
              tooltip: 'Generate New Insights',
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.auto_awesome),
            ),
    );
  }
}