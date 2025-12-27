import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingBudget != null ? 'Edit Budget' : 'Add Budget'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Budget Amount'),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid amount' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Text('Start: ${DateFormat.yMMMd().format(_startDate)}')),
                        TextButton(onPressed: () => _pickDate(isStart: true), child: const Text('Select')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: Text('End:   ${DateFormat.yMMMd().format(_endDate)}')),
                        TextButton(onPressed: () => _pickDate(isStart: false), child: const Text('Select')),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _save, child: const Text('Save Budget')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
