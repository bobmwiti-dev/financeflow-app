import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/transaction_viewmodel_fixed.dart';
import '../../../viewmodels/income_viewmodel.dart';

class KenyaFinancialInsightsCard extends StatelessWidget {
  const KenyaFinancialInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ', decimalDigits: 0);
    
    return Consumer2<TransactionViewModel, IncomeViewModel>(
      builder: (context, transactionViewModel, incomeViewModel, child) {
        final transactions = transactionViewModel.transactions;
        final insights = _generateKenyaSpecificInsights(transactions, incomeViewModel);
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.insights,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Kenya Financial Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildInsightItem(insight, currencyFormat),
                )),
                
                if (insights.isEmpty)
                  _buildEmptyInsights(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInsightItem(KenyaFinancialInsight insight, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: insight.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            insight.icon,
            color: insight.color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (insight.amount != null)
            Text(
              currencyFormat.format(insight.amount!),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: insight.color,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Add more transactions to get insights',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll analyze your spending patterns and provide Kenya-specific financial tips',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  List<KenyaFinancialInsight> _generateKenyaSpecificInsights(
    List<dynamic> transactions, 
    IncomeViewModel incomeViewModel
  ) {
    final insights = <KenyaFinancialInsight>[];
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    
    // Filter current month transactions
    final monthTransactions = transactions.where((tx) {
      final txDate = tx.date;
      return txDate.year == currentMonth.year && txDate.month == currentMonth.month;
    }).toList();
    
    if (monthTransactions.isEmpty) return insights;

    final totalIncome = incomeViewModel.getTotalIncome();
    
    // 1. M-Pesa Usage Analysis
    final mpesaTransactions = monthTransactions.where((tx) => 
      tx.description?.toLowerCase().contains('mpesa') == true ||
      tx.description?.toLowerCase().contains('paybill') == true ||
      tx.description?.toLowerCase().contains('buy goods') == true
    ).toList();
    
    if (mpesaTransactions.isNotEmpty) {
      final mpesaAmount = mpesaTransactions.fold<double>(0, (sum, tx) => sum + tx.amount.abs());
      final percentage = (mpesaAmount / _getTotalExpenses(monthTransactions)) * 100;
      
      insights.add(KenyaFinancialInsight(
        title: 'M-Pesa Dominance',
        description: '${percentage.toInt()}% of your spending goes through M-Pesa. Consider M-Shwari savings for better rates.',
        icon: Icons.phone_android,
        color: Colors.green,
        amount: mpesaAmount,
      ));
    }
    
    // 2. Pure Betting Insight (SportPesa, Betika, etc.)
    const bettingKeywords = [
      'sportpesa',
      'betika',
      'odibets',
      'betway',
      '1xbet',
      '22bet',
      'betlion',
      'melbet',
      'bangbet',
      'betwinner',
    ];

    bool isBettingTx(dynamic tx) {
      if (tx.isExpense != true) return false;
      final desc = (tx.description ?? tx.title ?? '').toString().toLowerCase();
      for (final keyword in bettingKeywords) {
        if (desc.contains(keyword)) return true;
      }
      return false;
    }

    final bettingMonthTx = monthTransactions.where(isBettingTx).toList();
    if (bettingMonthTx.isNotEmpty) {
      final bettingMonthAmount = bettingMonthTx
          .fold<double>(0, (sum, tx) => sum + tx.amount.abs());

      // Last 12 months betting spend (approximate leakage magnitude)
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
      final bettingYearTx = transactions
          .where((tx) =>
              tx.date.isAfter(oneYearAgo) &&
              tx.date.isBefore(now.add(const Duration(days: 1))) &&
              isBettingTx(tx))
          .toList();
      final bettingYearAmount = bettingYearTx
          .fold<double>(0, (sum, tx) => sum + tx.amount.abs());

      final bettingShareOfIncome = totalIncome > 0
          ? (bettingMonthAmount / totalIncome) * 100
          : 0.0;

      final yearlyEstimate = bettingYearAmount > 0
          ? bettingYearAmount
          : bettingMonthAmount * 12;

      final shareText = bettingShareOfIncome > 0
          ? bettingShareOfIncome.toStringAsFixed(1)
          : '0';

      insights.add(KenyaFinancialInsight(
        title: 'Betting Leakage',
        description:
            'You spent KES ${bettingMonthAmount.toStringAsFixed(0)} on betting this month (~$shareText% of income). At this pace that is about KES ${yearlyEstimate.toStringAsFixed(0)} per year that could build your emergency fund instead.',
        icon: Icons.sports_esports,
        color: Colors.red.shade700,
        amount: bettingMonthAmount,
      ));
    }
    
    // 3. Transport Spending Analysis
    final transportSpending = _getCategorySpending(monthTransactions, ['Transport', 'Fuel', 'Matatu']);
    if (transportSpending > 0) {
      final totalIncome = incomeViewModel.getTotalIncome();
      final transportPercentage = (transportSpending / totalIncome) * 100;
      
      if (transportPercentage > 15) {
        insights.add(KenyaFinancialInsight(
          title: 'High Transport Costs',
          description: 'Transport is ${transportPercentage.toInt()}% of income. Consider carpooling or matatu season tickets.',
          icon: Icons.directions_bus,
          color: Colors.orange,
          amount: transportSpending,
        ));
      }
    }
    
    // 4. Utility Bills Optimization
    final utilitySpending = _getCategorySpending(monthTransactions, ['Utilities', 'Bills']);
    if (utilitySpending > 0) {
      insights.add(KenyaFinancialInsight(
        title: 'Utility Management',
        description: 'Set up KPLC token auto-purchase and Safaricom bundle subscriptions to save on fees.',
        icon: Icons.electrical_services,
        color: Colors.blue,
        amount: utilitySpending,
      ));
    }
    
    // 5. School Fees Planning (Kenya-specific)
    final educationSpending = _getCategorySpending(monthTransactions, ['Education', 'School Fees']);
    if (educationSpending > 0) {
      insights.add(KenyaFinancialInsight(
        title: 'Education Investment',
        description: 'Consider opening an education savings account with tax benefits under Kenya\'s tax laws.',
        icon: Icons.school,
        color: Colors.purple,
        amount: educationSpending,
      ));
    }
    
    // 6. Emergency Fund Recommendation (Kenya context)
    final totalExpenses = _getTotalExpenses(monthTransactions);
    final savingsRate = ((totalIncome - totalExpenses) / totalIncome) * 100;
    
    if (savingsRate < 20) {
      insights.add(KenyaFinancialInsight(
        title: 'Emergency Fund Alert',
        description: 'Aim to save 20% for emergencies. In Kenya, 6 months of expenses is recommended due to economic volatility.',
        icon: Icons.shield,
        color: Colors.red,
        amount: totalExpenses * 6,
      ));
    }
    
    // 6. Investment Opportunities (NSE/Government Bonds)
    if (savingsRate > 30) {
      insights.add(KenyaFinancialInsight(
        title: 'Investment Ready',
        description: 'Great savings rate! Consider NSE stocks, government bonds, or M-Akiba for wealth building.',
        icon: Icons.trending_up,
        color: Colors.green,
        amount: (totalIncome - totalExpenses),
      ));
    }
    
    return insights.take(3).toList(); // Show top 3 insights
  }
  
  double _getTotalExpenses(List<dynamic> transactions) {
    return transactions
        .where((tx) => tx.isExpense == true)
        .fold<double>(0, (sum, tx) => sum + tx.amount.abs());
  }
  
  double _getCategorySpending(List<dynamic> transactions, List<String> categories) {
    return transactions
        .where((tx) => 
            tx.isExpense == true && 
            categories.any((cat) => 
                tx.category?.toLowerCase().contains(cat.toLowerCase()) == true ||
                tx.description?.toLowerCase().contains(cat.toLowerCase()) == true
            )
        )
        .fold<double>(0, (sum, tx) => sum + tx.amount.abs());
  }
}

class KenyaFinancialInsight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double? amount;
  
  const KenyaFinancialInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.amount,
  });
}
