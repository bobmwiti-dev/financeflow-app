import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/family_member_model.dart';

class AddFamilyMemberDialog extends StatefulWidget {
  const AddFamilyMemberDialog({super.key});

  @override
  State<AddFamilyMemberDialog> createState() => _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState extends State<AddFamilyMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _emailController = TextEditingController();
  
  FamilyRole _selectedRole = FamilyRole.child;
  DateTime? _dateOfBirth;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _updateBudgetBasedOnRole();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateBudgetBasedOnRole() {
    final suggestedBudget = FamilyMember.rolePresets[_selectedRole] ?? 200.0;
    _budgetController.text = suggestedBudget.toStringAsFixed(0);
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );
    
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _saveMember() {
    if (_formKey.currentState!.validate()) {
      final member = FamilyMember(
        name: _nameController.text.trim(),
        budget: double.parse(_budgetController.text),
        role: _selectedRole,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        dateOfBirth: _dateOfBirth,
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      Navigator.of(context).pop(member);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add, color: Colors.blue),
          SizedBox(width: 8),
          Text('Add Family Member'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'Enter family member name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                
                const SizedBox(height: 16),
                
                // Role Selection
                const Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: FamilyRole.values.map((role) {
                      return RadioListTile<FamilyRole>(
                        title: Row(
                          children: [
                            Icon(FamilyMember.roleIcons[role], size: 20),
                            const SizedBox(width: 8),
                            Text(FamilyMember.roleDisplayNames[role]!),
                          ],
                        ),
                        subtitle: Text(
                          'Suggested budget: \$${FamilyMember.rolePresets[role]?.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        value: role,
                        groupValue: _selectedRole,
                        onChanged: (FamilyRole? value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                              _updateBudgetBasedOnRole();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Budget Field
                TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Budget *',
                    hintText: 'Enter monthly budget',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    suffixText: 'USD',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Budget is required';
                    }
                    final budget = double.tryParse(value);
                    if (budget == null) {
                      return 'Please enter a valid number';
                    }
                    if (budget < 0) {
                      return 'Budget cannot be negative';
                    }
                    if (budget > 10000) {
                      return 'Budget seems too high (max: \$10,000)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Date of Birth
                InkWell(
                  onTap: _selectDateOfBirth,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date of Birth (Optional)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _dateOfBirth != null
                                    ? DateFormat('MMM dd, yyyy').format(_dateOfBirth!)
                                    : 'Tap to select date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _dateOfBirth != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_dateOfBirth != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _dateOfBirth = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Email Field (Optional)
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (Optional)',
                    hintText: 'Enter email address',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Active Status
                SwitchListTile(
                  title: const Text('Active Member'),
                  subtitle: const Text('Member can make purchases'),
                  value: _isActive,
                  onChanged: (bool value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Budget Recommendation
                if (_dateOfBirth != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recommended budget for this age: \$${_getRecommendedBudget().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveMember,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Member'),
        ),
      ],
    );
  }

  double _getRecommendedBudget() {
    if (_dateOfBirth == null) return FamilyMember.rolePresets[_selectedRole] ?? 200.0;
    
    final age = DateTime.now().year - _dateOfBirth!.year;
    
    switch (_selectedRole) {
      case FamilyRole.child:
        if (age < 8) return 50.0;
        if (age < 12) return 100.0;
        return 200.0;
      case FamilyRole.teen:
        if (age < 16) return 300.0;
        return 500.0;
      case FamilyRole.parent:
      case FamilyRole.guardian:
        return FamilyMember.rolePresets[_selectedRole] ?? 1500.0;
    }
  }
}
