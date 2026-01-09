import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_extensions.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../models/goal_model.dart';
import '../../viewmodels/goal_viewmodel.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/icon_display.dart';
import 'edit_goal_screen.dart';

class GoalDetailsScreen extends StatefulWidget {
  final Goal goal;
  final String? heroTag;

  const GoalDetailsScreen({super.key, required this.goal, this.heroTag});

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {

  static const Color _accentColor = AppTheme.primaryColor;

  LinearGradient get _accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.primaryColor,
          AppTheme.secondaryColor,
        ],
      );

  BoxDecoration _premiumCardDecoration(ThemeData theme, {double radius = 24}) {
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
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      boxShadow: AppTheme.boxShadow,
    );
  }

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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final latestGoal = viewModel.goals.firstWhere(
          (g) => g.id == widget.goal.id,
          orElse: () => widget.goal,
        );

        return Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            title: Text(
              latestGoal.name,
            ),
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withAlpha((0.06 * 255).toInt()),
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildHeader(context, latestGoal),
                        const SizedBox(height: 24),
                        _buildInfoCard(context, latestGoal),
                        const SizedBox(height: 16),
                        if (latestGoal.targetMonthlyContribution != null &&
                            latestGoal.targetMonthlyContribution! > 0)
                          _buildMonthlyPlanCard(context, latestGoal),
                        const SizedBox(height: 16),
                        _buildContributionHistoryHeader(context, latestGoal),
                      ],
                    ),
                  ),
                ),
                ..._buildContributionHistorySlivers(context, latestGoal),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAddFundsDialog(context, latestGoal);
            },
            label: const Text('Add Funds'),
            icon: const Icon(Icons.add),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Goal currentGoal) {
    final theme = Theme.of(context);
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

    final header = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface,
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

    if (widget.heroTag == null) return header;

    return Hero(
      tag: widget.heroTag!,
      child: Material(
        type: MaterialType.transparency,
        child: header,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Goal currentGoal) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('MMM dd, yyyy', locale);
    return Container(
      decoration: _premiumCardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentGoal.name, style: theme.textTheme.headlineSmall),
            if (currentGoal.description != null && currentGoal.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(currentGoal.description!, style: theme.textTheme.bodyMedium),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Target by: ${currentGoal.targetDate != null ? dateFormat.format(currentGoal.targetDate!) : 'N/A'}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyPlanCard(BuildContext context, Goal currentGoal) {
    // Using CurrencyService via toCurrency() extension
    final theme = Theme.of(context);
    return Container(
      decoration: _premiumCardDecoration(theme),
      child: ListTile(
        leading: Icon(Icons.schedule, color: _accentColor),
        title: const Text('Monthly Plan'),
        subtitle: Text(
          'Target: ${(currentGoal.targetMonthlyContribution ?? 0.0).toCurrency()} / month',
        ),
      ),
    );
  }

  Widget _buildContributionHistoryHeader(BuildContext context, Goal currentGoal) {
    final theme = Theme.of(context);
    return Container(
      decoration: _premiumCardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contribution History', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContributionHistorySlivers(BuildContext context, Goal currentGoal) {
    final viewModel = context.watch<GoalViewModel>();
    final contributions = viewModel.contributions;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('MMM dd, yyyy', locale);

    if (contributions.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: _premiumCardDecoration(Theme.of(context)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No contributions recorded yet.',
                    style: TextStyle(color: AppTheme.secondaryTextColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverList.separated(
          itemCount: contributions.length,
          itemBuilder: (context, index) {
            final contribution = contributions[index];
            return Container(
              decoration: _premiumCardDecoration(
                Theme.of(context),
                radius: 16,
              ),
              child: ListTile(
                leading: const Icon(Icons.arrow_upward, color: AppTheme.successColor),
                title: Text('+ ${contribution.amount.toCurrency()}'),
                trailing: Text(dateFormat.format(contribution.date)),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 0),
        ),
      ),
    ];
  }

  void _showAddFundsDialog(BuildContext context, Goal currentGoal) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: _premiumCardDecoration(theme),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: _accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) => _accentGradient.createShader(bounds),
                        child: const Text(
                          'Add Funds',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.2),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        _accentColor.withValues(alpha: 0.02),
                        colorScheme.surface,
                      ],
                    ),
                  ),
                  child: TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                      prefixStyle: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount = double.tryParse(amountController.text);
                          if (amount != null && amount > 0) {
                            final viewModel = context.read<GoalViewModel>();
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);

                            final success = await viewModel.updateGoalProgress(currentGoal, amount);

                            if (success) {
                              HapticFeedback.heavyImpact();
                            } else {
                              HapticFeedback.vibrate();
                            }

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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}