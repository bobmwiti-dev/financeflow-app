import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/goal_viewmodel.dart';
import '../../../viewmodels/income_viewmodel.dart';
import '../../../models/goal_model.dart';
import '../../../models/transaction_model.dart';
import '../../../services/transaction_service.dart';

/// Combined card that can display either savings rate summary or savings goals list.
/// Users may toggle between the two modes via a simple tab selector in the header.
class SavingsRateGoalsCard extends StatefulWidget {
  const SavingsRateGoalsCard({
    super.key,
    required this.income,
    required this.expenses,
    this.targetSavingsRate = 0.30, // 30% default target
  });

  final double income;
  final double expenses;
  final double targetSavingsRate;

  @override
  State<SavingsRateGoalsCard> createState() => _SavingsRateGoalsCardState();
}

class _SavingsRateGoalsCardState extends State<SavingsRateGoalsCard> {
  bool _showRate = true;

  // Cached analytics
  double? _ytdRate;
  double? _rollingAvgRate;
  int _savingsStreak = 0;
  int _completedGoals = 0;
  String? _largestGoalName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildAnalyticsRow(),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showRate ? _buildSavingsRateView() : _buildGoalsView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _showRate ? 'Savings Rate' : 'Savings Goals',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Simple toggle buttons
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildToggleChip(label: 'Rate', icon: Icons.trending_up, selected: _showRate, onTap: () {
                setState(() => _showRate = true);
              }),
              _buildToggleChip(label: 'Goals', icon: Icons.flag, selected: !_showRate, onTap: () {
                setState(() => _showRate = false);
              }),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildToggleChip({required String label, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : Colors.black54),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// View displaying savings rate percentage, status chip, and progress bar.
  Widget _buildAnalyticsRow() {
    // chips row under header
    List<Widget> chips = [];
    if (_ytdRate != null) {
      chips.add(_buildMetricChip(label: 'YTD ${( _ytdRate!*100).toStringAsFixed(1)}%', icon: Icons.calendar_today));
    }
    if (_rollingAvgRate != null) {
      chips.add(_buildMetricChip(label: '3-mo ${( _rollingAvgRate!*100).toStringAsFixed(1)}%', icon: Icons.trending_up));
    }
    chips.add(_buildMetricChip(label: 'Streak $_savingsStreak', icon: Icons.whatshot));
    chips.add(_buildMetricChip(label: '🏆 $_completedGoals', icon: Icons.emoji_events));
    if (_largestGoalName != null) {
      chips.add(_buildMetricChip(label: _largestGoalName!, icon: Icons.flag));
    }
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _buildMetricChip({required String label, required IconData icon}) {
    return Chip(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 4), Text(label)],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildSavingsRateView() {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final savings = (widget.income - widget.expenses).clamp(0, double.infinity);
    final double rate = widget.income == 0 ? 0 : savings / widget.income;
    final bool onTrack = rate >= widget.targetSavingsRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: (rate*100).toStringAsFixed(1), style: const TextStyle(fontSize: 28,fontWeight: FontWeight.bold)),
                    TextSpan(text: '%', style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
                  ]),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('/ ${(widget.targetSavingsRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: onTrack ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                onTrack ? 'On Track' : 'Behind',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Progress to goal bar with gradient
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.4)],
              ).createShader(rect);
            },
            child: LinearProgressIndicator(
              value: (widget.targetSavingsRate == 0)
                  ? 0
                  : (rate / widget.targetSavingsRate).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(onTrack ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monthly Savings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(currency.format(savings), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monthly Income', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(currency.format(widget.income), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _calculateAnalytics() async {
    final incomeVm = Provider.of<IncomeViewModel>(context, listen: false);
    final goalVm = Provider.of<GoalViewModel>(context, listen: false);
    final transactionSvc = TransactionService.instance;

    final now = DateTime.now();
    // Year-to-date income & expenses
    final ytdIncome = incomeVm.incomeSources
        .where((i) => i.date.year == now.year)
        .fold<double>(0, (s, i) => s + i.amount);

    // need expenses list -> lastTransactions may not have full YTD; simple fetch last 500 maybe unrealistic.
    final expenses = transactionSvc.lastTransactions
        .where((t) => t.date.year == now.year && t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount.abs());
    _ytdRate = ytdIncome == 0 ? 0 : ((ytdIncome - expenses) / ytdIncome);

    // 3-month rolling avg
    double rollingSumRate = 0;
    int monthsCounted = 0;
    for (int m = 0; m < 3; m++) {
      final month = DateTime(now.year, now.month - m, 1);
      final monthIncome = incomeVm.incomeSources
          .where((i) => i.date.year == month.year && i.date.month == month.month)
          .fold<double>(0, (s, i) => s + i.amount);
      final monthExpenses = transactionSvc.lastTransactions
          .where((t) => t.date.year == month.year && t.date.month == month.month && t.type == TransactionType.expense)
          .fold<double>(0, (s, t) => s + t.amount.abs());
      if (monthIncome > 0) {
        rollingSumRate += ((monthIncome - monthExpenses) / monthIncome);
        monthsCounted++;
      }
    }
    _rollingAvgRate = monthsCounted == 0 ? 0 : rollingSumRate / monthsCounted;

    // savings streak – consecutive months on track starting from current month backwards
    int streak = 0;
    for (int offset = 0; offset < 12; offset++) {
      final month = DateTime(now.year, now.month - offset, 1);
      final inc = incomeVm.incomeSources.where((i) => i.date.year == month.year && i.date.month == month.month).fold<double>(0, (s, i) => s + i.amount);
      final exp = transactionSvc.lastTransactions.where((t) => t.date.year == month.year && t.date.month == month.month && t.type == TransactionType.expense).fold<double>(0, (s, t) => s + t.amount.abs());
      if (inc == 0) break; // no data ends streak
      final rate = (inc - exp) / inc;
      if (rate >= widget.targetSavingsRate) {
        streak++;
      } else {
        break;
      }
    }
    _savingsStreak = streak;

    // goals analytics
    _completedGoals = goalVm.goals.where((g) => g.progressPercentage >= 100).length;
    final activeGoals = goalVm.goals.where((g) => g.progressPercentage < 100).toList();
    if (activeGoals.isNotEmpty) {
      activeGoals.sort((a, b) => b.targetAmount.compareTo(a.targetAmount));
      _largestGoalName = activeGoals.first.name;
    }

    if (mounted) setState(() {});
  }

  /// View re-using the existing SavingsGoalsCard for goal display.
  Widget _buildGoalsView() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Consumer<GoalViewModel>(
      builder: (context, goalViewModel, child) {
        final goals = goalViewModel.goals;
        final isLoading = goalViewModel.isLoading;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (goals.isEmpty) {
          return _buildEmptyState(context);
        }
        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: goals.length > 3 ? 3 : goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _getGoalColor(goal.category ?? '').withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildGoalItem(goal, currencyFormat),
                );
              },
            ),
            if (goals.length > 3)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/goals'),
                child: const Text('View All Goals'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.savings, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('No savings goals yet',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/goals'),
            child: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(Goal goal, NumberFormat currencyFormat) {
    final progress = goal.progressPercentage / 100;
    final goalColor = _getGoalColor(goal.category ?? '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: goalColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: goalColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getGoalIcon(goal.category ?? ''), color: goalColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${goal.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(color: goalColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(goalColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(goal.currentAmount),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                currencyFormat.format(goal.targetAmount),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getGoalColor(String category) {
    switch (category.toLowerCase()) {
      case 'emergency':
      case 'savings':
        return Colors.green;
      case 'education':
        return Colors.blue;
      case 'travel':
        return Colors.orange;
      case 'electronics':
        return Colors.purple;
      case 'vehicle':
        return Colors.indigo;
      case 'home':
        return Colors.brown;
      case 'business':
        return Colors.teal;
      case 'wedding':
        return Colors.pink;
      case 'health':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getGoalIcon(String category) {
    switch (category.toLowerCase()) {
      case 'emergency':
      case 'savings':
        return Icons.shield;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      case 'electronics':
        return Icons.laptop;
      case 'vehicle':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'business':
        return Icons.business;
      case 'wedding':
        return Icons.celebration;
      case 'health':
        return Icons.local_hospital;
      default:
        return Icons.savings;
    }
  }

}
