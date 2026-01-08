import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../viewmodels/loan_viewmodel.dart';
import '../../models/loan_model.dart';
import '../../constants/app_constants.dart';

class LoanFormScreen extends StatefulWidget {
  final Loan? loan; // Null for new loan, non-null for edit

  const LoanFormScreen({
    super.key,
    this.loan,
  });

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _lenderController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final Logger _logger = Logger('LoanFormScreen');
  
  String _status = AppConstants.loanStatusOptions.first;
  String _paymentFrequency = AppConstants.frequencyOptions.first;
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 365)); // Default to 1 year
  bool _isLoading = false;

  LinearGradient get _accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6366F1),
          Color(0xFF8B5CF6),
        ],
      );

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

  @override
  void initState() {
    super.initState();
    
    // If editing an existing loan, populate the form
    if (widget.loan != null) {
      _nameController.text = widget.loan!.name;
      _totalAmountController.text = widget.loan!.totalAmount.toString();
      _amountPaidController.text = widget.loan!.amountPaid.toString();
      _interestRateController.text = widget.loan!.interestRate.toString();
      _lenderController.text = widget.loan!.lender;
      _installmentAmountController.text = widget.loan!.installmentAmount.toString();
      _status = widget.loan!.status;
      _paymentFrequency = widget.loan!.paymentFrequency;
      _startDate = widget.loan!.startDate;
      _dueDate = widget.loan!.dueDate;
      if (widget.loan!.notes != null) {
        _notesController.text = widget.loan!.notes!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalAmountController.dispose();
    _amountPaidController.dispose();
    _interestRateController.dispose();
    _lenderController.dispose();
    _installmentAmountController.dispose();
    _notesController.dispose();
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
        // If due date is before start date, adjust it
        if (_dueDate.isBefore(_startDate)) {
          _dueDate = _startDate.add(const Duration(days: 365));
        }
      });
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isAfter(_startDate) ? _dueDate : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveLoan() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final loanViewModel = Provider.of<LoanViewModel>(context, listen: false);
        
        final loan = Loan(
          id: widget.loan?.id, // Will be null for new loans
          name: _nameController.text,
          totalAmount: double.parse(_totalAmountController.text),
          amountPaid: double.parse(_amountPaidController.text),
          interestRate: double.parse(_interestRateController.text),
          startDate: _startDate,
          dueDate: _dueDate,
          lender: _lenderController.text,
          status: _status,
          paymentFrequency: _paymentFrequency,
          installmentAmount: double.parse(_installmentAmountController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        
        final success = await loanViewModel.addLoan(loan);
        
        if (success) {
          if (mounted) {
            Navigator.pop(context, loan); // Return the saved loan
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save loan')),
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

  Future<void> _deleteLoan() async {
    if (widget.loan?.id == null) {
      _logger.warning('Cannot delete loan - ID is null');
      return;
    }
    
    _logger.info('Attempting to delete loan with ID: ${widget.loan!.id}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      final loanViewModel = Provider.of<LoanViewModel>(context, listen: false);
      _logger.info('Calling loanViewModel.deleteLoan with ID: ${widget.loan!.id}');
      final success = await loanViewModel.deleteLoan(widget.loan!.id!);
      
      _logger.info('Loan deletion result: $success');
      
      if (success) {
        _logger.info('Loan deletion successful, navigating back');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loan deleted successfully')),
          );
          Navigator.pop(context, 'deleted'); // Return deleted status
        }
      } else {
        _logger.warning('Loan deletion failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete loan')),
          );
        }
      }
    } catch (e) {
      _logger.severe('Error deleting loan: $e');
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.loan != null;
    final title = isEditing ? 'Edit Loan' : 'Add Loan';
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: _accentGradient),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.white70],
          ).createShader(bounds),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.white,
              onPressed: () {
                _showDeleteConfirmationDialog();
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: _premiumCardDecoration(theme),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNameField(),
                        const SizedBox(height: 16),
                        _buildLenderField(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTotalAmountField(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInterestRateField(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAmountPaidField(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInstallmentAmountField(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDateRangePicker(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusDropdown(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFrequencyDropdown(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildNotesField(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ).animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
              ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Loan Name',
        hintText: 'E.g., Home Mortgage, Car Loan',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.label),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a name for this loan';
        }
        return null;
      },
    );
  }

  Widget _buildLenderField() {
    return TextFormField(
      controller: _lenderController,
      decoration: const InputDecoration(
        labelText: 'Lender',
        hintText: 'E.g., Bank Name, Person',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the lender name';
        }
        return null;
      },
    );
  }

  Widget _buildTotalAmountField() {
    return TextFormField(
      controller: _totalAmountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Total Amount',
        hintText: 'E.g., 10000.00',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
        prefixText: '\$ ',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the total loan amount';
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

  Widget _buildAmountPaidField() {
    return TextFormField(
      controller: _amountPaidController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Amount Paid',
        hintText: 'E.g., 2000.00',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payments),
        prefixText: '\$ ',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the amount paid';
        }
        try {
          final amountPaid = double.parse(value);
          if (amountPaid < 0) {
            return 'Amount paid cannot be negative';
          }
          if (_totalAmountController.text.isNotEmpty) {
            final totalAmount = double.parse(_totalAmountController.text);
            if (amountPaid > totalAmount) {
              return 'Amount paid cannot exceed total amount';
            }
          }
        } catch (e) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildInterestRateField() {
    return TextFormField(
      controller: _interestRateController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Interest Rate',
        hintText: 'E.g., 5.5',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.percent),
        suffixText: '%',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the interest rate';
        }
        try {
          final rate = double.parse(value);
          if (rate < 0) {
            return 'Interest rate cannot be negative';
          }
        } catch (e) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildInstallmentAmountField() {
    return TextFormField(
      controller: _installmentAmountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Installment Amount',
        hintText: 'E.g., 500.00',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today),
        prefixText: '\$ ',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the installment amount';
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
          'Loan Period',
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
                onTap: () => _selectDueDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_dueDate)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Duration: ${_dueDate.difference(_startDate).inDays} days',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.info),
      ),
      items: AppConstants.loanStatusOptions.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _status = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a status';
        }
        return null;
      },
    );
  }

  Widget _buildFrequencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _paymentFrequency,
      decoration: const InputDecoration(
        labelText: 'Payment Frequency',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.repeat),
      ),
      items: AppConstants.frequencyOptions.map((frequency) {
        return DropdownMenuItem<String>(
          value: frequency,
          child: Text(frequency),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _paymentFrequency = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a payment frequency';
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        hintText: 'Add any additional details about this loan',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: _accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _saveLoan,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Center(
              child: Text(
                widget.loan != null ? 'Update Loan' : 'Add Loan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Loan'),
          content: const Text(
            'Are you sure you want to delete this loan? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(ctx).pop(); // Dismiss dialog
                _deleteLoan();      // Call the delete method
              },
            ),
          ],
        );
      },
    );
  }
}
