import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/currency_extensions.dart';
import '../../utils/enhanced_animations.dart';

/// A consolidated overview card showing balance, income, and expenses
/// with interactive period selection and animations
class ConsolidatedFinancialOverview extends StatefulWidget {
  final double balance;
  final double income;
  final double expenses;
  final VoidCallback? onViewDetails;
  final Function(String period)? onPeriodChanged;

  const ConsolidatedFinancialOverview({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    this.onViewDetails,
    this.onPeriodChanged,
  });

  @override
  State<ConsolidatedFinancialOverview> createState() => _ConsolidatedFinancialOverviewState();
}

class _ConsolidatedFinancialOverviewState extends State<ConsolidatedFinancialOverview> with SingleTickerProviderStateMixin {
  final List<String> _periods = ['Week', 'Month', 'Quarter', 'Year'];
  String _selectedPeriod = 'Month';
  late PageController _pageController;
  int _currentPage = 1; // Start with Month selected

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage, viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changePeriod(int index) {
    HapticFeedback.selectionClick();
    if (index != _currentPage) {
      setState(() {
        _currentPage = index;
        _selectedPeriod = _periods[index];
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      if (widget.onPeriodChanged != null) {
        widget.onPeriodChanged!(_selectedPeriod);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Period selection tabs
          _buildPeriodSelector(),
          
          // Financial data cards
          SizedBox(
            height: 190, // Fixed height for consistent UI
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _changePeriod,
              itemCount: _periods.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                // Apply scaling effect to current page
                return EnhancedAnimations.modernHoverEffect(
                  child: _buildFinancialDataCard(_periods[index]),
                  scale: 1.02,
                  elevation: 2.0,
                );
              },
            ),
          ),
          
          // View details button
          if (widget.onViewDetails != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                onPressed: widget.onViewDetails,
                icon: const Icon(Icons.insights, size: 16),
                label: const Text('View Detailed Analysis'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideY(begin: 0.2, end: 0),
            ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 600))
    .slideY(begin: 0.05, end: 0);
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          _periods.length,
          (index) => _buildPeriodTab(index),
        ),
      ),
    );
  }

  Widget _buildPeriodTab(int index) {
    final isSelected = _selectedPeriod == _periods[index];
    
    return EnhancedAnimations.scaleOnTap(
      onTap: () => _changePeriod(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _periods[index],
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialDataCard(String period) {
    // Adjust values based on selected period for demo
    final multiplier = period == 'Week' ? 0.25 :
                     period == 'Month' ? 1.0 :
                     period == 'Quarter' ? 3.0 : 12.0;
    
    final adjustedIncome = widget.income * multiplier;
    final adjustedExpenses = widget.expenses * multiplier;
    final adjustedBalance = widget.balance * multiplier;
    
    // Determine if values are increasing/decreasing for animation
    final incomeChange = adjustedIncome > widget.income;
    final expensesChange = adjustedExpenses > widget.expenses;
    
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with period
            Text(
              '$period Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Balance amount with animation
            Row(
              children: [
                Text(
                  'Balance:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                _AnimatedMoneyText(
                  amount: adjustedBalance,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Income & Expenses Row
            Row(
              children: [
                // Income
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: Colors.green.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Income',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _AnimatedMoneyText(
                        amount: adjustedIncome,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                        increasing: incomeChange,
                      ),
                    ],
                  ),
                ),
                
                // Expenses
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expenses',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _AnimatedMoneyText(
                        amount: adjustedExpenses,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                        increasing: expensesChange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to animate changes in monetary values with appropriate effects
class _AnimatedMoneyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool? increasing;

  const _AnimatedMoneyText({
    required this.amount,
    this.style,
    this.increasing,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAmount = amount.toCurrency();
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Add a slide up/down animation based on value increasing/decreasing
        if (increasing != null) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, increasing! ? 0.5 : -0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuad,
            )),
            child: FadeTransition(opacity: animation, child: child),
          );
        }
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(
        formattedAmount,
        key: ValueKey<String>(formattedAmount),
        style: style,
      ),
    );
  }
}
