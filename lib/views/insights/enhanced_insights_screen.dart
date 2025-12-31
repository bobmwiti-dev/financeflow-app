import 'package:flutter/material.dart';
import '../../utils/currency_extensions.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import local files
import '../../models/insight_model.dart';
import '../../viewmodels/insights_viewmodel.dart';
import '../../viewmodels/bill_viewmodel.dart';
import '../../models/bill_model.dart' as bill_model;
import '../../widgets/app_navigation_drawer.dart';
import '../../widgets/analytics/interactive_spending_chart.dart';
import '../../widgets/analytics/actionable_insight_card.dart';

class EnhancedInsightsScreen extends StatefulWidget {
  const EnhancedInsightsScreen({super.key});

  @override
  State<EnhancedInsightsScreen> createState() => _EnhancedInsightsScreenState();
}

class _EnhancedInsightsScreenState extends State<EnhancedInsightsScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 9; // AI Insights tab selected
  late TabController _tabController;
  bool _isGeneratingInsights = false;
  final List<String> _tabLabels = ['Dashboard', 'All Insights', 'Spending', 'Saving', 'Investing'];
  String _searchQuery = '';
  bool _showSearch = false;

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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
    setState(() {
      _selectedIndex = index;
    });
  }

  // Get appropriate icon for each insight type
  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'Spending Pattern':
        return Icons.trending_up;
      case 'Budget Alert':
        return Icons.warning_amber;
      case 'Saving Opportunity':
        return Icons.savings;
      case 'Financial Health':
        return Icons.favorite;
      case 'Income Trend':
        return Icons.account_balance_wallet;
      case 'Goal Progress':
        return Icons.flag;
      case 'Tax Insight':
        return Icons.receipt_long;
      case 'Investment Opportunity':
        return Icons.auto_graph;
      case 'Credit Score':
        return Icons.credit_score;
      case 'Debt Management':
        return Icons.money_off;
      default:
        return FontAwesomeIcons.lightbulb;
    }
  }

  // Get appropriate color for each insight type
  Color _getInsightColor(String type) {
    switch (type) {
      case 'Spending Pattern':
        return Colors.blue.shade700;
      case 'Budget Alert':
        return Colors.orange.shade700;
      case 'Saving Opportunity':
        return Colors.green.shade700;
      case 'Financial Health':
        return Colors.purple.shade700;
      case 'Income Trend':
        return Colors.teal.shade700;
      case 'Goal Progress':
        return Colors.indigo.shade700;
      case 'Tax Insight':
        return Colors.brown.shade700;
      case 'Investment Opportunity':
        return Colors.deepPurple.shade700;
      case 'Credit Score':
        return Colors.lightBlue.shade700;
      case 'Debt Management':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  // Build dashboard tab with interactive charts
  Widget _buildDashboardTab(List<Insight> insights) {
    // Extract spending pattern insights
    final spendingInsights = insights
        .where((insight) => insight.type == 'Spending Pattern')
        .map((insight) => SpendingPatternInsight.fromInsight(insight))
        .toList();
        
    // We'll use these variables in future implementation phases

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Text(
            'Financial Insights Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalized insights to help you improve your financial health',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 24),

          // Spending patterns chart
          if (spendingInsights.isNotEmpty)
            InteractiveSpendingChart(
              insights: spendingInsights,
              title: 'Spending Breakdown',
              onInsightTap: (insight) {
                _showInsightDetails(insight);
              },
            ),

          const SizedBox(height: 24),

          // Top actionable insights section
          Text(
            'Top Actionable Insights',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Show actionable insights cards
          ...insights
              .where((insight) => 
                  insight.type == 'Budget Alert' || 
                  insight.type == 'Saving Opportunity' ||
                  insight.type == 'Financial Health' ||
                  insight.type == 'Expense Anomaly')
              .take(3)
              .map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ActionableInsightCard(
                      insight: insight,
                      onTakeAction: () {
                        // Navigate to relevant screen based on insight type
                        _takeActionOnInsight(insight);
                      },
                      onDismiss: () {
                        // Mark insight as dismissed in viewmodel
                        _dismissInsight(insight);
                      },
                    ),
                  )),

          // Show more insights button
          if (insights.length > 3)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Switch to All Insights tab
                  _tabController.animateTo(1);
                },
                icon: const Icon(Icons.insights),
                label: const Text('View All Insights'),
              ),
            ),
        ],
      ),
    );
  }

  // Handle taking action on an insight
  Future<void> _takeActionOnInsight(Insight insight) async {
    final messenger = ScaffoldMessenger.of(context);

    // Special handling for subscription detection insights generated by
    // InsightsService._generateSubscriptionInsights. These carry a 'payee'
    // and 'amount' field in their data map.
    final data = insight.data;
    final payeeRaw = data != null ? data['payee'] : null;
    final amountRaw = data != null ? data['amount'] : null;

    if (payeeRaw != null && amountRaw != null) {
      final billViewModel = Provider.of<BillViewModel>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Sign in to track subscriptions as upcoming bills.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final payee = payeeRaw.toString();

      double? amount;
      if (amountRaw is num) {
        amount = amountRaw.toDouble();
      } else {
        amount = double.tryParse(amountRaw.toString());
      }

      if (amount == null || amount <= 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not determine subscription amount from insight.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Basic de-duplication: if a bill with similar name and amount already
      // exists, do not create another.
      final existing = billViewModel.bills.where((b) {
        final sameName = b.name.toLowerCase() == payee.toLowerCase();
        final closeAmount = (b.amount - amount!).abs() / amount < 0.1;
        return sameName && closeAmount;
      }).toList();

      if (existing.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('You are already tracking $payee as a bill.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Estimate next due date roughly one month after the last observed
      // payment (insight.date) so that it appears in upcoming bills and
      // the cash flow forecast.
      final lastPaymentDate = insight.date;
      final nextDueDate = DateTime(
        lastPaymentDate.year,
        lastPaymentDate.month + 1,
        lastPaymentDate.day,
      );

      final bill = bill_model.Bill(
        name: payee,
        amount: amount,
        dueDate: nextDueDate,
        isRecurring: true,
        frequency: 'Monthly',
        category: 'Subscription',
        autoPay: false,
      );

      final success = await billViewModel.addBill(user.uid, bill);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'We\'ll track $payee as a monthly subscription bill.'
                : 'Failed to create a bill for $payee.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? null : Colors.red,
        ),
      );

      return;
    }

    // Generic fallback for other insight types: simple acknowledgement.
    messenger.showSnackBar(
      SnackBar(
        content: Text('Taking action on: ${insight.title}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Handle dismissing an insight
  void _dismissInsight(Insight insight) {
    // This would mark the insight as dismissed in the viewmodel
    // Provider.of<InsightsViewModel>(context, listen: false).dismissInsight(insight);
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dismissed: ${insight.title}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInsightDetails(Insight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and type
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getInsightColor(insight.type).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getInsightColor(insight.type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getInsightIcon(insight.type),
                        color: _getInsightColor(insight.type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.type,
                            style: TextStyle(
                              color: _getInsightColor(insight.type),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
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
                    Text(
                      insight.description,
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Different details based on insight type
                    if (insight is SpendingPatternInsight)
                      _buildSpendingPatternDetails(insight),
                    if (insight is BudgetAlertInsight)
                      _buildBudgetAlertDetails(insight),
                    if (insight is SavingOpportunityInsight)
                      _buildSavingOpportunityDetails(insight),
                    if (insight is FinancialHealthInsight)
                      _buildFinancialHealthDetails(insight),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              _takeActionOnInsight(insight);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getInsightColor(insight.type),
              foregroundColor: Colors.white,
            ),
            child: const Text('Take Action'),
          ),
        ],
      ),
    );
  }

  // Build details widgets for different insight types
  Widget _buildSpendingPatternDetails(SpendingPatternInsight insight) {
    final isIncrease = insight.percentageChange > 0;
    // Using toKenyaDualCurrency() for Kenya market insights
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Category', insight.category),
        _buildDetailRow('Previous Amount', insight.previousAmount.toKenyaDualCurrency()),
        _buildDetailRow('Current Amount', insight.currentAmount.toKenyaDualCurrency()),
        _buildDetailRow(
          'Change', 
          '${insight.percentageChange >= 0 ? '+' : ''}${insight.percentageChange.toStringAsFixed(1)}%',
          valueColor: isIncrease ? Colors.red : Colors.green,
        ),
        _buildDetailRow('Time Frame', insight.timeFrame),
      ],
    );
  }

  Widget _buildBudgetAlertDetails(BudgetAlertInsight insight) {
    // Using toKenyaDualCurrency() for Kenya market insights
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Category', insight.category),
        _buildDetailRow('Budget Amount', insight.budgetAmount.toKenyaDualCurrency()),
        _buildDetailRow('Spent Amount', insight.spentAmount.toKenyaDualCurrency()),
        _buildDetailRow(
          'Usage', 
          '${(insight.percentageUsed * 100).toStringAsFixed(0)}%',
          valueColor: insight.percentageUsed > 0.9 ? Colors.red : 
                     insight.percentageUsed > 0.75 ? Colors.orange : 
                     Colors.green,
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: insight.percentageUsed,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            insight.percentageUsed > 0.9 ? Colors.red : 
            insight.percentageUsed > 0.75 ? Colors.orange : 
            Colors.green,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildSavingOpportunityDetails(SavingOpportunityInsight insight) {
    // Using toKenyaDualCurrency() for Kenya market insights
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Category', insight.category),
        _buildDetailRow(
          'Potential Savings', 
          insight.potentialSavings.toKenyaDualCurrency(),
          valueColor: Colors.green,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.suggestion,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialHealthDetails(FinancialHealthInsight insight) {
    Color healthColor;
    String healthLabel;
    
    switch (insight.overallHealth) {
      case 'good':
        healthColor = Colors.green;
        healthLabel = 'Good';
        break;
      case 'moderate':
        healthColor = Colors.orange;
        healthLabel = 'Moderate';
        break;
      default:
        healthColor = Colors.red;
        healthLabel = 'Needs Attention';
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: healthColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            healthLabel,
            style: TextStyle(color: healthColor, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          'Savings Rate', 
          '${(insight.savingsRate * 100).toStringAsFixed(1)}%',
          valueColor: insight.savingsRate > 0.15 ? Colors.green : Colors.orange,
        ),
        _buildDetailRow(
          'Debt-to-Income', 
          insight.debtToIncomeRatio.toStringAsFixed(2),
          valueColor: insight.debtToIncomeRatio < 0.36 ? Colors.green : Colors.red,
        ),
        _buildDetailRow(
          'Emergency Fund', 
          '${insight.emergencyFundMonths.toStringAsFixed(1)} months',
          valueColor: insight.emergencyFundMonths > 3 ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 16),
        const Text(
          'Recommendations:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...insight.recommendations.map((recommendation) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(recommendation),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // Filter insights based on tab selection
  List<Insight> _getFilteredInsights(List<Insight> allInsights, int tabIndex) {
    if (tabIndex == 1) return allInsights; // All insights
    
    // Filter based on tab index
    switch (tabIndex) {
      case 2: // Spending
        return allInsights.where((insight) => 
          insight.type.contains('Spending') || 
          insight.type.contains('Budget') || 
          insight.type.contains('Expense')
        ).toList();
      case 3: // Saving
        return allInsights.where((insight) => 
          insight.type.contains('Saving') || 
          insight.type.contains('Savings')
        ).toList();
      case 4: // Investing
        return allInsights.where((insight) => 
          insight.type.contains('Investment') || 
          insight.type.contains('Goal')
        ).toList();
      default: // Dashboard (already handled)
        return allInsights;
    }
  }

  // Build insights list for non-dashboard tabs
  Widget _buildInsightsList(List<Insight> insights) {
    if (insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.lightbulb,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No insights available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate new insights to see personalized financial advice',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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
          child: ActionableInsightCard(
            insight: insight,
            onTakeAction: () => _takeActionOnInsight(insight),
            onDismiss: () => _dismissInsight(insight),
          ),
        ).animate().fadeIn(duration: const Duration(milliseconds: 300), delay: Duration(milliseconds: 50 * index));
      },
    );
  }

  // Build app bar with search functionality
  AppBar _buildAppBar() {
    return AppBar(
      title: _showSearch
          ? TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search insights...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            )
          : const Text('Financial Insights'),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close : Icons.search),
          tooltip: _showSearch ? 'Cancel Search' : 'Search Insights',
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Generate New Insights',
          onPressed: _isGeneratingInsights ? null : _generateNewInsights,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
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
          
          // Filter insights based on search query if needed
          final filteredInsights = _searchQuery.isEmpty
              ? viewModel.insights
              : viewModel.insights.where((insight) =>
                  insight.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  insight.description.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Dashboard Tab
              _buildDashboardTab(filteredInsights),
              // Other tabs with filtered insights
              ...List.generate(_tabLabels.length - 1, (index) {
                return _buildInsightsList(
                  _getFilteredInsights(filteredInsights, index + 1),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<InsightsViewModel>(
        builder: (context, viewModel, child) {
          if (_isGeneratingInsights) {
            return FloatingActionButton(
              onPressed: null,
              backgroundColor: Theme.of(context).primaryColor,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }
          return FloatingActionButton(
            onPressed: _generateNewInsights,
            tooltip: 'Generate New Insights',
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.auto_awesome),
          );
        },
      ),
    );
  }
}

