import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/emergency_fund_viewmodel.dart';
import '../../../viewmodels/income_viewmodel.dart';
import '../../../models/emergency_fund_model.dart';
import '../../../utils/currency_extensions.dart';

/// Enhanced Emergency Fund Card with improved CRUD operations and visual polish
class EnhancedEmergencyFundCard extends StatefulWidget {
  const EnhancedEmergencyFundCard({super.key});

  @override
  State<EnhancedEmergencyFundCard> createState() => _EnhancedEmergencyFundCardState();
}

class _EnhancedEmergencyFundCardState extends State<EnhancedEmergencyFundCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.forward();
      _pulseController.repeat();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<EmergencyFundViewModel, IncomeViewModel>(
      builder: (context, emergencyFundVM, incomeVM, child) {
        final emergencyFund = emergencyFundVM.emergencyFund;
        final monthlyIncome = incomeVM.getTotalIncome();
        final estimatedExpenses = monthlyIncome * 0.7;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return MouseRegion(
          onEnter: (_) {
            if (mounted) {
              setState(() => _isHovered = true);
            }
          },
          onExit: (_) {
            if (mounted) {
              setState(() => _isHovered = false);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.98),
                  colorScheme.surface.withValues(alpha: 0.98),
                ],
              ),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isHovered ? 0.16 : 0.08),
                  blurRadius: _isHovered ? 24 : 18,
                  offset: Offset(0, _isHovered ? 14 : 10),
                ),
              ],
            ),
            child: emergencyFund == null
                ? _buildSetupCard(context, emergencyFundVM, estimatedExpenses)
                : _buildFundCard(context, emergencyFundVM, emergencyFund),
          ),
        ).animate()
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildSetupCard(BuildContext context, EmergencyFundViewModel viewModel, double estimatedExpenses) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.security_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Fund',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Build financial security',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.tertiary.withValues(alpha: 0.12),
                  colorScheme.tertiaryContainer.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.tertiary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 48,
                  color: const Color(0xFFFF9800),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Start Your Emergency Fund',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Protect yourself from unexpected expenses with 3-6 months of living costs',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSetupOption(
                        context,
                        'Quick Setup',
                        'Based on your income',
                        estimatedExpenses * 3,
                        () => _createEmergencyFund(context, viewModel, estimatedExpenses, 3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSetupOption(
                        context,
                        'Recommended',
                        '6 months coverage',
                        estimatedExpenses * 6,
                        () => _createEmergencyFund(context, viewModel, estimatedExpenses, 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showCustomSetupDialog(context, viewModel, estimatedExpenses),
                  icon: const Icon(Icons.tune),
                  label: const Text('Custom Setup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.tertiary,
                    side: BorderSide(color: colorScheme.tertiary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupOption(BuildContext context, String title, String subtitle, double amount, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.tertiary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              amount.toKenyaDualCurrency(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundCard(BuildContext context, EmergencyFundViewModel viewModel, EmergencyFund fund) {
    final progress = fund.progressPercentage / 100;
    final isComplete = fund.isComplete;
    final progressColor = _getProgressColor(progress);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFundHeader(context, viewModel, fund),
          const SizedBox(height: 20),
          _buildAmountDisplay(fund, progressColor),
          const SizedBox(height: 20),
          _buildProgressBar(progress, progressColor, isComplete),
          const SizedBox(height: 16),
          _buildStatusSection(fund, isComplete),
          const SizedBox(height: 20),
          _buildActionButtons(context, viewModel, fund),
        ],
      ),
    );
  }

  Widget _buildFundHeader(BuildContext context, EmergencyFundViewModel viewModel, EmergencyFund fund) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.security,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency Fund',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Financial security buffer',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'add':
                HapticFeedback.selectionClick();
                _showTransactionDialog(context, viewModel, true);
                break;
              case 'withdraw':
                HapticFeedback.selectionClick();
                _showTransactionDialog(context, viewModel, false);
                break;
              case 'edit':
                HapticFeedback.selectionClick();
                _showEditTargetDialog(context, viewModel, fund);
                break;
              case 'delete':
                HapticFeedback.selectionClick();
                _showDeleteConfirmation(context, viewModel);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'add',
              child: Row(
                children: [
                  Icon(Icons.add, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text('Add Funds'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'withdraw',
              child: Row(
                children: [
                  Icon(Icons.remove, color: Color(0xFFFF5722)),
                  SizedBox(width: 8),
                  Text('Withdraw'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF2196F3)),
                  SizedBox(width: 8),
                  Text('Edit Target'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Color(0xFFFF5722)),
                  SizedBox(width: 8),
                  Text('Delete Fund'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.more_vert,
              color: Colors.grey,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountDisplay(EmergencyFund fund, Color progressColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Amount',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fund.currentAmount.toKenyaDualCurrency(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Target Amount',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fund.targetAmount.toKenyaDualCurrency(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${fund.targetMonths} months',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress, Color progressColor, bool isComplete) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(1)}% Complete',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
            if (isComplete)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'FUNDED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress * _progressController.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        progressColor,
                        progressColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isComplete ? [
                      BoxShadow(
                        color: progressColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(EmergencyFund fund, bool isComplete) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remaining = fund.remainingAmount;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.info_outline,
            color: isComplete ? colorScheme.primary : colorScheme.tertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete 
                    ? 'Fully Funded!' 
                    : '${remaining.toKenyaDualCurrency()} remaining',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isComplete ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isComplete
                    ? 'Your emergency fund provides excellent financial security'
                    : 'Keep building to reach your ${fund.targetMonths}-month target',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EmergencyFundViewModel viewModel, EmergencyFund fund) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              _showTransactionDialog(context, viewModel, true);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Funds'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: fund.currentAmount > 0 
              ? () {
                  HapticFeedback.selectionClick();
                  _showTransactionDialog(context, viewModel, false);
                }
              : null,
            icon: const Icon(Icons.remove, size: 18),
            label: const Text('Withdraw'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return const Color(0xFF4CAF50);
    if (progress >= 0.7) return const Color(0xFF8BC34A);
    if (progress >= 0.4) return const Color(0xFFFFC107);
    return const Color(0xFFFF9800);
  }

  Future<void> _createEmergencyFund(BuildContext context, EmergencyFundViewModel viewModel, double monthlyExpenses, int months) async {
    final success = await viewModel.createEmergencyFund(
      monthlyExpenses: monthlyExpenses,
      targetMonths: months,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? 'Emergency fund created with $months-month target!'
              : 'Failed to create emergency fund. Please try again.',
          ),
          backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
        ),
      );
    }
  }

  void _showCustomSetupDialog(BuildContext context, EmergencyFundViewModel viewModel, double estimatedExpenses) {
    final targetController = TextEditingController();
    final monthsController = TextEditingController(text: '6');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Emergency Fund Setup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Amount',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
                hintText: (estimatedExpenses * 6).toStringAsFixed(0),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: monthsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Months',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
                hintText: '6',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final targetText = targetController.text.trim();
              final monthsText = monthsController.text.trim();
              
              final targetAmount = double.tryParse(targetText) ?? (estimatedExpenses * 6);
              final months = int.tryParse(monthsText) ?? 6;
              
              Navigator.of(context).pop();
              
              final success = await viewModel.createEmergencyFund(
                monthlyExpenses: targetAmount / months,
                targetMonths: months,
              );
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? 'Custom emergency fund created!'
                        : 'Failed to create emergency fund. Please try again.',
                    ),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                  ),
                );
              }
            },
            child: const Text('Create Fund'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDialog(BuildContext context, EmergencyFundViewModel viewModel, bool isAdding) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdding ? 'Add to Emergency Fund' : 'Withdraw from Emergency Fund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
                hintText: isAdding ? 'Enter amount to add' : 'Enter amount to withdraw',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Reason for transaction',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amountText = amountController.text.trim();
              if (amountText.isEmpty) return;
              
              final amount = double.tryParse(amountText);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              Navigator.of(context).pop();
              
              bool success;
              if (isAdding) {
                success = await viewModel.addAmount(amount);
              } else {
                success = await viewModel.withdrawAmount(amount);
              }
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                        ? '${isAdding ? 'Added' : 'Withdrew'} ${amount.toKenyaDualCurrency()} ${isAdding ? 'to' : 'from'} emergency fund'
                        : 'Transaction failed. Please try again.',
                    ),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdding ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
              foregroundColor: Colors.white,
            ),
            child: Text(isAdding ? 'Add Funds' : 'Withdraw'),
          ),
        ],
      ),
    );
  }

  void _showEditTargetDialog(BuildContext context, EmergencyFundViewModel viewModel, EmergencyFund fund) {
    final targetController = TextEditingController(text: fund.targetAmount.toStringAsFixed(0));
    final monthsController = TextEditingController(text: fund.targetMonths.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Emergency Fund Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Amount (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: monthsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Months',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final targetAmount = double.tryParse(targetController.text.trim()) ?? fund.targetAmount;
              final months = int.tryParse(monthsController.text.trim()) ?? fund.targetMonths;
              
              Navigator.of(context).pop();
              
              final success = await viewModel.updateTarget(targetAmount, months);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? 'Emergency fund target updated!'
                        : 'Failed to update target. Please try again.',
                    ),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, EmergencyFundViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Emergency Fund'),
        content: const Text(
          'Are you sure you want to delete your emergency fund? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await viewModel.deleteEmergencyFund();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? 'Emergency fund deleted'
                        : 'Failed to delete emergency fund. Please try again.',
                    ),
                    backgroundColor: success ? const Color(0xFF4CAF50) : const Color(0xFFFF5722),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
