import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../models/debt_payoff_goal.dart';
import '../../../viewmodels/debt_goals_viewmodel.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/animated_loading_indicator.dart';

/// Dashboard card summarising the highest-priority debt payoff goal.
class DebtPayoffCard extends StatefulWidget {
  const DebtPayoffCard({super.key});

  @override
  State<DebtPayoffCard> createState() => _DebtPayoffCardState();
}

class _DebtPayoffCardState extends State<DebtPayoffCard> {

  @override
  void initState() {
    super.initState();
    // Fetch goals when the widget is first initialized.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DebtGoalsViewModel>(context, listen: false).loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtGoalsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: AnimatedLoadingIndicator(size: 40));
        }
        if (vm.goals.isEmpty) {
          return _buildEmptyState(context);
        }

        // For simplicity: pick the first goal (could be sorted by priority later)
        final goal = vm.goals.first;
        return _buildGoalCard(context, goal);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No Debt Goals Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Add a debt payoff goal to start tracking your progress.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.addGoalRoute);
              },
              child: const Text('Add Goal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, DebtPayoffGoal goal) {
    final currency = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);
    final paidPercent = goal.progressPercentage.clamp(0, 100);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 40,
              lineWidth: 8,
              percent: (paidPercent / 100).clamp(0, 1),
              center: Text('${paidPercent.toStringAsFixed(0)}%'),
              progressColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.grey.shade300,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Balance: ${currency.format(goal.currentBalance)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Min Payment: ${currency.format(goal.minimumMonthlyPayment)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppConstants.debtGoalDetailsRoute,
                  arguments: goal,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
