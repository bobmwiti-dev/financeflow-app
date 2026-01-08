import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../utils/currency_extensions.dart';

import '../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../models/transaction_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../services/navigation_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/category_icons.dart';
import '../add_transaction/add_transaction_screen.dart';
import '../transactions/transaction_form_screen.dart';
import '../reports/reports_screen.dart';


class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  static const Map<String, List<String>> _quickFilterGroups = {
    'Essentials': ['Housing', 'Rent', 'Utilities', 'Groceries', 'Food'],
    'Lifestyle': ['Entertainment', 'Shopping', 'Dining', 'Leisure', 'Travel'],
    'Subscriptions': ['Subscriptions', 'Streaming', 'Internet', 'TV'],
    'Transport': ['Transport', 'Transportation', 'Fuel', 'Taxi', 'Ridesharing'],
  };

  int _selectedIndex = 1; // Expenses tab selected

  // Initialize to first day of current month to match dropdown item values
  final ValueNotifier<DateTime> _selectedMonthNotifier = ValueNotifier(
    DateTime(DateTime.now().year, DateTime.now().month, 1),
  );
  
  // Enhanced filtering and sorting
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'date'; // date, amount, category
  bool _sortAscending = false;
   String? _selectedQuickFilter;
   bool _showOnlyThisWeek = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Consumer will automatically load data via TransactionViewModel
  }

  @override
  void dispose() {
    _selectedMonthNotifier.dispose();
    _searchController.dispose();
    super.dispose();
  }

  BoxDecoration _premiumCardDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.surface,
          colorScheme.surfaceContainerHighest,
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.08),
          blurRadius: 28,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  bool _isDenseLayout(BuildContext context) {
    if (!kIsWeb) return false;
    final size = MediaQuery.of(context).size;
    return size.width >= 900;
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    final String route = NavigationService.routeForDrawerIndex(index);

    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
            'Expenses',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: Consumer<TransactionViewModel>(
          builder: (context, viewModel, child) {
            // Use viewModel's loading state instead of local loading state
            if (viewModel.isLoading && viewModel.transactions.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return Column(
              children: [
                // Enhanced Header with Search and Filters
                _buildEnhancedHeader(viewModel),
                Expanded(
                  child: ValueListenableBuilder<DateTime>(
                    valueListenable: _selectedMonthNotifier,
                    builder: (context, selectedMonth, child) {
                      return _buildContent(viewModel, selectedMonth);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTransactionScreen(expenseOnly: true),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          tooltip: 'Add Expense',
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ).animate()
        .scale(delay: const Duration(milliseconds: 800))
        .fadeIn(delay: const Duration(milliseconds: 800)),
    );
  }

  Widget _buildQuickFilterChip(String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedQuickFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedQuickFilter = isSelected ? null : label;
            _showOnlyThisWeek = false;
          });
        },
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary.withValues(alpha: 0.14),
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      ),
    );
  }

  List<DropdownMenuItem<DateTime>> _buildMonthDropdownItems(TransactionViewModel viewModel) {
    final List<DropdownMenuItem<DateTime>> items = [];

    // Collect months present in transactions
    final monthsSet = <DateTime>{};
    for (final transaction in viewModel.transactions) {
      monthsSet.add(DateTime(transaction.date.year, transaction.date.month, 1));
    }
    // Always include current month
    final nowStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    monthsSet.add(nowStart);

    // Fallback: if still empty (no expenses yet) generate last 12 months
    if (monthsSet.isEmpty) {
      for (int i = 0; i < 12; i++) {
        monthsSet.add(DateTime(nowStart.year, nowStart.month - i, 1));
      }
    }

    final monthsList = monthsSet.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending

    // Ensure selected month exists in the list
    if (monthsList.isNotEmpty && !monthsList.contains(_selectedMonthNotifier.value)) {
      _selectedMonthNotifier.value = monthsList.first;
    }

    for (final month in monthsList) {
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

  Widget _buildEnhancedHeader(TransactionViewModel viewModel) {
    final isDense = _isDenseLayout(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isDense ? 8 : 16,
      ),
      child: Column(
        children: [
          // Month Selector Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _premiumCardDecoration(colorScheme),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<DateTime>(
                    valueListenable: _selectedMonthNotifier,
                    builder: (context, selectedMonth, child) {
                      final items = _buildMonthDropdownItems(viewModel);
                      if (items.isEmpty) {
                        return const Text('No data', style: TextStyle(fontSize: 14));
                      }
                      return DropdownButton<DateTime>(
                        value: items.any((item) => item.value == selectedMonth) 
                            ? selectedMonth 
                            : items.first.value,
                        items: items,
                        onChanged: (DateTime? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedQuickFilter = null;
                              _selectedCategory = 'All';
                              _showOnlyThisWeek = false;
                            });
                            _selectedMonthNotifier.value = newValue;
                          }
                        },
                        isExpanded: true,
                        underline: const SizedBox(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isDense ? 8 : 12),
          // Search and Filter Row
          Row(
            children: [
              // Search Bar
              Expanded(
                flex: 2,
                child: Container(
                  decoration: _premiumCardDecoration(colorScheme),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: _premiumCardDecoration(colorScheme),
                child: Builder(
                  builder: (context) {
                    final items = _buildCategoryFilterItems(viewModel);
                    return DropdownButton<String>(
                      value: items.any((item) => item.value == _selectedCategory) 
                          ? _selectedCategory 
                          : 'All',
                      items: items,
                      onChanged: (value) => setState(() => _selectedCategory = value ?? 'All'),
                      underline: const SizedBox(),
                      icon: Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Sort Button
              Container(
                decoration: _premiumCardDecoration(colorScheme),
                child: IconButton(
                  onPressed: _showSortOptions,
                  icon: Icon(Icons.sort, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          SizedBox(height: isDense ? 6 : 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickFilterChip('Essentials'),
                  _buildQuickFilterChip('Lifestyle'),
                  _buildQuickFilterChip('Subscriptions'),
                  _buildQuickFilterChip('Transport'),
                ],
              ),
            ),
          ),
          if (!isDense) const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildHeaderActionChip(
                  theme: theme,
                  background: colorScheme.primaryContainer,
                  foreground: colorScheme.onPrimaryContainer,
                  icon: Icons.insights_rounded,
                  label: 'View Reports',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ReportsScreen(),
                      ),
                    );
                  },
                ),
                _buildHeaderActionChip(
                  theme: theme,
                  background: colorScheme.secondaryContainer,
                  foreground: colorScheme.onSecondaryContainer,
                  icon: Icons.auto_graph_rounded,
                  label: 'Optimize Spending',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ReportsScreen(
                          focusExpenseOptimization: true,
                        ),
                      ),
                    );
                  },
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

  List<DropdownMenuItem<String>> _buildCategoryFilterItems(TransactionViewModel viewModel) {
    final categories = <String>{'All'};
    for (final transaction in viewModel.transactions) {
      if (transaction.type == TransactionType.expense) {
        categories.add(transaction.category);
      }
    }
    
    // Ensure selected category exists in the list
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }
    
    return categories.map((category) => DropdownMenuItem(
      value: category,
      child: Text(category, style: const TextStyle(fontSize: 12)),
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
            ...['date', 'amount', 'category'].map((option) => ListTile(
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

  Widget _buildHeaderActionChip({
    required ThemeData theme,
    required Color background,
    required Color foreground,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TransactionViewModel viewModel, DateTime selectedMonth) {
    final isDense = _isDenseLayout(context);

    var expenses = viewModel.transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == selectedMonth.year &&
            t.date.month == selectedMonth.month)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      expenses = expenses.where((expense) =>
          expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          expense.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (expense.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      expenses = expenses.where((expense) => expense.category == _selectedCategory).toList();
    }

    if (_selectedQuickFilter != null) {
      final groupCategories = _quickFilterGroups[_selectedQuickFilter!] ?? const [];
      if (groupCategories.isNotEmpty) {
        expenses = expenses
            .where((expense) => groupCategories.contains(expense.category))
            .toList();
      }
    }

    if (_showOnlyThisWeek) {
      final today = DateTime.now();
      expenses = expenses.where((expense) {
        final diff = today.difference(expense.date).inDays;
        return diff >= 0 && diff <= 7;
      }).toList();
    }

    // Apply sorting
    expenses.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'amount':
          comparison = a.amount.abs().compareTo(b.amount.abs());
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    if (expenses.isEmpty) {
      return _buildEmptyState(selectedMonth);
    }

    const headerItemCount = 6;
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: isDense ? 8.0 : 16.0,
      ),
      itemCount: headerItemCount + expenses.length,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildEnhancedExpenseSummary(viewModel, selectedMonth, expenses);
        }
        if (index == 1) {
          return SizedBox(height: isDense ? 10 : 16);
        }
        if (index == 2) {
          return _buildExpenseStats(expenses);
        }
        if (index == 3) {
          return SizedBox(height: isDense ? 10 : 16);
        }
        if (index == 4) {
          return const SizedBox.shrink();
        }
        if (index == 5) {
          return const SizedBox.shrink();
        }

        final expense = expenses[index - headerItemCount];
        return RepaintBoundary(child: _buildEnhancedExpenseCard(expense));
      },
    );
  }

  Widget _buildEmptyState(DateTime selectedMonth) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDense = _isDenseLayout(context);

    return Center(
      child: Container(
        margin: EdgeInsets.all(isDense ? 24.0 : 32.0),
        padding: const EdgeInsets.all(40.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
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
                    Colors.grey.withValues(alpha: 0.1),
                    Colors.grey.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF4A4A4A)],
              ).createShader(bounds),
              child: Text(
                'No Expenses for ${DateFormat.yMMMM().format(selectedMonth)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No expenses found for the selected month. Try selecting a different month or add a new expense.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionScreen(expenseOnly: true),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Add First Expense',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate()
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildEnhancedExpenseSummary(TransactionViewModel viewModel, DateTime selectedMonth, List<Transaction> expenses) {
    // Using toCurrency() for Kenya-focused display

    // If no expenses for selected month, show "No data" message
    if (expenses.isEmpty) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDense = _isDenseLayout(context);

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isDense ? 4 : 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              'No expense data to display for this month.',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final double totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount.abs());
    final double averageExpense = totalExpenses / expenses.length;

    // Calculate category totals for selected month
    final Map<String, double> categoryTotals = {};
    for (var transaction in expenses) {
      categoryTotals.update(
        transaction.category,
        (total) => total + transaction.amount.abs(),
        ifAbsent: () => transaction.amount.abs(),
      );
    }

    String? topCategory;
    double topCategoryShare = 0;
    if (categoryTotals.isNotEmpty && totalExpenses > 0) {
      final topEntry = categoryTotals.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      topCategory = topEntry.key;
      topCategoryShare = (topEntry.value / totalExpenses) * 100;
    }

    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final dailyAverage = totalExpenses / daysInMonth;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDense = _isDenseLayout(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isDense ? 4 : 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
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
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withAlpha(30),
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
                    'Expense Summary',
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
            const SizedBox(height: 16),
            _ExpensesSparkline(
              expenses: expenses,
              selectedMonth: selectedMonth,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Expenses',
                  totalExpenses.toCurrency(),
                  const Color(0xFF6366F1),
                ),
                _buildSummaryItem(
                  'Average',
                  averageExpense.toCurrency(),
                  const Color(0xFF8B5CF6),
                ),
                _buildSummaryItem(
                  'Count',
                  '${expenses.length}',
                  const Color(0xFF6366F1),
                ),
              ],
            ),
            if (categoryTotals.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Category Breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoryDistribution(categoryTotals),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (topCategory != null)
                    Text(
                      'Top: $topCategory (${topCategoryShare.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    'Avg / day: ${dailyAverage.toCurrency()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
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

  Widget _buildCategoryDistribution(Map<String, double> categoryTotals) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    
    return Column(
      children: sortedCategories.take(5).map((entry) {
        final percentage = (entry.value.abs() / categoryTotals.values.fold(0.0, (sum, val) => sum + val.abs())) * 100;
        final categoryColor = CategoryIcons.getColorForCategory(entry.key);
        final categoryIcon = CategoryIcons.getIconForCategory(entry.key);
        final isSelected = _selectedCategory == entry.key;
        
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              if (_selectedCategory == entry.key) {
                _selectedCategory = 'All';
              } else {
                _selectedCategory = entry.key;
              }
              _selectedQuickFilter = null;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? categoryColor.withAlpha(20) : categoryColor.withAlpha(5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? categoryColor.withAlpha(80) : categoryColor.withAlpha(10),
                width: 1,
              ),
            ),
            child: Row(
            children: [
              // Category icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  categoryIcon,
                  size: 16,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.grey.shade200,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [
                            categoryColor,
                            categoryColor.withAlpha(80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: categoryColor,
                  ),
                ),
              ),
            ],
          ),
          )
        );
      }).toList(),
    );
  }

  Widget _buildExpenseStats(List<Transaction> expenses) {
    if (expenses.isEmpty) return const SizedBox.shrink();
    
    // Using toCurrency() for Kenya-focused display
    final today = DateTime.now();
    final thisWeek = expenses.where((e) => 
        today.difference(e.date).inDays <= 7).length;
    final largestExpense = expenses.reduce((a, b) => 
        a.amount.abs() > b.amount.abs() ? a : b);
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isThisWeekActive = _showOnlyThisWeek;
    final isCategoriesReset =
        _selectedCategory == 'All' && _selectedQuickFilter == null && !_showOnlyThisWeek;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: _premiumCardDecoration(colorScheme),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'This Week',
            '$thisWeek',
            Icons.calendar_today,
            const Color(0xFF6366F1),
            onTap: () {
              setState(() {
                _showOnlyThisWeek = !_showOnlyThisWeek;
              });
            },
            isActive: isThisWeekActive,
          ),
          _buildStatItem(
            'Largest',
            largestExpense.amount.abs().toCurrency(),
            Icons.trending_up,
            const Color(0xFF8B5CF6),
            onTap: () {
              setState(() {
                _sortBy = 'amount';
                _sortAscending = false;
              });
            },
          ),
          _buildStatItem(
            'Categories',
            '${expenses.map((e) => e.category).toSet().length}',
            Icons.category,
            const Color(0xFF6366F1),
            onTap: () {
              setState(() {
                _selectedCategory = 'All';
                _selectedQuickFilter = null;
                _showOnlyThisWeek = false;
              });
            },
            isActive: isCategoriesReset,
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 500))
      .slideX(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color,
      {VoidCallback? onTap, bool isActive = false}) {
    final effectiveColor = isActive ? color : color.withAlpha(230);
    final backgroundColor = isActive ? color.withAlpha(32) : color.withAlpha(10);

    final content = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: effectiveColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: effectiveColor,
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

    if (onTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: content,
      ),
    );
  }

  Widget _buildEnhancedExpenseCard(Transaction expense) {
    // Using toCurrency() for Kenya-focused display
    final dateFormat = DateFormat('MMM dd');
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDense = _isDenseLayout(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isDense ? 4 : 6,
      ),
      decoration: _premiumCardDecoration(colorScheme),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionFormScreen(
                  transaction: expense,
                  isExpense: true,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildExpenseIcon(expense),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(expense.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (expense.description != null && expense.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          expense.description!,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status indicator
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: expense.status == TransactionStatus.completed 
                                ? const Color(0xFF6366F1)
                                : expense.status == TransactionStatus.pending
                                    ? const Color(0xFF8B5CF6)
                                    : Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          expense.amount.abs().toCurrency(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF6366F1),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(expense.category).withValues(alpha: 0.15),
                            _getCategoryColor(expense.category).withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(expense.category).withValues(alpha: 0.1),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        expense.category,
                        style: TextStyle(
                          color: _getCategoryColor(expense.category),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Quick action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuickActionButton(
                          Icons.edit,
                          const Color(0xFF6366F1),
                          () => _editExpense(expense),
                        ),
                        const SizedBox(width: 3),
                        _buildQuickActionButton(
                          Icons.copy,
                          const Color(0xFF8B5CF6),
                          () => _duplicateExpense(expense),
                        ),
                        const SizedBox(width: 3),
                        _buildQuickActionButton(
                          Icons.delete,
                          Colors.red,
                          () => _deleteExpense(expense),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 400))
      .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildExpenseIcon(Transaction expense) {
    // Check if this expense might be a brand/subscription (check title for brand names)
    final title = expense.title.toLowerCase();
    final hasBrandName = title.contains('netflix') || 
                        title.contains('spotify') || 
                        title.contains('apple') ||
                        title.contains('youtube') ||
                        title.contains('starbucks') ||
                        title.contains('amazon') ||
                        title.contains('google') ||
                        title.contains('paypal');
    
    if (hasBrandName) {
      // Use brand logo for recognized brands
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CategoryIcons.getColorForCategory(expense.title).withValues(alpha: 0.15),
              CategoryIcons.getColorForCategory(expense.title).withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CategoryIcons.getColorForCategory(expense.title).withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CategoryIcons.getBrandCircleWidget(
          expense.title,
          size: 32.0,
        ),
      );
    } else {
      // Use category-based icon for regular expenses
      final iconData = CategoryIcons.getIconForCategory(expense.category);
      final iconColor = CategoryIcons.getColorForCategory(expense.category);
      
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              iconColor.withValues(alpha: 0.15),
              iconColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          iconData,
          color: iconColor,
          size: 20,
        ),
      );
    }
  }

  Widget _buildQuickActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 14, color: color),
        tooltip: icon == Icons.edit
            ? 'Edit'
            : icon == Icons.copy
                ? 'Duplicate'
                : icon == Icons.delete
                    ? 'Delete'
                    : null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  void _editExpense(Transaction expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          transaction: expense,
          isExpense: true,
        ),
      ),
    );
  }

  void _duplicateExpense(Transaction expense) async {
    final duplicatedExpense = Transaction(
      id: '', // Will be generated
      title: '${expense.title} (Copy)',
      amount: expense.amount,
      category: expense.category,
      date: DateTime.now(),
      type: expense.type,
      description: expense.description,
      status: TransactionStatus.pending,
      userId: expense.userId,
      accountId: expense.accountId,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          transaction: duplicatedExpense,
          isExpense: true,
        ),
      ),
    );
  }

  void _deleteExpense(Transaction expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final viewModel = Provider.of<TransactionViewModel>(context, listen: false);
              
              navigator.pop();
              
              if (expense.id != null) {
                await viewModel.deleteTransaction(expense.id!);
              }
              
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${expense.title} deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    if (AppTheme.categoryColors.containsKey(category)) {
      return AppTheme.categoryColors[category]!;
    }
    return AppTheme.categoryColors['Other']!;
  }
}

