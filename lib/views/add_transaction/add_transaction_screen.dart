import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/transaction_model.dart' as models;
import '../../services/transaction_service.dart';
import '../../widgets/account_selector_widget.dart';

class AddTransactionScreen extends StatefulWidget {
  final models.Transaction? transaction;

  const AddTransactionScreen({
    super.key,
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final TransactionService _transactionService = TransactionService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';
  bool _isExpense = true;
  bool _isLoading = false;
  String? _selectedAccountId;
  
  final List<String> _categories = [
    'Food',
    'Shopping',
    'Transportation',
    'Entertainment',
    'Housing',
    'Utilities',
    'Health',
    'Education',
    'Travel',
    'Personal',
    'Gifts',
    'Income',
    'Savings',
    'Investments',
    'Other',
  ];
  

  @override
  void initState() {
    super.initState();
    
    // If editing an existing transaction, populate the fields
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _notesController.text = widget.transaction!.notes ?? '';
      _selectedDate = widget.transaction!.date;
      _selectedCategory = widget.transaction!.category;
      _isExpense = widget.transaction!.isExpense;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final amount = double.parse(_amountController.text);
      
      final transaction = models.Transaction(
        id: widget.transaction?.id,
        title: _titleController.text,
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        type: _isExpense ? models.TransactionType.expense : models.TransactionType.income,
        userId: _auth.currentUser?.uid ?? '',
        accountId: _selectedAccountId ?? 'default_account',
        description: _notesController.text.isEmpty ? null : _notesController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      // logger.info()
      if (widget.transaction != null) {
        // Update existing transaction
        // Get the firestoreId for the transaction to update
        final transactionId = widget.transaction!.firestoreId;
        if (transactionId != null) {
          await _transactionService.updateTransaction(transactionId, transaction);
        } else {
          // If no firestoreId, create as new transaction
          await _transactionService.addTransaction(transaction);
        }
      } else {
        // Add new transaction
        await _transactionService.addTransaction(transaction);
      }
      
      if (mounted) {
        Navigator.pop(context, transaction); // Return the saved transaction
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTransactionTypeSelector(),
                    const SizedBox(height: 24),
                    AccountSelectorWidget(
                      selectedAccountId: _selectedAccountId,
                      onAccountSelected: (accountId) {
                        setState(() {
                          _selectedAccountId = accountId;
                        });
                      },
                      label: 'Account',
                      isRequired: true,
                      hintText: 'Choose account for this transaction',
                    ),
                    const SizedBox(height: 16),
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildCategorySelector(),
                    const SizedBox(height: 16),
                    _buildNotesField(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
              ),
            ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpense = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isExpense 
                      ? Colors.red.withValues(alpha: 0.1) 
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: _isExpense ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expense',
                      style: TextStyle(
                        color: _isExpense ? Colors.red : Colors.grey,
                        fontWeight: _isExpense ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isExpense = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !_isExpense 
                      ? Colors.green.withValues(alpha: 0.1) 
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: !_isExpense ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Income',
                      style: TextStyle(
                        color: !_isExpense ? Colors.green : Colors.grey,
                        fontWeight: !_isExpense ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Amount',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('MMMM d, yyyy').format(_selectedDate),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.transaction != null ? 'Update Transaction' : 'Add Transaction',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
