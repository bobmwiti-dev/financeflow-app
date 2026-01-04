import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/budget_adherence_card.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services
import '../../services/transaction_service.dart';
import '../../services/realtime_data_service.dart';
import '../../services/mpesa_import_service.dart';
import '../../services/sms_import_service.dart';

// Models
import '../../models/transaction_model.dart' as models;

// Widgets
import 'package:financeflow_app/views/dashboard/widgets/enhanced_monthly_summary.dart';
import 'package:financeflow_app/views/dashboard/widgets/financial_summary_card.dart';
import 'package:financeflow_app/views/dashboard/widgets/spending_trend_chart.dart';
import './widgets/insight_of_the_day_card.dart';
import './widgets/smart_transactions_card.dart';
import 'widgets/side_hustle_summary_card.dart';
import './widgets/enhanced_bills_card.dart';
import './widgets/unified_savings_card.dart';
import 'widgets/enhanced_emergency_fund_card.dart';
import 'widgets/smart_alerts_card.dart';
import 'widgets/mpesa_import_card.dart';
import 'widgets/enhanced_cash_flow_forecast_card.dart';
import './widgets/quick_actions_panel.dart';

// Theme
import '../../themes/app_theme.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../widgets/notification_badge.dart'; 
import 'package:financeflow_app/constants/app_constants.dart';
import 'package:financeflow_app/viewmodels/income_viewmodel.dart';
import 'package:financeflow_app/viewmodels/debt_goals_viewmodel.dart';
import 'package:financeflow_app/viewmodels/account_viewmodel.dart';
import 'widgets/enhanced_safe_to_spend_card.dart';
import '../../widgets/account_balance_widget.dart';
import 'package:financeflow_app/viewmodels/transaction_viewmodel_fixed.dart';

/// Dashboard screen showing financial overview, recent transactions, and quick actions
class DashboardScreen extends StatefulWidget {

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TransactionService _transactionService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late IncomeViewModel _incomeViewModel;
  final Logger logger = Logger('DashboardScreen');

  late final AnimationController _animationController;
  bool _isRefreshing = false;
  bool _isLoading = true;
  bool _isError = false;
  
  // Listen to transaction updates from TransactionViewModel
  TransactionViewModel? _transactionViewModel;
  VoidCallback? _txViewModelListener;
  
  // Dashboard data
  double _expenses = 0.0;
  double _balance = 0.0;
  Map<String, double> _categoryTotals = {};
  int _selectedMonthIndex = DateTime.now().month - 1;
  int _selectedYear = DateTime.now().year;
  
  DateTime get _selectedMonthDate =>
      DateTime(_selectedYear, _selectedMonthIndex + 1);
  
  // Previous month data for trends
  double _previousExpenses = 0.0;
  double _previousIncome = 0.0;
  
  // Historical data for trend analysis
  final List<Map<String, dynamic>> _transactionHistory = [];
  final List<Map<String, dynamic>> _incomeHistory = [];
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  List<String> _frequentPayees = [];
  int _recentBankSmsImported = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Initialize services and viewmodels
    _transactionService = Provider.of<TransactionService>(context, listen: false);
    _incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
    _transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
    final smsImportService = Provider.of<SmsImportService>(context, listen: false);
    
    // Listen to income changes and refresh dashboard data
    _incomeViewModel.addListener(_onIncomeChanged);
    // Listen to transaction changes via TransactionViewModel
    _txViewModelListener = () {
      if (!mounted) return;
      _onTransactionsUpdated();
    };
    _transactionViewModel?.addListener(_txViewModelListener!);
    
    // Load initial data
    _loadInitialData();
    
    // Attempt automatic imports once per day (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybeRunFirstTimeFlows();

      await MpesaImportService.autoImportIfNeeded(
        minInterval: const Duration(hours: 24),
      );

