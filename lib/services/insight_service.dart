import '../models/insight_model.dart';
import '../viewmodels/transaction_viewmodel_fixed.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/bill_viewmodel.dart';
import '../viewmodels/goal_viewmodel.dart';
import '../viewmodels/income_viewmodel.dart';

class InsightService {
  final TransactionViewModel? transactionViewModel;
  final BudgetViewModel? budgetViewModel;
  final BillViewModel? billViewModel;
  final GoalViewModel? goalViewModel;
  final IncomeViewModel? incomeViewModel;

  InsightService({
    this.transactionViewModel,
    this.budgetViewModel,
    this.billViewModel,
    this.goalViewModel,
    this.incomeViewModel,
  });

  // Generate insights based on real app data for a specific month
  Future<List<Insight>> getInsights({DateTime? selectedMonth}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final month = selectedMonth ?? DateTime.now();
    final List<Insight> insights = [];

    // Generate spending pattern insights
    insights.addAll(await _generateSpendingPatternInsights(month));
    
    // Generate budget alert insights
    insights.addAll(await _generateBudgetAlertInsights(month));
    
    // Generate saving opportunity insights
    insights.addAll(await _generateSavingOpportunityInsights(month));
    
    // Generate financial health insights
    insights.addAll(await _generateFinancialHealthInsights(month));
    
    // Generate bill-related insights
    insights.addAll(await _generateBillInsights(month));
    
    // Generate goal progress insights
    insights.addAll(await _generateGoalInsights(month));

    // Sort by relevance score (highest first)
    insights.sort((a, b) => (b.relevanceScore ?? 0.0).compareTo(a.relevanceScore ?? 0.0));
    
    // Return top 5 most relevant insights
    return insights.take(5).toList();
  }

  Future<List<Insight>> _generateSpendingPatternInsights(DateTime month) async {
    final insights = <Insight>[];
    
    if (transactionViewModel == null) return insights;
    
    try {
      final currentMonthTransactions = transactionViewModel!.transactions
          .where((t) => t.date.year == month.year && t.date.month == month.month)
          .toList();
      
      final previousMonth = DateTime(month.year, month.month - 1);
      final previousMonthTransactions = transactionViewModel!.transactions
          .where((t) => t.date.year == previousMonth.year && t.date.month == previousMonth.month)
          .toList();
      
      // Group by category and compare spending
      final currentSpending = <String, double>{};
      final previousSpending = <String, double>{};
      
      for (final transaction in currentMonthTransactions) {
        if (transaction.type.toString().contains('expense')) {
          currentSpending[transaction.category] = 
              (currentSpending[transaction.category] ?? 0.0) + transaction.amount;
        }
      }
      
      for (final transaction in previousMonthTransactions) {
        if (transaction.type.toString().contains('expense')) {
          previousSpending[transaction.category] = 
              (previousSpending[transaction.category] ?? 0.0) + transaction.amount;
        }
      }
      
      // Find significant changes (>20% increase)
      for (final category in currentSpending.keys) {
        final currentAmount = currentSpending[category] ?? 0.0;
        final previousAmount = previousSpending[category] ?? 0.0;
        
        if (previousAmount > 0 && currentAmount > previousAmount) {
          final percentageChange = ((currentAmount - previousAmount) / previousAmount) * 100;
          
          if (percentageChange > 20) {
            insights.add(SpendingPatternInsight(
              title: "Increased Spending in '$category'",
              description: "Your spending on $category this month is ${percentageChange.toStringAsFixed(1)}% higher than last month. Consider reviewing your $category expenses.",
              date: DateTime.now(),
              category: category,
              percentageChange: percentageChange,
              previousAmount: previousAmount,
              currentAmount: currentAmount,
              timeFrame: "month",
              relevanceScore: (percentageChange / 100).clamp(0.5, 1.0),
            ));
          }
        }
      }
    } catch (e) {
      // Handle errors gracefully
    }
    
    return insights;
  }

