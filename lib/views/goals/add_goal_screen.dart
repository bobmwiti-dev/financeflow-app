import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/goal_model.dart';
import '../../viewmodels/goal_viewmodel.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common/icon_display.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contributionController = TextEditingController();
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
      initialDate: _targetDate ?? now.add(const Duration(days: 365)), // Default to 1 year from now
      firstDate: now,
      lastDate: DateTime(now.year + 20), // Allow up to 20 years in future
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

    final goal = Goal(
      name: _nameController.text.trim(),
      targetAmount: double.tryParse(_targetAmountController.text.trim()) ?? 0,
      targetDate: _targetDate,
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      icon: _selectedIcon,
      targetMonthlyContribution: double.tryParse(_contributionController.text.trim()),
    );

    final success = await viewModel.addGoal(goal);
    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save goal. Please try again.')),
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
        title: const Text('Add Goal'),
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
                                  'Save Goal',
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
      'savings': 'General',
      'car': 'Vehicle',
      'house': 'Home',
      'vacation': 'Travel',
      'gift': 'Gifts',
      'education': 'Education',
      'electronics': 'Tech',
      'emergency': 'Emergency',
      'other': 'Other',
    };
    
    return SizedBox(
      height: 110, // Increased height to accommodate descriptions
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
              width: 70, // Slightly reduced width
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                        size: 28, // Slightly reduced icon size
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
                      height: 1.1, // Tighter line height
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