      // Bank SMS (KCB, Equity, etc.) via SmsImportService
      final imported = await smsImportService.autoImportIfNeeded(
        minInterval: const Duration(hours: 24),
      );
      if (mounted && (imported ?? 0) > 0) {
        setState(() {
          _recentBankSmsImported = imported!;
        });
      }
    });
    
    // Start entrance animation
    _animationController.forward();
  }

  Future<void> _maybeRunFirstTimeFlows() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quickSetupCompleted = prefs.getBool('quick_setup_completed') ?? false;

      if (!quickSetupCompleted) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/quick_setup');
        return;
      }

      final snapshotShown = prefs.getBool('first_30_snapshot_shown') ?? false;
      if (!snapshotShown) {
        if (!mounted) return;
        Navigator.of(context).pushNamed('/first_30_days_snapshot');
      }
    } catch (_) {
      // no-op
    }
  }



  @override
  void dispose() {
    _incomeViewModel.removeListener(_onIncomeChanged);
    if (_txViewModelListener != null && _transactionViewModel != null) {
      _transactionViewModel!.removeListener(_txViewModelListener!);
    }
    super.dispose();
  }

  /// Called when income data changes to refresh dashboard calculations
  void _onIncomeChanged() {
    logger.info('Income changed, updating dashboard balance');
    if (mounted) {
      // Recalculate real balance with new income
      final accountVm = Provider.of<AccountViewModel>(context, listen: false);
      final vm = _transactionViewModel ?? Provider.of<TransactionViewModel>(context, listen: false);

      // Get current month transactions from the view model
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final monthTransactions = vm.transactions.where((t) =>
        t.date.year == currentMonth.year && t.date.month == currentMonth.month,
      ).toList();

      final realBalance = accountVm.getTotalBalance(
        monthTransactions,
        _incomeViewModel.incomeSources,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _balance = realBalance;
          });
        }
      });
    }
  }

  void _onTransactionsUpdated() {
    final vm = _transactionViewModel;
    if (vm == null) return;

    // Filter transactions for the currently selected month index
    final currentMonth = _selectedMonthDate;
    final monthTransactions = vm.transactions.where((t) =>
      t.date.year == currentMonth.year && t.date.month == currentMonth.month,
    ).toList();

    logger.info('Processing ${monthTransactions.length} transactions for dashboard (from TransactionViewModel)');
    _processTransactions(monthTransactions);
  }

  /// Load initial dashboard data (called once in initState)
  Future<void> _loadInitialData({bool refreshAll = false}) async {
    if (!mounted) return;

    logger.info('Loading initial dashboard data - refreshAll: $refreshAll');
    
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    // Load one-time data only on initial load or full refresh
    if (refreshAll) {
      logger.info('Loading debt goals for full refresh');
      final debtGoalsViewModel = Provider.of<DebtGoalsViewModel>(context, listen: false);
      await debtGoalsViewModel.loadGoals();
    }

    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        logger.warning('No authenticated user found');
        if (mounted) {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
        return;
      }
      
      logger.info('Loading dashboard data for user: ${user.uid}');
      // At this point, the transaction stream listener will start delivering
      // current-month data via _setupTransactionListener. Do not block the
      // initial render on heavier background analytics.

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Kick off heavier work in the background without blocking UI.
      // Fetch frequent payees
      () async {
        logger.info('Fetching frequent payees in background');
        final fetchedPayees = await _transactionService.getFrequentPayees(limit: 3);
        if (mounted) {
          setState(() {
            _frequentPayees = fetchedPayees;
          });
          logger.info('Loaded ${fetchedPayees.length} frequent payees');
        }
      }();

      // Load previous month data for trends in the background
      () async {
        final currentMonth = _selectedMonthDate;
        logger.info('Background load of historical data for ${DateFormat.yMMMM().format(currentMonth)}');
        await _loadPreviousMonthData(currentMonth);
      }();
    } catch (e) {
      if (!mounted) return;
      logger.severe('Error loading initial dashboard data: $e');
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  /// Load historical data for trend calculations and financial summary
  Future<void> _loadPreviousMonthData(DateTime currentMonth) async {
    try {
      // Load data from multiple months to include all generated mock data
      final monthsToLoad = <DateTime>[];
      
      // Add current and previous months
      monthsToLoad.add(currentMonth);
      monthsToLoad.add(DateTime(currentMonth.year, currentMonth.month - 1));
      
      // Add months from 2025 where we have data (January-August and current month)
      for (int month = 1; month <= 9; month++) {
        monthsToLoad.add(DateTime(2025, month));
      }
      
      logger.info('Loading historical data from ${monthsToLoad.length} months');
      
      // Collect all transactions from these months
      final allTransactions = <dynamic>[];
      for (final month in monthsToLoad) {
        try {
          final monthTransactions = await _transactionService.getTransactionsByMonth(month).first;
          allTransactions.addAll(monthTransactions);
          logger.info('Loaded ${monthTransactions.length} transactions from ${DateFormat.yMMMM().format(month)}');
        } catch (e) {
          logger.warning('Failed to load transactions for ${DateFormat.yMMMM().format(month)}: $e');
        }
      }
      
      double previousIncome = 0.0;
      double previousExpenses = 0.0;
      
      // Build transaction history for Financial Summary Card from all transactions
      _transactionHistory.clear();
      for (final transaction in allTransactions) {
        _transactionHistory.add({
          'date': transaction.date,
          'amount': transaction.amount.abs(),
          'type': transaction.isExpense ? 'expense' : 'income',
          'category': transaction.category,
        });
        
        if (!transaction.isExpense) {
          previousIncome += transaction.amount.abs();
        } else {
          previousExpenses += transaction.amount.abs();
        }
      }
      
      // Build income history for Financial Summary Card
      if (mounted) {
        final incomeVM = Provider.of<IncomeViewModel>(context, listen: false);
        _incomeHistory.clear();
        for (final income in incomeVM.incomeSources) {
          _incomeHistory.add({
            'date': income.date,
            'amount': income.amount,
            'name': income.name,
          });
        }
        
        // Compute previous month income (use the month before current)
        final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1);
        final prevIncomeFromSources = incomeVM.incomeSources.where((src) =>
          src.date.year == previousMonth.year && src.date.month == previousMonth.month).fold<double>(0.0, (total, src) => total + src.amount);
        if (prevIncomeFromSources > 0) {
          previousIncome = prevIncomeFromSources;
        }
      }
      
      if (mounted) {
        setState(() {
          _previousIncome = previousIncome;
          _previousExpenses = previousExpenses;
        });
        logger.info('Previous month - Income: \$${previousIncome.toStringAsFixed(2)}, Expenses: \$${previousExpenses.toStringAsFixed(2)}');
      }
    } catch (e) {
      logger.warning('Failed to load previous month data: $e');
      // Set defaults if we can't load previous data
      if (mounted) {
        setState(() {
          _previousIncome = 0.0;
          _previousExpenses = 0.0;
        });
      }
    }
  }

  /// Process transaction data and update dashboard state
  Future<void> _processTransactions(List<models.Transaction> transactions) async {
    // Calculate financial summary from transaction stream
    double income = 0.0;
    double expenses = 0.0;
    Map<String, double> categoryTotals = {};

    for (final transaction in transactions) {
      if (!transaction.isExpense) {
        // Treat transaction type income
        income += transaction.amount.abs();
      } else {
        expenses += transaction.amount.abs();
      }

      // Update category totals
      final category = transaction.category;
      if (transaction.isExpense) {
        categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount.abs();
      }
    }

    // Add income sources from IncomeViewModel so dashboard stays in sync
    final currentMonth = _selectedMonthDate;
    final incomeVM = Provider.of<IncomeViewModel>(context, listen: false);
    incomeVM.setSelectedMonth(currentMonth);
    final double incomeSourcesTotal = incomeVM.getTotalIncome();
    logger.info('Income from ViewModel: \$${incomeSourcesTotal.toStringAsFixed(2)}, Transaction income: \$${income.toStringAsFixed(2)}');
    // Replace transaction-derived income with authoritative income source total if available
    if (incomeSourcesTotal > 0) {
      income = incomeSourcesTotal;
      logger.info('Using ViewModel income as authoritative source');
    }

    // Sort transactions by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    // Take the 5 most recent
    final recentTransactions = transactions.take(5).toList();
    logger.info('Selected ${recentTransactions.length} recent transactions for display');


    // Cash flow calculation is now handled by EnhancedCashFlowForecastCard

    // Update state with calculated values
    if (mounted) {
      // Get real balance from AccountViewModel
      final accountVm = Provider.of<AccountViewModel>(context, listen: false);
      final realBalance = accountVm.getTotalBalance(
        transactions,
        _incomeViewModel.incomeSources,
      );
      
      logger.info('Dashboard calculations - Expenses: \$${expenses.toStringAsFixed(2)}, Real Balance: \$${realBalance.toStringAsFixed(2)}, Categories: ${categoryTotals.length}');
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _expenses = expenses;
            _balance = realBalance;
            _categoryTotals = categoryTotals;
          });
        }
      });
      logger.info('Dashboard state updated successfully');
    }
  }

  /// Refresh dashboard data with animation
  Future<void> _refreshDashboard() async {
    logger.info('Refreshing dashboard data');
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadInitialData(refreshAll: true);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access RealtimeDataService for real-time updates when needed
    Provider.of<RealtimeDataService>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    logger.info('Building dashboard - Loading: $_isLoading, Error: $_isError, Refreshing: $_isRefreshing');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              logger.info('Manual refresh triggered from app bar');
              _refreshDashboard();
            },
          ),
          NotificationBadge(
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.pushNamed(context, '/notification_test');
            },
            tooltip: 'Test Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: 0,
        onItemSelected: (index) {
          String route = NavigationService.routeForDrawerIndex(index);
          
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          if (ModalRoute.of(context)?.settings.name != route) {
            NavigationService.navigateToReplacement(route);
          }
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withAlpha((0.06 * 255).toInt()),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: _buildBody(context),
      ),
      // bottomNavigationBar: _buildBottomNavigationBar(context), // Removed
    );
  }

  Widget _buildBankSmsImportBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.sms, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Imported $_recentBankSmsImported new bank SMS transactions today',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey.shade600,
            onPressed: () {
              setState(() {
                _recentBankSmsImported = 0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard data...'),
          ],
        ),
      );
    }

    if (_isError) {
      logger.warning('Error state in dashboard');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[300],
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load dashboard data',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  logger.info('Retrying dashboard data load');
                  _refreshDashboard();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Main body animation is now handled by flutter_animate on SingleChildScrollView

    return RefreshIndicator(
      onRefresh: () async {
        logger.info('Dashboard refresh triggered by pull-to-refresh');
        return _refreshDashboard();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24), // Added bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 12),
            _buildUserGreeting(),
            if (_recentBankSmsImported > 0) ...[
              const SizedBox(height: 8),
              _buildBankSmsImportBanner(),
            ],

            // Insight of the Day should be the first card after greeting
            InsightOfTheDayCard(
              selectedMonth: _selectedMonthDate,
            ),
            const SizedBox(height: 8),

            // This month at a glance
            EnhancedMonthlySummary(
              selectedMonth: _selectedMonthDate,
            ).animate().fadeIn(delay: 50.ms, duration: 400.ms),
            const SizedBox(height: 16),

            // Financial summary card with chart visualization
            Consumer<IncomeViewModel>(
              builder: (context, incomeViewModel, child) {
                return FinancialSummaryCard(
                  income: incomeViewModel.getTotalIncome(),
                  expenses: _expenses,
                  balance: _balance,
                  categoryTotals: _categoryTotals,
                  isRefreshing: _isRefreshing,
                  previousIncome: _previousIncome > 0 ? _previousIncome : null,
                  previousExpenses: _previousExpenses > 0 ? _previousExpenses : null,
                  transactionHistory: _transactionHistory,
                  incomeHistory: _incomeHistory,
                  selectedMonth: _selectedMonthDate,
                ).animate().fadeIn(delay: 75.ms, duration: 400.ms);
              },
            ),
            const SizedBox(height: 16),

            // Monthly spending trend card
            const SpendingTrendChart().animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 16),

            // Safe-to-spend + cash flow forecast
            EnhancedSafeToSpendCard(
              selectedMonth: _selectedMonthDate,
            ).animate().fadeIn(delay: 125.ms, duration: 400.ms),
            const SizedBox(height: 16),
            EnhancedCashFlowForecastCard(
              onViewDetails: () => Navigator.pushNamed(context, '/cash_flow_forecast'),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 16),

            // Next upcoming debits
            const EnhancedBillsCard(),
            const SizedBox(height: 16),

            // Goals & emergency fund
            Consumer<IncomeViewModel>(
              builder: (context, incomeViewModel, child) {
                return UnifiedSavingsCard(
                  income: incomeViewModel.getTotalIncome(),
                  expenses: _expenses,
                  targetSavingsRate: 0.30,
                  onViewAllGoals: () => Navigator.pushNamed(context, '/goals'),
                  onGoalTap: (goal) => Navigator.pushNamed(context, '/goal_details', arguments: goal),
                );
              },
            ),
            const SizedBox(height: 16),
            const EnhancedEmergencyFundCard().animate().fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 16),

            // Side-hustle (Business) Summary
            SideHustleSummaryCard(
              selectedMonth: _selectedMonthDate,
            ).animate().fadeIn(delay: 175.ms, duration: 400.ms),
            const SizedBox(height: 16),

            // Account Balance Widget
            const AccountBalanceWidget(
              showAllAccounts: false, // Show only default account on dashboard
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 16),

            // M-Pesa Import Card
            const MpesaImportCard().animate().fadeIn(delay: 225.ms, duration: 400.ms),
            const SizedBox(height: 16),
            // Recent Transactions
            RecentTransactionsCard(selectedMonth: _selectedMonthDate),
            const SizedBox(height: 16),
            
            // Quick action buttons
            QuickActionsPanel(
                recentPayees: _frequentPayees, // Use dynamic payees
                onActionSelected: (action) {
                  switch (action) {
                    case 'add_expense':
                       Navigator.pushNamed(context, '/add_transaction', arguments: {'type': 'expense'});
                       break;
                     case 'add_income':
                       // This case is handled directly by QuickActionsPanel
                       // No need to handle it here as the panel navigates to IncomeFormScreen
                       break;
                    case 'new_bill':
                      Navigator.pushNamed(context, '/add_bill');
                      break;
                    case 'new_goal':
                      NavigationService.navigateTo(AppConstants.addGoalRoute);
                      break;
                    case 'transfer':
                       NavigationService.navigateTo(AppConstants.transferRoute);
                     case 'new_budget':
                       NavigationService.navigateTo(AppConstants.addBudgetRoute);
                       break;
                     case 'mpesa_import':
                       Navigator.pushNamed(context, '/mpesa_import');
                       break;
                     case 'transport_intelligence':
                       Navigator.pushNamed(context, '/transport_intelligence');
                       break;
                     default:
                       break;
                  }
                },
                onPayeeSelected: (payee) {
                  Navigator.pushNamed(
                    context, 
                    '/add_transaction',
                    arguments: {'payee': payee}
                  );
                },
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms), // Keep existing item animation
            const SizedBox(height: 24),
            
            // Smart Alerts Card
            const SmartAlertsCard().animate().fadeIn(delay: 700.ms, duration: 500.ms),
            const SizedBox(height: 24),
            
            // Spending by category
            BudgetAdherenceCard(selectedMonth: _selectedMonthDate).animate().fadeIn(delay: 610.ms, duration: 500.ms),
            const SizedBox(height: 24),
            const SizedBox(height: 70), // Space for FAB
          ],
        ),
      ).animate(controller: _animationController) // Apply the controller here
          .slideY(begin: 0.1, end: 0.0, duration: 500.ms, curve: Curves.easeOut)
          .fadeIn(duration: 500.ms, curve: Curves.easeInOut),
    );
  }
  
  Widget _buildMonthSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _months.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedMonthIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(_months[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        logger.info('Month selector changed to: ${_months[index]} for year $_selectedYear');
                        setState(() {
                          _selectedMonthIndex = index;
                        });
                        final currentMonth = _selectedMonthDate;
                        _loadPreviousMonthData(currentMonth);
                        _onTransactionsUpdated();
                      }
                    },
                    backgroundColor:
                        Colors.grey.withValues(alpha: 0.1 * 255),
                    selectedColor: AppTheme.primaryColor
                        .withValues(alpha: 0.2 * 255),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildYearSelector(theme, colorScheme),
      ],
    ).animate().fadeIn(delay: 50.ms, duration: 400.ms);
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedYear += delta;
    });
    final currentMonth = _selectedMonthDate;
    _loadPreviousMonthData(currentMonth);
    _onTransactionsUpdated();
  }

  Widget _buildYearSelector(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _changeYear(-1),
            child: Icon(
              Icons.chevron_left,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$_selectedYear',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _changeYear(1),
            child: Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGreeting() {
    final user = _auth.currentUser;
    final String displayName = user?.displayName?.split(' ').first ?? 'There';
    final String? photoURL = user?.photoURL;
    final String initials = user?.displayName?.isNotEmpty == true
        ? user!.displayName!.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning,';
    } else if (hour < 17) {
      greeting = 'Good afternoon,';
    } else {
      greeting = 'Good evening,';
    }

    // Dynamic subtitle
    final dayOfWeek = DateFormat('EEEE').format(now);
    final thisMonthLabel =
        'This month: ${_months[_selectedMonthIndex]} $_selectedYear';
    String subtitle = "Here's your financial overview for today.";
    final totalIncome = _incomeViewModel.getTotalIncome();
    if (_expenses > 0 && totalIncome > 0) {
      final savingsRate = ((totalIncome - _expenses) / totalIncome * 100);
      if (savingsRate > 20) {
        subtitle = "Great job! Your savings rate is ${savingsRate.toStringAsFixed(0)}% so far.";
      } else if (savingsRate > 0) {
        subtitle = "You're on the right track. Keep it up!";
      } else {
        subtitle = "Let's review your spending for the month.";
      }
    } else if (dayOfWeek == 'Friday') {
      subtitle = "It's Friday — a great time to check in on your money wins.";
    } else if (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
      subtitle = "Weekend check-in: keep your spending aligned with your goals.";
    } else if (dayOfWeek == 'Monday') {
      subtitle = "A new week, a fresh start for your finances!";
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
                      ),
                      child: Text(
                        thisMonthLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 26,
            backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
            backgroundColor: colorScheme.primaryContainer,
            child: photoURL == null
                ? Text(
                    initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 25.ms, duration: 500.ms);
  }



}

// Local AppNavigationDrawer class definition removed.