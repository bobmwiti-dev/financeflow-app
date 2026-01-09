import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/goal_model.dart';
import '../../viewmodels/goal_viewmodel.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/icon_display.dart';

class EditGoalScreen extends StatefulWidget {
  final Goal goal;

  const EditGoalScreen({super.key, required this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _descriptionController;
  late TextEditingController _contributionController;
  DateTime? _targetDate;
  String? _selectedIcon;
  bool _isSaving = false;

  static const Color _accentColor = AppTheme.primaryColor;

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
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      boxShadow: AppTheme.boxShadow,
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
    _targetAmountController = TextEditingController(text: widget.goal.targetAmount.toString());
    _descriptionController = TextEditingController(text: widget.goal.description);
    _contributionController = TextEditingController(text: widget.goal.targetMonthlyContribution?.toString() ?? '');
    _targetDate = widget.goal.targetDate;
    _selectedIcon = widget.goal.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _descriptionController.dispose();
    _contributionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
      helpText: 'Select target date for your goal',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    setState(() => _isSaving = true);
    final viewModel = context.read<GoalViewModel>();

    final updatedGoal = Goal(
      id: widget.goal.id, // Keep the original ID
      name: _nameController.text.trim(),
      targetAmount: double.tryParse(_targetAmountController.text.trim()) ?? 0,
      currentAmount: widget.goal.currentAmount, // Preserve the current amount
      targetDate: _targetDate,
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      icon: _selectedIcon,
      targetMonthlyContribution: double.tryParse(_contributionController.text.trim()),
      category: widget.goal.category, // Preserve other fields
      priority: widget.goal.priority,
    );

    final success = await viewModel.updateGoal(updatedGoal);
    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.pop(context, true); // Pop back to details screen
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update goal. Please try again.')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${widget.goal.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final viewModel = context.read<GoalViewModel>();
      await viewModel.deleteGoal(widget.goal.id!);
      
      if (mounted) {
        // Pop back to goals list
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Goal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmation(),
            tooltip: 'Delete Goal',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: _premiumCardDecoration(theme),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Goal name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Target amount',
                        prefixText: '\$',
                        hintText: 'e.g., 5000',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final value = double.tryParse(v ?? '');
                        if (value == null || value <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Target date'),
                      subtitle: Text(
                        _targetDate != null ? dateFormat.format(_targetDate!) : 'Select date',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        onPressed: _pickDate,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description (optional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contributionController,
                      decoration: const InputDecoration(
                        labelText: 'Target monthly contribution (optional)',
                        prefixText: '\$',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 24),
                    Text('Choose an icon', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Select an icon that represents your goal category',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    _buildIconPicker(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: AnimatedSwitcher(
                          duration: AppTheme.mediumAnimationDuration,
                          child: _isSaving
                              ? const SizedBox(
                                  key: ValueKey('saving'),
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Update Goal',
                                  key: ValueKey('save'),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    final icons = getAvailableIconKeys();
    
    // Map of icon keys to their descriptions
    final Map<String, String> iconDescriptions = {
      'savings': 'General Savings',
      'car': 'Vehicle/Transport',
      'house': 'Home/Property',
      'vacation': 'Travel/Vacation',
      'gift': 'Gifts/Special',
      'education': 'Education/Learning',
      'electronics': 'Technology/Gadgets',
      'emergency': 'Emergency Fund',
      'other': 'Other Goals',
    };
    
    return SizedBox(
      height: 90, // Increased height to accommodate descriptions
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: icons.length,
        itemBuilder: (context, index) {
          final iconKey = icons[index];
          final isSelected = _selectedIcon == iconKey;
          final description = iconDescriptions[iconKey] ?? iconKey;
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedIcon = iconKey);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 80, // Increased width for descriptions
              child: Column(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? _accentColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? Border.all(color: _accentColor, width: 2) : null,
                    ),
                    child: Center(
                      child: IconDisplay(
                        iconData: iconKey,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? _accentColor : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
