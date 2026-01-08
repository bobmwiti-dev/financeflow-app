import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import '../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../viewmodels/income_viewmodel.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../../models/transaction_model.dart' as app_models;
import '../../models/time_period_model.dart';
import '../../themes/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../services/local_ai_intelligence_service.dart';
import '../../widgets/ai_insights/financial_intelligence_card.dart';
import '../../models/transaction_model.dart';
import 'widgets/report_card.dart';
import 'widgets/advanced_period_selector.dart';
import 'widgets/comparative_analysis_card.dart';
import 'widgets/smart_anomaly_card.dart';
import 'widgets/kenya_insights_card.dart';
import 'widgets/expense_optimization_card.dart';
import 'widgets/quick_action_items_card.dart';
import 'widgets/cross_screen_navigation_hub_card.dart';
import '../../widgets/notification_badge.dart';
import '../../utils/currency_extensions.dart';

class ReportsScreen extends StatefulWidget {
  final bool focusExpenseOptimization;

  const ReportsScreen({
    super.key,
    this.focusExpenseOptimization = false,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  int _selectedIndex = 3; // Reports tab selected
  DateTime _selectedMonth = DateTime.now(); // Keep for backward compatibility

  LinearGradient get _accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6366F1),
          Color(0xFF8B5CF6),
        ],
      );

  // Month selection notifier (first day of the month)
  final ValueNotifier<DateTime> _selectedMonthNotifier = ValueNotifier(
    DateTime(DateTime.now().year, DateTime.now().month, 1),
  );
  final GlobalKey _expenseOptimizationKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToExpenseOptimization = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize with current month
    _selectedMonth = DateTime.now();
    
    // Load all data first to populate the month dropdown and reports
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
      final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
      final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
      
      // Load all data needed for reports
      Future.wait([
        transactionViewModel.loadAllTransactions(),
        budgetViewModel.loadBudgets(),
        incomeViewModel.loadIncomeSources(),
      ]).then((_) {
        final logger = Logger('ReportsScreen');
        logger.info('Loaded ${transactionViewModel.allTransactions.length} total transactions');
        logger.info('Loaded ${incomeViewModel.incomeSources.length} total income sources');
        
        // Check if we have data for January 2025 (transactions or income)
        bool hasJan2025Data = false;
        
        if (transactionViewModel.allTransactions.isNotEmpty) {
          final jan2025Transactions = transactionViewModel.allTransactions.where((tx) => 
            tx.date.year == 2025 && tx.date.month == 1).toList();
          
          if (jan2025Transactions.isNotEmpty) {
            logger.info('Found ${jan2025Transactions.length} transactions for January 2025');
            hasJan2025Data = true;
          }
        }
        
        if (incomeViewModel.incomeSources.isNotEmpty) {
          final jan2025Income = incomeViewModel.incomeSources.where((income) => 
            income.date.year == 2025 && income.date.month == 1).toList();
          
          if (jan2025Income.isNotEmpty) {
            logger.info('Found ${jan2025Income.length} income sources for January 2025');
            hasJan2025Data = true;
          }
        }
        
        if (!hasJan2025Data) {
          // Find the most recent month with any data (transactions or income)
          DateTime? mostRecentDate;
          
          if (transactionViewModel.allTransactions.isNotEmpty) {
            final mostRecentTx = transactionViewModel.allTransactions.reduce((a, b) => 
              a.date.isAfter(b.date) ? a : b);
            mostRecentDate = mostRecentTx.date;
          }
          
          if (incomeViewModel.incomeSources.isNotEmpty) {
            final mostRecentIncome = incomeViewModel.incomeSources.reduce((a, b) => 
              a.date.isAfter(b.date) ? a : b);
            
            if (mostRecentDate == null || mostRecentIncome.date.isAfter(mostRecentDate)) {
              mostRecentDate = mostRecentIncome.date;
            }
          }
          
          if (mostRecentDate != null) {
            final newSelectedMonth = DateTime(mostRecentDate.year, mostRecentDate.month, 1);
            logger.info('No January 2025 data, using most recent: ${newSelectedMonth.year}-${newSelectedMonth.month}');
            
            if (mounted) {
              setState(() {
                _selectedMonth = newSelectedMonth;
              });
            }
          }
        }
      }).catchError((error) {
        Logger('ReportsScreen').severe('Error loading data: $error');
      });
    });
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    final String route = NavigationService.routeForDrawerIndex(index);

    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  void _onTimePeriodChanged(TimePeriod newPeriod) {
    setState(() {
      // Update backward compatibility month for existing cards
      _selectedMonth = DateTime.now();
    });
    
    final logger = Logger('ReportsScreen');
    logger.info('Time period changed to: ${newPeriod.displayName} (${newPeriod.type.name})');
  }

  @override
  void dispose() {
    _selectedMonthNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToExpenseOptimization() {
    if (_hasScrolledToExpenseOptimization) return;
    final context = _expenseOptimizationKey.currentContext;
    if (context == null) return;

    _hasScrolledToExpenseOptimization = true;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.focusExpenseOptimization && !_hasScrolledToExpenseOptimization) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToExpenseOptimization();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: _accentGradient),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.white70],
          ).createShader(bounds),
          child: const Text(
            'Reports',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: () {
              // Manually refresh all transactions
              final viewModel = Provider.of<TransactionViewModel>(context, listen: false);
              viewModel.loadAllTransactions().then((_) {
                final logger = Logger('ReportsScreen');
                logger.info('Manual refresh - All transactions: ${viewModel.allTransactions.length}');
                setState(() {
                  // Force rebuild
                });
              });
            },
          ),
          NotificationBadge(
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            color: Colors.white,
            onPressed: () {
              // Share reports
            },
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Period Selector
                AdvancedPeriodSelector(
                  selectedPeriod: TimePeriod.currentMonth(),
                  onPeriodChanged: _onTimePeriodChanged,
                  showComparison: true,
                ),
                const SizedBox(height: 16),
                
                // Quick Action Items Card (New)
                QuickActionItemsCard(
                  selectedPeriod: TimePeriod.currentMonth(),
                ),
                const SizedBox(height: 16),
                
                // Cross-Screen Navigation Hub (New)
                const CrossScreenNavigationHubCard(),
                const SizedBox(height: 16),
                
                // Smart Anomaly Detection Card (New)
                SmartAnomalyCard(
                  selectedPeriod: TimePeriod.currentMonth(),
                ),
                const SizedBox(height: 16),
                
                // Comparative Analysis Card (New)
                Consumer2<TransactionViewModel, IncomeViewModel>(
                  builder: (context, transactionViewModel, incomeViewModel, _) {
                    return ComparativeAnalysisCard(
                      selectedPeriod: TimePeriod.currentMonth(),
                      allTransactions: transactionViewModel.allTransactions,
                      allIncomeSources: incomeViewModel.incomeSources,
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Kenya-Specific Insights Card (New)
                Consumer2<TransactionViewModel, IncomeViewModel>(
                  builder: (context, transactionViewModel, incomeViewModel, _) {
                    return KenyaInsightsCard(
                      selectedPeriod: TimePeriod.currentMonth(),
                      allTransactions: transactionViewModel.allTransactions,
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Expense Optimization Card (New)
                Container(
                  key: _expenseOptimizationKey,
                  child: Consumer2<TransactionViewModel, IncomeViewModel>(
                    builder: (context, transactionViewModel, incomeViewModel, _) {
                      return ExpenseOptimizationCard(
                        selectedPeriod: TimePeriod.currentMonth(),
                        allTransactions: transactionViewModel.allTransactions,
                        highlightOnInit: widget.focusExpenseOptimization,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // AI Financial Intelligence Card (NEW)
                _buildAIIntelligenceCard(),
                const SizedBox(height: 16),
                
                // Enhanced cards (updated to work with new period system)
                _buildFinancialOverviewCard(), // Merged Income vs Expenses
                const SizedBox(height: 16),
                _buildSmartCategoryAnalysisCard(), // Enhanced Category Breakdown
                const SizedBox(height: 16),
                _buildPredictiveBudgetCard(), // Enhanced Budget Performance
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Financial Overview Card (replaces Income vs Expenses)
  Widget _buildFinancialOverviewCard() {
    return Consumer2<TransactionViewModel, IncomeViewModel>(
      builder: (context, transactionViewModel, incomeViewModel, _) {
        // Ensure we have loaded all transactions for reports
        if (transactionViewModel.allTransactions.isEmpty && !transactionViewModel.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            transactionViewModel.loadAllTransactions();
          });
        }
        
        // Ensure we have loaded income sources
        if (incomeViewModel.incomeSources.isEmpty && !incomeViewModel.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            incomeViewModel.setSelectedMonth(_selectedMonth);
            incomeViewModel.loadIncomeSources();
          });
        }
        
        if (transactionViewModel.isLoading || incomeViewModel.isLoading) {
          return const ReportCard(
            title: '💰 Financial Overview',
            child: SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        double income = 0;
        double expenses = 0;
        int incomeTransactions = 0;
        int expenseTransactions = 0;

        // Get income from IncomeViewModel (filtered by selected time period)
        final currentMonth = DateTime.now();
        final incomeSourcesForPeriod = incomeViewModel.incomeSources.where((source) => 
          source.date.year == currentMonth.year && source.date.month == currentMonth.month).toList();
        income = incomeSourcesForPeriod.fold(0.0, (sum, source) => sum + source.amount);
        incomeTransactions = incomeSourcesForPeriod.length;

        // Get expenses from TransactionViewModel (filtered by selected time period)
        final selectedPeriodExpenses = transactionViewModel.allTransactions
            .where((t) =>
                t.type == app_models.TransactionType.expense &&
                t.date.year == currentMonth.year && t.date.month == currentMonth.month)
            .toList();
        expenses = selectedPeriodExpenses.fold(0.0, (sum, t) => sum + t.amount.abs());
        expenseTransactions = selectedPeriodExpenses.length;

        final netIncome = income - expenses;
        final savingsRate = income > 0 ? (netIncome / income) * 100 : 0.0;

        return ReportCard(
          title: '💰 Financial Overview - ${currentMonth.month}/${currentMonth.year}',
          child: Column(
            children: [
              // Summary Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Income',
                      income.toCurrency(),
                      '$incomeTransactions sources',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Expenses',
                      expenses.toCurrency(),
                      '$expenseTransactions transactions',
                      Icons.trending_down,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Net Income and Savings Rate
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: netIncome >= 0 
                        ? [Colors.green.withValues(alpha: 0.1), Colors.blue.withValues(alpha: 0.1)]
                        : [Colors.red.withValues(alpha: 0.1), Colors.orange.withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (netIncome >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Income',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              netIncome.toCurrency(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: netIncome >= 0 ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Savings Rate',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${savingsRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: savingsRate >= 20 ? Colors.green[700] : 
                                       savingsRate >= 10 ? Colors.orange[700] : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Financial Health Indicator
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getHealthColor(savingsRate).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getHealthIcon(savingsRate),
                            size: 16,
                            color: _getHealthColor(savingsRate),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getHealthMessage(savingsRate),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getHealthColor(savingsRate),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Enhanced Smart Category Analysis Card (replaces Category Breakdown)
  Widget _buildSmartCategoryAnalysisCard() {
    return Consumer<TransactionViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.allTransactions.isEmpty && !viewModel.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.loadAllTransactions();
          });
        }
        
        if (viewModel.isLoading) {
          return const ReportCard(
            title: '📊 Smart Category Analysis',
            child: SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final allTransactions = viewModel.allTransactions.isNotEmpty 
            ? viewModel.allTransactions 
            : viewModel.transactions;

        final currentMonth = DateTime.now();
        final selectedMonthTransactions = allTransactions.where((tx) {
          return tx.type == app_models.TransactionType.expense &&
                 tx.date.year == currentMonth.year &&
                 tx.date.month == currentMonth.month;
        }).toList();

        if (selectedMonthTransactions.isEmpty) {
          return const ReportCard(
            title: '📊 Smart Category Analysis',
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No expense data available for the selected period',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          );
        }

        // Calculate category totals with trends
        final categoryTotals = <String, double>{};
        final categoryTransactions = <String, List<app_models.Transaction>>{};
        
        for (final transaction in selectedMonthTransactions) {
          final category = transaction.category.isNotEmpty ? transaction.category : 'Other';
          categoryTotals.update(category, (value) => value + transaction.amount.abs(), 
              ifAbsent: () => transaction.amount.abs());
          categoryTransactions.putIfAbsent(category, () => []).add(transaction);
        }

        // Sort categories by amount (highest first)
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final totalExpenses = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
        final topCategories = sortedCategories.take(5).toList();

        return ReportCard(
          title: '📊 Smart Category Analysis - ${currentMonth.month}/${currentMonth.year}',
          child: Column(
            children: [
              // Top spending insight
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.withValues(alpha: 0.1), Colors.purple.withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insights, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        topCategories.isNotEmpty 
                            ? '${topCategories.first.key} is your top expense (${((topCategories.first.value / totalExpenses) * 100).toStringAsFixed(1)}%)'
                            : 'No category data available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Category breakdown with insights
              ...topCategories.map((entry) {
                final percentage = (entry.value / totalExpenses) * 100;
                final transactions = categoryTransactions[entry.key] ?? [];
                final avgTransaction = transactions.isNotEmpty ? (entry.value / transactions.length).toDouble() : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  entry.value.toCurrency(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Progress bar
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(entry.key)),
                        ),
                        const SizedBox(height: 6),
                        
                        // Transaction insights
                        Row(
                          children: [
                            Icon(Icons.receipt, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${transactions.length} transactions',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.analytics, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'Avg: ${avgTransaction.toCurrency()}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
  
  // Enhanced Predictive Budget Card (replaces Budget Performance)
  Widget _buildPredictiveBudgetCard() {
    return Consumer3<BudgetViewModel, TransactionViewModel, IncomeViewModel>(
      builder: (context, budgetVm, transactionVm, incomeVm, _) {
        final currentMonth = DateTime.now();
        // Ensure budget data is loaded for the selected month
        if (budgetVm.selectedMonth.year != currentMonth.year ||
            budgetVm.selectedMonth.month != currentMonth.month) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            budgetVm.loadBudgetsForMonth(currentMonth);
          });
        }

        if (budgetVm.isLoading) {
          return const ReportCard(
            title: '🎯 Predictive Budget Analysis',
            child: SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final selectedMonthBudgets = budgetVm.budgets;
        
        if (selectedMonthBudgets.isEmpty) {
          return const ReportCard(
            title: '🎯 Predictive Budget Analysis',
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No budgets set for the selected period',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          );
        }

        // Calculate actual spending vs budgets
        final allTransactions = transactionVm.allTransactions.isNotEmpty 
            ? transactionVm.allTransactions 
            : transactionVm.transactions;

        final selectedPeriodTransactions = allTransactions.where((tx) {
          return tx.type == app_models.TransactionType.expense &&
                 tx.date.year == currentMonth.year &&
                 tx.date.month == currentMonth.month;
        }).toList();

        final categorySpending = <String, double>{};
        for (final tx in selectedPeriodTransactions) {
          final category = tx.category.isNotEmpty ? tx.category : 'Other';
          categorySpending.update(category, (value) => value + tx.amount.abs(), 
              ifAbsent: () => tx.amount.abs());
        }

        final totalBudget = selectedMonthBudgets.fold(0.0, (sum, budget) => sum + budget.amount);
        final totalSpent = categorySpending.values.fold(0.0, (sum, amount) => sum + amount);
        final overallUtilization = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;
        
        // Predictive analysis
        final now = DateTime.now();
        final endOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
        final daysInPeriod = endOfMonth.day;
        final daysPassed = now.day;
        final daysRemaining = daysInPeriod - daysPassed;
        
        final dailySpendRate = daysPassed > 0 ? totalSpent / daysPassed : 0;
        final projectedSpending = totalSpent + (dailySpendRate * daysRemaining);
        final projectedUtilization = totalBudget > 0 ? (projectedSpending / totalBudget) * 100 : 0.0;

        return ReportCard(
          title: '🎯 Predictive Budget Analysis - ${currentMonth.month}/${currentMonth.year}',
          child: Column(
            children: [
              // Overall budget status
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getBudgetGradientColors(overallUtilization),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget Used',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${overallUtilization.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _getBudgetStatusColor(overallUtilization),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Projected',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${projectedUtilization.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getBudgetStatusColor(projectedUtilization),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Progress bar
                    LinearProgressIndicator(
                      value: (overallUtilization / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_getBudgetStatusColor(overallUtilization)),
                    ),
                    const SizedBox(height: 8),
                    
                    // Predictive insight
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPredictionColor(projectedUtilization).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getPredictionIcon(projectedUtilization),
                            size: 16,
                            color: _getPredictionColor(projectedUtilization),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getPredictionMessage(projectedUtilization, daysRemaining),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getPredictionColor(projectedUtilization),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Budget breakdown
              Text(
                'Budget Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              
              ...selectedMonthBudgets.take(5).map((budget) {
                final spent = categorySpending[budget.category] ?? 0.0;
                final utilization = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getBudgetStatusColor(utilization).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                budget.category,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${spent.toCurrency()} / ${budget.amount.toCurrency()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (utilization / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(_getBudgetStatusColor(utilization)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${utilization.toStringAsFixed(1)}% used',
                              style: TextStyle(
                                fontSize: 11,
                                color: _getBudgetStatusColor(utilization),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(budget.amount - spent).toCurrency()} remaining',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
  
  // Helper methods for enhanced cards
  Widget _buildSummaryCard(String title, String amount, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getHealthColor(double savingsRate) {
    if (savingsRate >= 20) return Colors.green;
    if (savingsRate >= 10) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getHealthIcon(double savingsRate) {
    if (savingsRate >= 20) return Icons.trending_up;
    if (savingsRate >= 10) return Icons.trending_flat;
    return Icons.trending_down;
  }
  
  String _getHealthMessage(double savingsRate) {
    if (savingsRate >= 20) return 'Excellent savings rate! Keep it up!';
    if (savingsRate >= 10) return 'Good savings rate. Consider increasing it.';
    if (savingsRate >= 0) return 'Low savings rate. Review your expenses.';
    return 'Spending exceeds income. Immediate action needed.';
  }
  
  List<Color> _getBudgetGradientColors(double utilization) {
    if (utilization >= 100) {
      return [Colors.red.withValues(alpha: 0.1), Colors.deepOrange.withValues(alpha: 0.1)];
    } else if (utilization >= 75) {
      return [Colors.orange.withValues(alpha: 0.1), Colors.amber.withValues(alpha: 0.1)];
    } else {
      return [Colors.green.withValues(alpha: 0.1), Colors.teal.withValues(alpha: 0.1)];
    }
  }
  
  Color _getBudgetStatusColor(double utilization) {
    if (utilization >= 100) return Colors.red;
    if (utilization >= 75) return Colors.orange;
    return Colors.green;
  }
  
  Color _getPredictionColor(double projectedUtilization) {
    if (projectedUtilization >= 110) return Colors.red;
    if (projectedUtilization >= 90) return Colors.orange;
    return Colors.green;
  }
  
  IconData _getPredictionIcon(double projectedUtilization) {
    if (projectedUtilization >= 110) return Icons.warning;
    if (projectedUtilization >= 90) return Icons.info;
    return Icons.check_circle;
  }
  
  String _getPredictionMessage(double projectedUtilization, int daysRemaining) {
    if (projectedUtilization >= 110) {
      return 'Warning: You\'re likely to exceed your budget by ${(projectedUtilization - 100).toStringAsFixed(1)}%';
    } else if (projectedUtilization >= 90) {
      return 'Caution: You\'re on track to use ${projectedUtilization.toStringAsFixed(1)}% of your budget';
    } else {
      return 'Good: You\'re on track to stay within budget with $daysRemaining days remaining';
    }
  }

  // AI Financial Intelligence Card
  Widget _buildAIIntelligenceCard() {
    return Consumer2<TransactionViewModel, IncomeViewModel>(
      builder: (context, transactionVm, incomeVm, _) {
        return FutureBuilder<FinancialIntelligence>(
          future: _getAIIntelligence(transactionVm, incomeVm),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                margin: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Analyzing your financial data with AI...'),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                margin: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.orange, size: 32),
                        const SizedBox(height: 8),
                        const Text('AI analysis temporarily unavailable'),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return Card(
                margin: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 100,
                  child: const Center(
                    child: Text('Add more transactions to get AI insights'),
                  ),
                ),
              );
            }

            return FinancialIntelligenceCard(
              intelligence: snapshot.data!,
              onViewDetails: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIInsightsDetailScreen(
                      intelligence: snapshot.data!,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<FinancialIntelligence> _getAIIntelligence(
    TransactionViewModel transactionVm,
    IncomeViewModel incomeVm,
  ) async {
    final aiService = LocalAIIntelligenceService();
    
    // Convert app_models.Transaction to Transaction for AI service
    final transactions = transactionVm.allTransactions.map((tx) => Transaction(
      id: tx.id,
      userId: tx.userId,
      title: tx.title,
      amount: tx.amount,
      date: tx.date,
      category: tx.category,
      type: tx.isExpense ? TransactionType.expense : TransactionType.income,
      description: tx.description ?? '',
      accountId: tx.accountId,
    )).toList();

    return await aiService.analyzeFinancialData(
      transactions: transactions,
      incomeSources: incomeVm.incomeSources,
      analysisDate: DateTime.now(),
    );
  }
  
  Color _getCategoryColor(String category) {
    if (AppTheme.categoryColors.containsKey(category)) {
      return AppTheme.categoryColors[category]!.withAlpha((0.7 * 255).toInt());
    }
    return AppTheme.categoryColors['Other']!.withAlpha((0.7 * 255).toInt());
  }

}
