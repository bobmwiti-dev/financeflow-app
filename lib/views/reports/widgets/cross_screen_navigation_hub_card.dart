import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../models/action_item_model.dart';
import '../../../services/action_items_service.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../viewmodels/income_viewmodel.dart';
import '../../../viewmodels/budget_viewmodel.dart';
import '../../../viewmodels/goal_viewmodel.dart';
import '../../../viewmodels/bill_viewmodel.dart';
import 'report_card.dart';

class CrossScreenNavigationHubCard extends StatefulWidget {
  const CrossScreenNavigationHubCard({super.key});

  @override
  State<CrossScreenNavigationHubCard> createState() => _CrossScreenNavigationHubCardState();
}

class _CrossScreenNavigationHubCardState extends State<CrossScreenNavigationHubCard>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  List<NavigationShortcut> _shortcuts = [];
  bool _isLoading = true;
  NavigationShortcutType _selectedType = NavigationShortcutType.screen;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _generateNavigationShortcuts();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  void _generateNavigationShortcuts() async {
    setState(() {
      _isLoading = true;
    });

    _loadingController.forward();

    // Simulate loading time for better UX
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    try {
      final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
      final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
      final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
      final goalViewModel = Provider.of<GoalViewModel>(context, listen: false);
      final billViewModel = Provider.of<BillViewModel>(context, listen: false);

      final shortcuts = ActionItemsService.generateNavigationShortcuts(
        allTransactions: transactionViewModel.allTransactions,
        allIncomeSources: incomeViewModel.incomeSources,
        allBudgets: budgetViewModel.budgets,
        allGoals: goalViewModel.goals,
        allBills: billViewModel.bills,
      );

      if (mounted) {
        setState(() {
          _shortcuts = shortcuts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _shortcuts = [];
          _isLoading = false;
        });
      }
    }
  }

  List<NavigationShortcut> get _filteredShortcuts {
    return _shortcuts.where((shortcut) => shortcut.type == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      title: '🧭 Smart Navigation Hub',
      child: Column(
        children: [
          // Navigation Hub Header
          _buildNavigationHeader(),
          
          const SizedBox(height: 16),
          
          if (_isLoading) ...[
            _buildLoadingState(),
          ] else if (_shortcuts.isEmpty) ...[
            _buildEmptyState(),
          ] else ...[
            // Navigation Type Tabs
            _buildNavigationTypeTabs(),
            const SizedBox(height: 16),
            
            // Navigation Grid
            _buildNavigationGrid(),
          ],
        ],
      ),
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildNavigationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _loadingController.value * 2 * 3.14159,
                  child: Icon(
                    _isLoading ? Icons.refresh : Icons.dashboard,
                    color: Colors.indigo[700],
                    size: 24,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoading ? 'Loading Navigation Options...' : 'Quick Access Dashboard',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLoading 
                      ? 'Preparing smart shortcuts to your features'
                      : 'Jump to any screen with contextual information',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_shortcuts.length} Shortcuts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.indigo.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: _loadingController.value,
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.explore,
                        color: Colors.indigo[600],
                        size: 24,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Preparing Navigation Hub',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Navigation Options Available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTypeTabs() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: NavigationShortcutType.values.map((type) {
          final isSelected = _selectedType == type;
          final count = _shortcuts.where((s) => s.type == type).length;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = type;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.indigo.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getTypeIcon(type),
                    size: 16,
                    color: isSelected ? Colors.white : Colors.indigo,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getTypeLabel(type),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.indigo,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.indigo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavigationGrid() {
    final filteredShortcuts = _filteredShortcuts;
    
    if (filteredShortcuts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_getTypeLabel(_selectedType).toLowerCase()} shortcuts available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final rowCount = (filteredShortcuts.length / 2).ceil();
    final gridHeight = (rowCount * 150.0 + ((rowCount - 1) * 12.0)).clamp(150.0, 520.0);

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredShortcuts.length,
        itemBuilder: (context, index) {
          final shortcut = filteredShortcuts[index];
          return _buildNavigationTile(shortcut, index);
        },
      ),
    );
  }

  Widget _buildNavigationTile(NavigationShortcut shortcut, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: shortcut.color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: shortcut.color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: shortcut.isEnabled ? () => _handleNavigationTap(shortcut) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: shortcut.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        shortcut.icon,
                        color: shortcut.color,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    if (shortcut.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: shortcut.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          shortcut.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Title
                Text(
                  shortcut.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Description
                Expanded(
                  child: Text(
                    shortcut.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Action indicator
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: shortcut.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 11,
                        color: shortcut.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 100))
      .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.easeOutCubic);
  }

  void _handleNavigationTap(NavigationShortcut shortcut) {
    // Navigate to the target route with arguments
    if (shortcut.arguments.isNotEmpty) {
      Navigator.of(context).pushNamed(shortcut.route, arguments: shortcut.arguments);
    } else {
      Navigator.of(context).pushNamed(shortcut.route);
    }
  }

  IconData _getTypeIcon(NavigationShortcutType type) {
    switch (type) {
      case NavigationShortcutType.screen:
        return Icons.screen_share;
      case NavigationShortcutType.feature:
        return Icons.extension;
      case NavigationShortcutType.analysis:
        return Icons.analytics;
      case NavigationShortcutType.management:
        return Icons.settings;
    }
  }

  String _getTypeLabel(NavigationShortcutType type) {
    switch (type) {
      case NavigationShortcutType.screen:
        return 'Screens';
      case NavigationShortcutType.feature:
        return 'Features';
      case NavigationShortcutType.analysis:
        return 'Analysis';
      case NavigationShortcutType.management:
        return 'Management';
    }
  }
}
