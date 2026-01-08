import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/transaction_model.dart' as models;
import '../../services/transaction_service.dart';
import '../../widgets/account_selector_widget.dart';

class AddTransactionScreen extends StatefulWidget {
  final models.Transaction? transaction;
  final bool expenseOnly;
  final bool? initialIsExpense;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.expenseOnly = false,
    this.initialIsExpense,
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

  bool get _isTypeLocked => widget.expenseOnly && widget.transaction == null;

  BoxDecoration _premiumCardDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.surface,
          colorScheme.surfaceContainerHighest,
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.08),
          blurRadius: 28,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }
  
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
    } else {
      if (widget.initialIsExpense != null) {
        _isExpense = widget.initialIsExpense!;
      }
    }

    if (_isTypeLocked) {
      _isExpense = true;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.transaction != null;
    final title = _isTypeLocked
        ? (isEditing ? 'Edit Expense' : 'Add Expense')
        : (isEditing
            ? (_isExpense ? 'Edit Expense' : 'Edit Income')
            : (_isExpense ? 'Add Expense' : 'Add Income'));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isExpense
                  ? const [Color(0xFF6366F1), Color(0xFF8B5CF6)]
                  : [Colors.green.shade600, Colors.teal.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
              child: SafeArea(
                top: false,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: _premiumCardDecoration(colorScheme),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildTransactionTypeSelector(theme, colorScheme),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: _premiumCardDecoration(colorScheme),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
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
                              const SizedBox(height: 12),
                              _buildTitleField(theme, colorScheme),
                              const SizedBox(height: 12),
                              _buildAmountField(theme, colorScheme),
                              const SizedBox(height: 12),
                              _buildDateField(theme, colorScheme),
                              const SizedBox(height: 12),
                              _buildCategorySelector(theme, colorScheme),
                              const SizedBox(height: 12),
                              _buildNotesField(theme, colorScheme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: _buildSubmitButton(theme, colorScheme),
              ),
            ),
    );
  }

  Widget _buildTransactionTypeSelector(ThemeData theme, ColorScheme colorScheme) {
    if (_isTypeLocked) {
      return Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.arrow_downward,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Expense',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _setTransactionType(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isExpense
                    ? colorScheme.errorContainer.withValues(alpha: 0.35)
                    : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    color: _isExpense ? colorScheme.error : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expense',
                    style: TextStyle(
                      color: _isExpense ? colorScheme.error : colorScheme.onSurfaceVariant,
                      fontWeight: _isExpense ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 1,
          height: 44,
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _setTransactionType(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !_isExpense
                    ? colorScheme.secondaryContainer.withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: !_isExpense ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Income',
                    style: TextStyle(
                      color: !_isExpense ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      fontWeight: !_isExpense ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String labelText,
    required IconData icon,
    String? hintText,
  }) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.8)),
    );
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: colorScheme.surface,
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
    );
  }

  Widget _buildTitleField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _titleController,
      textInputAction: TextInputAction.next,
      decoration: _fieldDecoration(
        theme,
        colorScheme,
        labelText: 'Title',
        hintText: 'e.g. Lunch, Uber, Rent',
        icon: Icons.title,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _amountController,
      textInputAction: TextInputAction.next,
      decoration: _fieldDecoration(
        theme,
        colorScheme,
        labelText: 'Amount',
        hintText: '0.00',
        icon: Icons.attach_money,
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

  Widget _buildDateField(ThemeData theme, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: _fieldDecoration(
          theme,
          colorScheme,
          labelText: 'Date',
          icon: Icons.calendar_today,
        ),
        child: Text(
          DateFormat('MMMM d, yyyy').format(_selectedDate),
        ),
      ),
    );
  }

  List<String> _categoriesForSelectedType() {
    if (_isExpense) {
      return _categories
          .where((c) => c != 'Income' && c != 'Savings' && c != 'Investments')
          .toList();
    }
    return _categories;
  }

  void _setTransactionType(bool isExpense) {
    setState(() {
      _isExpense = isExpense;
      final categories = _categoriesForSelectedType();
      if (!categories.contains(_selectedCategory)) {
        _selectedCategory = categories.first;
      }
    });
  }

  Widget _buildCategorySelector(ThemeData theme, ColorScheme colorScheme) {
    final categories = _categoriesForSelectedType();
    final selectedValue = categories.contains(_selectedCategory) ? _selectedCategory : categories.first;
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: _fieldDecoration(
        theme,
        colorScheme,
        labelText: 'Category',
        icon: Icons.category,
      ),
      items: categories.map((category) {
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

  Widget _buildNotesField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _notesController,
      minLines: 1,
      maxLines: 4,
      decoration: _fieldDecoration(
        theme,
        colorScheme,
        labelText: 'Notes (Optional)',
        hintText: 'Add a note for this transaction',
        icon: Icons.note,
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, ColorScheme colorScheme) {
    final isEditing = widget.transaction != null;
    final label = _isTypeLocked
        ? (isEditing ? 'Update Expense' : 'Add Expense')
        : (isEditing
            ? (_isExpense ? 'Update Expense' : 'Update Income')
            : (_isExpense ? 'Add Expense' : 'Add Income'));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isExpense
              ? const [Color(0xFF6366F1), Color(0xFF8B5CF6)]
              : [Colors.green.shade600, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isExpense ? const Color(0xFF6366F1) : Colors.green)
                .withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _saveTransaction,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