  Future<List<Insight>> _generateBudgetAlertInsights(DateTime month) async {
    final insights = <Insight>[];
    
    if (budgetViewModel == null || transactionViewModel == null) return insights;
    
    try {
      final budgets = budgetViewModel!.budgets;
      final monthTransactions = transactionViewModel!.transactions
          .where((t) => t.date.year == month.year && t.date.month == month.month)
          .toList();
      
      for (final budget in budgets) {
        final categorySpending = monthTransactions
            .where((t) => t.category == budget.category && t.type.toString().contains('expense'))
            .fold(0.0, (sum, t) => sum + t.amount);
        
        final percentageUsed = (categorySpending / budget.amount) * 100;
        
        if (percentageUsed > 75) {
          final remaining = budget.amount - categorySpending;
          insights.add(BudgetAlertInsight(
            title: percentageUsed > 100 ? "Budget Exceeded: ${budget.category}" : "Approaching Budget Limit: ${budget.category}",
            description: percentageUsed > 100 
                ? "You have exceeded your ${budget.category} budget by \$${(categorySpending - budget.amount).toStringAsFixed(0)}."
                : "You have used ${percentageUsed.toStringAsFixed(0)}% of your ${budget.category} budget. \$${remaining.toStringAsFixed(0)} remaining.",
            date: DateTime.now(),
            category: budget.category,
            budgetAmount: budget.amount,
            spentAmount: categorySpending,
            percentageUsed: percentageUsed,
            relevanceScore: (percentageUsed / 100).clamp(0.7, 1.0),
          ));
        }
      }
    } catch (e) {
      // Handle errors gracefully
    }
    
    return insights;
  }

  Future<List<Insight>> _generateSavingOpportunityInsights(DateTime month) async {
    final insights = <Insight>[];
    
    if (transactionViewModel == null) return insights;
    
    try {
      final monthTransactions = transactionViewModel!.transactions
          .where((t) => t.date.year == month.year && t.date.month == month.month)
          .toList();
      
      // Find recurring small expenses that could be optimized
      final categoryTotals = <String, double>{};
      final categoryCounts = <String, int>{};
      
      for (final transaction in monthTransactions) {
        if (transaction.type.toString().contains('expense')) {
          categoryTotals[transaction.category] = 
              (categoryTotals[transaction.category] ?? 0.0) + transaction.amount;
          categoryCounts[transaction.category] = 
              (categoryCounts[transaction.category] ?? 0) + 1;
        }
      }
      
      // Look for categories with many small transactions
      for (final category in categoryTotals.keys) {
        final total = categoryTotals[category] ?? 0.0;
        final count = categoryCounts[category] ?? 0;
        
        if (count > 10 && total > 500) { // Many transactions, significant amount
          final potentialSavings = total * 0.15; // Assume 15% savings potential
          
          insights.add(SavingOpportunityInsight(
            title: "Optimize Your $category Spending",
            description: "You made $count $category transactions this month totaling \$${total.toStringAsFixed(0)}. Consider consolidating or finding alternatives to save money.",
            date: DateTime.now(),
            category: category,
            potentialSavings: potentialSavings,
            suggestion: "Review your $category expenses and look for patterns or alternatives.",
            relevanceScore: (total / 1000).clamp(0.3, 0.8),
          ));
        }
      }
    } catch (e) {
      // Handle errors gracefully
    }
    
    return insights;
  }

