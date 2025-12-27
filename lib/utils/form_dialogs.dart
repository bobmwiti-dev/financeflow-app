import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'enhanced_animations.dart';
import '../widgets/dashboard/unified_financial_management_panel.dart';

/// A utility class that provides consistent form dialogs for financial items
class FormDialogs {
  /// Shows a modern modal popup to add/edit an income source
  static Future<FinancialManagementItem?> showIncomeFormDialog({
    required BuildContext context,
    FinancialManagementItem? existingItem,
  }) async {
    final nameController = TextEditingController(
      text: existingItem?.name ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingItem?.description ?? '',
    );
    final amountController = TextEditingController(
      text: existingItem?.amount != null
          ? existingItem!.amount.toString()
          : '',
    );
    
    String period = existingItem?.period ?? 'Monthly';
    IconData selectedIcon = existingItem?.icon ?? Icons.account_balance_wallet;
    bool isRecurring = existingItem?.isRecurring ?? true;
    DateTime selectedDate = existingItem?.date ?? DateTime.now();
    
    // Income icons
    final incomeIcons = [
      Icons.account_balance_wallet,
      Icons.work,
      Icons.business_center,
      Icons.trending_up,
      Icons.attach_money,
      Icons.savings,
      Icons.real_estate_agent,
      Icons.design_services,
    ];
    
    // Show modern popup dialog
    return showDialog<FinancialManagementItem>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: EnhancedAnimations.fadeSlide(
          duration: const Duration(milliseconds: 300),
          child: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Income Source',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Name field
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      hintText: 'Income Source Name',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description field
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      hintText: 'Description',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Amount field
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Payment Period dropdown
                  DropdownButtonFormField<String>(
                    value: period,
                    decoration: const InputDecoration(
                      labelText: 'Payment Period',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'Bi-weekly', child: Text('Bi-weekly')),
                      DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly')),
                      DropdownMenuItem(value: 'Annually', child: Text('Annually')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => period = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Received',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Recurring switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recurring Income',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'This income source repeats regularly',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      Switch(
                        value: isRecurring,
                        onChanged: (value) {
                          setState(() {
                            isRecurring = value;
                          });
                        },
                        activeColor: Colors.green.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Icon selection
                  const Text(
                    'Choose an Icon:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: incomeIcons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => selectedIcon = icon);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.green.shade600.withValues(alpha: 0.15) 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.green.shade600 : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? Colors.green.shade600 : Colors.grey.shade700,
                            size: 24,
                          ),
                        ),
                      ).animate(target: isSelected ? 1 : 0)
                        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOutCubic);
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          // Validate inputs
                          if (nameController.text.isEmpty || amountController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please fill all required fields'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                            return;
                          }
                          
                          // Create new income item
                          final item = FinancialManagementItem(
                            id: existingItem?.id ?? const Uuid().v4(),
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            amount: double.tryParse(amountController.text) ?? 0,
                            period: period,
                            icon: selectedIcon,
                            date: selectedDate,
                            isRecurring: isRecurring,
                          );
                          
                          Navigator.of(context).pop(item);
                        },
                        child: Text(
                          existingItem != null ? 'Update' : 'Add',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a modern modal dialog to add/edit a budget category
  static Future<FinancialManagementItem?> showBudgetFormDialog({
    required BuildContext context,
    FinancialManagementItem? existingItem,
  }) async {
    final nameController = TextEditingController(
      text: existingItem?.name ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingItem?.description ?? '',
    );
    final amountController = TextEditingController(
      text: existingItem?.amount != null
          ? existingItem!.amount.toString()
          : '',
    );
    
    String period = existingItem?.period ?? 'Monthly';
    IconData selectedIcon = existingItem?.icon ?? Icons.pie_chart;
    DateTime selectedDate = existingItem?.date ?? DateTime.now();
    
    // Budget icons
    final budgetIcons = [
      Icons.pie_chart,
      Icons.home,
      Icons.restaurant,
      Icons.directions_car,
      Icons.shopping_bag,
      Icons.storefront,
      Icons.card_giftcard,
      Icons.school,
      Icons.medical_services,
      Icons.sports_esports,
    ];
    
    // Show modern popup dialog
    return showDialog<FinancialManagementItem>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: EnhancedAnimations.fadeSlide(
          duration: const Duration(milliseconds: 300),
          child: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingItem != null ? 'Edit Budget Category' : 'Add Budget Category',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Category Name field
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Housing, Food, Transportation',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description field
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Monthly spending limit',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Budget Amount field
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Budget Amount',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Budget Period dropdown
                  DropdownButtonFormField<String>(
                    value: period,
                    decoration: const InputDecoration(
                      labelText: 'Budget Period',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'Bi-weekly', child: Text('Bi-weekly')),
                      DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly')),
                      DropdownMenuItem(value: 'Annually', child: Text('Annually')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => period = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Icon selection
                  const Text(
                    'Choose an Icon:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: budgetIcons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => selectedIcon = icon);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.blue.shade600.withValues(alpha: 0.15) 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.blue.shade600 : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade700,
                            size: 24,
                          ),
                        ),
                      ).animate(target: isSelected ? 1 : 0)
                        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOutCubic);
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                        ),
                        onPressed: () {
                          // Validate inputs
                          if (nameController.text.isEmpty || amountController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please fill all required fields'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                            return;
                          }
                          
                          // Create budget item
                          final item = FinancialManagementItem(
                            id: existingItem?.id ?? const Uuid().v4(),
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            amount: double.tryParse(amountController.text) ?? 0,
                            period: period,
                            icon: selectedIcon,
                            date: selectedDate,
                          );
                          
                          Navigator.of(context).pop(item);
                        },
                        child: Text(
                          existingItem != null ? 'Update' : 'Add',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a modern modal dialog to add/edit a loan
  static Future<FinancialManagementItem?> showLoanFormDialog({
    required BuildContext context,
    FinancialManagementItem? existingItem,
  }) async {
    final nameController = TextEditingController(
      text: existingItem?.name ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingItem?.description ?? '',
    );
    final amountController = TextEditingController(
      text: existingItem?.amount != null
          ? existingItem!.amount.toString()
          : '',
    );
    final interestController = TextEditingController(text: '5.0');
    
    String period = existingItem?.period ?? 'Monthly';
    IconData selectedIcon = existingItem?.icon ?? Icons.account_balance;
    DateTime startDate = existingItem?.date ?? DateTime.now();
    DateTime dueDate = DateTime.now().add(const Duration(days: 365));
    
    // Loan icons
    final loanIcons = [
      Icons.account_balance,
      Icons.home,
      Icons.school,
      Icons.directions_car,
      Icons.credit_card,
      Icons.medical_services,
      Icons.home_repair_service,
      Icons.business,
    ];
    
    // Show modern popup dialog
    return showDialog<FinancialManagementItem>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: EnhancedAnimations.fadeSlide(
          duration: const Duration(milliseconds: 300),
          child: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingItem != null ? 'Edit Loan' : 'Add Loan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Name field
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Loan Name',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Mortgage, Car Loan, etc.',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description field
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Home loan from Bank XYZ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Interest rate field
                  TextField(
                    controller: interestController,
                    decoration: const InputDecoration(
                      labelText: 'Interest Rate (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Monthly payment amount field
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Payment',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Loan start date
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && picked != startDate) {
                        setState(() {
                          startDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(startDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Loan due date
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2050),
                      );
                      if (picked != null && picked != dueDate) {
                        setState(() {
                          dueDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(dueDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Payment frequency dropdown
                  DropdownButtonFormField<String>(
                    value: period,
                    decoration: const InputDecoration(
                      labelText: 'Payment Frequency',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'Bi-weekly', child: Text('Bi-weekly')),
                      DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly')),
                      DropdownMenuItem(value: 'One-time', child: Text('One-time')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => period = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Icon selection
                  const Text(
                    'Choose an Icon:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: loanIcons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => selectedIcon = icon);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.purple.shade600.withValues(alpha: 0.15) 
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.purple.shade600 : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? Colors.purple.shade600 : Colors.grey.shade700,
                            size: 24,
                          ),
                        ),
                      ).animate(target: isSelected ? 1 : 0)
                        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 200.ms, curve: Curves.easeOutCubic);
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                        ),
                        onPressed: () {
                          // Validate inputs
                          if (nameController.text.isEmpty || 
                              amountController.text.isEmpty ||
                              interestController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please fill all required fields'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                            return;
                          }
                          
                          // Create description with interest rate
                          final interest = double.tryParse(interestController.text) ?? 0;
                          final baseDescription = descriptionController.text.trim();
                          final fullDescription = baseDescription.isNotEmpty
                              ? '$baseDescription - ${interest.toStringAsFixed(1)}% interest'
                              : '${interest.toStringAsFixed(1)}% interest';
                          
                          // Create loan item
                          final item = FinancialManagementItem(
                            id: existingItem?.id ?? const Uuid().v4(),
                            name: nameController.text.trim(),
                            description: fullDescription,
                            amount: double.tryParse(amountController.text) ?? 0,
                            period: period,
                            icon: selectedIcon,
                            date: startDate,
                          );
                          
                          Navigator.of(context).pop(item);
                        },
                        child: Text(
                          existingItem != null ? 'Update' : 'Add',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
