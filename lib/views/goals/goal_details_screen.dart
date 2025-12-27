import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_extensions.dart';
import 'package:provider/provider.dart';

import '../../models/goal_model.dart';
import '../../viewmodels/goal_viewmodel.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/icon_display.dart';
import 'edit_goal_screen.dart';

class GoalDetailsScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailsScreen({super.key, required this.goal});

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {

  @override
  void initState() {
    super.initState();
    // Fetch the contributions when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GoalViewModel>(context, listen: false).fetchContributions(widget.goal.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalViewModel>(
      builder: (context, viewModel, child) {
        final latestGoal = viewModel.goals.firstWhere(
          (g) => g.id == widget.goal.id,
          orElse: () => widget.goal,
        );

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(latestGoal.name),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditGoalScreen(goal: latestGoal),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
                _buildHeader(context, latestGoal),
                const SizedBox(height: 24),
                _buildInfoCard(context, latestGoal),
                const SizedBox(height: 16),
                if (latestGoal.targetMonthlyContribution != null && latestGoal.targetMonthlyContribution! > 0)
                  _buildMonthlyPlanCard(context, latestGoal),
                const SizedBox(height: 16),
                _buildContributionHistory(context, latestGoal),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddFundsDialog(context, latestGoal),
            label: const Text('Add Funds'),
            icon: const Icon(Icons.add),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Goal currentGoal) {
    final progress = (currentGoal.currentAmount / currentGoal.targetAmount).clamp(0.0, 1.0);
    final progressPercent = (progress * 100).toStringAsFixed(1);
    // Using CurrencyService via toCurrency() extension
    Color progressColor;
    if (progress < 0.3) {
      progressColor = AppTheme.errorColor;
    } else if (progress < 0.7) {
      progressColor = AppTheme.warningColor;
    } else {
      progressColor = AppTheme.successColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).cardColor,
          boxShadow: AppTheme.boxShadow,
        ),
        child: SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (currentGoal.icon != null && currentGoal.icon!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: IconDisplay(iconData: currentGoal.icon, size: 32),
                      ),
                    Text(
                      '$progressPercent%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentGoal.currentAmount.toCurrency()} / ${currentGoal.targetAmount.toCurrency()}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Goal currentGoal) {
        final locale = Localizations.localeOf(context).toString();
        final dateFormat = DateFormat('MMM dd, yyyy', locale);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentGoal.name, style: Theme.of(context).textTheme.headlineSmall),
            if (currentGoal.description != null && currentGoal.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(currentGoal.description!, style: Theme.of(context).textTheme.bodyMedium),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Target by: ${currentGoal.targetDate != null ? dateFormat.format(currentGoal.targetDate!) : 'N/A'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyPlanCard(BuildContext context, Goal currentGoal) {
    // Using CurrencyService via toCurrency() extension
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule, color: AppTheme.primaryColor),
        title: const Text('Monthly Plan'),
        subtitle: Text('Target: ${(currentGoal.targetMonthlyContribution ?? 0.0).toCurrency()} / month'),
      ),
    );
  }

  Widget _buildContributionHistory(BuildContext context, Goal currentGoal) {
    final viewModel = context.watch<GoalViewModel>();
    final contributions = viewModel.contributions;
        final locale = Localizations.localeOf(context).toString();
        final dateFormat = DateFormat('MMM dd, yyyy', locale);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contribution History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (contributions.isEmpty)
              const Center(
                child: Text(
                  'No contributions recorded yet.',
                  style: TextStyle(color: AppTheme.secondaryTextColor),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contributions.length,
                itemBuilder: (context, index) {
                  final contribution = contributions[index];
                  return ListTile(
                    leading: const Icon(Icons.arrow_upward, color: AppTheme.successColor),
                    title: Text('+ ${contribution.amount.toCurrency()}'),
                    trailing: Text(dateFormat.format(contribution.date)),
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
              ),
          ],
        ),
      ),
    );
  }

    void _showAddFundsDialog(BuildContext context, Goal currentGoal) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Funds'),
          content: TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  final viewModel = context.read<GoalViewModel>();
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  final success = await viewModel.updateGoalProgress(currentGoal, amount);

                  if (!mounted) return;

                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Contribution added!' : 'Failed to add contribution'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}