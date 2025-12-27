import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/currency_extensions.dart';

import '../../models/budget_model.dart';

class SmartBudgetRecommendations extends StatefulWidget {
  final List<Budget> budgets;
  final double totalIncome;
  final Function(Budget) onApplyRecommendation;
  
  const SmartBudgetRecommendations({
    super.key,
    required this.budgets,
    required this.totalIncome,
    required this.onApplyRecommendation,
  });

  @override
  State<SmartBudgetRecommendations> createState() => _SmartBudgetRecommendationsState();
}

class _SmartBudgetRecommendationsState extends State<SmartBudgetRecommendations> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<BudgetRecommendation> _recommendations = [];
  BudgetRecommendation? _expandedRecommendation;
  bool _hasGeneratedRecommendations = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _generateRecommendations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SmartBudgetRecommendations oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budgets != widget.budgets ||
        oldWidget.totalIncome != widget.totalIncome) {
      _generateRecommendations();
    }
  }

  void _generateRecommendations() {
    // Reset state
    setState(() {
      _recommendations = [];
      _expandedRecommendation = null;
      _hasGeneratedRecommendations = false;
    });

    // Simulating processing delay for effect
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final recommendations = <BudgetRecommendation>[];
      // Using CurrencyService via toCurrency() extension
      
      // 1. Generate housing/rent recommendation if not present
      if (!_hasBudgetCategory('Housing') && !_hasBudgetCategory('Rent')) {
        // 30% of income is standard recommendation for housing
        final recommendedAmount = widget.totalIncome * 0.3;
        recommendations.add(
          BudgetRecommendation(
            category: 'Housing',
            currentAmount: 0,
            recommendedAmount: recommendedAmount,
            impactScore: 5, // High impact
            reason: 'Housing should be about 30% of your income',
            details: 'Financial experts recommend allocating around 30% of your income to housing expenses. '
                   'This ensures you have enough for other necessities while maintaining comfortable living arrangements.',
            changeType: 'new',
            improvementMessage: 'Having a housing budget helps you find affordable living options.',
            customIcon: Icons.home,
          ),
        );
      }
      
      // 2. Check for overspending categories to recommend reductions
      for (final budget in widget.budgets) {
        if (budget.spent > budget.amount * 1.2) { // Consistently over budget by 20%
          final recommendedAmount = budget.spent * 0.9; // Recommend slightly less than actual spending
          recommendations.add(
            BudgetRecommendation(
              category: budget.category,
              currentAmount: budget.amount,
              recommendedAmount: recommendedAmount,
              impactScore: 4, // High impact
              reason: 'You consistently spend more than budgeted',
              details: 'Your actual spending in ${budget.category} is consistently higher than your budget. '
                     'Adjusting your budget to ${recommendedAmount.toCurrency()} (slightly below your current spending) '
                     'will make your budget more realistic while encouraging some spending reduction.',
              changeType: 'increase',
              improvementMessage: 'A more realistic budget reduces financial stress.',
              customIcon: _getCategoryIcon(budget.category),
            ),
          );
        }
      }
      
      // 3. Check for missing essential budget categories
      for (final category in ['Groceries', 'Transportation', 'Utilities', 'Healthcare']) {
        if (!_hasBudgetCategory(category)) {
          // Recommended percentages based on typical financial advice
          double percentage;
          switch (category) {
            case 'Groceries':
              percentage = 0.15; // 15% of income
              break;
            case 'Transportation':
              percentage = 0.10; // 10% of income
              break;
            case 'Utilities':
              percentage = 0.08; // 8% of income
              break;
            case 'Healthcare':
              percentage = 0.05; // 5% of income
              break;
            default:
              percentage = 0.05; // Default to 5%
          }
          
          final recommendedAmount = widget.totalIncome * percentage;
          recommendations.add(
            BudgetRecommendation(
              category: category,
              currentAmount: 0,
              recommendedAmount: recommendedAmount,
              impactScore: 4, // High impact
              reason: 'Essential category missing from your budget',
              details: '$category is an essential expense category that should be included in your budget. '
                     'Based on your income, we recommend allocating ${(percentage * 100).toStringAsFixed(0)}% '
                     '(${recommendedAmount.toCurrency()}) to this category.',
              changeType: 'new',
              improvementMessage: 'Planning for essentials prevents unexpected financial strain.',
              customIcon: _getCategoryIcon(category),
            ),
          );
        }
      }
      
      // 4. Check for missing savings/investments if income is substantial
      if (!_hasBudgetCategory('Savings') && !_hasBudgetCategory('Investments')) {
        // 20% of income is recommended for savings/investments
        final recommendedAmount = widget.totalIncome * 0.2;
        recommendations.add(
          BudgetRecommendation(
            category: 'Savings',
            currentAmount: 0,
            recommendedAmount: recommendedAmount,
            impactScore: 5, // High impact
            reason: 'No savings allocation in your budget',
            details: 'Financial experts recommend saving at least 20% of your income. '
                   'Adding a ${recommendedAmount.toCurrency()} monthly savings budget will help you build an emergency fund '
                   'and save for future goals.',
            changeType: 'new',
            improvementMessage: 'Starting to save improves long-term financial security.',
            customIcon: Icons.savings,
          ),
        );
      }
      
      // 5. Check for high discretionary spending categories that could be reduced
      for (final category in ['Entertainment', 'Dining Out', 'Shopping']) {
        final budgetForCategory = widget.budgets.where((b) => b.category == category).toList();
        if (budgetForCategory.isNotEmpty) {
          final budget = budgetForCategory.first;
          if (budget.amount > widget.totalIncome * 0.15) { // More than 15% on discretionary
            final recommendedAmount = widget.totalIncome * 0.1; // Recommend 10% of income
            recommendations.add(
              BudgetRecommendation(
                category: budget.category,
                currentAmount: budget.amount,
                recommendedAmount: recommendedAmount,
                impactScore: 3, // Medium impact
                reason: 'Discretionary spending could be reduced',
                details: 'Your current budget allocates ${budget.amount.toCurrency()} to ${budget.category}, '
                       'which is relatively high compared to your income. Reducing this to '
                       '${recommendedAmount.toCurrency()} would free up funds for savings or other priorities.',
                changeType: 'decrease',
                improvementMessage: 'Reducing discretionary spending increases financial flexibility.',
                customIcon: _getCategoryIcon(budget.category),
              ),
            );
          }
        }
      }
      
      // Sort recommendations by impact score (highest first)
      recommendations.sort((a, b) => b.impactScore.compareTo(a.impactScore));
      
      // Take top 3 recommendations for focused impact
      final topRecommendations = recommendations.take(3).toList();
      
      setState(() {
        _recommendations = topRecommendations;
        _hasGeneratedRecommendations = true;
        _animationController.forward();
      });
    });
  }

  bool _hasBudgetCategory(String category) {
    return widget.budgets.any((budget) => 
      budget.category.toLowerCase() == category.toLowerCase());
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'housing':
      case 'rent':
        return Icons.home;
      case 'groceries':
      case 'food':
        return Icons.local_grocery_store;
      case 'transportation':
        return Icons.directions_car;
      case 'utilities':
        return Icons.power;
      case 'healthcare':
        return Icons.medical_services;
      case 'entertainment':
        return Icons.movie;
      case 'dining out':
      case 'restaurants':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'savings':
        return Icons.savings;
      case 'investments':
        return Icons.trending_up;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasGeneratedRecommendations) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing your budget...'),
          ],
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Your budget looks great!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'We don\'t have any recommendations at this time.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _recommendations.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        final isExpanded = _expandedRecommendation == recommendation;
        
        // Calculate animation delay for staggered appearance
        final delay = Duration(milliseconds: 100 * index);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RecommendationCard(
            recommendation: recommendation,
            isExpanded: isExpanded,
            onToggleExpand: () {
              setState(() {
                _expandedRecommendation = isExpanded ? null : recommendation;
              });
            },
            onApply: () {
              // Create a new budget or update existing with recommended amount
              final now = DateTime.now();
              final budget = Budget(
                category: recommendation.category,
                amount: recommendation.recommendedAmount,
                startDate: DateTime(now.year, now.month, 1),  // First day of current month
                endDate: DateTime(now.year, now.month + 1, 0),  // Last day of current month
              );
              
              widget.onApplyRecommendation(budget);
              
              // Show success feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${recommendation.category} budget updated!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'VIEW',
                    textColor: Colors.white,
                    onPressed: () {
                      // Navigate to budget details or list
                    },
                  ),
                ),
              );
              
              // Remove the recommendation after applying
              setState(() {
                _recommendations.remove(recommendation);
                if (_expandedRecommendation == recommendation) {
                  _expandedRecommendation = null;
                }
              });
            },
          ).animate(controller: _animationController)
            .fadeIn(duration: const Duration(milliseconds: 400), delay: delay)
            .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400), delay: delay)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: const Duration(milliseconds: 400), delay: delay),
        );
      },
    );
  }
}

