import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../models/action_item_model.dart';
import '../../../models/time_period_model.dart';
import '../../../services/action_items_service.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../viewmodels/income_viewmodel.dart';
import '../../../viewmodels/budget_viewmodel.dart';
import '../../../viewmodels/goal_viewmodel.dart';
import '../../../viewmodels/bill_viewmodel.dart';
import 'report_card.dart';

class QuickActionItemsCard extends StatefulWidget {
  final TimePeriod selectedPeriod;

  const QuickActionItemsCard({
    super.key,
    required this.selectedPeriod,
  });

  @override
  State<QuickActionItemsCard> createState() => _QuickActionItemsCardState();
}

class _QuickActionItemsCardState extends State<QuickActionItemsCard>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  List<ActionItem> _actionItems = [];
  List<QuickInsight> _quickInsights = [];
  bool _isLoading = true;
  int _selectedPriorityFilter = -1; // -1 = all, 0-3 = specific priority

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    
    _generateActionItems();
  }

  @override
  void didUpdateWidget(QuickActionItemsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod) {
      _generateActionItems();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  void _generateActionItems() async {
    setState(() {
      _isLoading = true;
    });

    _loadingController.reset();
    _loadingController.forward();

    // Simulate analysis time for better UX
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    try {
      final transactionViewModel = Provider.of<TransactionViewModel>(context, listen: false);
      final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
      final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
      final goalViewModel = Provider.of<GoalViewModel>(context, listen: false);
      final billViewModel = Provider.of<BillViewModel>(context, listen: false);

      final actionItems = ActionItemsService.generateActionItems(
        allTransactions: transactionViewModel.allTransactions,
        allIncomeSources: incomeViewModel.incomeSources,
        allBudgets: budgetViewModel.budgets,
        allGoals: goalViewModel.goals,
        allBills: billViewModel.bills,
        currentPeriod: widget.selectedPeriod,
      );

      final quickInsights = ActionItemsService.generateQuickInsights(
        allTransactions: transactionViewModel.allTransactions,
        allIncomeSources: incomeViewModel.incomeSources,
        allBudgets: budgetViewModel.budgets,
        allGoals: goalViewModel.goals,
        currentPeriod: widget.selectedPeriod,
      );

      if (mounted) {
        setState(() {
          _actionItems = actionItems;
          _quickInsights = quickInsights;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _actionItems = [];
          _quickInsights = [];
          _isLoading = false;
        });
      }
    }
  }

  List<ActionItem> get _filteredActionItems {
    if (_selectedPriorityFilter == -1) return _actionItems;
    final targetPriority = ActionItemPriority.values[_selectedPriorityFilter];
    return _actionItems.where((item) => item.priority == targetPriority).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      title: '⚡ Quick Action Items - ${widget.selectedPeriod.displayName}',
      child: Column(
        children: [
          // Quick Insights Summary
          if (!_isLoading && _quickInsights.isNotEmpty) ...[
            _buildQuickInsightsSummary(),
            const SizedBox(height: 16),
          ],
          
          // Action Items Header
          _buildActionItemsHeader(),
          
          const SizedBox(height: 16),
          
          if (_isLoading) ...[
            _buildLoadingState(),
          ] else if (_actionItems.isEmpty) ...[
            _buildNoActionItemsState(),
          ] else ...[
            // Priority Filter Tabs
            _buildPriorityFilter(),
            const SizedBox(height: 16),
            
            // Action Items List
            _buildActionItemsList(),
          ],
        ],
      ),
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildQuickInsightsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.05),
            Colors.purple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickInsights.length,
              itemBuilder: (context, index) {
                final insight = _quickInsights[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: insight.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            insight.icon,
                            color: insight.color,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              insight.title,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insight.value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: insight.color,
                        ),
                      ),
                      Text(
                        insight.description,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItemsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_loadingAnimation.value * 0.1),
                  child: Icon(
                    _isLoading ? Icons.hourglass_empty : Icons.bolt,
                    color: Colors.orange[700],
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
                  _isLoading ? 'Analyzing Your Financial Data...' : 'Action Items Ready',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLoading 
                      ? 'Generating personalized recommendations'
                      : '${_actionItems.length} actionable recommendations',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!_isLoading && _actionItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getHighestPriorityColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_actionItems.where((item) => item.priority.index >= 2).length} High Priority',
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
      height: 200,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
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
                        value: _loadingAnimation.value,
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.psychology,
                        color: Colors.orange[600],
                        size: 32,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Generating Smart Recommendations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing budgets, goals, bills, and spending patterns...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoActionItemsState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: Colors.green[600],
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All Good!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No urgent action items detected. Your finances are on track for ${widget.selectedPeriod.displayName}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_up,
                  size: 16,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Keep up the great work!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', -1, _actionItems.length),
          const SizedBox(width: 8),
          ...ActionItemPriority.values.asMap().entries.map((entry) {
            final index = entry.key;
            final priority = entry.value;
            final count = _actionItems.where((item) => item.priority == priority).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                priority.name.toUpperCase(),
                index,
                count,
                color: _getPriorityColor(priority),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, int count, {Color? color}) {
    final isSelected = _selectedPriorityFilter == index;
    final chipColor = color ?? Colors.orange;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriorityFilter = isSelected ? -1 : index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: chipColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : chipColor,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : chipColor,
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
  }

  Widget _buildActionItemsList() {
    final filteredItems = _filteredActionItems;
    
    if (filteredItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.filter_list_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No action items match the selected filter',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...filteredItems.take(5).map((item) => 
          _buildActionItemTile(item)),
        
        if (filteredItems.length > 5)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.more_horiz,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredItems.length - 5} more action items available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionItemTile(ActionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleActionItemTap(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 14),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Priority
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.priorityLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Description
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Action Button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: item.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.actionText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (item.amount != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              '\$${item.amount!.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: item.color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: Duration(milliseconds: _filteredActionItems.indexOf(item) * 100))
      .slideX(begin: 0.2, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  void _handleActionItemTap(ActionItem item) {
    // Navigate to the target route with arguments
    if (item.routeArguments.isNotEmpty) {
      Navigator.of(context).pushNamed(item.targetRoute, arguments: item.routeArguments);
    } else {
      Navigator.of(context).pushNamed(item.targetRoute);
    }
  }

  Color _getHighestPriorityColor() {
    if (_actionItems.isEmpty) return Colors.green;
    
    final highestPriority = _actionItems
        .map((item) => item.priority.index)
        .reduce((a, b) => a > b ? a : b);
    
    return _getPriorityColor(ActionItemPriority.values[highestPriority]);
  }

  Color _getPriorityColor(ActionItemPriority priority) {
    switch (priority) {
      case ActionItemPriority.low:
        return Colors.blue;
      case ActionItemPriority.medium:
        return Colors.orange;
      case ActionItemPriority.high:
        return Colors.red;
      case ActionItemPriority.urgent:
        return Colors.purple;
    }
  }
}