class _ExpensesSparkline extends StatefulWidget {
  final List<Transaction> expenses;
  final DateTime selectedMonth;

  const _ExpensesSparkline({
    required this.expenses,
    required this.selectedMonth,
  });

  @override
  State<_ExpensesSparkline> createState() => _ExpensesSparklineState();
}

class _ExpensesSparklineState extends State<_ExpensesSparkline> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final expenses = widget.expenses;
    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedMonth = widget.selectedMonth;
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final dailyTotals = List<double>.filled(daysInMonth, 0);

    for (final tx in expenses) {
      if (tx.date.year == selectedMonth.year && tx.date.month == selectedMonth.month) {
        final dayIndex = tx.date.day - 1;
        if (dayIndex >= 0 && dayIndex < daysInMonth) {
          dailyTotals[dayIndex] += tx.amount.abs();
        }
      }
    }

    final maxValue = dailyTotals.fold<double>(0, (prev, v) => math.max(prev, v));
    if (maxValue <= 0) {
      // Flat line when all values are zero
      return const SizedBox(height: 40);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const double sparklineHeight = 56.0;

    return SizedBox(
      height: sparklineHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface.withValues(alpha: 0.9),
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return MouseRegion(
                onHover: (event) {
                  if (width <= 0 || dailyTotals.isEmpty) return;
                  final dxStep = dailyTotals.length == 1
                      ? width
                      : width / (dailyTotals.length - 1);
                  if (dxStep <= 0) return;
                  final rawIndex = event.localPosition.dx / dxStep;
                  final index = rawIndex.round().clamp(0, dailyTotals.length - 1);
                  if (_hoveredIndex != index) {
                    setState(() => _hoveredIndex = index);
                  }
                },
                onExit: (_) {
                  if (_hoveredIndex != null) {
                    setState(() => _hoveredIndex = null);
                  }
                },
                child: CustomPaint(
                  painter: _ExpensesSparklinePainter(
                    dailyTotals: dailyTotals,
                    maxValue: maxValue,
                    lineColor: colorScheme.error,
                    hoveredIndex: kIsWeb ? _hoveredIndex : null,
                    firstDayOfMonth: DateTime(
                      selectedMonth.year,
                      selectedMonth.month,
                      1,
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExpensesSparklinePainter extends CustomPainter {
  final List<double> dailyTotals;
  final double maxValue;
  final Color lineColor;
  final int? hoveredIndex;
  final DateTime firstDayOfMonth;

  _ExpensesSparklinePainter({
    required this.dailyTotals,
    required this.maxValue,
    required this.lineColor,
    required this.hoveredIndex,
    required this.firstDayOfMonth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyTotals.isEmpty || maxValue <= 0) return;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    final dxStep = dailyTotals.length == 1
        ? 0.0
        : size.width / (dailyTotals.length - 1);

    double normalize(double v) => v / maxValue;

    for (int i = 0; i < dailyTotals.length; i++) {
      final x = dxStep * i;
      final value = normalize(dailyTotals[i]);
      final y = size.height - (value * size.height * 0.8);

      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
        fillPath.moveTo(point.dx, size.height);
        fillPath.lineTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withValues(alpha: 0.18),
          lineColor.withValues(alpha: 0.01),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    if (hoveredIndex != null &&
        hoveredIndex! >= 0 &&
        hoveredIndex! < points.length) {
      final index = hoveredIndex!;
      final hoverPoint = points[index];
      final hoverAmount = dailyTotals[index];
      final hoverDate = firstDayOfMonth.add(Duration(days: index));

      // Marker circle
      final markerPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      final markerStrokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(hoverPoint, 3.5, markerPaint);
      canvas.drawCircle(hoverPoint, 3.5, markerStrokePaint);

      // Tooltip label
      final label = '${DateFormat.MMMd().format(hoverDate)} • ${hoverAmount.toCurrency()}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        maxLines: 1,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      const double padding = 6.0;
      final tooltipWidth = textPainter.width + padding * 2;
      final tooltipHeight = textPainter.height + padding * 2;

      double tooltipX = hoverPoint.dx - tooltipWidth / 2;
      double tooltipY = hoverPoint.dy - tooltipHeight - 8;

      // Keep tooltip within bounds
      if (tooltipX < 4) tooltipX = 4;
      if (tooltipX + tooltipWidth > size.width - 4) {
        tooltipX = size.width - tooltipWidth - 4;
      }
      if (tooltipY < 4) {
        tooltipY = hoverPoint.dy + 8;
      }

      final tooltipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
        const Radius.circular(6),
      );

      final tooltipPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.78);

      canvas.drawRRect(tooltipRect, tooltipPaint);
      textPainter.paint(
        canvas,
        Offset(tooltipRect.left + padding, tooltipRect.top + padding),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExpensesSparklinePainter oldDelegate) {
    if (oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.firstDayOfMonth != firstDayOfMonth) {
      return true;
    }
    if (oldDelegate.dailyTotals.length != dailyTotals.length) {
      return true;
    }
    for (int i = 0; i < dailyTotals.length; i++) {
      if (oldDelegate.dailyTotals[i] != dailyTotals[i]) {
        return true;
      }
    }
    return false;
  }
}
