import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/income_viewmodel.dart';
import '../../models/income_source_model.dart';
import '../../themes/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../widgets/account_selector_widget.dart';

class IncomeFormScreen extends StatefulWidget {
  final IncomeSource? incomeSource; // Null for new income source, non-null for edit

  const IncomeFormScreen({
    super.key,
    this.incomeSource,
  });

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = AppConstants.incomeSourceTypes.first;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;
  String _frequency = AppConstants.frequencyOptions.first;
  bool _isLoading = false;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    
    // If editing an existing income source, populate the form
    if (widget.incomeSource != null) {
      _nameController.text = widget.incomeSource!.name;
      _amountController.text = widget.incomeSource!.amount.toString();
      _selectedType = widget.incomeSource!.type;
      _date = widget.incomeSource!.date;
      _isRecurring = widget.incomeSource!.isRecurring;
      _frequency = widget.incomeSource!.frequency;
      _selectedAccountId = widget.incomeSource!.accountId;
      if (widget.incomeSource!.notes != null) {
        _notesController.text = widget.incomeSource!.notes!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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

  InputDecoration _fieldDecoration(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String labelText,
    required IconData icon,
    String? hintText,
    String? prefixText,
    bool alignLabelWithHint = false,
  }) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.8)),
    );
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: colorScheme.surface,
      alignLabelWithHint: alignLabelWithHint,
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _saveIncomeSource() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
        
        final incomeSource = IncomeSource(
          id: widget.incomeSource?.id, // Will be null for new income sources
          name: _nameController.text,
          type: _selectedType,
          amount: double.parse(_amountController.text),
          date: _date,
          isRecurring: _isRecurring,
          frequency: _frequency,
          accountId: _selectedAccountId ?? 'default_account',
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        
        await incomeViewModel.addIncomeSource(incomeSource);
        if (mounted) {
          if (mounted) {
            Navigator.pop(context, true); // Return success
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save income source')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
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
  }

  Future<void> _deleteIncomeSource() async {
    if (widget.incomeSource?.id == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final incomeViewModel = Provider.of<IncomeViewModel>(context, listen: false);
      final id = widget.incomeSource!.id!;
      await incomeViewModel.deleteIncomeSource(id);
      if (mounted) {
        if (mounted) {
          Navigator.pop(context, 'deleted'); // Return deleted status
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete income source')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
    final isEditing = widget.incomeSource != null;
    final title = isEditing ? 'Edit Income Source' : 'Add Income Source';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                    child: Container(
                      decoration: _premiumCardDecoration(colorScheme),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            hintText: 'Choose account for this income',
                          ),
                          const SizedBox(height: 12),
                          _buildNameField(theme, colorScheme),
                          const SizedBox(height: 12),
                          _buildTypeDropdown(theme, colorScheme),
                          const SizedBox(height: 12),
                          _buildAmountField(theme, colorScheme),
                          const SizedBox(height: 12),
                          _buildDatePicker(theme, colorScheme),
                          const SizedBox(height: 12),
                          _buildRecurringToggle(theme, colorScheme),
                          if (_isRecurring) ...[
                            const SizedBox(height: 12),
                            _buildFrequencyDropdown(theme, colorScheme),
                          ],
                          const SizedBox(height: 12),
                          _buildNotesField(theme, colorScheme),
                        ],
                      ),
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
                child: _buildSaveButton(),
              ),
            ),
    );
  }

  Widget _buildNameField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _nameController,
      decoration: _fieldDecoration(
        theme,
        colorScheme,
        labelText: 'Income Source Name',
        hintText: 'E.g., Monthly Salary, Freelance Project',
        icon: Icons.label,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a name for this income source';
        }
        return null;
      },
    );
  }

  Widget _buildTypeDropdown(ThemeData theme, ColorScheme colorScheme) {
    // Ensure selected type exists in the list
    if (!AppConstants.incomeSourceTypes.contains(_selectedType)) {
      _selectedType = AppConstants.incomeSourceTypes.first;
    }
    
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: _fieldDecoration(
        theme,
        colorScheme,
        labelText: 'Income Type',
        icon: Icons.category,
      ),
      items: AppConstants.incomeSourceTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedType = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an income type';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: _fieldDecoration(
        theme,
        colorScheme,
        labelText: 'Amount',
        hintText: 'E.g., 1500.00',
        icon: Icons.attach_money,
        prefixText: '\$ ',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
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

  Widget _buildDatePicker(ThemeData theme, ColorScheme colorScheme) {
    final dateFormat = DateFormat(AppConstants.dateFormat);
    
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: _fieldDecoration(
          theme,
          colorScheme,
          labelText: 'Date Received',
          icon: Icons.calendar_today,
        ),
        child: Text(dateFormat.format(_date)),
      ),
    );
  }

  Widget _buildRecurringToggle(ThemeData theme, ColorScheme colorScheme) {
    return SwitchListTile(
      title: const Text('Recurring Income'),
      subtitle: Text(
        'This income source repeats regularly',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      value: _isRecurring,
      activeColor: AppTheme.primaryColor,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        setState(() {
          _isRecurring = value;
        });
      },
    );
  }

  Widget _buildFrequencyDropdown(ThemeData theme, ColorScheme colorScheme) {
    // Ensure selected frequency exists in the list
    if (!AppConstants.frequencyOptions.contains(_frequency)) {
      _frequency = AppConstants.frequencyOptions.first;
    }
    
    return DropdownButtonFormField<String>(
      value: _frequency,
      decoration: _fieldDecoration(
        theme,
        colorScheme,
        labelText: 'Frequency',
        icon: Icons.repeat,
      ),
      items: AppConstants.frequencyOptions.map((frequency) {
        return DropdownMenuItem<String>(
          value: frequency,
          child: Text(frequency),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _frequency = value;
          });
        }
      },
    );
  }

  Widget _buildNotesField(ThemeData theme, ColorScheme colorScheme) {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: _fieldDecoration(
        theme,
        colorScheme,
        labelText: 'Notes (Optional)',
        hintText: 'Add any additional details about this income source',
        icon: Icons.note,
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSaveButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _saveIncomeSource,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            widget.incomeSource != null ? 'Update Income Source' : 'Add Income Source',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Income Source'),
          content: const Text(
            'Are you sure you want to delete this income source? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteIncomeSource(); // Delete the income source
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
