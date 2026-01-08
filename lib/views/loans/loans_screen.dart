import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_extensions.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../viewmodels/loan_viewmodel.dart';
import '../../models/loan_model.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../themes/app_theme.dart';
import '../../services/navigation_service.dart';
import '../../constants/app_constants.dart';
import 'loan_form_screen.dart';
import 'loan_payment_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  @override
  void dispose() {
    _summaryTimer?.cancel();
    super.dispose();
  }
  Loan? _recentlyAddedLoan;
  Timer? _summaryTimer;
  int _selectedIndex = 8; // Loans tab selected
  bool _isLoading = false;
  String _selectedFilter = 'All';

  LinearGradient get _accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6366F1),
          Color(0xFF8B5CF6),
        ],
      );

  BoxDecoration _premiumCardDecoration(ThemeData theme) {
    final colorScheme = theme.colorScheme;
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

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loanViewModel = Provider.of<LoanViewModel>(context, listen: false);
      await loanViewModel.loadLoans();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading loans: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);

    final route = NavigationService.routeForDrawerIndex(index);

    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    if (ModalRoute.of(context)?.settings.name != route) {
      NavigationService.navigateToReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loanViewModel = Provider.of<LoanViewModel>(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: _accentGradient),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.white70],
          ).createShader(bounds),
          child: const Text(
            'Loan Management',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _selectedFilter = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'All',
                  child: Text('All Loans'),
                ),
                ...AppConstants.loanStatusOptions.map((status) => 
                  PopupMenuItem(
                    value: status,
                    child: Text('$status Loans'),
                  )
                ),
                const PopupMenuItem(
                  value: 'Overdue',
                  child: Text('Overdue Loans'),
                ),
              ],
              icon: const Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
        ],
      ),
      drawer: AppNavigationDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadLoans,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(loanViewModel),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: _accentGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoanFormScreen(),
                ),
              );
              
              if (result is Loan) {
                setState(() {
                  _recentlyAddedLoan = result;
                });
                _summaryTimer?.cancel();
                _summaryTimer = Timer(const Duration(seconds: 5), () {
                  if (mounted) setState(() => _recentlyAddedLoan = null);
                });
                _loadLoans();
              } else if (result == true) {
                _loadLoans();
              }
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ).animate()
        .scale(duration: 200.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms),
    );
  }

  Widget _buildContent(LoanViewModel viewModel) {
    // Filter loans based on selected filter
    List<Loan> filteredLoans;
    if (_selectedFilter == 'All') {
      filteredLoans = viewModel.loans;
    } else if (_selectedFilter == 'Overdue') {
      filteredLoans = viewModel.getOverdueLoans();
    } else {
      filteredLoans = viewModel.getLoansByStatus(_selectedFilter);
    }

    if (filteredLoans.isEmpty) {
      return _buildEmptyState();
    }

    final List<Widget> children = [];

    // Recently added confirmation
    if (_recentlyAddedLoan != null) {
      children..add(_buildAddedLoanCard())..add(const SizedBox(height: 8));
    }

    children.addAll([
      _buildLoanSummary(viewModel),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => _accentGradient.createShader(bounds),
              child: Text(
                _selectedFilter == 'All' ? 'All Loans' : '$_selectedFilter Loans',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: _accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${filteredLoans.length} ${filteredLoans.length == 1 ? 'loan' : 'loans'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      ...filteredLoans.asMap().entries.map((entry) {
        final index = entry.key;
        final loan = entry.value;
        return _buildLoanCard(loan).animate(delay: (index * 100).ms)
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.3, duration: 400.ms, curve: Curves.easeOut);
      }),
    ]);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildAddedLoanCard() {
    // Using toKenyaDualCurrency() for Kenya loan market
    final theme = Theme.of(context);
    final l = _recentlyAddedLoan!;
    return Container(
      decoration: _premiumCardDecoration(theme),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: _accentGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white),
        ),
        title: Text(
          l.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Amount: ${l.totalAmount.toKenyaDualCurrency()}',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _recentlyAddedLoan = null),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: _premiumCardDecoration(theme),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _accentGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const FaIcon(
                FontAwesomeIcons.handHoldingDollar,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => _accentGradient.createShader(bounds),
              child: Text(
                _selectedFilter == 'All' 
                    ? 'No loans added yet' 
                    : 'No $_selectedFilter loans',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Track your loans and manage payments\nwith our comprehensive loan system',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: _accentGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoanFormScreen(),
                      ),
                    );
                    
                    if (result == true) {
                      _loadLoans();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Add Loan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildLoanSummary(LoanViewModel viewModel) {
    // Using toKenyaDualCurrency() for Kenya loan market
    final totalLoanAmount = viewModel.getTotalLoanAmount();
    final totalRemainingAmount = viewModel.getTotalRemainingAmount();
    final totalAmountPaid = viewModel.getTotalAmountPaid();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _accentGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.chartLine,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Loan Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Loan Amount',
                  totalLoanAmount.toKenyaDualCurrency(),
                  Colors.white,
                  Colors.white70,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Amount Paid',
                  totalAmountPaid.toKenyaDualCurrency(),
                  Colors.white,
                  Colors.white70,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Remaining',
                  totalRemainingAmount.toKenyaDualCurrency(),
                  Colors.white,
                  Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Overall Payment Progress',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: totalLoanAmount > 0 ? totalAmountPaid / totalLoanAmount : 0,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                totalLoanAmount > 0 
                    ? '${((totalAmountPaid / totalLoanAmount) * 100).toStringAsFixed(1)}% paid' 
                    : '0% paid',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusCount(
                'Active Loans',
                viewModel.getLoansByStatus('Active').length.toString(),
                Colors.white,
              ),
              _buildStatusCount(
                'Paid Loans',
                viewModel.getLoansByStatus('Paid').length.toString(),
                Colors.white,
              ),
              _buildStatusCount(
                'Overdue Loans',
                viewModel.getOverdueLoans().length.toString(),
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildSummaryItem(String title, String value, Color valueColor, Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: titleColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCount(String title, String count, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              count,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanCard(Loan loan) {
    // Using toKenyaDualCurrency() for Kenya loan market
    final theme = Theme.of(context);
    final dateFormat = DateFormat(AppConstants.dateFormat);
    
    Color statusColor;
    switch (loan.status) {
      case 'Active':
        statusColor = loan.isOverdue ? AppTheme.errorColor : const Color(0xFF6366F1);
        break;
      case 'Paid':
        statusColor = AppTheme.successColor;
        break;
      case 'Defaulted':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _premiumCardDecoration(theme),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoanFormScreen(loan: loan),
            ),
          );
          
          if (result == true || result == 'deleted') {
            // Refresh the list if a loan was updated or deleted
            _loadLoans();
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: statusColor.withAlpha((0.1 * 255).toInt()),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha((0.2 * 255).toInt()),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          loan.isOverdue ? Icons.warning : Icons.check_circle,
                          color: statusColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loan.isOverdue ? 'Overdue' : loan.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (loan.status == 'Active')
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoanPaymentScreen(loan: loan),
                          ),
                        );
                        
                        if (result == true) {
                          // Refresh the list if a payment was made
                          _loadLoans();
                        }
                      },
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Make Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loan.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lender: ${loan.lender}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            loan.totalAmount.toKenyaDualCurrency(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Interest: ${loan.interestRate}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid: ${loan.amountPaid.toKenyaDualCurrency()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Remaining: ${loan.remainingAmount.toKenyaDualCurrency()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: loan.remainingAmount > 0 ? AppTheme.expenseColor : AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${loan.percentPaid.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getProgressColor(loan.percentPaid),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: loan.amountPaid / loan.totalAmount,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(loan.percentPaid)),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            dateFormat.format(loan.startDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Due Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            dateFormat.format(loan.dueDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: loan.isOverdue ? AppTheme.errorColor : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Payment: ${loan.installmentAmount.toKenyaDualCurrency()} (${loan.paymentFrequency})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (loan.notes != null && loan.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        loan.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
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

  Color _getProgressColor(double percentage) {
    if (percentage < 30) {
      return AppTheme.errorColor;
    } else if (percentage < 70) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.successColor;
    }
  }
}
