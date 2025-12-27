import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/bill_model.dart';
import '../../viewmodels/bill_viewmodel.dart';

/// Minimal placeholder screen for adding a new bill / recurring payment.
/// This keeps navigation from Quick Actions functional until a full feature
/// is implemented.
class AddBillScreen extends StatefulWidget {
  const AddBillScreen({super.key});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 30)); // Default to 30 days from now
  bool _isRecurring = false;
  String _frequency = 'Monthly';
  bool _isSaving = false;
  String? _category;
  bool _autoPay = false;
  final List<String> _categories = const ['Utilities', 'Subscription', 'Rent', 'Insurance', 'Phone', 'Internet', 'Other'];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in')));
      setState(() => _isSaving = false);
      return;
    }
    final bill = Bill(
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text),
      dueDate: _dueDate,
      isRecurring: _isRecurring,
      frequency: _isRecurring ? _frequency : null,
      category: _category,
      autoPay: _autoPay,
    );
    final success = await Provider.of<BillViewModel>(context, listen: false).addBill(uid, bill);
    setState(() => _isSaving = false);
    if (success && mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Bill')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Bill Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid amount' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Due Date: ${DateFormat.yMMMd().format(_dueDate)}'),
                        ),
                        TextButton(
                          onPressed: _pickDate,
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Recurring'),
                      value: _isRecurring,
                      onChanged: (v) => setState(() => _isRecurring = v),
                    ),
                    if (_isRecurring)
                      DropdownButtonFormField<String>(
                        value: _frequency,
                        decoration: const InputDecoration(labelText: 'Frequency'),
                        items: const [
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly')),
                          DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                        ],
                        onChanged: (v) => setState(() => _frequency = v!),
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      hint: const Text('Select a category'),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _category = v),
                      validator: (v) => v == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto-Pay Enabled'),
                      subtitle: const Text('Mark if this bill is paid automatically.'),
                      value: _autoPay,
                      onChanged: (v) => setState(() => _autoPay = v),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save Bill'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


