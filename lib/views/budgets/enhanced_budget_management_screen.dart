import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/budget_model.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../widgets/budget/smart_budget_recommendations.dart';
import '../../widgets/budget/premium_budget_pie_chart.dart';
import '../../widgets/budget/premium_budget_timeline.dart';
import '../../models/transaction_model.dart' as app_models;

class EnhancedBudgetManagementScreen extends StatefulWidget {
  const EnhancedBudgetManagementScreen({super.key});

  @override
  State<EnhancedBudgetManagementScreen> createState() => _EnhancedBudgetManagementScreenState();
}

class _EnhancedBudgetManagementScreenState extends State<EnhancedBudgetManagementScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 3; // Budget tab index
  late TabController _tabController;
  final List<String> _tabLabels = ['Dashboard', 'Timeline', 'Recommendations'];
  
  // Enhanced filtering and sorting
  String _searchQuery = '';
  String _selectedPeriod = 'monthly';
  String _selectedCategory = 'all';
  String _sortBy = 'category'; // category, amount, spent, remaining
  bool _sortAscending = true;
  bool _isLoading = false;
  late DateTime _currentSelectedMonth;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    
    // Initialize current selected month
    _currentSelectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    
    // Load budgets when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudgets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadBudgets() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Safely capture context before async gap
      final viewModel = Provider.of<BudgetViewModel>(context, listen: false);
      // Load budgets for the current month (BudgetViewModel handles the selected month)
      await viewModel.loadBudgets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading budgets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBudgetChange(String category, double newAmount) {
    final viewModel = Provider.of<BudgetViewModel>(context, listen: false);
    final existingBudget = viewModel.getBudgetByCategory(category);
    
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1); // First day of current month
    final endDate = DateTime(now.year, now.month + 1, 0); // Last day of current month
    
    if (existingBudget != null) {
      // Update existing budget
      final updatedBudget = Budget(
        id: existingBudget.id,
        category: category,
        amount: newAmount,
        startDate: existingBudget.startDate,
        endDate: existingBudget.endDate,
        spent: existingBudget.spent,
      );
      viewModel.addBudget(updatedBudget);
    } else {
      // Create new budget
      final newBudget = Budget(
        category: category,
        amount: newAmount,
        startDate: startDate,
        endDate: endDate,
      );
      viewModel.addBudget(newBudget);
    }
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$category budget updated'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handlePeriodChange(String period) {
    setState(() {
      _selectedPeriod = period;
    });
  }

  void _handleCategoryChange(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _handleRecommendationApply(Budget budget) {
    final viewModel = Provider.of<BudgetViewModel>(context, listen: false);
    viewModel.addBudget(budget);
  }

  // Enhanced filtering and sorting logic
  List<Budget> _getFilteredAndSortedBudgets(List<Budget> budgets) {
    var filteredBudgets = budgets;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredBudgets = filteredBudgets.where((budget) =>
          budget.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'all') {
      filteredBudgets = filteredBudgets.where((budget) => 
          budget.category == _selectedCategory).toList();
    }

    // Apply sorting
    filteredBudgets.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'spent':
          comparison = a.spent.compareTo(b.spent);
          break;
        case 'remaining':
          final aRemaining = a.amount - a.spent;
          final bRemaining = b.amount - b.spent;
          comparison = aRemaining.compareTo(bRemaining);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredBudgets;
  }

  Widget _buildEnhancedHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month Selector Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFFDFDFD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_currentSelectedMonth),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search and Filter Row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Bar
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search budget categories...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Category Filter
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    items: _buildCategoryFilterItems(),
                    onChanged: (value) => setState(() => _selectedCategory = value ?? 'all'),
                    underline: const SizedBox(),
                    icon: Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                  ),
                ),
                const SizedBox(width: 8),
                // Sort Button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: IconButton(
                    onPressed: _showSortOptions,
                    icon: Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    tooltip: 'Sort by $_sortBy',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: -0.1, end: 0);
  }

  List<DropdownMenuItem<String>> _buildCategoryFilterItems() {
    final categories = <String>{'all'};
    
    // Get real categories from BudgetViewModel
    final viewModel = Provider.of<BudgetViewModel>(context, listen: false);
    final budgetCategories = viewModel.budgets.map((budget) => budget.category).toSet();
    categories.addAll(budgetCategories);
    
    // Ensure selected category exists in the list
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'all';
    }
    
    return categories.map((category) => DropdownMenuItem(
      value: category,
      child: Text(category == 'all' ? 'All Categories' : category, 
                  style: const TextStyle(fontSize: 12)),
    )).toList();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...['category', 'amount', 'spent', 'remaining'].map((option) => ListTile(
              title: Text(option.toUpperCase()),
              leading: Radio<String>(
                value: option,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
              ),
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _sortAscending = true);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Ascending'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _sortAscending = false);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Descending'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFE0E7FF)],
          ).createShader(bounds),
          child: const Text(
            'Budget Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorWeight: 3,
        ),
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: Column(
        children: [
          // Enhanced Header with Search and Filters
          _buildEnhancedHeader(),
          Expanded(
            child: Consumer<BudgetViewModel>(
              builder: (context, viewModel, child) {
                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final budgets = _getFilteredAndSortedBudgets(viewModel.budgets);
                
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Enhanced Dashboard Tab
                    _buildEnhancedDashboardTab(budgets, viewModel),
                    
                    // Timeline Tab
                    _buildTimelineTab(budgets, viewModel),
                    
                    // Recommendations Tab
                    _buildRecommendationsTab(budgets, viewModel),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/add_budget');
          },
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          tooltip: 'Add Budget',
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ).animate()
        .scale(delay: const Duration(milliseconds: 800))
        .fadeIn(delay: const Duration(milliseconds: 800)),
    );
  }

  Widget _buildEnhancedDashboardTab(List<Budget> budgets, BudgetViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Month Navigation Header
          _buildDashboardMonthSelector(viewModel),
          const SizedBox(height: 16),
          
          // Enhanced Budget Summary Section
          _buildEnhancedBudgetSummary(viewModel),
          const SizedBox(height: 16),
          
          // Budget Statistics Widget
          _buildBudgetStats(budgets, viewModel),
          const SizedBox(height: 16),
          
          // Premium Budget Pie Chart
          if (budgets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PremiumBudgetPieChart(
                budgets: budgets,
                totalBudget: viewModel.getTotalBudget(),
                onBudgetChanged: _handleBudgetChange,
              ),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 800), delay: const Duration(milliseconds: 300))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: const Duration(milliseconds: 800)),
              
          const SizedBox(height: 20),
          
          // Enhanced Budget Categories List
          _buildEnhancedCategoriesList(budgets, viewModel),
        ],
      ),
    );
  }

  Widget _buildEnhancedBudgetSummary(BudgetViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final totalBudget = viewModel.getTotalBudget();
    final totalSpent = viewModel.getTotalSpent();
    final remaining = viewModel.getRemainingBudget();
    final percentUsed = viewModel.getPercentUsed();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFDFDFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF4A4A4A)],
                  ).createShader(bounds),
                  child: const Text(
                    'Budget Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEnhancedSummaryItem(
                  'Total Budget',
                  currencyFormat.format(totalBudget),
                  const Color(0xFF6366F1),
                ),
                _buildEnhancedSummaryItem(
                  'Spent',
                  currencyFormat.format(totalSpent),
                  Colors.orange,
                ),
                _buildEnhancedSummaryItem(
                  'Remaining',
                  currencyFormat.format(remaining),
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Enhanced Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Usage',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${percentUsed.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: percentUsed > 90 ? Colors.red : 
                               percentUsed > 75 ? Colors.orange : 
                               Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (percentUsed / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: percentUsed > 90 
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : percentUsed > 75 
                                  ? [Colors.orange.shade400, Colors.orange.shade600]
                                  : [Colors.green.shade400, Colors.green.shade600],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.1, end: 0);
  }



  Widget _buildTimelineTab(List<Budget> budgets, BudgetViewModel viewModel) {
    return FutureBuilder<List<app_models.Transaction>>(
      future: viewModel.getTransactionsForBudgets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        // Use empty list if no data, the premium timeline will handle it gracefully
        final transactions = snapshot.data ?? [];

        return PremiumBudgetTimeline(
          budgets: budgets,
          transactions: transactions,
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: _handlePeriodChange,
          selectedCategory: _selectedCategory,
          onCategoryChanged: _handleCategoryChange,
          selectedMonth: _currentSelectedMonth,
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 600))
          .slideY(begin: 0.05, end: 0, duration: const Duration(milliseconds: 600));
      },
    );
  }

  Widget _buildRecommendationsTab(List<Budget> budgets, BudgetViewModel viewModel) {
    return SmartBudgetRecommendations(
      budgets: budgets,
      totalIncome: viewModel.getTotalBudget(), // Using total budget as a proxy for income
      onApplyRecommendation: _handleRecommendationApply,
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.05, end: 0, duration: const Duration(milliseconds: 600));
  }





  Widget _buildEnhancedSummaryItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetStats(List<Budget> budgets, BudgetViewModel viewModel) {
    if (budgets.isEmpty) return const SizedBox.shrink();
    
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final overBudgetCount = budgets.where((b) => b.spent > b.amount).length;
    final nearLimitCount = budgets.where((b) => 
        b.spent > (b.amount * 0.8) && b.spent <= b.amount).length;
    final avgSpending = budgets.isNotEmpty 
        ? budgets.map((b) => b.spent).reduce((a, b) => a + b) / budgets.length
        : 0.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Over Budget',
            '$overBudgetCount',
            Icons.warning,
            Colors.red,
          ),
          _buildStatItem(
            'Near Limit',
            '$nearLimitCount',
            Icons.info,
            Colors.orange,
          ),
          _buildStatItem(
            'Avg Spending',
            currencyFormat.format(avgSpending),
            Icons.analytics,
            Colors.blue,
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 500))
      .slideX(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedCategoriesList(List<Budget> budgets, BudgetViewModel viewModel) {
    if (budgets.isEmpty) {
      return _buildEmptyBudgetState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '${budgets.length} ${budgets.length == 1 ? 'category' : 'categories'}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            return _buildEnhancedBudgetCard(budget, index);
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedBudgetCard(Budget budget, int index) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final percentUsed = budget.amount > 0 ? (budget.spent / budget.amount * 100) : 0.0;
    final remaining = budget.amount - budget.spent;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFDFDFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBudgetDetails(budget),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(budget.category).withValues(alpha: 0.15),
                            _getCategoryColor(budget.category).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(budget.category),
                        color: _getCategoryColor(budget.category),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currencyFormat.format(budget.spent)} of ${currencyFormat.format(budget.amount)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: percentUsed > 100 ? Colors.red :
                                       percentUsed > 80 ? Colors.orange : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currencyFormat.format(remaining),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: remaining >= 0 ? Colors.green : Colors.red,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentUsed.toStringAsFixed(1)}% used',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (percentUsed / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: percentUsed > 100 
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : percentUsed > 80 
                                  ? [Colors.orange.shade400, Colors.orange.shade600]
                                  : [Colors.green.shade400, Colors.green.shade600],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 400))
      .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: index * 100));
  }

  Widget _buildEmptyBudgetState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32.0),
        padding: const EdgeInsets.all(40.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFDFDFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                    const Color(0xFF6366F1).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No budgets created yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first budget to start managing your finances',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDetails(Budget budget) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              budget.category,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Add budget details here
            Text('Budget: \$${budget.amount.toStringAsFixed(2)}'),
            Text('Spent: \$${budget.spent.toStringAsFixed(2)}'),
            Text('Remaining: \$${(budget.amount - budget.spent).toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transportation':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'utilities':
        return Colors.green;
      case 'healthcare':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.home;
      case 'healthcare':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }

  Widget _buildDashboardMonthSelector(BudgetViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFDFDFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Previous Month Button
          IconButton(
            onPressed: () {
              final previousMonth = DateTime(
                _currentSelectedMonth.year,
                _currentSelectedMonth.month - 1,
                1,
              );
              setState(() {
                _currentSelectedMonth = previousMonth;
              });
              viewModel.loadBudgetsForMonth(previousMonth);
            },
            icon: Icon(Icons.chevron_left, color: Colors.grey[600]),
            tooltip: 'Previous Month',
          ),
          
          // Month Dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: DropdownButton<DateTime>(
                value: _currentSelectedMonth,
                items: _buildDashboardMonthDropdownItems(),
                onChanged: (DateTime? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _currentSelectedMonth = newValue;
                    });
                    viewModel.loadBudgetsForMonth(newValue);
                  }
                },
                isExpanded: true,
                underline: const SizedBox(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          // Next Month Button
          IconButton(
            onPressed: () {
              final now = DateTime.now();
              final nextMonth = DateTime(
                _currentSelectedMonth.year,
                _currentSelectedMonth.month + 1,
                1,
              );
              // Don't allow future months beyond current month
              if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                setState(() {
                  _currentSelectedMonth = nextMonth;
                });
                viewModel.loadBudgetsForMonth(nextMonth);
              }
            },
            icon: Icon(Icons.chevron_right, color: Colors.grey[600]),
            tooltip: 'Next Month',
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: -0.2, duration: 300.ms, curve: Curves.easeOut);
  }

  List<DropdownMenuItem<DateTime>> _buildDashboardMonthDropdownItems() {
    final List<DropdownMenuItem<DateTime>> items = [];
    final now = DateTime.now();

    // Generate last 12 months
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      items.add(
        DropdownMenuItem(
          value: month,
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    return items;
  }
}
