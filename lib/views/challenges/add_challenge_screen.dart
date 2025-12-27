import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/spending_challenge_model.dart';
import '../../viewmodels/challenge_view_model.dart';
import '../../constants/app_constants.dart';

class AddChallengeScreen extends StatefulWidget {
  final SpendingChallenge? challenge; // Optional challenge for editing
  
  const AddChallengeScreen({super.key, this.challenge});

  @override
  State<AddChallengeScreen> createState() => _AddChallengeScreenState();
}

class _AddChallengeScreenState extends State<AddChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  
  ChallengeType _selectedType = ChallengeType.noSpend;
  ChallengeDifficulty _selectedDifficulty = ChallengeDifficulty.medium;
  ChallengeStatus _selectedStatus = ChallengeStatus.active;
  
  final List<String> _selectedCategories = [];
  
  @override
  void initState() {
    super.initState();
    
    // If editing an existing challenge, populate the form
    if (widget.challenge != null) {
      final challenge = widget.challenge!;
      _titleController.text = challenge.title;
      _descriptionController.text = challenge.description;
      _targetAmountController.text = challenge.targetAmount.toString();
      _currentAmountController.text = challenge.currentAmount.toString();
      _startDate = challenge.startDate;
      _endDate = challenge.endDate;
      _selectedType = challenge.type;
      _selectedDifficulty = challenge.difficulty;
      _selectedStatus = challenge.status;
      _selectedCategories.addAll(challenge.categories);
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020), // Allow dates from 2020
      lastDate: DateTime(2030, 12, 31), // Allow dates up to 2030
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  IconData _getIconForChallengeType(ChallengeType type) {
    switch (type) {
      case ChallengeType.noSpend:
        return Icons.money_off;
      case ChallengeType.budgetLimit:
        return Icons.shopping_cart_checkout;
      case ChallengeType.savingsTarget:
        return Icons.savings;
      case ChallengeType.habitBuilding:
        return Icons.track_changes;
      case ChallengeType.custom:
        return Icons.star;
    }
  }

  Future<void> _addChallenge() async {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.challenge != null;
      
      final challenge = isEditing 
        ? widget.challenge!.copyWith(
            title: _titleController.text,
            description: _descriptionController.text,
            type: _selectedType,
            difficulty: _selectedDifficulty,
            status: _selectedStatus,
            startDate: _startDate,
            endDate: _endDate,
            targetAmount: double.tryParse(_targetAmountController.text) ?? 0.0,
            currentAmount: double.tryParse(_currentAmountController.text) ?? 0.0,
            categories: _selectedCategories,
            icon: _getIconForChallengeType(_selectedType),
          )
        : SpendingChallenge(
            title: _titleController.text,
            description: _descriptionController.text,
            type: _selectedType,
            difficulty: _selectedDifficulty,
            status: _selectedStatus,
            startDate: _startDate,
            endDate: _endDate,
            targetAmount: double.tryParse(_targetAmountController.text) ?? 0.0,
            currentAmount: double.tryParse(_currentAmountController.text) ?? 0.0,
            categories: _selectedCategories,
            icon: _getIconForChallengeType(_selectedType),
            color: Colors.blue, // Placeholder color
          );

      final viewModel = Provider.of<ChallengeViewModel>(context, listen: false);
      try {
        if (isEditing) {
          await viewModel.updateChallenge(challenge);
        } else {
          await viewModel.addChallenge(challenge);
        }
        
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to ${isEditing ? 'update' : 'add'} challenge: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge != null ? 'Edit Challenge' : 'Add Challenge'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Challenge Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ChallengeType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Challenge Type',
                  border: OutlineInputBorder(),
                ),
                items: ChallengeType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ChallengeDifficulty>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
                items: ChallengeDifficulty.values.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(difficulty.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ChallengeStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ChallengeStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentAmountController,
                decoration: const InputDecoration(
                  labelText: 'Current Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text(DateFormat('MMM d, yyyy').format(_startDate)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(context, false),
                      child: Text(DateFormat('MMM d, yyyy').format(_endDate)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Categories:'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var category in AppConstants.expenseCategories)
                    FilterChip(
                      label: Text(category),
                      selected: _selectedCategories.contains(category),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addChallenge,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.challenge != null ? 'Update Challenge' : 'Add Challenge'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
