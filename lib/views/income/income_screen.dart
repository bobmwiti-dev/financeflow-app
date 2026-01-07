import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_extensions.dart';

import '../../viewmodels/income_viewmodel.dart';
import '../../models/income_source_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import '../../services/navigation_service.dart';
import '../../utils/category_icons.dart';
import 'income_form_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  int _selectedIndex = 7; // Income tab selected
  bool _isLoading = false;
  
  final ValueNotifier<DateTime> _selectedMonthNotifier = ValueNotifier(
    DateTime(DateTime.now().year, DateTime.now().month, 1),
  );
  
  // Enhanced filtering and sorting
  String _searchQuery = '';
  String _selectedType = 'All';
  String _sortBy = 'date'; // date, amount, name
  bool _sortAscending = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIncomeSources();
  }

  @override
  void dispose() {
    _selectedMonthNotifier.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIncomeSources() async {
    setState(() => _isLoading = true);

    try {
      final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
      // Update view model's selected month before loading
      incomeViewModel.setSelectedMonth(_selectedMonthNotifier.value);
      await incomeViewModel.loadIncomeSources();
    } catch (e) {
      if (e.toString().contains('index')) {
        // Handle index creation error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Index creation in progress...'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          // Try again after a short delay
          Future.delayed(const Duration(seconds: 5), _loadIncomeSources);
        }
      } else {
        // Handle other errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading income sources: $e')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFD1FAE5)],
          ).createShader(bounds),
          child: const Text(
            'Income',
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
      body: Consumer<IncomeViewModel>(
        builder: (context, viewModel, child) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Enhanced Header with Search and Filters
              _buildEnhancedHeader(viewModel),
              Expanded(
                child: _buildContent(viewModel),
              ),
            ],
          );
        },
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IncomeFormScreen(),
              ),
            );
            if (result == true) {
              _loadIncomeSources();
            }
          },
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          tooltip: 'Add Income Source',
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ).animate()
        .scale(delay: const Duration(milliseconds: 800))
        .fadeIn(delay: const Duration(milliseconds: 800)),
    );
  }

  Widget _buildEnhancedHeader(IncomeViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month Selector Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                            _selectedMonthNotifier.value = newValue;
                            _loadIncomeSources();
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
                          color: colorScheme.shadow.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search income sources...',
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
                // Type Filter
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Builder(
                    builder: (context) {
                      final items = _buildTypeFilterItems(viewModel);
                      return DropdownButton<String>(
                        value: items.any((item) => item.value == _selectedType) 
                            ? _selectedType 
                            : 'All',
                        items: items,
                        onChanged: (value) => setState(() => _selectedType = value ?? 'All'),
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

  List<DropdownMenuItem<DateTime>> _buildMonthDropdownItems(IncomeViewModel viewModel) {
    final List<DropdownMenuItem<DateTime>> items = [];

    // Collect months present in income sources
    final monthsSet = <DateTime>{};
    for (final src in viewModel.incomeSources) {
      monthsSet.add(DateTime(src.date.year, src.date.month, 1));
    }
    // Always include current month
    final nowStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    monthsSet.add(nowStart);

    // Fallback: if still empty (no income yet) generate last 12 months
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

  List<DropdownMenuItem<String>> _buildTypeFilterItems(IncomeViewModel viewModel) {
    final types = <String>{'All', 'Recurring'};
    for (final source in viewModel.incomeSources) {
      types.add(source.type);
    }
    
    // Ensure selected type exists in the list
    if (!types.contains(_selectedType)) {
      _selectedType = 'All';
    }
    
    return types.map((type) => DropdownMenuItem(
      value: type,
      child: Text(type, style: const TextStyle(fontSize: 12)),
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
            ...['date', 'amount', 'name'].map((option) => ListTile(
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

  Widget _buildContent(IncomeViewModel viewModel) {
    var incomeSources = viewModel.getFilteredIncomeSources();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      incomeSources = incomeSources.where((source) =>
          source.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          source.type.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply type filter
    List<IncomeSource> filteredSources;
    if (_selectedType == 'All') {
      filteredSources = incomeSources;
    } else if (_selectedType == 'Recurring') {
      filteredSources = incomeSources.where((source) => source.isRecurring).toList();
    } else {
      filteredSources = incomeSources.where((source) => source.type == _selectedType).toList();
    }

    // Apply sorting
    filteredSources.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    if (filteredSources.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnhancedIncomeSummary(viewModel, filteredSources),
            const SizedBox(height: 16),
            _buildIncomeStats(filteredSources),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedType == 'All' 
                      ? 'All Income Sources' 
                      : _selectedType == 'Recurring'
                          ? 'Recurring Income'
                          : '$_selectedType Income',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${filteredSources.length} ${filteredSources.length == 1 ? 'source' : 'sources'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...filteredSources.map((source) => _buildEnhancedIncomeCard(source)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32.0),
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
                    const Color(0xFF10B981).withValues(alpha: 0.1),
                    const Color(0xFF10B981).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF4A4A4A)],
              ).createShader(bounds),
              child: Text(
                _selectedType == 'All' 
                    ? 'No income sources added yet' 
                    : _selectedType == 'Recurring'
                        ? 'No recurring income sources'
                        : 'No $_selectedType income sources',
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
              'Track your income by adding your income sources',
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
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IncomeFormScreen(),
                    ),
                  );
                  
                  if (result == true) {
                    _loadIncomeSources();
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Add Income Source',
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
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildEnhancedIncomeSummary(IncomeViewModel viewModel, List<IncomeSource> incomeSources) {
    // Using toKenyaDualCurrency() for Kenya market
    final totalIncome = viewModel.getTotalIncome();
    final distribution = viewModel.getIncomeDistribution();

    String? topType;
    double topShare = 0;
    if (distribution.isNotEmpty && totalIncome > 0) {
      final topEntry = distribution.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      topType = topEntry.key;
      topShare = (topEntry.value / totalIncome) * 100;
    }

    final recurringIncomeTotal = viewModel
        .getRecurringIncome()
        .fold<double>(0.0, (sum, s) => sum + s.amount);

    final recurringShare = totalIncome > 0
        ? (recurringIncomeTotal / totalIncome) * 100
        : 0.0;

    final selectedMonth = viewModel.selectedMonth ?? DateTime.now();
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final dailyAverage = daysInMonth > 0 ? totalIncome / daysInMonth : 0.0;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                    'Income Summary',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Income',
                  totalIncome.toKenyaDualCurrency(),
                  AppTheme.incomeColor,
                ),
                _buildSummaryItem(
                  'Average',
                  incomeSources.isNotEmpty 
                      ? (totalIncome / incomeSources.length).toKenyaDualCurrency()
                      : 0.0.toKenyaDualCurrency(),
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Count',
                  '${incomeSources.length}',
                  AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Income Distribution',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildIncomeDistribution(viewModel),
            if (distribution.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (topType != null)
                        Text(
                          'Top: $topType (${topShare.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        'Avg / day: ${dailyAverage.toKenyaDualCurrency()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (recurringIncomeTotal > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Recurring: ${recurringIncomeTotal.toKenyaDualCurrency()} (${recurringShare.toStringAsFixed(1)}% of total)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w400,
                        ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
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

  Widget _buildIncomeDistribution(IncomeViewModel viewModel) {
    final distribution = viewModel.getIncomeDistribution();
    final totalIncome = viewModel.getTotalIncome();
    
    if (distribution.isEmpty || totalIncome == 0) {
      return const Text(
        'No income data to display',
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    return Column(
      children: distribution.entries.map((entry) {
        final percentage = (entry.value / totalIncome) * 100;
        final typeColor = _getIncomeTypeColor(entry.key);
        final isSelected = _selectedType == entry.key;
        
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedType = _selectedType == entry.key ? 'All' : entry.key;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? typeColor.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? typeColor.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: entry.value / totalIncome,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIncomeStats(List<IncomeSource> incomeSources) {
    if (incomeSources.isEmpty) return const SizedBox.shrink();
    
    // Using toKenyaDualCurrency() for Kenya market
    final today = DateTime.now();
    final thisMonth = incomeSources.where((s) => 
        s.date.year == today.year && s.date.month == today.month).length;
    final largestIncome = incomeSources.isNotEmpty 
        ? incomeSources.reduce((a, b) => a.amount > b.amount ? a : b)
        : null;
    final recurringCount = incomeSources.where((s) => s.isRecurring).length;
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRecurringActive = _selectedType == 'Recurring';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'This Month',
            '$thisMonth',
            Icons.calendar_today,
            Colors.green,
          ),
          _buildStatItem(
            'Largest',
            largestIncome != null 
                ? largestIncome.amount.toKenyaDualCurrency()
                : 0.0.toKenyaDualCurrency(),
            Icons.trending_up,
            Colors.blue,
            onTap: () {
              setState(() {
                _sortBy = 'amount';
                _sortAscending = false;
              });
            },
          ),
          _buildStatItem(
            'Recurring',
            '$recurringCount',
            Icons.repeat,
            Colors.purple,
            onTap: () {
              setState(() {
                _selectedType = _selectedType == 'Recurring' ? 'All' : 'Recurring';
              });
            },
            isActive: isRecurringActive,
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
    final backgroundColor = isActive ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.08);

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

  Widget _buildEnhancedIncomeCard(IncomeSource source) {
    // Using toKenyaDualCurrency() for Kenya market
    final dateFormat = DateFormat('MMM dd');
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IncomeFormScreen(incomeSource: source),
              ),
            );
            
            if (result == true || result == 'deleted') {
              _loadIncomeSources();
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.15),
                        const Color(0xFF10B981).withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CategoryIcons.getBrandCircleWidget(
                    source.name,
                    size: 40.0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateFormat.format(source.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (source.isRecurring) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Recurring',
                            style: TextStyle(
                              color: Colors.purple[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          source.amount.toKenyaDualCurrency(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppTheme.incomeColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getIncomeTypeColor(source.type).withValues(alpha: 0.15),
                            _getIncomeTypeColor(source.type).withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getIncomeTypeColor(source.type).withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        source.type,
                        style: TextStyle(
                          color: _getIncomeTypeColor(source.type),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quick action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuickActionButton(
                          Icons.edit,
                          Colors.blue,
                          () => _editIncome(source),
                        ),
                        const SizedBox(width: 4),
                        _buildQuickActionButton(
                          Icons.copy,
                          Colors.green,
                          () => _duplicateIncome(source),
                        ),
                        const SizedBox(width: 4),
                        _buildQuickActionButton(
                          Icons.delete,
                          Colors.red,
                          () => _deleteIncome(source),
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

  void _editIncome(IncomeSource source) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomeFormScreen(incomeSource: source),
      ),
    );
    
    if (result == true || result == 'deleted') {
      _loadIncomeSources();
    }
  }

  void _duplicateIncome(IncomeSource source) async {
    final duplicatedSource = IncomeSource(
      id: '', // Will be generated
      name: '${source.name} (Copy)',
      amount: source.amount,
      type: source.type,
      date: DateTime.now(),
      accountId: source.accountId,
      isRecurring: source.isRecurring,
      frequency: source.frequency,
      notes: source.notes,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncomeFormScreen(incomeSource: duplicatedSource),
      ),
    );
    
    if (result == true) {
      _loadIncomeSources();
    }
  }

  void _deleteIncome(IncomeSource source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income Source'),
        content: Text('Are you sure you want to delete "${source.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
              
              navigator.pop();
              
              if (source.id != null) {
                await incomeViewModel.deleteIncomeSource(source.id!);
              }
              
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${source.name} deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
                _loadIncomeSources();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getIncomeTypeColor(String type) {
    switch (type) {
      case 'Salary':
        return Colors.blue;
      case 'Side Hustle':
        return Colors.purple;
      case 'Loan':
        return Colors.orange;
      case 'Grant':
        return Colors.teal;
      case 'Family Contribution':
        return Colors.pink;
      case 'Business':
        return Colors.indigo;
      case 'Dividend':
        return Colors.green;
      case 'Investment':
        return Colors.amber.shade700;
      case 'Gift':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
