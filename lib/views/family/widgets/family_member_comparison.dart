import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../models/family_budget_model.dart';
import '../../../themes/app_theme.dart';

class FamilyMemberComparison extends StatefulWidget {
  const FamilyMemberComparison({super.key});

  @override
  State<FamilyMemberComparison> createState() => _FamilyMemberComparisonState();
}

class _FamilyMemberComparisonState extends State<FamilyMemberComparison> {
  String _selectedView = 'Spending';
  int _selectedMemberIndex = -1;
  
  final List<String> _viewOptions = ['Spending', 'Budget Usage', 'Categories'];

  @override
  Widget build(BuildContext context) {
    // In a real app, this would come from the ViewModel
    final members = FamilyBudgetSampleData.getSampleData().members;
    
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
          _buildHeader(),
          const SizedBox(height: 24),
          _buildViewSelector(),
          const SizedBox(height: 24),
          _buildComparisonChart(members),
          const SizedBox(height: 24),
          _buildMembersList(members),
          if (_selectedMemberIndex != -1) ...[
            const SizedBox(height: 24),
            _buildMemberDetails(members[_selectedMemberIndex]),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Member Comparison',
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
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {},
          tooltip: 'Share comparison',
          color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 400))
          .slideX(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildViewSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: _viewOptions.map((view) {
          final isSelected = view == _selectedView;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedView = view;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  view,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 500),
          delay: const Duration(milliseconds: 200))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildComparisonChart(List<FamilyMember> members) {
    // Choose the appropriate chart based on the selected view
    switch (_selectedView) {
      case 'Spending':
        return _buildSpendingBarChart(members);
      case 'Budget Usage':
        return _buildBudgetUsageBarChart(members);
      case 'Categories':
        return _buildCategoryPieChart(members);
      default:
        return _buildSpendingBarChart(members);
    }
  }

  Widget _buildSpendingBarChart(List<FamilyMember> members) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: members.map((m) => m.spent).reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.white,
              tooltipRoundedRadius: 8,
              tooltipBorder: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final member = members[groupIndex];
                return BarTooltipItem(
                  '${member.name}\n',
                  const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '\$${member.spent.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= members.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(
                      members[value.toInt()].name,
                      style: TextStyle(
                        color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 500,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      '\$${value.toInt()}',
                      style: TextStyle(
                        color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: List.generate(
            members.length,
            (index) {
              final member = members[index];
              final isSelected = index == _selectedMemberIndex;
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: member.spent,
                    color: isSelected ? AppTheme.accentColor : AppTheme.accentColor.withAlpha((255 * 0.7).round()),
                    width: 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 300))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildBudgetUsageBarChart(List<FamilyMember> members) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 120, // Percentage can go over 100%
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.white,
              tooltipRoundedRadius: 8,
              tooltipBorder: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final member = members[groupIndex];
                return BarTooltipItem(
                  '${member.name}\n',
                  const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '${member.percentSpent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= members.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(
                      members[value.toInt()].name,
                      style: TextStyle(
                        color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      '${value.toInt()}%',
                      style: TextStyle(
                        color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: List.generate(
            members.length,
            (index) {
              final member = members[index];
              final isSelected = index == _selectedMemberIndex;
              final percentSpent = member.percentSpent;
              
              Color barColor;
              if (percentSpent > 100) {
                barColor = AppTheme.errorColor;
              } else if (percentSpent > 80) {
                barColor = AppTheme.warningColor;
              } else {
                barColor = AppTheme.successColor;
              }
              
              if (!isSelected) {
                barColor = barColor.withAlpha((255 * 0.7).round());
              }
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: percentSpent,
                    color: barColor,
                    width: 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 300))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildCategoryPieChart(List<FamilyMember> members) {
    // For simplicity, we'll use a placeholder pie chart
    // In a real app, this would show category breakdown for the selected member
    // or a comparison across members
    
    final categories = FamilyBudgetSampleData.getSampleData().categories;
    final selectedMember = _selectedMemberIndex != -1 ? members[_selectedMemberIndex] : null;
    
    return Column(
      children: [
        if (selectedMember == null)
          const Text(
            'Select a family member to see category breakdown',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Column(
            children: [
              Text(
                '${selectedMember.name}\'s Spending by Category',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(
                      categories.length,
                      (index) {
                        final category = categories[index];
                        return PieChartSectionData(
                          value: category.spent,
                          title: '${(category.spent / selectedMember.spent * 100).toStringAsFixed(0)}%',
                          color: category.color,
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 300))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildMembersList(List<FamilyMember> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Members',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              members.length,
              (index) => _buildMemberChip(members[index], index),
            ),
          ),
        ),
      ],
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 400))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildMemberChip(FamilyMember member, int index) {
    final isSelected = index == _selectedMemberIndex;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // Determine color based on budget usage
    Color statusColor;
    if (member.percentSpent > 100) {
      statusColor = AppTheme.errorColor;
    } else if (member.percentSpent > 80) {
      statusColor = AppTheme.warningColor;
    } else {
      statusColor = AppTheme.successColor;
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMemberIndex = isSelected ? -1 : index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor.withAlpha((255 * 0.1).round()) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                member.name[0],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.accentColor : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              member.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.accentColor : AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(member.spent),
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 60,
              height: 4,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: member.percentSpent / 100,
                child: Container(
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 500 + index * 100))
      .slideX(begin: 0.05, end: 0);
  }

  Widget _buildMemberDetails(FamilyMember member) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isOverBudget = member.spent > member.budgetAllocation;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  member.name[0],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${member.name}\'s Budget Details',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'April 2025',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedMemberIndex = -1;
                  });
                },
                iconSize: 20,
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailColumn(
                'Budget',
                currencyFormat.format(member.budgetAllocation),
                AppTheme.accentColor,
              ),
              _buildDetailColumn(
                'Spent',
                currencyFormat.format(member.spent),
                isOverBudget ? AppTheme.errorColor : AppTheme.expenseColor,
              ),
              _buildDetailColumn(
                'Remaining',
                currencyFormat.format(member.remaining),
                isOverBudget ? AppTheme.errorColor : AppTheme.incomeColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget Usage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${member.percentSpent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOverBudget
                          ? AppTheme.errorColor
                          : member.percentSpent > 80
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
                  value: member.percentSpent / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget
                        ? AppTheme.errorColor
                        : member.percentSpent > 80
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.expenseColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('Adjust Budget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 400))
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildDetailColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textColor.withAlpha((255 * 0.7).round()),
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
}
