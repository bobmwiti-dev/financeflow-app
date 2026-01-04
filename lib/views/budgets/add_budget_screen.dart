import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/budget_model.dart';
import '../../viewmodels/budget_viewmodel.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _category = 'General';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;
  Budget? _editingBudget;

  final List<String> _categories = [
    'General',
    'Food',
    'Transport',
    'Entertainment',
    'Utilities',
    'Shopping',
  ];

  @override
  void initState() {
    super.initState();
    // Check if we're editing an existing budget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budget = ModalRoute.of(context)?.settings.arguments as Budget?;
      if (budget != null) {
        setState(() {
          _editingBudget = budget;
          _amountController.text = budget.amount.toString();
          _category = budget.category;
          _startDate = budget.startDate;
          _endDate = budget.endDate;
        });
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    final viewModel = Provider.of<BudgetViewModel>(context, listen: false);
    bool success;
    
    if (_editingBudget != null) {
      // Update existing budget
      final updatedBudget = _editingBudget!.copyWith(
        category: _category,
        amount: double.parse(_amountController.text),
        startDate: _startDate,
        endDate: _endDate,
      );
      success = await viewModel.updateBudget(updatedBudget);
    } else {
      // Create new budget
      final budget = Budget(
        category: _category,
        amount: double.parse(_amountController.text),
        startDate: _startDate,
        endDate: _endDate,
      );
      success = await viewModel.addBudget(budget);
    }
    
    setState(() => _isSaving = false);
    if (success && mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = _editingBudget != null;
    final title = isEditing ? 'Edit Budget' : 'Create Budget';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final horizontalPadding =
                      maxWidth > 640 ? (maxWidth - 640) / 2 : 16.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      24,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.surface,
                            colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.96),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.23),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer
                                          .withValues(alpha: 0.95),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.pie_chart_outline,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isEditing
                                              ? 'Adjust this budget to better match your month.'
                                              : 'Create a budget to guide your spending this month.',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isEditing
                                              ? colorScheme.secondaryContainer
                                              : colorScheme.primaryContainer)
                                          .withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isEditing ? 'Editing' : 'New',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: isEditing
                                            ? colorScheme.onSecondaryContainer
                                            : colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              DropdownButtonFormField<String>(
                                value: _category,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon:
                                      const Icon(Icons.category_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                items: _categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _category = v ?? _category),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Budget Amount',
                                  hintText: 'e.g. 50,000',
                                  prefixIcon:
                                      const Icon(Icons.payments_outlined),
                                  prefixText: 'KSh ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                validator: (v) => (v == null ||
                                        double.tryParse(v) == null)
                                    ? 'Enter valid amount'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Budget Period',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _pickDate(isStart: true),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Start',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.calendar_today_outlined,
                                          ),
                                        ),
                                        child: Text(
                                          DateFormat.yMMMd()
                                              .format(_startDate),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _pickDate(isStart: false),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'End',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.calendar_today_outlined,
                                          ),
                                        ),
                                        child: Text(
                                          DateFormat.yMMMd().format(_endDate),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    _save();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: const Text('Save Budget'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