class RecommendationCard extends StatelessWidget {
  final BudgetRecommendation recommendation;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onApply;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    // Using CurrencyService via toCurrency() extension
    final colorByImpact = _getColorByImpactScore(recommendation.impactScore);
    final percentChange = recommendation.currentAmount > 0
        ? '${((recommendation.recommendedAmount - recommendation.currentAmount) / recommendation.currentAmount * 100).toStringAsFixed(0)}%'
        : 'New';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggleExpand,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorByImpact.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category icon with impact background
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorByImpact.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      recommendation.customIcon,
                      color: colorByImpact,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Category and reason
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recommendation.reason,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Impact indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorByImpact.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getChangeIcon(recommendation.changeType),
                          color: colorByImpact,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          percentChange,
                          style: TextStyle(
                            color: colorByImpact,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Budget amount comparison
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    if (recommendation.currentAmount > 0) ... [
                      Expanded(
                        child: _buildAmountBox(
                          'Current',
                          recommendation.currentAmount.toCurrency(),
                          Colors.grey.shade700,
                          Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: _buildAmountBox(
                        'Recommended',
                        recommendation.recommendedAmount.toCurrency(),
                        colorByImpact,
                        colorByImpact.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Expanded details
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  height: isExpanded ? null : 0,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          recommendation.details,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recommendation.improvementMessage,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onApply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorByImpact,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Apply Recommendation'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expansion indicator
              if (!isExpanded)
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountBox(String label, String amount, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorByImpactScore(int score) {
    switch (score) {
      case 5:
        return Colors.red.shade700; // Highest impact
      case 4:
        return Colors.orange.shade700;
      case 3:
        return Colors.amber.shade700;
      case 2:
        return Colors.blue.shade700;
      case 1:
        return Colors.green.shade700; // Lowest impact
      default:
        return Colors.purple.shade700;
    }
  }

  IconData _getChangeIcon(String changeType) {
    switch (changeType) {
      case 'increase':
        return Icons.arrow_upward;
      case 'decrease':
        return Icons.arrow_downward;
      case 'new':
        return Icons.add_circle_outline;
      default:
        return Icons.remove;
    }
  }
}

class BudgetRecommendation {
  final String category;
  final double currentAmount;
  final double recommendedAmount;
  final int impactScore; // 1-5 scale, 5 being highest impact
  final String reason;
  final String details;
  final String changeType; // 'increase', 'decrease', 'new'
  final String improvementMessage;
  final IconData customIcon;

  BudgetRecommendation({
    required this.category,
    required this.currentAmount,
    required this.recommendedAmount,
    required this.impactScore,
    required this.reason,
    required this.details,
    required this.changeType,
    required this.improvementMessage,
    required this.customIcon,
  });
}
