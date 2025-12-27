import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/loan_viewmodel.dart';
import '../../themes/app_theme.dart';

mixin LoanAnalyticsMethods<T extends StatefulWidget> on State<T> {
  void showAnalyticsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              buildAnalyticsHeader(),
              Expanded(
                child: buildAnalyticsContent(scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAnalyticsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Loan Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: ['Overview', 'Payment Progress', 'Interest Analysis', 'Comparison']
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isSelected = getSelectedAnalyticsTab() == index;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setSelectedAnalyticsTab(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        tab,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAnalyticsContent(ScrollController scrollController) {
    return Consumer<LoanViewModel>(
      builder: (context, loanViewModel, child) {
        switch (getSelectedAnalyticsTab()) {
          case 0:
            return buildOverviewAnalytics(loanViewModel);
          case 1:
            return buildPaymentProgressAnalytics(loanViewModel);
          case 2:
            return buildInterestAnalytics(loanViewModel);
          case 3:
            return buildComparisonAnalytics(loanViewModel);
          default:
            return const SizedBox();
        }
      },
    );
  }

  Widget buildOverviewAnalytics(LoanViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLoanOverviewCard(viewModel),
          const SizedBox(height: 16),
          buildLoanDistributionChart(viewModel),
          const SizedBox(height: 16),
          buildPaymentScheduleCard(viewModel),
        ],
      ),
    );
  }

  Widget buildLoanOverviewCard(LoanViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final totalLoanAmount = viewModel.getTotalLoanAmount();
    final totalAmountPaid = viewModel.getTotalAmountPaid();
    final totalRemainingAmount = viewModel.getTotalRemainingAmount();
    final totalInterestPaid = viewModel.getTotalInterestPaid();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Portfolio Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: buildFinancialMetric(
                    'Total Loans',
                    currencyFormat.format(totalLoanAmount),
                    AppTheme.primaryColor,
                    Icons.account_balance,
                  ),
                ),
                Expanded(
                  child: buildFinancialMetric(
                    'Amount Paid',
                    currencyFormat.format(totalAmountPaid),
                    AppTheme.successColor,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: buildFinancialMetric(
                    'Remaining',
                    currencyFormat.format(totalRemainingAmount),
                    AppTheme.expenseColor,
                    Icons.trending_down,
                  ),
                ),
                Expanded(
                  child: buildFinancialMetric(
                    'Interest Paid',
                    currencyFormat.format(totalInterestPaid),
                    Colors.orange,
                    Icons.percent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Overall Progress: ${totalLoanAmount > 0 ? ((totalAmountPaid / totalLoanAmount) * 100).toStringAsFixed(1) : 0}% of loans paid off',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFinancialMetric(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildLoanDistributionChart(LoanViewModel viewModel) {
    final loans = viewModel.loans;
    
    if (loans.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No loan data available for chart'),
        ),
      );
    }

    final totalAmount = viewModel.getTotalLoanAmount();
    final pieChartSections = loans.map((loan) {
      final percentage = (loan.totalAmount / totalAmount) * 100;
      return PieChartSectionData(
        color: getLoanTypeColor(loan.name),
        value: loan.totalAmount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Distribution by Amount',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: pieChartSections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentScheduleCard(LoanViewModel viewModel) {
    final activeLoans = viewModel.getLoansByStatus('Active');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Payments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (activeLoans.isEmpty)
              const Text('No active loans with upcoming payments')
            else
              ...activeLoans.take(3).map((loan) => buildUpcomingPaymentItem(loan)),
          ],
        ),
      ),
    );
  }

  Widget buildUpcomingPaymentItem(loan) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: loan.isOverdue ? Colors.red : AppTheme.primaryColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Next payment: ${currencyFormat.format(loan.installmentAmount)}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(loan.dueDate),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: loan.isOverdue ? Colors.red : null,
                ),
              ),
              if (loan.isOverdue)
                const Text(
                  'OVERDUE',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPaymentProgressAnalytics(LoanViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPaymentProgressChart(viewModel),
          const SizedBox(height: 16),
          buildLoanStatusBreakdown(viewModel),
        ],
      ),
    );
  }

  Widget buildPaymentProgressChart(LoanViewModel viewModel) {
    final loans = viewModel.loans;
    
    if (loans.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No loan data available for chart'),
        ),
      );
    }

    final barGroups = loans.asMap().entries.map((entry) {
      final index = entry.key;
      final loan = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: loan.totalAmount,
            color: Colors.grey.shade300,
            width: 20,
          ),
          BarChartRodData(
            toY: loan.amountPaid,
            color: AppTheme.successColor,
            width: 20,
          ),
        ],
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Progress by Loan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < loans.length) {
                            return Text(
                              loans[index].name.length > 8 
                                  ? '${loans[index].name.substring(0, 8)}...'
                                  : loans[index].name,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 8),
                const Text('Total Amount'),
                const SizedBox(width: 24),
                Container(
                  width: 16,
                  height: 16,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 8),
                const Text('Amount Paid'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoanStatusBreakdown(LoanViewModel viewModel) {
    final activeLoans = viewModel.getLoansByStatus('Active').length;
    final paidLoans = viewModel.getLoansByStatus('Paid').length;
    final overdueLoans = viewModel.getOverdueLoans().length;
    final totalLoans = viewModel.loans.length;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Status Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: buildStatusMetric(
                    'Active',
                    activeLoans.toString(),
                    AppTheme.primaryColor,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: buildStatusMetric(
                    'Paid Off',
                    paidLoans.toString(),
                    AppTheme.successColor,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: buildStatusMetric(
                    'Overdue',
                    overdueLoans.toString(),
                    Colors.red,
                    Icons.warning,
                  ),
                ),
                Expanded(
                  child: buildStatusMetric(
                    'Total',
                    totalLoans.toString(),
                    Colors.grey.shade600,
                    Icons.account_balance,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusMetric(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildInterestAnalytics(LoanViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildInterestOverviewCard(viewModel),
          const SizedBox(height: 16),
          buildInterestComparisonChart(viewModel),
        ],
      ),
    );
  }

  Widget buildInterestOverviewCard(LoanViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final totalInterestPaid = viewModel.getTotalInterestPaid();
    final totalLoanAmount = viewModel.getTotalLoanAmount();
    final totalAmountPaid = viewModel.getTotalAmountPaid();
    final estimatedTotalInterest = totalLoanAmount * 0.15; // Rough estimate
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interest Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: buildFinancialMetric(
                    'Interest Paid',
                    currencyFormat.format(totalInterestPaid),
                    Colors.orange,
                    Icons.percent,
                  ),
                ),
                Expanded(
                  child: buildFinancialMetric(
                    'Est. Total Interest',
                    currencyFormat.format(estimatedTotalInterest),
                    Colors.red.shade300,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Interest Rate Impact: ${totalInterestPaid > 0 ? ((totalInterestPaid / totalAmountPaid) * 100).toStringAsFixed(1) : 0}% of payments go to interest',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInterestComparisonChart(LoanViewModel viewModel) {
    final loans = viewModel.loans;
    
    if (loans.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No loan data available for chart'),
        ),
      );
    }

    final pieChartSections = loans.map((loan) {
      final interestRate = loan.interestRate;
      return PieChartSectionData(
        color: _getInterestRateColor(interestRate),
        value: interestRate,
        title: '${interestRate.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interest Rates Comparison',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: pieChartSections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getInterestRateColor(double rate) {
    if (rate <= 3.0) return Colors.green;
    if (rate <= 5.0) return Colors.blue;
    if (rate <= 7.0) return Colors.orange;
    return Colors.red;
  }

  Widget buildComparisonAnalytics(LoanViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLoanComparisonCard(viewModel),
          const SizedBox(height: 16),
          buildPaymentEfficiencyCard(viewModel),
        ],
      ),
    );
  }

  Widget buildLoanComparisonCard(LoanViewModel viewModel) {
    final loans = viewModel.loans;
    
    if (loans.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No loan data available for comparison'),
        ),
      );
    }

    // Sort loans by interest rate
    final sortedLoans = List<dynamic>.from(loans)
      ..sort((a, b) => b.interestRate.compareTo(a.interestRate));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Comparison',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedLoans.take(5).map((loan) => buildLoanComparisonItem(loan)),
          ],
        ),
      ),
    );
  }

  Widget buildLoanComparisonItem(loan) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final progressPercentage = (loan.amountPaid / loan.totalAmount) * 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loan.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${loan.interestRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getInterestRateColor(loan.interestRate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currencyFormat.format(loan.amountPaid)} / ${currencyFormat.format(loan.totalAmount)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                '${progressPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressPercentage / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
          ),
        ],
      ),
    );
  }

  Widget buildPaymentEfficiencyCard(LoanViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final totalPaid = viewModel.getTotalAmountPaid();
    final totalInterest = viewModel.getTotalInterestPaid();
    final principalPaid = totalPaid - totalInterest;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Efficiency',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: buildFinancialMetric(
                    'Principal Paid',
                    currencyFormat.format(principalPaid),
                    AppTheme.primaryColor,
                    Icons.account_balance,
                  ),
                ),
                Expanded(
                  child: buildFinancialMetric(
                    'Interest Paid',
                    currencyFormat.format(totalInterest),
                    Colors.orange,
                    Icons.percent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insights,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Efficiency: ${totalPaid > 0 ? ((principalPaid / totalPaid) * 100).toStringAsFixed(1) : 0}% of payments go to principal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getLoanTypeColor(String loanName) {
    final name = loanName.toLowerCase();
    if (name.contains('personal')) return Colors.blue;
    if (name.contains('auto') || name.contains('car')) return Colors.green;
    if (name.contains('home') || name.contains('mortgage')) return Colors.brown;
    if (name.contains('student')) return Colors.purple;
    if (name.contains('business')) return Colors.orange;
    return Colors.grey;
  }

  // Abstract methods that implementing classes must provide
  int getSelectedAnalyticsTab();
  void setSelectedAnalyticsTab(int index);
}
