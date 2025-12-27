import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import '../../viewmodels/budget_viewmodel.dart';
import '../../models/budget_model.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? budget; // Null for new budget, non-null for edit

  const BudgetFormScreen({
    super.key,
    this.budget,
  });

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final Logger _logger = Logger('BudgetFormScreen');
  
  String _selectedCategory = AppConstants.expenseCategories.first;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30)); // Default to 1 month
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // If editing an existing budget, populate the form
    if (widget.budget != null) {
      _amountController.text = widget.budget!.amount.toString();
      _selectedCategory = widget.budget!.category;
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, adjust it
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      
      final budget = Budget(
        id: widget.budget?.id, // Keep existing ID for updates, null for new
        category: _selectedCategory,
        amount: amount,
        startDate: _startDate,
        endDate: _endDate,
        spent: widget.budget?.spent ?? 0.0, // Keep existing spent amount
      );

      final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
      final success = await budgetViewModel.addBudget(budget);
      
      if (success) {
        _logger.info('Budget saved successfully');
        _showSnackBar(
          widget.budget == null ? 'Budget created successfully' : 'Budget updated successfully',
          isError: false,
        );
        if (mounted) {
          Navigator.pop(context, 'saved'); // Return saved status
        }
      } else {
        _logger.warning('Failed to save budget');
        _showSnackBar('Failed to save budget', isError: true);
      }
    } catch (e) {
      _logger.severe('Error saving budget: $e');
      _showSnackBar('Error saving budget: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBudget() async {
    if (widget.budget?.id == null) {
      _logger.warning('Cannot delete budget: ID is null');
      _showSnackBar('Error: Budget ID not found', isError: true);
      return;
    }

    _logger.info('Debug: Calling deleteBudget with ID: ${widget.budget!.id}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      final budgetViewModel = Provider.of<BudgetViewModel>(context, listen: false);
      final success = await budgetViewModel.deleteBudget(widget.budget!.id!);
      
      if (success) {
        _logger.info('Budget deletion successful');
        _showSnackBar('Budget deleted successfully', isError: false);
        if (mounted) {
          Navigator.pop(context, 'deleted'); // Go back to budget list
        }
      } else {
        _logger.warning('Budget deletion failed');
        _showSnackBar('Failed to delete budget', isError: true);
      }
    } catch (e) {
      _logger.severe('Error deleting budget: $e');
      _showSnackBar('Error deleting budget: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.budget != null;
    final title = isEditing ? 'Edit Budget' : 'Create Budget';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmationDialog();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    _buildDateRangePicker(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: AppConstants.expenseCategories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Budget Amount',
        hintText: 'E.g., 500.00',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
        prefixText: '\$ ',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a budget amount';
        }
        try {
          final amount = double.parse(value);
          if (amount <= 0) {
            return 'Amount must be greater than zero';
          }
        } catch (e) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildDateRangePicker() {
    final dateFormat = DateFormat(AppConstants.dateFormat);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Period',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectStartDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_startDate)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectEndDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_endDate)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Duration: ${_endDate.difference(_startDate).inDays + 1} days',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveBudget,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.budget == null ? 'Create Budget' : 'Update Budget',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    _logger.info('Showing delete confirmation dialog for budget: ${widget.budget?.id}');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: Text(
            'Are you sure you want to delete this budget (${widget.budget?.category})? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                _logger.info('Delete cancelled');
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _logger.info('Delete confirmed, closing dialog and calling _deleteBudget');
                Navigator.pop(context); // Close dialog
                _deleteBudget(); // Delete the budget
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

}
