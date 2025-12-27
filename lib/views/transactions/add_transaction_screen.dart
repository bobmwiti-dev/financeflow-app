import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart' as models;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/transaction_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/animated_buttons.dart';
import '../../widgets/account_selector_widget.dart';

class AddTransactionScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialCategory;
  final models.Transaction? transaction;
  
  const AddTransactionScreen({
    super.key, 
    this.initialDate,
    this.initialCategory,
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';
  String _selectedPaymentMethod = 'Cash';
  bool _isExpense = true;
  bool _isLoading = false;
  String? _selectedAccountId;
  
  final TransactionService _transactionService = TransactionService.instance;
  
  // Predefined categories and payment methods
  final List<String> _categories = [
    'Food', 
    'Transportation', 
    'Entertainment', 
    'Shopping', 
    'Utilities', 
    'Health', 
    'Education',
    'Rent',
    'Salary',
    'Investment',
    'Other'
  ];
  
  final List<String> _paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'UPI',
    'Bank Transfer',
    'Other'
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Set initial values if provided
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Parse amount and adjust sign based on transaction type
      double amount = double.parse(_amountController.text);
      if (_isExpense) {
        amount = -amount; // Expenses are negative
      }
      
      // Create transaction object
      final transaction = models.Transaction(
        title: _titleController.text.trim(),
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        type: _isExpense ? models.TransactionType.expense : models.TransactionType.income,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        accountId: _selectedAccountId ?? 'default_account',
        status: models.TransactionStatus.completed, // Default for new transactions
      );
      
      // Save to Firestore
      final result = await _transactionService.addTransaction(transaction);
      
      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add transaction'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: Text(_isExpense ? 'Add Expense' : 'Add Income'),
        backgroundColor: _isExpense ? AppTheme.primaryColor : Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Toggle between expense and income
          IconButton(
            icon: Icon(_isExpense ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              setState(() {
                _isExpense = !_isExpense;
              });
            },
            tooltip: _isExpense ? 'Switch to Income' : 'Switch to Expense',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Account selector
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
              ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 16),
              
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 16),
              
              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 16),
              
              // Date picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
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
              ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 16),
              
              // Payment method dropdown
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: const Icon(Icons.payment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  }
                },
              ).animate().fadeIn(duration: 300.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ).animate().fadeIn(duration: 300.ms, delay: 500.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 24),
              
              // Save button
              AnimatedButtons.primaryButton(
                label: 'Save Transaction',
                onPressed: _isLoading ? () {} : () => _saveTransaction(),
                icon: Icons.save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