  Future<List<Insight>> _generateFinancialHealthInsights(DateTime month) async {
    final insights = <Insight>[];
    
    if (transactionViewModel == null || incomeViewModel == null) return insights;
    
    try {
      final monthTransactions = transactionViewModel!.transactions
          .where((t) => t.date.year == month.year && t.date.month == month.month)
          .toList();
      
      // Use the same data sources as Enhanced Monthly Summary for consistency
      final monthIncome = incomeViewModel!.getFilteredIncomeSources()
          .fold(0.0, (sum, i) => sum + i.amount);
      
      final monthExpenses = monthTransactions
          .where((t) => t.type.toString().contains('expense'))
          .fold(0.0, (sum, t) => sum + t.amount.abs());
      
      if (monthIncome > 0) {
        final savingsRate = ((monthIncome - monthExpenses) / monthIncome) * 100;
        
        String healthStatus;
        List<String> recommendations = [];
        
        if (savingsRate >= 20) {
          healthStatus = "excellent";
          recommendations.add("Great job! Consider investing your surplus.");
        } else if (savingsRate >= 10) {
          healthStatus = "good";
          recommendations.add("You're saving well. Try to increase it to 20%.");
        } else if (savingsRate >= 0) {
          healthStatus = "moderate";
          recommendations.add("Consider reducing expenses to increase savings.");
          recommendations.add("Look for additional income sources.");
        } else {
          healthStatus = "poor";
          recommendations.add("You're spending more than you earn. Review your budget immediately.");
          recommendations.add("Consider cutting non-essential expenses.");
        }
        
        insights.add(FinancialHealthInsight(
          title: "Monthly Financial Health Check",
          description: "Your savings rate this month is ${savingsRate.toStringAsFixed(1)}%. Your financial health is $healthStatus.",
          date: DateTime.now(),
          savingsRate: savingsRate,
          debtToIncomeRatio: 0.0, // Would need debt data
          emergencyFundMonths: 0.0, // Would need savings account data
          overallHealth: healthStatus,
          recommendations: recommendations,
          relevanceScore: 0.9,
        ));
      }
    } catch (e) {
      // Handle errors gracefully
    }
    
    return insights;
  }

  Future<List<Insight>> _generateBillInsights(DateTime month) async {
    final insights = <Insight>[];
    
    if (billViewModel == null) return insights;
    
    try {
      final upcomingBills = billViewModel!.bills
          .where((b) => b.dueDate.isAfter(DateTime.now()) && 
                       b.dueDate.isBefore(DateTime.now().add(const Duration(days: 7))))
          .toList();
      
      if (upcomingBills.isNotEmpty) {
        final totalUpcoming = upcomingBills.fold(0.0, (sum, b) => sum + b.amount);
        
        insights.add(Insight(
          title: "Upcoming Bills Alert",
          description: "You have ${upcomingBills.length} bills due in the next 7 days totaling \$${totalUpcoming.toStringAsFixed(0)}. Plan your cash flow accordingly.",
          type: "Bill Alert",
          date: DateTime.now(),
          relevanceScore: 0.85,
        ));
      }
    } catch (e) {
      // Handle errors gracefully
    }
    
    return insights;
  }

  Future<List<Insight>> _generateGoalInsights(DateTime month) async {
    final insights = <Insight>[];
    
    if (goalViewModel == null) return insights;
    
    try {
      final goals = goalViewModel!.goals;
      
      for (final goal in goals) {
        if (!goal.isCompleted && goal.targetDate != null) {
          final daysRemaining = goal.targetDate!.difference(DateTime.now()).inDays;
          final remainingAmount = goal.targetAmount - goal.currentAmount;
          
          if (daysRemaining > 0 && daysRemaining <= 30) {
            final dailySavingsNeeded = remainingAmount / daysRemaining;
            
            insights.add(Insight(
              title: "Goal Deadline Approaching: ${goal.name}",
              description: "Your goal '${goal.name}' is due in $daysRemaining days. You need to save \$${dailySavingsNeeded.toStringAsFixed(0)} per day to reach your target.",
              type: "Goal Progress",
              date: DateTime.now(),
              relevanceScore: (30 - daysRemaining) / 30 * 0.8 + 0.2,
            ));
          }
        }
      }
    } catch (e) {
      // Handle errors gracefully
    }
    
    return insights;
  }
}
