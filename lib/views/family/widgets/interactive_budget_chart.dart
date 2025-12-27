import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../models/family_budget_model.dart';
import '../../../themes/app_theme.dart';

class InteractiveBudgetChart extends StatefulWidget {
  const InteractiveBudgetChart({super.key});

  @override
  State<InteractiveBudgetChart> createState() => _InteractiveBudgetChartState();
}

class _InteractiveBudgetChartState extends State<InteractiveBudgetChart> {
  int? _selectedCategoryIndex;
  bool _showDetailView = false;
  
  @override
  Widget build(BuildContext context) {
    // In a real app, this would come from the ViewModel
    final budgetData = FamilyBudgetSampleData.getSampleData();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _showDetailView && _selectedCategoryIndex != null
              ? _buildDetailView(budgetData.categories[_selectedCategoryIndex!])
              : _buildOverview(budgetData),
          const SizedBox(height: 24),
          _buildBudgetSummary(context, budgetData),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showDetailView && _selectedCategoryIndex != null
                  ? FamilyBudgetSampleData.getSampleData()
                      .categories[_selectedCategoryIndex!].name
                  : 'Family Budget Allocation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 4),
            Text(
              'April 2025',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                  ),
            ).animate()
              .fadeIn(
                  duration: const Duration(milliseconds: 400),
                  delay: const Duration(milliseconds: 100))
              .slideX(begin: -0.1, end: 0),
          ],
        ),
        Row(
          children: [
            if (_showDetailView)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showDetailView = false;
                  });
                },
                tooltip: 'Back to overview',
                color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
              ).animate()
                .fadeIn(duration: const Duration(milliseconds: 400))
                .slideX(begin: 0.1, end: 0),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showChartOptions(context);
              },
              color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideX(begin: 0.1, end: 0),
          ],
        ),
      ],
    );
  }

  Widget _buildOverview(FamilyBudgetData budgetData) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _buildPieSections(budgetData),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                    final index = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                    setState(() {
                      _selectedCategoryIndex = index;
                      _showDetailView = true;
                    });
                  }
                },
              ),
            ),
          ),
        ).animate()
          .fadeIn(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200))
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: List.generate(
            budgetData.categories.length,
            (index) => _buildLegendItem(
              budgetData.categories[index].name,
              budgetData.categories[index].color,
              index,
              100 * index,
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                  _showDetailView = true;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(FamilyBudgetData budgetData) {
    return List.generate(
      budgetData.categories.length,
      (index) {
        final category = budgetData.categories[index];
        final isTouched = index == _selectedCategoryIndex;
        final radius = isTouched ? 110.0 : 100.0;
        
        return PieChartSectionData(
          value: category.amount,
          title: '${(category.amount / budgetData.totalBudget * 100).toStringAsFixed(0)}%',
          color: category.color,
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: isTouched
              ? Icon(
                  category.icon,
                  size: 20,
                  color: Colors.white,
                )
              : null,
          badgePositionPercentageOffset: 1.1,
        );
      },
    );
  }

  Widget _buildDetailView(BudgetCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category.color.withAlpha((255 * 0.2).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category.name} Details',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(category.percentSpent).toStringAsFixed(1)}% of budget used',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
        
        const SizedBox(height: 20),
        
        // Progress bar for overall category
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget: \$${category.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Spent: \$${category.spent.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: category.spent > category.amount
                        ? AppTheme.errorColor
                        : AppTheme.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: category.percentSpent / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  category.spent > category.amount
                      ? AppTheme.errorColor
                      : category.color,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
            ),
        
        const SizedBox(height: 24),
        
        // Subcategories list
        ...List.generate(
          category.subcategories.length,
          (index) => _buildSubcategoryItem(
            category.subcategories[index],
            category.color,
            index,
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategoryItem(
      BudgetSubcategory subcategory, Color parentColor, int index) {
    final isOverBudget = subcategory.spent > subcategory.amount;
    final progressColor = isOverBudget ? AppTheme.errorColor : parentColor;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                subcategory.icon,
                size: 16,
                color: parentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subcategory.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '\$${subcategory.spent.toStringAsFixed(0)} / \$${subcategory.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isOverBudget ? AppTheme.errorColor : AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: subcategory.percentSpent / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: 150 + (index * 50)),
        );
  }

  Widget _buildLegendItem(
      String label, Color color, int index, int delayMs,
      {required VoidCallback onTap}) {
    final isSelected = index == _selectedCategoryIndex;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha((255 * 0.1).round()) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 400 + delayMs),
        );
  }

  Widget _buildBudgetSummary(BuildContext context, FamilyBudgetData budgetData) {
    final percentUsed = budgetData.percentSpent;
    final isOverBudget = budgetData.totalSpent > budgetData.totalBudget;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Budget', '\$${budgetData.totalBudget.toStringAsFixed(0)}',
                  AppTheme.accentColor),
              _buildSummaryItem('Spent', '\$${budgetData.totalSpent.toStringAsFixed(0)}',
                  isOverBudget ? AppTheme.errorColor : AppTheme.expenseColor),
              _buildSummaryItem('Remaining', '\$${budgetData.remaining.toStringAsFixed(0)}',
                  isOverBudget ? AppTheme.errorColor : AppTheme.incomeColor),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget Usage',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${percentUsed.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOverBudget
                          ? AppTheme.errorColor
                          : percentUsed > 80
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentUsed / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget
                        ? AppTheme.errorColor
                        : percentUsed > 80
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 600))
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _showChartOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chart Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.pie_chart),
                title: const Text('Pie Chart'),
                onTap: () {
                  Navigator.pop(context);
                  // Would switch to pie chart view
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Bar Chart'),
                onTap: () {
                  Navigator.pop(context);
                  // Would switch to bar chart view
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_view),
                title: const Text('Treemap'),
                onTap: () {
                  Navigator.pop(context);
                  // Would switch to treemap view
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Change Theme'),
                onTap: () {
                  Navigator.pop(context);
                  // Would show theme options
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
